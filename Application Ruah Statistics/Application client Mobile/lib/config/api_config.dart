/// Configuration des URLs de l'API cabinet-etudes.
///
/// Par defaut, l'app cible **l'API en production sur Railway** — la meme
/// API que celle consommee par le site web (Next.js) et l'admin. Aucun
/// service mobile-specifique n'existe : tout passe par `/api/v1/...`.
///
/// Overrides possibles au moment du build ou du `flutter run` :
///
/// * Docker local (emulateur Android) :
///   `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001/api/v1`
///
/// * Docker local (telephone physique en USB debug, apres
///   `adb reverse tcp:8001 tcp:8001`) :
///   `flutter run --dart-define=API_BASE_URL=http://localhost:8001/api/v1`
///
/// * Autre environnement Railway (staging par ex.) :
///   `flutter build apk --dart-define=API_BASE_URL=https://<staging>/api/v1`
class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api-production-bc863.up.railway.app/api/v1',
  );

  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 20);

  /// Racine du serveur qui sert les fichiers `/uploads/*` — c'est `baseUrl`
  /// sans le suffixe `/api/v1`. Les uploads sont montes a la racine par
  /// `main.py` (`app.mount("/uploads", StaticFiles...)`).
  static String get uploadsBase {
    const suffix = '/api/v1';
    if (baseUrl.endsWith(suffix)) {
      return baseUrl.substring(0, baseUrl.length - suffix.length);
    }
    return baseUrl;
  }

  /// Convertit une valeur brute d'`image_url`/`photo_url`/`logo_url` en URL
  /// absolue chargeable par [CachedNetworkImage]. Retourne `null` quand
  /// l'entree est vide (le backend renvoie souvent `""` plutot que `null`
  /// quand l'admin n'a pas encore televerse la ressource) ou invalide.
  ///
  /// * URL absolue (`http://…`, `https://…`) : renvoyee telle quelle.
  /// * Chemin `/uploads/xxx.png` : prefixe par [uploadsBase].
  /// * `""` ou `null` : renvoie `null` — l'appelant affiche son fallback
  ///   (degrade, initiales, emoji), pas une image cassee.
  static String? resolveMediaUrl(String? raw) {
    if (raw == null) return null;
    final s = raw.trim();
    if (s.isEmpty) return null;
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/')) return '$uploadsBase$s';
    return '$uploadsBase/$s';
  }

  static const String companyName = 'RUAH-STATISTICS';
  static const String companyPhone = '+225 05 45 07 98 50';
  static const String companyWhatsapp = '2250545079850';
  static const String companyEmail = 'contact@ruah-statistics.com';
  static const String companyAddress =
      "123 Avenue de l'Independance, Abidjan, Cote d'Ivoire";
}
