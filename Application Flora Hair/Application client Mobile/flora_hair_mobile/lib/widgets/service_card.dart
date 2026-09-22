import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/service.dart';
import '../utils/media.dart';

/// Ligne de prestation pour la liste `/services`.
///
/// Volontairement plate (pas de fond ni de bordure) : c'est la forme
/// « annonce » qui laisse respirer la liste, comme dans les catalogues
/// mobiles. Toutes les couleurs viennent de `Theme.of(context)` — la
/// carte reste lisible dans les deux modes sans revisiter ce fichier.
class ServiceCard extends StatelessWidget {
  const ServiceCard({super.key, required this.service, this.onTap});

  final Service service;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(FloraTheme.cardRadius),
              child: SizedBox(
                width: 96,
                height: 96,
                child: service.imageUrl != null && service.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: mediaUrl(service.imageUrl),
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            Container(color: scheme.surfaceContainerHighest),
                        placeholder: (_, __) =>
                            Container(color: scheme.surfaceContainerHighest),
                      )
                    : Container(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.spa, color: scheme.primary, size: 32),
                      ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  Text(
                    service.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${service.durationMinutes} min',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    service.formattedPrice(),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(color: scheme.primary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
