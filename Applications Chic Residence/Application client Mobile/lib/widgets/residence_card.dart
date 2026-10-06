import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../config/format.dart';
import '../config/theme.dart';
import '../models/residence.dart';
import '../providers/providers.dart';
import 'app_surface.dart';

/// Card style Airbnb : image carrée arrondie, cœur overlay, badge
/// « Coup de cœur », titre + prix + note.
///
/// Les éléments posés **sur la photo** (cœur, badges) utilisent
/// `tokens.textOnPhoto` — blanc dans les deux thèmes, puisque le fond est une
/// image et non une surface du thème.
class ResidenceCard extends ConsumerWidget {
  const ResidenceCard({
    super.key,
    required this.residence,
    this.onTap,
    this.horizontal = false,
  });

  final Residence residence;
  final VoidCallback? onTap;
  final bool horizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final favorites = ref.watch(favoritesProvider);
    final isFav = favorites.contains(residence.id);
    final width = horizontal ? 260.0 : double.infinity;

    return SizedBox(
      width: width,
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: CachedNetworkImage(
                        imageUrl: ApiConfig.resolveImage(residence.mainPhoto),
                        fit: BoxFit.cover,
                        placeholder: (_, __) =>
                            Container(color: t.imagePlaceholder),
                        errorWidget: (_, __, ___) => Container(
                          color: t.imagePlaceholder,
                          child: Icon(Icons.image_outlined,
                              size: 40, color: t.textSecondary),
                        ),
                      ),
                    ),
                    if (residence.availability != AvailabilityStatus.available)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _StatusPill(status: residence.availability),
                      )
                    else if (residence.rating >= 4.5 &&
                        residence.reviewsCount > 0)
                      const Positioned(
                        top: 12,
                        left: 12,
                        child: _GuestFavoritePill(),
                      ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: _FavoriteButton(
                        favored: isFav,
                        onTap: () => ref
                            .read(favoritesProvider.notifier)
                            .toggle(residence.id),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          '${residence.type.label} à ${residence.city}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: -0.2,
                              ),
                        ),
                      ),
                      if (residence.reviewsCount > 0) ...[
                        const SizedBox(width: 6),
                        Icon(Icons.star_rounded,
                            size: 14, color: t.textPrimary),
                        const SizedBox(width: 3),
                        Text(
                          residence.rating.toStringAsFixed(2),
                          style: Theme.of(context)
                              .textTheme
                              .labelMedium
                              ?.copyWith(fontSize: 13),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${Money.fcfa(residence.pricePerNight)} par nuit',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: t.textSecondary,
                          fontSize: 13,
                        ),
                  ),
                  const SizedBox(height: 2),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Badge blanc « Coup de cœur ». Posé sur la photo : il reste blanc dans les
/// deux thèmes, comme chez Airbnb.
class _GuestFavoritePill extends StatelessWidget {
  const _GuestFavoritePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: const Text(
        'Coup de cœur',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Color(0xFF222222),
        ),
      ),
    );
  }
}

class _FavoriteButton extends StatelessWidget {
  const _FavoriteButton({required this.favored, required this.onTap});
  final bool favored;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Center(
            child: Icon(
              favored ? Icons.favorite : Icons.favorite_border,
              color: favored ? AppColors.primary500 : t.textOnPhoto,
              size: 26,
              shadows: const [
                Shadow(
                  blurRadius: 6,
                  color: Colors.black38,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final AvailabilityStatus status;

  @override
  Widget build(BuildContext context) {
    final color = status == AvailabilityStatus.occupied
        ? AppColors.error
        : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
