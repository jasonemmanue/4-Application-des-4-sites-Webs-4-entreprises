import 'lien_api.dart';

/// Configuration API pour l'app Gestionnaire (terrain).
class ApiConfig {
  ApiConfig._();

  /// Base URL — surchargeable via --dart-define pour le dev local.
  /// En production le lien est decode depuis [LienApi] (XOR, pas en clair).
  static final String baseUrl = const String.fromEnvironment('API_BASE_URL').isEmpty
      ? LienApi.apiUrl
      : const String.fromEnvironment('API_BASE_URL');

  static const String appVersion = '2.1.0';

  /// Fichiers servis par l'API (`/uploads/…`) ou par le site (`/images/…`).
  static String resolve(String url) {
    if (url.startsWith('http')) return url;
    final path = url.startsWith('/') ? url : '/$url';
    return path.startsWith('/uploads/')
        ? '$baseUrl$path'
        : '${LienApi.siteUrl}$path';
  }

  static const String apiPrefix = '/api/v1';
  static String get apiBase => '$baseUrl$apiPrefix';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 25);

  static const String tokenKey = 'staff_jwt';
  static const String userKey = 'staff_user';
  static const Duration inactivityTimeout = Duration(hours: 24);
}
