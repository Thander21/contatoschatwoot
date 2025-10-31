import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/contact.dart';
import '../services/contacts_cache_service.dart';
import '../services/contacts_service.dart';
import '../services/company_service.dart';

class CompanyManagementScreen extends StatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  State<CompanyManagementScreen> createState() => _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends State<CompanyManagementScreen> {
  final _logger = Logger('CompanyManagementScreen');
  final _cacheService = ContactsCacheService();
  final _contactsService = ContactsService();
  final _companyService = CompanyService();

  List<Contact> _problemContacts = [];
  final Set<int> _selectedIds = {};
  final Map<int, String> _companySuggestions = {};
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
      _status = 'Buscando contatos...';
    });

    try {
      // Usa o cache
      final allContacts = await _cacheService.getContacts();
      final withoutCompany = _companyService.getContactsWithoutCompany(allContacts);
      final withCompanyInName = _companyService.getContactsWithCompanyInName(allContacts);

      // Gera sugestões
      final suggestions = <int, String>{};
      for (var contact in [...withoutCompany, ...withCompanyInName]) {
        final suggested = _companyService.suggestCompany(contact);
        if (suggested != null && contact.id != null) {
          suggestions[contact.id!] = suggested;
        }
      }

      setState(() {
        _problemContacts = [...withoutCompany, ...withCompanyInName];
        _companySuggestions.addAll(suggestions);
        _status = '${_problemContacts.length} contatos sem empresa';
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
    if (_filterType == 'com_sugestao') {
      return _problemContacts.where((c) => _companySuggestions.containsKey(c.id)).toList();
    }
    if (_filterType == 'no_nome') {
      return _companyService.getContactsWithCompanyInName(_problemContacts);
    }
    return _problemContacts;
  }

  Future<void> _processSelected() async {
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um contato')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _status = 'Processando empresas...';
    });

    try {
      final contactsToUpdate = <Contact>[];

      for (var contact in _problemContacts) {
        if (!_selectedIds.contains(contact.id)) continue;

        Contact updated;
        if (_companySuggestions.containsKey(contact.id)) {
          // Usa a sugestão
          final company = _companySuggestions[contact.id]!;
          updated = _companyService.processContactCompany(contact);
          if (!updated.hasCompany) {
            updated = updated.copyWith(company: company);
          }
        } else {
          // Apenas processa (extrai do nome se houver)
          updated = _companyService.processContactCompany(contact);
        }

        if (updated != contact) {
          contactsToUpdate.add(updated);
        }
      }

      if (contactsToUpdate.isEmpty) {
        throw Exception('Nenhum contato foi modificado');
      }

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
      _logger.severe('Erro ao processar', e);
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

  void _showEditDialog(Contact contact) {
    final controller = TextEditingController(
      text: _companySuggestions[contact.id] ?? _companyService.suggestCompany(contact) ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Empresa'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Contato: ${contact.name}', style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'Empresa',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                if (controller.text.isNotEmpty) {
                  _companySuggestions[contact.id!] = controller.text;
                } else {
                  _companySuggestions.remove(contact.id);
                }
              });
              Navigator.pop(context);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredContacts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Empresas'),
        actions: [
          if (_selectedIds.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _isProcessing ? null : _processSelected,
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
              color: Colors.purple.shade50,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.purple),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${_selectedIds.length} contato(s) selecionado(s)',
                      style: const TextStyle(color: Colors.purple),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedIds.clear()),
                    child: const Text('Limpar'),
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
                        ? const Center(child: Text('Todos os contatos têm empresa'))
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
              onPressed: _isProcessing ? null : _processSelected,
              label: Text('Processar ${_selectedIds.length}'),
              icon: const Icon(Icons.business),
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
          _buildFilterChip('Com sugestão', 'com_sugestao'),
          _buildFilterChip('Empresa no nome', 'no_nome'),
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
    final suggestion = _companySuggestions[contact.id];

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: isSelected ? Colors.purple.shade50 : null,
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
        title: Row(
          children: [
            Expanded(child: Text(contact.name)),
            IconButton(
              icon: const Icon(Icons.edit, size: 20),
              onPressed: () => _showEditDialog(contact),
              tooltip: 'Editar empresa',
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phoneNumber, style: const TextStyle(fontSize: 12)),
            if (suggestion != null)
              Row(
                children: [
                  const Icon(Icons.business, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Sugestão: $suggestion',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
