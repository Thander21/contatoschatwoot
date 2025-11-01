import 'credentials_service.dart';

/// Configurações centralizadas da API
/// Agora utiliza credenciais dinâmicas do CredentialsService
class ApiConfig {
  static final _credentialsService = CredentialsService();

  // Account ID padrão (pode ser configurável no futuro)
  static const String accountId = '1';

  /// Verifica se as credenciais estão configuradas
  static bool get hasCredentials => _credentialsService.hasCredentials;

  /// Obtém a URL base da API
  static String get baseUrl {
    if (!_credentialsService.hasCredentials) {
      throw Exception('Credenciais não configuradas. Configure a URL e token primeiro.');
    }
    return _credentialsService.apiUrl!;
  }

  /// Obtém o token da API
  static String get apiToken {
    if (!_credentialsService.hasCredentials) {
      throw Exception('Credenciais não configuradas. Configure a URL e token primeiro.');
    }
    return _credentialsService.apiToken!;
  }

  /// Headers para requisições HTTP
  static Map<String, String> get headers => {
    'Accept': 'application/json; charset=utf-8',
    'api_access_token': apiToken,
    'Content-Type': 'application/json',
  };

  /// Endpoint para listagem de contatos
  static String get contactsEndpoint => '$baseUrl/api/v1/accounts/$accountId/contacts';

  /// Endpoint para operações em contato específico
  static String contactEndpoint(String contactId) =>
      '$baseUrl/api/v1/accounts/$accountId/contacts/$contactId';
}
