/// Serviço para gerenciar credenciais da API em cache de sessão
/// As credenciais são armazenadas apenas em memória e perdidas ao fechar o app
class CredentialsService {
  static final CredentialsService _instance = CredentialsService._internal();
  factory CredentialsService() => _instance;
  CredentialsService._internal();

  String? _apiUrl;
  String? _apiToken;

  /// Verifica se as credenciais estão configuradas
  bool get hasCredentials => _apiUrl != null && _apiToken != null;

  /// Obtém a URL da API
  String? get apiUrl => _apiUrl;

  /// Obtém o token da API
  String? get apiToken => _apiToken;

  /// Define as credenciais
  void setCredentials(String url, String token) {
    _apiUrl = url.trim();
    _apiToken = token.trim();
  }

  /// Limpa as credenciais (chamado ao fechar o app)
  void clearCredentials() {
    _apiUrl = null;
    _apiToken = null;
  }

  /// Valida se a URL tem formato válido
  bool isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Valida se o token não está vazio
  bool isValidToken(String token) {
    return token.trim().isNotEmpty;
  }
}
