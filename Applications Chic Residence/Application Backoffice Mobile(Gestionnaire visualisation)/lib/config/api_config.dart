class ApiConfig {
  ApiConfig._();

  /// Cibles :
  ///  - Production Railway (défaut) : https://api-production-4e71.up.railway.app
  ///  - Docker local (émulateur Android) : http://10.0.2.2:8002
  /// Exemple : flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8002
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-production-4e71.up.railway.app',
  );
  static const String apiPrefix = '/api/v1';
  static String get apiBase => '$baseUrl$apiPrefix';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String tokenKey = 'admin_jwt';
  static const String refreshKey = 'admin_refresh';
  static const Duration inactivityTimeout = Duration(days: 7);
}
