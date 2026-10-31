import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/api_config.dart';
import '../config/format.dart';
import '../config/theme.dart';
import '../models/residence.dart';
import '../providers/providers.dart';

/// Carte logement de la maquette : photo en haut avec le cœur, titre, quartier,
/// prix en rouge, note et capacité.
class ResidenceCard extends ConsumerWidget {
  const ResidenceCard({
    super.key,
    required this.residence,
    this.onTap,
    this.width,
    this.imageHeight = 150,
    this.trailing,
  });

  final Residence residence;
  final VoidCallback? onTap;
  final double? width;
  final double imageHeight;

  /// Remplace le cœur (non utilisé sur les favoris où il sert à retirer).
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final isFav = ref.watch(favoritesProvider).contains(residence.id);

    return SizedBox(
      width: width,
      child: Container(
        decoration: BoxDecoration(
          color: t.surfaceElevated,
          borderRadius: BorderRadius.circular(18),
          border: t.isDark ? Border.all(color: t.border) : null,
          boxShadow: [
            BoxShadow(
              color: t.shadow,
              blurRadius: 16,
              spreadRadius: -6,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: imageHeight,
                  width: double.infinity,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      ResidencePhoto(url: residence.mainPhoto),
                      if (residence.availability !=
                          AvailabilityStatus.available)
                        Positioned(
                          left: 10,
                          top: 10,
                          child: AvailabilityPill(residence: residence),
                        ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: trailing ??
                            HeartButton(
                              favored: isFav,
                              onTap: () => ref
                                  .read(favoritesProvider.notifier)
                                  .toggle(residence.id),
                            ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        residence.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.place_outlined,
                              size: 14, color: t.textSecondary),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              residence.city,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12.5, color: t.textSecondary),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      PriceLine(price: residence.pricePerNight),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          if (residence.reviewsCount > 0) ...[
                            const Icon(Icons.star_rounded,
                                size: 16, color: AppColors.star),
                            const SizedBox(width: 3),
                            Text(
                              '${residence.rating.toStringAsFixed(1).replaceAll('.', ',')} '
                              '(${residence.reviewsCount} avis)',
                              style: TextStyle(
                                  fontSize: 12, color: t.textSecondary),
                            ),
                          ],
                          const Spacer(),
                          Icon(Icons.person_outline_rounded,
                              size: 15, color: t.textSecondary),
                          const SizedBox(width: 2),
                          Text(
                            '${residence.capacity} pers.',
                            style:
                                TextStyle(fontSize: 12, color: t.textSecondary),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResidencePhoto extends StatelessWidget {
  const ResidencePhoto({super.key, required this.url, this.fit = BoxFit.cover});
  final String url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return CachedNetworkImage(
      imageUrl: ApiConfig.resolveImage(url),
      fit: fit,
      placeholder: (_, __) => Container(color: t.imagePlaceholder),
      errorWidget: (_, __, ___) => Container(
        color: t.imagePlaceholder,
        child: Icon(Icons.image_outlined, size: 40, color: t.textSecondary),
      ),
    );
  }
}

class PriceLine extends StatelessWidget {
  const PriceLine({super.key, required this.price, this.size = 15});
  final int price;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: Money.fcfa(price),
            style: TextStyle(
              fontSize: size,
              fontWeight: FontWeight.w700,
              color: t.brand,
            ),
          ),
          TextSpan(
            text: ' / nuit',
            style: TextStyle(
              fontSize: size - 2.5,
              fontWeight: FontWeight.w500,
              color: t.brand,
            ),
          ),
        ],
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }
}

/// Cœur sur la photo : blanc dans les deux thèmes, le fond est une image.
class HeartButton extends StatelessWidget {
  const HeartButton({super.key, required this.favored, required this.onTap});
  final bool favored;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: favored ? 'Retirer des favoris' : 'Ajouter aux favoris',
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            favored ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            color: favored ? AppColors.primary600 : Colors.white,
            size: 26,
            shadows: const [
              Shadow(blurRadius: 6, color: Colors.black45, offset: Offset(0, 1)),
            ],
          ),
        ),
      ),
    );
  }
}

class AvailabilityPill extends StatelessWidget {
  const AvailabilityPill({super.key, required this.residence});
  final Residence residence;

  @override
  Widget build(BuildContext context) {
    final color = residence.availability == AvailabilityStatus.occupied
        ? AppColors.primary700
        : AppColors.warning;
    final label = residence.availabilityLabel.isNotEmpty
        ? residence.availabilityLabel
        : residence.availability.label;
    return Container(
      constraints: const BoxConstraints(maxWidth: 190),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
