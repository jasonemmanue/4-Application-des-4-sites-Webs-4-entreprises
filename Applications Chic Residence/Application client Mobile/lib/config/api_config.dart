/// Configuration des endpoints API de CHIC RESIDENCE.
///
/// Le backend est le meme FastAPI que celui du site web Next.js.
/// Ajuster [baseUrl] selon l'environnement (local, staging, production).
class ApiConfig {
  ApiConfig._();

  /// Base URL — a surcharger via --dart-define=API_BASE_URL=...
  ///
  /// Cibles courantes :
  ///  - Production Railway (défaut) : https://api-production-4e71.up.railway.app
  ///  - Docker local (émulateur Android) : http://10.0.2.2:8002
  ///  - Docker local (device physique) : http://<ip-LAN>:8002
  ///
  /// Exemple :
  ///   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8002
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-production-4e71.up.railway.app',
  );

  /// Prefixe versionne
  static const String apiPrefix = '/api/v1';

  /// URL complete
  static String get apiBase => '$baseUrl$apiPrefix';

  /// Base URL du site web qui sert les images statiques (`/images/...`,
  /// `/uploads/...`). Les résidences renvoient des URLs relatives — elles
  /// sont résolues via [resolveImage] avant d'être passées à
  /// CachedNetworkImage.
  ///
  /// - Production : `https://www.chicresidencemeublee.com`
  /// - Dev local  : passer `--dart-define=SITE_BASE_URL=http://10.0.2.2:3007`
  static const String siteBaseUrl = String.fromEnvironment(
    'SITE_BASE_URL',
    defaultValue: 'https://www.chicresidencemeublee.com',
  );

  /// Convertit une URL d'image renvoyée par l'API en URL absolue chargeable.
  ///
  /// Règles :
  /// - `null` ou vide → placeholder Chic Residence (couleur marque).
  /// - `http(s)://…` → renvoyée telle quelle.
  /// - `/uploads/…` → préfixée par [baseUrl] (servie par le backend FastAPI,
  ///   via `app.mount("/uploads", …)`).
  /// - `/images/…` ou n'importe quel autre chemin relatif → préfixé par
  ///   [siteBaseUrl] (fichiers Next.js `public/…`).
  static String resolveImage(String? url) {
    final u = (url ?? '').trim();
    if (u.isEmpty) {
      return 'https://placehold.co/800x600/EF4444/FFFFFF?text=Chic+Residence';
    }
    if (u.startsWith('http://') || u.startsWith('https://')) return u;
    if (u.startsWith('/uploads/') || u.startsWith('uploads/')) {
      return '$baseUrl/${u.replaceFirst(RegExp(r'^/'), '')}';
    }
    // Chemins relatifs `/images/…`, `/videos/…` : servis par le site Next.js.
    return '$siteBaseUrl/${u.replaceFirst(RegExp(r'^/'), '')}';
  }

  /// Timeout par defaut
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// WhatsApp
  static const String whatsappNumber = '2250545079850';
  static const String contactPhone = '+225 05 45 07 98 50';
  static const String contactEmail = 'chicresidencemeublee@gmail.com';
  static const String companyAddress =
      "Dans le dos de l'Ivoire Trade Center (ITC), Abidjan";

  /// Session anonyme
  static const String sessionIdKey = 'chic_session_id';

  /// Nom saisi a la derniere reservation — affiche sur le Profil.
  static const String guestNameKey = 'chic_guest_name';

  /// Le pop-up « Aucun frais cache » n'est montre qu'une fois.
  static const String feesNoticeSeenKey = 'chic_fees_notice_seen';

  /// Reservation hold
  static const Duration bookingHold = Duration(minutes: 30);

  /// Paiement — depot 50%
  static const double depositRatio = 0.5;

  /// Frais de service — 5% des nuitees
  static const double serviceFeeRatio = 0.05;

  /// Poll paiement (Wave, Orange, MTN)
  static const Duration paymentPollInterval = Duration(seconds: 4);
  static const Duration paymentTimeout = Duration(seconds: 90);
  static const int maxPaymentRetries = 10;
}
