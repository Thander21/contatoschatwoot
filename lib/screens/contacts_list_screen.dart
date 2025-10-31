import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/contact.dart';
import '../services/contacts_cache_service.dart';
import '../services/contacts_service.dart';
import '../services/backup_service.dart';

class ContactsListScreen extends StatefulWidget {
  const ContactsListScreen({super.key});

  @override
  State<ContactsListScreen> createState() => _ContactsListScreenState();
}

class _ContactsListScreenState extends State<ContactsListScreen> {
  final _logger = Logger('ContactsListScreen');
  final _cacheService = ContactsCacheService();
  final _backupService = BackupService();
  final _searchController = TextEditingController();

  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  String _status = 'Carregando contatos...';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
      _status = _cacheService.isLoaded
          ? 'Carregando do cache...'
          : 'Carregando contatos da API...';
    });

    try {
      // Usa o cache
      final contacts = await _cacheService.getContacts();

      setState(() {
        _allContacts = contacts;
        _filteredContacts = contacts;
        _status = '${contacts.length} contatos carregados';
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Erro ao carregar contatos', e);
      if (mounted) {
        setState(() {
          _status = 'Erro: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _filterContacts(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredContacts = _allContacts;
      } else {
        final lowerQuery = query.toLowerCase();
        _filteredContacts = _allContacts.where((contact) {
          return contact.name.toLowerCase().contains(lowerQuery) ||
              (contact.email?.toLowerCase().contains(lowerQuery) ?? false) ||
              contact.phoneNumber.contains(lowerQuery) ||
              (contact.company?.toLowerCase().contains(lowerQuery) ?? false);
        }).toList();
      }
    });
  }

  Future<void> _exportToExcel() async {
    if (_filteredContacts.isEmpty) return;

    setState(() => _status = 'Exportando...');

    try {
      final path = await _backupService.exportToExcel(
        _filteredContacts,
        customFileName: 'lista_contatos_${DateTime.now().millisecondsSinceEpoch}.xlsx',
        onStatusUpdate: (status) {
          if (mounted) setState(() => _status = status);
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Exportado com sucesso!\n$path'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      _logger.severe('Erro ao exportar', e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao exportar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Todos os Contatos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _isLoading ? null : _exportToExcel,
            tooltip: 'Exportar para Excel',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadContacts,
            tooltip: 'Recarregar',
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
                labelText: 'Buscar contato',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _filterContacts('');
                        },
                      )
                    : null,
              ),
              onChanged: _filterContacts,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_status, style: const TextStyle(fontSize: 12)),
                Text(
                  '${_filteredContacts.length} contatos',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredContacts.isEmpty
                    ? const Center(child: Text('Nenhum contato encontrado'))
                    : ListView.builder(
                        itemCount: _filteredContacts.length,
                        itemBuilder: (context, index) {
                          return _buildContactCard(_filteredContacts[index]);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard(Contact contact) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: contact.hasCountryCode ? Colors.green : Colors.orange,
          child: Text(
            contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(contact.name.isEmpty ? 'Sem nome' : contact.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(contact.phoneNumber),
            if (contact.email != null) Text(contact.email!, style: const TextStyle(fontSize: 12)),
            if (contact.company != null)
              Text(
                contact.company!,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!contact.hasCountryCode)
              const Icon(Icons.warning, color: Colors.orange, size: 16),
            if (!contact.hasCompany)
              const Icon(Icons.business_outlined, color: Colors.grey, size: 16),
          ],
        ),
        onTap: () => _showContactDetails(contact),
      ),
    );
  }

  void _showContactDetails(Contact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(contact.name),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('ID', contact.id?.toString() ?? 'N/A'),
              _buildDetailRow('Telefone', contact.phoneNumber),
              if (contact.email != null) _buildDetailRow('Email', contact.email!),
              if (contact.company != null) _buildDetailRow('Empresa', contact.company!),
              if (contact.createdAt != null)
                _buildDetailRow('Criado', contact.createdAt.toString().substring(0, 16)),
              if (contact.updatedAt != null)
                _buildDetailRow('Atualizado', contact.updatedAt.toString().substring(0, 16)),
              const Divider(),
              _buildStatusRow('Código +55', contact.hasCountryCode),
              _buildStatusRow('Telefone válido', contact.hasValidPhone),
              _buildStatusRow('Tem empresa', contact.hasCompany),
              if (contact.email != null)
                _buildStatusRow('Email válido', contact.hasValidEmail),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, bool status) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,
            size: 16,
            color: status ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontSize: 12)),
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
