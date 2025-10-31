import 'package:logging/logging.dart';
import '../models/contact.dart';
import 'contacts_service.dart';

/// Serviço singleton para cache de contatos em memória
///
/// Mantém todos os contatos carregados em memória para evitar
/// múltiplas chamadas à API. Recarrega apenas quando necessário.
class ContactsCacheService {
  static final ContactsCacheService _instance = ContactsCacheService._internal();
  factory ContactsCacheService() => _instance;
  ContactsCacheService._internal();

  final _log = Logger('ContactsCacheService');
  final _contactsService = ContactsService();

  // Cache em memória
  List<Contact> _cachedContacts = [];
  bool _isLoaded = false;
  bool _isLoading = false;
  DateTime? _lastLoadTime;

  // Listeners para notificar quando os contatos mudarem
  final List<Function(List<Contact>)> _listeners = [];

  /// Retorna os contatos do cache (se já carregados) ou carrega da API
  Future<List<Contact>> getContacts({bool forceReload = false}) async {
    // Se já está carregando, aguarda
    if (_isLoading) {
      _log.info('Já está carregando contatos, aguardando...');
      while (_isLoading) {
        await Future.delayed(Duration(milliseconds: 100));
      }
      return _cachedContacts;
    }

    // Se já tem cache e não é reload forçado, retorna o cache
    if (_isLoaded && !forceReload) {
      _log.info('Retornando ${_cachedContacts.length} contatos do cache');
      return _cachedContacts;
    }

    // Carrega da API
    return await _loadFromApi();
  }

  /// Carrega contatos da API e atualiza o cache
  Future<List<Contact>> _loadFromApi() async {
    _isLoading = true;
    _log.info('Carregando contatos da API...');

    try {
      final contacts = await _contactsService.fetchAllContacts(
        onStatusUpdate: (status) {
          _log.fine(status);
        },
      );

      _cachedContacts = contacts;
      _isLoaded = true;
      _lastLoadTime = DateTime.now();

      _log.info('✅ ${contacts.length} contatos carregados e salvos no cache');

      // Notifica todos os listeners
      _notifyListeners();

      return _cachedContacts;
    } catch (e) {
      _log.severe('Erro ao carregar contatos: $e');
      rethrow;
    } finally {
      _isLoading = false;
    }
  }

  /// Força recarregamento dos contatos
  Future<List<Contact>> reload() async {
    _log.info('🔄 Forçando reload dos contatos...');
    return await getContacts(forceReload: true);
  }

  /// Atualiza um contato específico no cache
  void updateContact(Contact updatedContact) {
    final index = _cachedContacts.indexWhere((c) => c.id == updatedContact.id);
    if (index != -1) {
      _cachedContacts[index] = updatedContact;
      _log.info('Contato ${updatedContact.id} atualizado no cache');
      _notifyListeners();
    }
  }

  /// Remove um contato do cache
  void removeContact(int contactId) {
    _cachedContacts.removeWhere((c) => c.id == contactId);
    _log.info('Contato $contactId removido do cache');
    _notifyListeners();
  }

  /// Remove múltiplos contatos do cache
  void removeContacts(List<int> contactIds) {
    final idsSet = contactIds.toSet();
    _cachedContacts.removeWhere((c) => idsSet.contains(c.id));
    _log.info('${contactIds.length} contatos removidos do cache');
    _notifyListeners();
  }

  /// Adiciona um listener para ser notificado quando os contatos mudarem
  void addListener(Function(List<Contact>) listener) {
    _listeners.add(listener);
  }

  /// Remove um listener
  void removeListener(Function(List<Contact>) listener) {
    _listeners.remove(listener);
  }

  /// Notifica todos os listeners sobre mudanças
  void _notifyListeners() {
    for (final listener in _listeners) {
      try {
        listener(_cachedContacts);
      } catch (e) {
        _log.warning('Erro ao notificar listener: $e');
      }
    }
  }

  /// Limpa o cache
  void clearCache() {
    _cachedContacts = [];
    _isLoaded = false;
    _lastLoadTime = null;
    _log.info('Cache limpo');
    _notifyListeners();
  }

  /// Retorna informações sobre o estado do cache
  Map<String, dynamic> getCacheInfo() {
    return {
      'isLoaded': _isLoaded,
      'isLoading': _isLoading,
      'contactsCount': _cachedContacts.length,
      'lastLoadTime': _lastLoadTime?.toIso8601String(),
    };
  }

  /// Verifica se o cache está carregado
  bool get isLoaded => _isLoaded;

  /// Verifica se está carregando
  bool get isLoading => _isLoading;

  /// Retorna a quantidade de contatos no cache
  int get count => _cachedContacts.length;

  /// Retorna quando foi o último carregamento
  DateTime? get lastLoadTime => _lastLoadTime;
}
