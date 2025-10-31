/// Configurações centralizadas da API
class ApiConfig {
  // TODO: Mover para variável de ambiente ou SharedPreferences
  static const String baseUrl = 'https://chat.pdvdmais.com.br/api/v1';
  static const String apiToken = 'NdFydWAhjuf7Kp7xz3EittFK';
  static const String accountId = '1';

  static Map<String, String> get headers => {
    'Accept': 'application/json; charset=utf-8',
    'api_access_token': apiToken,
    'Content-Type': 'application/json',
  };

  static String get contactsEndpoint => '$baseUrl/accounts/$accountId/contacts';

  static String contactEndpoint(String contactId) =>
      '$baseUrl/accounts/$accountId/contacts/$contactId';
}
