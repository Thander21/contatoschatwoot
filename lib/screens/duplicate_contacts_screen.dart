import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/contact.dart';
import '../services/contacts_cache_service.dart';
import '../services/contacts_service.dart';
import '../services/duplicates_service.dart';

class DuplicateContactsScreen extends StatefulWidget {
  const DuplicateContactsScreen({super.key});

  @override
  State<DuplicateContactsScreen> createState() => _DuplicateContactsScreenState();
}

class _DuplicateContactsScreenState extends State<DuplicateContactsScreen> {
  final _logger = Logger('DuplicateContactsScreen');
  final _cacheService = ContactsCacheService();
  final _contactsService = ContactsService();
  final _duplicatesService = DuplicatesService();

  Map<String, List<Contact>> _duplicateGroups = {};
  bool _isLoading = true;
  String _status = 'Buscando contatos duplicados...';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final Set<String> _selectedGroups = {};
  bool _isDeleting = false;

  @override
  void initState() {
    super.initState();
    _findDuplicateContacts();
  }

  Future<void> _findDuplicateContacts() async {
    setState(() {
      _isLoading = true;
      _status = 'Buscando contatos duplicados...';
      _duplicateGroups = {};
      _selectedGroups.clear();
    });

    try {
      // Usa o cache
      final allContacts = await _cacheService.getContacts();

      // Usa o serviço de duplicados
      final groups = _duplicatesService.findDuplicateGroups(allContacts);

      setState(() {
        _duplicateGroups = groups;
        _status = '${_duplicateGroups.length} grupos de duplicatas encontrados';
      });
    } catch (e) {
      setState(() {
        _status = 'Erro: $e';
      });
      _logger.severe('Erro ao buscar contatos duplicados', e);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _deleteSelectedDuplicates() async {
    if (_selectedGroups.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione pelo menos um grupo para excluir')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: Text(
          'Tem certeza que deseja excluir ${_selectedGroups.length} ${_selectedGroups.length == 1 ? 'grupo' : 'grupos'} de contatos duplicados?\n\n'
          'Será mantido apenas o contato mais recente de cada grupo.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isDeleting = true;
      _status = 'Processando exclusão...';
    });

    int successCount = 0;
    int errorCount = 0;
    final List<int> deletedIds = [];

    try {
      for (final phone in _selectedGroups) {
        final group = _duplicateGroups[phone];
        if (group == null || group.length <= 1) continue;

        // Determina qual contato manter (mais recente e completo)
        final toKeep = _duplicatesService.getPrimaryContact(group);
        final toDelete = group.where((c) => c.id != toKeep.id).toList();

        // Deleta os duplicados
        for (final contact in toDelete) {
          try {
            await _contactsService.deleteContact(contact.id!);
            successCount++;
            deletedIds.add(contact.id!);
            _logger.info('Contato excluído com sucesso: ${contact.id}');
          } catch (e) {
            errorCount++;
            _logger.severe('Erro ao excluir contato ${contact.id}', e);
          }
        }
      }

      if (mounted) {
        final message = StringBuffer();
        message.write('Exclusão concluída! ');
        
        if (successCount > 0) {
          message.write('$successCount contatos excluídos com sucesso. ');
        }
        
        if (errorCount > 0) {
          message.write('Falha ao excluir $errorCount contatos.');
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(message.toString())),
        );

        // Atualiza o cache removendo os contatos deletados
        if (deletedIds.isNotEmpty) {
          _cacheService.removeContacts(deletedIds);
        }

        // Recarrega a lista após a exclusão
        _findDuplicateContacts();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _selectedGroups.clear();
        });
      }
    }
  }

  List<MapEntry<String, List<Contact>>> get _filteredGroups {
    if (_searchQuery.isEmpty) return _duplicateGroups.entries.toList();

    final query = _searchQuery.toLowerCase();
    return _duplicateGroups.entries.where((entry) {
      return entry.value.any((contact) {
        final name = contact.name.toLowerCase();
        final email = contact.email?.toLowerCase() ?? '';
        final phone = contact.phoneNumber?.toLowerCase() ?? '';
        
        return name.contains(query) || 
               email.contains(query) || 
               phone.contains(query);
      });
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contatos Duplicados'),
        actions: [
          if (_selectedGroups.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _isDeleting ? null : _deleteSelectedDuplicates,
              tooltip: 'Excluir selecionados',
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isDeleting ? null : _findDuplicateContacts,
            tooltip: 'Atualizar lista',
          ),
        ],
      ),
      body: Column(
        children: [
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
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_status),
                if (_duplicateGroups.isNotEmpty)
                  Text('${_filteredGroups.length} grupos, ${_selectedGroups.length} selecionados'),
              ],
            ),
          ),
          if (_selectedGroups.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              color: const Color.fromRGBO(0, 0, 255, 0.1),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.blue, size: 16.0),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: Text(
                      '${_selectedGroups.length} ${_selectedGroups.length == 1 ? 'grupo selecionado' : 'grupos selecionados'}. '
                      'Será mantido apenas o contato mais recente de cada grupo.',
                      style: const TextStyle(fontSize: 12.0, color: Colors.blue),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedGroups.clear()),
                    child: const Text('Limpar'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _duplicateGroups.isEmpty
                    ? const Center(child: Text('Nenhum contato duplicado encontrado'))
                    : _isDeleting
                        ? const Center(child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16.0),
                              Text('Excluindo contatos duplicados...'),
                            ],
                          ))
                        : ListView.builder(
                            itemCount: _filteredGroups.length,
                            itemBuilder: (context, index) {
                              final entry = _filteredGroups[index];
                              return _buildDuplicateGroup(entry.key, entry.value);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuplicateGroup(String phone, List<Contact> contacts) {
    // Determina qual é o contato principal (melhor)
    final primaryContact = _duplicatesService.getPrimaryContact(contacts);
    final isSelected = _selectedGroups.contains(phone);
    final duplicateCount = contacts.length - 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      color: isSelected ? const Color.fromRGBO(0, 0, 255, 0.1) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho do grupo
          ListTile(
            leading: Checkbox(
              value: isSelected,
              onChanged: (value) {
                setState(() {
                  if (value == true) {
                    _selectedGroups.add(phone);
                  } else {
                    _selectedGroups.remove(phone);
                  }
                });
              },
            ),
            title: Text(
              '${primaryContact.phoneNumber}\n',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('$duplicateCount ${duplicateCount == 1 ? 'duplicata' : 'duplicatas'}, ${contacts.length} contatos no total'),
            trailing: IconButton(
              icon: Icon(isSelected ? Icons.expand_less : Icons.expand_more),
              onPressed: () {
                setState(() {
                  if (isSelected) {
                    _selectedGroups.remove(phone);
                  } else {
                    _selectedGroups.add(phone);
                  }
                });
              },
            ),
          ),
          
          // Lista de contatos do grupo
          if (isSelected)
            Column(
              children: [
                const Divider(height: 1),
                ...contacts.map((contact) => _buildContactItem(contact, contact.id == primaryContact.id)),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildContactItem(Contact contact, bool isPrimary) {
    final name = contact.name;
    final email = contact.email;
    final phone = contact.phoneNumber;
    final updatedAt = contact.updatedAt?.toLocal().toString().substring(0, 16);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isPrimary ? const Color.fromRGBO(0, 128, 0, 0.1) : null,
        border: Border(
          top: BorderSide(color: Colors.grey.shade200, width: 1.0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (isPrimary)
                Container(
                  margin: const EdgeInsets.only(right: 8.0),
                  padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                  decoration: BoxDecoration(
                    color: Colors.green,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: const Text(
                    'PRINCIPAL',
                    style: TextStyle(color: Colors.white, fontSize: 10.0, fontWeight: FontWeight.bold),
                  ),
                ),
              Expanded(
                child: Text(
                  name,
                  style: TextStyle(
                    fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
          if (email != null && email.isNotEmpty) Text(email, style: const TextStyle(fontSize: 12.0)),
          Text(phone ?? '', style: const TextStyle(fontSize: 12.0)),
          if (updatedAt != null)
            Text(
              'Atualizado em: $updatedAt',
              style: const TextStyle(fontSize: 10.0, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
