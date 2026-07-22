import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/contact.dart';
import '../services/contacts_cache_service.dart';
import '../services/contacts_service.dart';
import '../services/phone_formatter_service.dart';

class InvalidPhonesScreen extends StatefulWidget {
  const InvalidPhonesScreen({super.key});

  @override
  State<InvalidPhonesScreen> createState() => _InvalidPhonesScreenState();
}

class _InvalidPhonesScreenState extends State<InvalidPhonesScreen> {
  final _logger = Logger('InvalidPhonesScreen');
  final _cacheService = ContactsCacheService();
  final _contactsService = ContactsService();
  final _phoneFormatter = PhoneFormatterService();

  List<Contact> _invalidContacts = [];
  final Set<int> _selectedIds = {};
  bool _isLoading = false;
  bool _isDeleting = false;
  String _status = 'Carregue os contatos primeiro no Dashboard';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // New State variables
  final Map<int, bool> _historyStatus = {}; // id -> hasHistory
  bool _isCheckingHistory = false;
  String _historyFilter = 'all'; // 'all', 'has_history', 'no_history'

  @override
  void initState() {
    super.initState();
    // Só carrega se já tiver cache
    if (_cacheService.isLoaded && _cacheService.count > 0) {
      _loadInvalidContacts();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvalidContacts() async {
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

      final invalid = _phoneFormatter.getContactsWithInvalidPhones(allContacts);

      if (mounted) {
        setState(() {
          _invalidContacts = invalid;
          _status =
              '${invalid.length} contatos com telefones inválidos encontrados';
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
    var list = _invalidContacts;

    // Filter by history
    if (_historyFilter != 'all') {
      list = list.where((c) {
        final hasHistory = _historyStatus[c.id];
        if (hasHistory == null) {
          return false; // Hide unchecked items when filtering
        }
        return _historyFilter == 'has_history' ? hasHistory : !hasHistory;
      }).toList();
    }

    if (_searchQuery.isEmpty) return list;

    final query = _searchQuery.toLowerCase();
    return list.where((contact) {
      final name = contact.name.toLowerCase();
      final email = contact.email?.toLowerCase() ?? '';
      final phone = contact.phoneNumber.toLowerCase();
      final company = contact.company?.toLowerCase() ?? '';

      return name.contains(query) ||
          email.contains(query) ||
          phone.contains(query) ||
          company.contains(query);
    }).toList();
  }

  Future<void> _recoverPhonesFromEmail() async {
    final candidates = _invalidContacts.where((c) {
      if (c.email == null || c.email!.isEmpty) return false;
      // Check if email starts with possible phone number (e.g. 55...)
      final parts = c.email!.split('@');
      if (parts.isEmpty) return false;
      final user = parts[0];

      // Basic check: looks like a phone number?
      final isNumeric = double.tryParse(user) != null;
      if (!isNumeric) return false;

      // Extract digits and check length
      final digits = user.replaceAll(RegExp(r'\D'), '');
      return digits.length >= 10 && digits.length <= 13;
    }).toList();

    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Nenhum email suspeito de ser telefone encontrado')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recuperar Telefones do Email'),
        content: Text(
          'Encontrados ${candidates.length} contatos onde o email parece ser um telefone.\n\n'
          'Deseja tentar atualizar esses telefones automaticamente?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Atualizar')),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
      _status = 'Atualizando contatos...';
    });

    int updatedCount = 0;

    for (var contact in candidates) {
      try {
        final emailPart = contact.email!.split('@')[0];
        final digits = emailPart.replaceAll(RegExp(r'\D'), '');

        // Construct new phone number
        String newPhone = digits;
        if (!newPhone.startsWith('+')) {
          if (newPhone.startsWith('55')) {
            newPhone = '+$newPhone';
          } else {
            // Assume BR if 10-11 digits
            if (newPhone.length >= 10 && newPhone.length <= 11) {
              newPhone = '+55$newPhone';
            }
          }
        }

        final updated = contact.copyWith(phoneNumber: newPhone);
        await _contactsService.updateContact(updated);
        updatedCount++;
      } catch (e) {
        _logger.warning('Erro ao atualizar contato ${contact.id}', e);
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$updatedCount contatos atualizados')),
      );
      _loadInvalidContacts();
    }
  }

  Future<void> _checkConversationHistory() async {
    setState(() {
      _isCheckingHistory = true;
      _status = 'Verificando histórico de conversas...';
    });

    int checked = 0;
    final total =
        _filteredContacts.length; // Check only currently filtered/visible

    for (var contact in _filteredContacts) {
      if (_historyStatus.containsKey(contact.id)) {
        checked++;
        continue;
      }

      try {
        final conversations =
            await _contactsService.getContactConversations(contact.id!);
        if (mounted) {
          setState(() {
            _historyStatus[contact.id!] = conversations.isNotEmpty;
            _status = 'Verificando... $checked / $total';
          });
        }
      } catch (e) {
        _logger.warning('Erro ao verificar conversas para ${contact.id}', e);
      }
      checked++;
    }

    if (mounted) {
      setState(() {
        _isCheckingHistory = false;
        _status = 'Verificação concluída';
      });
    }
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um contato')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Deseja excluir ${_selectedIds.length} contato(s) com telefones inválidos?\n\n'
          '⚠️ Esta ação não pode ser desfeita!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _status = 'Excluindo contatos...';
    });

    int successCount = 0;
    int errorCount = 0;
    final List<int> deletedIds = [];

    try {
      final contactsToDelete =
          _invalidContacts.where((c) => _selectedIds.contains(c.id)).toList();

      for (var contact in contactsToDelete) {
        try {
          await _contactsService.deleteContact(contact.id!);
          successCount++;
          deletedIds.add(contact.id!);
          _logger.info('Contato ${contact.id} excluído com sucesso');

          if (mounted) {
            setState(() {
              _status =
                  'Excluindo... $successCount de ${contactsToDelete.length}';
            });
          }
        } catch (e) {
          errorCount++;
          _logger.severe('Erro ao excluir contato ${contact.id}', e);
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Concluído!\n$successCount excluídos, $errorCount erros',
            ),
            backgroundColor: successCount > 0 ? Colors.green : Colors.red,
          ),
        );

        // Atualiza o cache removendo os contatos deletados
        if (deletedIds.isNotEmpty) {
          _cacheService.removeContacts(deletedIds);
        }

        _selectedIds.clear();
        _loadInvalidContacts();
      }
    } catch (e) {
      _logger.severe('Erro ao excluir contatos', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDeleting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Telefones Inválidos'),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: _isDeleting ? null : _deleteSelected,
              tooltip: 'Excluir selecionados',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading || _isDeleting || _isCheckingHistory
                ? null
                : _loadInvalidContacts,
            tooltip: 'Atualizar lista',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'recover') _recoverPhonesFromEmail();
              if (value == 'check_history') _checkConversationHistory();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'recover',
                child: Text('Recuperar via Email'),
              ),
              const PopupMenuItem(
                value: 'check_history',
                child: Text('Verificar Histórico'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Campo de busca
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  labelText: 'Buscar contatos',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                ),
                onChanged: (value) {
                  setState(() => _searchQuery = value);
                },
              ),
            ),

            // History Filter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Filtro: '),
                    Wrap(
                      spacing: 8,
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: _historyFilter == 'all',
                          onSelected: (v) =>
                              setState(() => _historyFilter = 'all'),
                        ),
                        ChoiceChip(
                          label: const Text('Com Conversas'),
                          selected: _historyFilter == 'has_history',
                          onSelected: (v) =>
                              setState(() => _historyFilter = 'has_history'),
                        ),
                        ChoiceChip(
                          label: const Text('Sem Conversas'),
                          selected: _historyFilter == 'no_history',
                          onSelected: (v) =>
                              setState(() => _historyFilter = 'no_history'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Status e botões de seleção
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                          child: Text(_status,
                              style: const TextStyle(fontSize: 12))),
                      Text(
                          '${filtered.length} itens | ${_selectedIds.length} selecionados'),
                    ],
                  ),
                  if (filtered.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isDeleting
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: _isDeleting || _selectedIds.isEmpty
                              ? null
                              : () {
                                  setState(() => _selectedIds.clear());
                                },
                          icon: const Icon(Icons.check_box_outline_blank,
                              size: 18),
                          label: const Text('Desmarcar Todos'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // Barra de ações quando tem seleção
            if (_selectedIds.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(8.0),
                color: Colors.red.shade50,
                child: Row(
                  children: [
                    const Icon(Icons.warning, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${_selectedIds.length} contato(s) selecionado(s) para exclusão',
                        style: const TextStyle(
                            color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() => _selectedIds.clear()),
                      child: const Text('Limpar'),
                    ),
                    ElevatedButton.icon(
                      onPressed: _deleteSelected,
                      icon: const Icon(Icons.delete),
                      label: const Text('Excluir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),

            // Lista de contatos
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _isDeleting
                      ? Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(_status),
                            ],
                          ),
                        )
                      : filtered.isEmpty
                          ? const Center(
                              child: Text(
                                  'Nenhum contato com telefone inválido encontrado'))
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
    );
  }

  Widget _buildContactCard(Contact contact) {
    final isSelected = _selectedIds.contains(contact.id);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: isSelected ? Colors.red.shade50 : null,
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: _isDeleting
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
                const Icon(Icons.phone, size: 16, color: Colors.red),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    contact.phoneNumber,
                    style: const TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (contact.email != null && contact.email!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.email, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(contact.email!)),
                ],
              ),
            ],
            if (contact.company != null && contact.company!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.business, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(child: Text(contact.company!)),
                ],
              ),
            ],
            if (contact.sourceId != null) ...[
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(Icons.input, size: 16, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Origem: ${contact.sourceId}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.blue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _getInvalidReason(contact.phoneNumber),
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontStyle: FontStyle.italic,
              ),
            ),
            if (_historyStatus.containsKey(contact.id))
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      _historyStatus[contact.id!]!
                          ? Icons.chat
                          : Icons.chat_bubble_outline,
                      size: 16,
                      color: _historyStatus[contact.id!]!
                          ? Colors.green
                          : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _historyStatus[contact.id!]!
                          ? 'Tem conversas'
                          : 'Sem histórico',
                      style: TextStyle(
                        fontSize: 12,
                        color: _historyStatus[contact.id!]!
                            ? Colors.green
                            : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _getInvalidReason(String phone) {
    if (phone.isEmpty) return 'Telefone vazio';

    String digits = phone.replaceAll(RegExp(r'\D+'), '');

    if (digits.startsWith('55')) {
      digits = digits.substring(2);
    }

    if (digits.length < 10) {
      return 'Muito curto (menos de 10 dígitos)';
    }

    if (digits.length > 11) {
      return 'Muito longo (mais de 11 dígitos)';
    }

    final ddd = int.tryParse(digits.substring(0, 2));
    if (ddd == null) {
      return 'DDD inválido';
    }

    return 'DDD não existe no Brasil ($ddd)';
  }
}
