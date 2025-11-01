import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/contact.dart';
import '../services/contacts_cache_service.dart';
import '../services/contacts_service.dart';
import '../services/phone_formatter_service.dart';

class PhoneFormatScreen extends StatefulWidget {
  const PhoneFormatScreen({super.key});

  @override
  State<PhoneFormatScreen> createState() => _PhoneFormatScreenState();
}

class _PhoneFormatScreenState extends State<PhoneFormatScreen> {
  final _logger = Logger('PhoneFormatScreen');
  final _cacheService = ContactsCacheService();
  final _contactsService = ContactsService();
  final _phoneFormatter = PhoneFormatterService();

  List<Contact> _problemContacts = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = false;
  bool _isProcessing = false;
  String _status = 'Carregue os contatos primeiro no Dashboard';
  String _filterType = 'todos';

  @override
  void initState() {
    super.initState();
    // Só carrega se já tiver cache
    if (_cacheService.isLoaded && _cacheService.count > 0) {
      _loadContacts();
    }
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _status = 'Buscando contatos...';
    });

    try {
      // Usa o cache
      final allContacts = await _cacheService.getContacts(
        onStatusUpdate: (status) {
          if (mounted) setState(() => _status = status);
        },
      );

      if (mounted) setState(() => _status = 'Analisando telefones...');

      // Filtra apenas contatos que precisam de formatação E são válidos
      // Exclui telefones inválidos (muito curtos, muito longos, DDD inválido)
      final problematic = _phoneFormatter.getContactsNeedingFormat(allContacts).where((contact) {
        // Verifica se é um telefone brasileiro válido
        // Se não for válido, não deve aparecer aqui (vai para tela de inválidos)
        final digits = contact.phoneNumber.replaceAll(RegExp(r'\D+'), '');
        final cleanDigits = digits.startsWith('55') ? digits.substring(2) : digits;

        // Telefone deve ter 10 ou 11 dígitos para ser formatável
        if (cleanDigits.length < 10 || cleanDigits.length > 11) {
          return false;
        }

        // Verifica se tem DDD válido
        if (cleanDigits.length >= 2) {
          final ddd = int.tryParse(cleanDigits.substring(0, 2));
          if (ddd != null && !_phoneFormatter.isValidBrazilianPhone('+55$cleanDigits')) {
            return false; // DDD inválido
          }
        }

        return true; // É válido e precisa de formatação
      }).toList();

      if (mounted) {
        setState(() {
          _problemContacts = problematic;
          _status = '${problematic.length} contatos precisam de formatação';
          _isLoading = false;
        });
      }
    } catch (e) {
      _logger.severe('Erro ao carregar', e);
      if (mounted) {
        setState(() {
          _status = 'Erro: $e';
          _isLoading = false;
        });
      }
    }
  }

  List<Contact> get _filteredContacts {
    if (_filterType == 'todos') return _problemContacts;

    return _problemContacts.where((contact) {
      final issue = _phoneFormatter.identifyPhoneIssue(contact.phoneNumber);
      switch (_filterType) {
        case 'sem_codigo':
          return issue == PhoneIssueType.missingCountryCode;
        case 'formato_antigo':
          return issue == PhoneIssueType.oldFormat;
        case 'muito_curto':
          return issue == PhoneIssueType.tooShort;
        case 'muito_longo':
          return issue == PhoneIssueType.tooLong;
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _formatSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um contato')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Formatação'),
        content: Text(
          'Deseja formatar ${_selectedIds.length} contato(s)?\n\n'
          'Os telefones serão atualizados com o código +55.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Formatar'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isProcessing = true;
      _status = 'Formatando contatos...';
    });

    try {
      final contactsToUpdate = _problemContacts
          .where((c) => _selectedIds.contains(c.id))
          .map((c) => _phoneFormatter.formatContact(c))
          .toList();

      final result = await _contactsService.updateMultipleContacts(
        contactsToUpdate,
        onStatusUpdate: (status) {
          if (mounted) setState(() => _status = status);
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Concluído!\n${result['success']} sucessos, ${result['errors']} erros',
            ),
            backgroundColor: Colors.green,
          ),
        );

        // Recarrega o cache da API após updates
        await _cacheService.reload();

        _selectedIds.clear();
        _loadContacts();
      }
    } catch (e) {
      _logger.severe('Erro ao formatar', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Corrigir Telefones'),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isProcessing ? null : _formatSelected,
              tooltip: 'Formatar selecionados',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isProcessing ? null : _loadContacts,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildFilterChips(),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(_status, style: const TextStyle(fontSize: 12))),
                      Text('${filtered.length} itens | ${_selectedIds.length} selecionados'),
                    ],
                  ),
                  if (filtered.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isProcessing
                              ? null
                              : () {
                                  setState(() {
                                    _selectedIds.clear();
                                    for (var contact in filtered) {
                                      if (contact.id != null) {
                                        _selectedIds.add(contact.id!);
                                      }
                                    }
                                  });
                                },
                          icon: const Icon(Icons.check_box, size: 18),
                          label: const Text('Selecionar Todos'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _isProcessing || _selectedIds.isEmpty
                              ? null
                              : () {
                                  setState(() => _selectedIds.clear());
                                },
                          icon: const Icon(Icons.check_box_outline_blank, size: 18),
                          label: const Text('Desmarcar Todos'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.blue.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} contato(s) selecionado(s)',
                        style: const TextStyle(color: Colors.blue),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedIds.clear()),
                      child: const Text('Limpar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _formatSelected,
                      icon: const Icon(Icons.check),
                      label: const Text('Formatar'),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isProcessing
                      ? const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Processando...'),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? const Center(child: Text('Nenhum contato precisa de formatação'))
                          : ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                return _buildContactCard(filtered[index]);
                              },
                            ),
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedIds.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _isProcessing ? null : _formatSelected,
              label: Text('Formatar ${_selectedIds.length}'),
              icon: const Icon(Icons.check),
            ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          _buildFilterChip('Todos', 'todos'),
          _buildFilterChip('Sem +55', 'sem_codigo'),
          _buildFilterChip('Formato antigo', 'formato_antigo'),
          _buildFilterChip('Muito curto', 'muito_curto'),
          _buildFilterChip('Muito longo', 'muito_longo'),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() => _filterType = value);
        },
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    final isSelected = _selectedIds.contains(contact.id);
    final issue = _phoneFormatter.identifyPhoneIssue(contact.phoneNumber);
    final formatted = _phoneFormatter.formatPhoneNumber(contact.phoneNumber);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: isSelected ? Colors.blue.shade50 : null,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: _isProcessing
              ? null
              : (value) {
                  setState(() {
                    if (value == true) {
                      _selectedIds.add(contact.id!);
                    } else {
                      _selectedIds.remove(contact.id);
                    }
                  });
                },
        ),
        title: Text(
          contact.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text('Atual: ${contact.phoneNumber}'),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.arrow_forward, size: 16, color: Colors.green),
                const SizedBox(width: 4),
                Text(
                  'Novo: $formatted',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _phoneFormatter.getIssueDescription(issue),
              style: const TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ],
        ),
      ),
    );
  }
}
