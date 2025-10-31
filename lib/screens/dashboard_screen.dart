import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import '../models/contact.dart';
import '../services/contacts_cache_service.dart';
import '../services/contacts_service.dart';
import '../services/phone_formatter_service.dart';
import '../services/company_service.dart';
import '../services/duplicates_service.dart';
import '../services/backup_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _logger = Logger('DashboardScreen');
  final _cacheService = ContactsCacheService();
  final _contactsService = ContactsService();
  final _backupService = BackupService();

  List<Contact> _contacts = [];
  bool _isLoading = true;
  String _status = 'Carregando contatos...';
  ContactsStatistics? _stats;

  @override
  void initState() {
    super.initState();
    _loadData();

    // Adiciona listener para atualizar quando o cache mudar
    _cacheService.addListener(_onCacheUpdated);
  }

  @override
  void dispose() {
    _cacheService.removeListener(_onCacheUpdated);
    super.dispose();
  }

  void _onCacheUpdated(List<Contact> contacts) {
    if (mounted) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _status = _cacheService.isLoaded
          ? 'Carregando do cache...'
          : 'Carregando contatos da API...';
    });

    try {
      // Usa o cache - só carrega da API se necessário
      final contacts = await _cacheService.getContacts();

      final stats = await _contactsService.getStatistics(contacts);

      setState(() {
        _contacts = contacts;
        _stats = stats;
        _status = '${contacts.length} contatos carregados';
        _isLoading = false;
      });
    } catch (e) {
      _logger.severe('Erro ao carregar dados', e);
      if (mounted) {
        setState(() {
          _status = 'Erro ao carregar: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _createBackup() async {
    if (_contacts.isEmpty) {
      _showMessage('Nenhum contato para fazer backup');
      return;
    }

    setState(() => _status = 'Criando backup...');

    try {
      final path = await _backupService.exportToExcel(
        _contacts,
        onStatusUpdate: (status) {
          if (mounted) setState(() => _status = status);
        },
      );

      if (mounted) {
        _showMessage('Backup criado com sucesso!\n$path', isError: false);
      }
    } catch (e) {
      _logger.severe('Erro ao criar backup', e);
      _showMessage('Erro ao criar backup: $e');
    }
  }

  void _showMessage(String message, {bool isError = true}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciador de Contatos Chatwoot'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading
                ? null
                : () async {
                    await _cacheService.reload();
                    _loadData();
                  },
            tooltip: 'Recarregar da API',
          ),
          IconButton(
            icon: const Icon(Icons.backup),
            onPressed: _isLoading ? null : _createBackup,
            tooltip: 'Fazer Backup',
          ),
        ],
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(_status),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStatisticsCard(),
                    const SizedBox(height: 16),
                    _buildIssuesCard(),
                    const SizedBox(height: 16),
                    _buildActionsCard(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.bar_chart, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Estatísticas Gerais',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildStatItem(
              'Total de Contatos',
              _stats?.total.toString() ?? '0',
              Icons.contacts,
              Colors.blue,
            ),
            _buildStatItem(
              'Status',
              _status,
              Icons.info_outline,
              Colors.grey,
              isSmall: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIssuesCard() {
    final hasIssues = _stats?.hasIssues ?? false;

    return Card(
      color: hasIssues ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  hasIssues ? Icons.warning_amber : Icons.check_circle,
                  size: 28,
                  color: hasIssues ? Colors.orange : Colors.green,
                ),
                const SizedBox(width: 12),
                Text(
                  hasIssues ? 'Problemas Detectados' : 'Tudo OK!',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            if (_stats != null) ...[
              _buildIssueItem(
                'Sem código +55',
                _stats!.withoutCountryCode,
                Icons.phone_android,
                Colors.red,
                onTap: () => Navigator.pushNamed(context, '/phone-format'),
              ),
              _buildIssueItem(
                'Duplicados',
                _stats!.duplicates,
                Icons.content_copy,
                Colors.orange,
                onTap: () => Navigator.pushNamed(context, '/duplicates'),
              ),
              _buildIssueItem(
                'Sem empresa',
                _stats!.withoutCompany,
                Icons.business,
                Colors.blue,
                onTap: () => Navigator.pushNamed(context, '/company-management'),
              ),
              _buildIssueItem(
                'Telefone inválido',
                _stats!.invalidPhone,
                Icons.phone_disabled,
                Colors.purple,
                onTap: () => Navigator.pushNamed(context, '/phone-format'),
              ),
              if (_stats!.invalidEmail > 0)
                _buildIssueItem(
                  'Email inválido',
                  _stats!.invalidEmail,
                  Icons.email,
                  Colors.brown,
                ),
              if (_stats!.withoutName > 0)
                _buildIssueItem(
                  'Sem nome',
                  _stats!.withoutName,
                  Icons.person_off,
                  Colors.pink,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.build, size: 28),
                const SizedBox(width: 12),
                Text(
                  'Ações Rápidas',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const Divider(height: 24),
            _buildActionButton(
              'Fazer Backup Completo',
              'Exportar todos os contatos para Excel',
              Icons.backup,
              Colors.green,
              onPressed: _createBackup,
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Corrigir Telefones',
              'Adicionar +55 e corrigir formatos',
              Icons.phone_android,
              Colors.blue,
              onPressed: () => Navigator.pushNamed(context, '/phone-format'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Limpar Duplicados',
              'Remover contatos duplicados',
              Icons.content_copy,
              Colors.orange,
              onPressed: () => Navigator.pushNamed(context, '/duplicates'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Gerenciar Empresas',
              'Renomear e preencher empresas',
              Icons.business,
              Colors.purple,
              onPressed: () => Navigator.pushNamed(context, '/company-management'),
            ),
            const SizedBox(height: 12),
            _buildActionButton(
              'Ver Todos os Contatos',
              'Lista completa com busca',
              Icons.list,
              Colors.grey,
              onPressed: () => Navigator.pushNamed(context, '/contacts-list'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool isSmall = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: color, size: isSmall ? 16 : 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: isSmall ? 12 : 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isSmall ? 12 : 18,
              fontWeight: isSmall ? FontWeight.normal : FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssueItem(
    String label,
    int count,
    IconData icon,
    Color color, {
    VoidCallback? onTap,
  }) {
    if (count == 0) return const SizedBox.shrink();

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton(
    String title,
    String subtitle,
    IconData icon,
    Color color, {
    required VoidCallback onPressed,
  }) {
    return OutlinedButton(
      onPressed: _isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.all(16),
        side: BorderSide(color: color.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }
}
