/// Adresse de l'API — partagée avec le site web et l'administration Next.js.
///
/// Un **seul** backend FastAPI (dépôt `salon-coiffure/`) sert :
///   • le site public (Next.js, port 3601 en Docker, 3000 en `npm run dev`)
///   • l'administration Next.js (port 3600 en Docker, 3001 en `npm run dev`)
///   • **cette application mobile** — pas d'API séparée
///
/// La valeur par défaut cible l'**API de production** (`api.florahair.online`,
/// hébergée sur Railway) : l'application, une fois compilée en release,
/// arrive dans les mains d'une cliente qui n'a rien à configurer. Un
/// appareil physique en clientèle n'atteint de toute façon jamais
/// `localhost:8000`.
///
/// Pour tester en développement contre la stack Docker locale, surcharger au
/// build :
///
/// ```bash
/// # Production (défaut, aucun --dart-define nécessaire)
/// flutter run
///
/// # Émulateur Android → API Docker locale (10.0.2.2 = alias vers l'hôte)
/// flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
///
/// # Simulateur iOS → API Docker locale (localhost fonctionne)
/// flutter run --dart-define=API_BASE_URL=http://localhost:8000
///
/// # Appareil physique + poste dev sur le même Wi-Fi (remplacer l'IP)
/// flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8000
///
/// # Release explicite production
/// flutter build apk --release \
///   --dart-define=API_BASE_URL=https://api.florahair.online
/// ```
class ApiConfig {
  /// Racine du backend, sans le préfixe `/api/v1`.
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.florahair.online',
  );

  /// Origine du site public — sert **uniquement** à résoudre les visuels
  /// livrés avec le site (`/images/...`), qui sont servis par Next et non
  /// par l'API. Les fichiers téléversés depuis l'admin (`/uploads/...`)
  /// restent servis par l'API et utilisent [baseUrl].
  ///
  /// Surchargeable au build : `--dart-define=SITE_BASE_URL=http://10.0.2.2:3601`.
  static const String siteBaseUrl = String.fromEnvironment(
    'SITE_BASE_URL',
    defaultValue: 'https://www.florahair.online',
  );

  static const String apiPrefix = '/api/v1';

  static String get apiRoot => '$baseUrl$apiPrefix';

  /// Étiquette envoyée dans l'en-tête `X-App-Source` de chaque requête HTTP.
  /// Le backend la stocke sur les réservations, avis, contacts et devis pour
  /// distinguer, dans l'administration, une demande mobile Android d'une
  /// demande venue du site web (qui n'envoie pas cet en-tête). Version à
  /// garder alignée sur `pubspec.yaml`.
  static const String appSource = 'android/1.0.0+1';

  // ── Contact salon ────────────────────────────────────
  static const String salonPhone = '+2250545079850';
  static const String salonWhatsapp = '2250545079850';
  static const String salonEmail = 'contact@florahair.com';
  static const String salonInfoline = '+2250545196765';

  // ── Paiement (GeniusPay) ────────────────────────────
  static const int paymentPollingIntervalSeconds = 3;
  static const int paymentTimeoutSeconds = 180;
  static const int paymentMaxRetries = 10;

  // ── Réservation ─────────────────────────────────────
  /// Délai avant expiration côté serveur d'une demande « à régler en
  /// ligne » restée sans paiement. Doit rester **aligné** sur
  /// `DEPOSIT_HOLD_MINUTES` de `backend/app/api/v1/routes/bookings.py`.
  static const int bookingExpiryMinutes = 30;

  /// Part du prix demandée en acompte. Le backend expose la valeur exacte
  /// via `GET /payments/config` (`deposit_percent`) : celle-ci n'est
  /// qu'un repli d'affichage tant que l'appel n'a pas répondu.
  static const double depositRatio = 0.5;
}
