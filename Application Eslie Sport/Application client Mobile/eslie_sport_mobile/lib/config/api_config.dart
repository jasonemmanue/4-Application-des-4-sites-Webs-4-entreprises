/// Configuration centrale de l'acces a l'API FastAPI du site salle-de-sport.
///
/// Trois cibles possibles, choisies au build avec `--dart-define`:
///
///   flutter run --dart-define=API_ENV=local     // emulateur -> http://10.0.2.2:3401
///   flutter run --dart-define=API_ENV=staging   // Railway preview
///   flutter run                                 // production (defaut)
///
/// `API_BASE_URL` peut aussi etre passe directement pour ecraser la resolution
/// par environnement, utile pour tester contre un tunnel ngrok par exemple.
class ApiConfig {
  ApiConfig._();

  static const String _envName = String.fromEnvironment(
    'API_ENV',
    defaultValue: 'production',
  );

  static const String _override = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  /// Emulateur Android : `10.0.2.2` = la machine hote (le laptop).
  /// Port `8010` = celui expose par `docker-compose.yml` du site pour l'API
  /// (voir `salle-de-sport/docker-compose.yml`, service `api` : `8010:8000`).
  static const String _localBase = 'http://10.0.2.2:8010';
  /// API deployee sur Railway (production).
  static const String _productionBase =
      'https://api-production-fc58.up.railway.app';

  /// Alias staging par defaut sur la meme instance — remplacez ici si un
  /// deploiement de preview distinct est mis en place.
  static const String _stagingBase = _productionBase;

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    return switch (_envName) {
      'local' => _localBase,
      'staging' => _stagingBase,
      _ => _productionBase,
    };
  }

  static const String apiVersion = '/api/v1';
  static String get apiBase => '$baseUrl$apiVersion';
  static String get uploadsBase => '$baseUrl/uploads';

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Coordonnees fallback si /settings/public est injoignable.
  static const String contactPhone = '+2250545079850';
  static const String whatsappNumber = '2250545079850';
  static const String contactPhoneDisplay = '+225 05 45 07 98 50';
  static const String gymName = 'ESLIE SPORT';
  static const String gymLocation = 'Blaukauss, Abidjan, Cote d\'Ivoire';
  static const String slogan = 'Parce que le corps a besoin de sport';

  static const int depositPercent = 50;
}
