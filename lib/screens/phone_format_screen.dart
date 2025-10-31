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
  bool _isLoading = true;
  bool _isProcessing = false;
  String _status = 'Carregando...';
  String _filterType = 'todos';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _status = 'Buscando contatos com problemas...';
    });

    try {
      // Usa o cache
      final allContacts = await _cacheService.getContacts();
      final problematic = _phoneFormatter.getContactsNeedingFormat(allContacts);

      setState(() {
        _problemContacts = problematic;
        _status = '${problematic.length} contatos precisam de formatação';
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Erro ao carregar', e);
      setState(() {
        _status = 'Erro: $e';
        _isLoading = false;
      });
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
      body: Column(
        children: [
          _buildFilterChips(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_status, style: const TextStyle(fontSize: 12)),
                Text('${filtered.length} itens | ${_selectedIds.length} selecionados'),
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
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) {
          setState(() {
            if (value == true) {
              _selectedIds.add(contact.id!);
            } else {
              _selectedIds.remove(contact.id);
            }
          });
        },
        title: Text(contact.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('De: '),
                Text(contact.phoneNumber),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.arrow_forward, size: 16),
                const SizedBox(width: 4),
                Text(
                  formatted,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
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
