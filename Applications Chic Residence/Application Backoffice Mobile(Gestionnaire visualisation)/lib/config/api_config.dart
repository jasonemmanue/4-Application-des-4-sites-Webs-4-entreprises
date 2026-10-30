import 'lien_api.dart';

class ApiConfig {
  ApiConfig._();

  /// Base URL — surchargeable via --dart-define pour le dev local.
  /// En production le lien est decode depuis [LienApi] (XOR, pas en clair).
  static final String baseUrl = const String.fromEnvironment('API_BASE_URL').isEmpty
      ? LienApi.apiUrl
      : const String.fromEnvironment('API_BASE_URL');
  static const String apiPrefix = '/api/v1';
  static String get apiBase => '$baseUrl$apiPrefix';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String tokenKey = 'admin_jwt';
  static const String refreshKey = 'admin_refresh';
  static const Duration inactivityTimeout = Duration(days: 7);
}
