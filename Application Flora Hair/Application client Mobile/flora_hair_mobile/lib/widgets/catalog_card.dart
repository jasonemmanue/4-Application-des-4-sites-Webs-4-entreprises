import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../utils/media.dart';

/// Carte « catalogue » du style Airbnb : image carrée à coins très
/// arrondis, cœur favori en surimpression, titre gras et sous-ligne
/// meta discrète en dessous.
///
/// Volontairement générique : sert pour une prestation, une coiffeuse
/// ou un article. Le parent passe l'URL brute (`mediaUrl` est appliqué
/// ici) et deux lignes de texte ; la carte s'occupe du visuel.
class CatalogCard extends StatelessWidget {
  const CatalogCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.metaLine,
    this.ratingLine,
    this.badge,
    this.onTap,
    this.width = 200,
    this.imageAspectRatio = 1.0,
  });

  final String title;
  final String? imageUrl;
  final String metaLine;
  final String? ratingLine;
  final String? badge;
  final VoidCallback? onTap;
  final double width;
  final double imageAspectRatio;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            AspectRatio(
              aspectRatio: imageAspectRatio,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
                      child: (imageUrl == null || imageUrl!.isEmpty)
                          ? Container(color: FloraColors.surfaceMuted)
                          : CachedNetworkImage(
                              imageUrl: mediaUrl(imageUrl),
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) =>
                                  Container(color: FloraColors.surfaceMuted),
                              placeholder: (_, __) =>
                                  Container(color: FloraColors.surfaceMuted),
                            ),
                    ),
                  ),
                  if (badge != null)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: FloraColors.surface,
                          borderRadius: BorderRadius.circular(FloraTheme.pillRadius),
                        ),
                        child: Text(
                          badge!,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: FloraColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.favorite_border,
                        color: Colors.white.withValues(alpha: 0.95),
                        shadows: const <Shadow>[
                          Shadow(
                            color: Colors.black45,
                            blurRadius: 6,
                          ),
                        ],
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: FloraColors.textPrimary,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              metaLine,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                color: FloraColors.textSecondary,
              ),
            ),
            if (ratingLine != null)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.star, size: 14, color: FloraColors.textPrimary),
                    const SizedBox(width: 4),
                    Text(
                      ratingLine!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: FloraColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
