import '../config/api_config.dart';

/// Résout une URL d'image renvoyée par l'API en URL absolue chargeable par
/// `CachedNetworkImage` / `Image.network`.
///
/// La base est partagée avec le site web : chaque record (service, coiffeuse,
/// article, galerie, avis, devis) porte un chemin **relatif**. Sans ce
/// pontage, `CachedNetworkImage(imageUrl: '/uploads/xxx.jpg')` échoue
/// silencieusement — le fichier n'est jamais téléchargé et la vignette reste
/// vide, sans erreur visible. C'est ce qui donnait « aucune image ne s'affiche
/// dans l'application » alors que les données arrivaient bien.
///
/// Deux sources, deux origines, exactement comme dans `admin/lib/media.ts` :
/// - `/uploads/…`  → fichier téléversé depuis l'admin, servi par l'API
///   (`api.florahair.online/uploads/…`)
/// - `/images/…`   → visuel livré avec le dépôt du site, servi par Next
///   (`www.florahair.online/images/…`)
///
/// Un chemin déjà absolu (`http://…`, `https://…`, `data:…`) ou vide est
/// renvoyé tel quel : cette fonction ne casse rien de ce qui marchait déjà.
String mediaUrl(String? url) {
  if (url == null) return '';
  final trimmed = url.trim();
  if (trimmed.isEmpty) return '';

  // Absolue ou data-URI : rien à faire.
  final lower = trimmed.toLowerCase();
  if (lower.startsWith('http://') ||
      lower.startsWith('https://') ||
      lower.startsWith('//') ||
      lower.startsWith('data:')) {
    return trimmed;
  }

  if (trimmed.startsWith('/uploads/')) {
    return '${ApiConfig.baseUrl}$trimmed';
  }

  if (trimmed.startsWith('/')) {
    return '${ApiConfig.siteBaseUrl}$trimmed';
  }

  // Chemin sans slash initial : on suppose un visuel du site.
  return '${ApiConfig.siteBaseUrl}/$trimmed';
}
