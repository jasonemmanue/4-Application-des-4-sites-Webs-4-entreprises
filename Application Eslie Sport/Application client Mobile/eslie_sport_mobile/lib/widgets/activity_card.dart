/// Carte d'activite Airbnb-like : grande image carree arrondie, petit
/// bouton favori en surimpression, puis titre + duree + niveau sous la
/// photo. Le tout sans ombre superflue, pour tenir dans un carrousel
/// horizontal ou dans une grille de recherche.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/activity.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;
  final bool showFavorite;
  final String? badgeLabel;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
    this.showFavorite = true,
    this.badgeLabel,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  child: activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: activity.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.surfaceSubtle),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.surfaceSubtle,
                            child: const Icon(Icons.fitness_center,
                                color: AppColors.textMuted, size: 40),
                          ),
                        )
                      : Container(
                          color: AppColors.surfaceSubtle,
                          child: const Icon(Icons.fitness_center,
                              color: AppColors.textMuted, size: 40),
                        ),
                ),
                if (badgeLabel != null)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _Pill(label: badgeLabel!),
                  ),
                if (showFavorite)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: _FavoriteButton(),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            activity.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${activity.durationMinutes} min · ${activity.level.isEmpty ? "Tous niveaux" : activity.level}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          if (activity.category.isNotEmpty) ...[
            const SizedBox(height: 2),
            Row(
              children: [
                const Icon(Icons.star, size: 12, color: AppColors.textPrimary),
                const SizedBox(width: 4),
                Text(
                  activity.category,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: AppShadows.pill,
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

/// Petit bouton coeur qui garde son etat en local (SharedPreferences pourra
/// s'y brancher plus tard) — pour l'instant, non persiste : le tap change
/// juste l'apparence du coeur.
class _FavoriteButton extends StatefulWidget {
  const _FavoriteButton();

  @override
  State<_FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<_FavoriteButton> {
  bool _liked = false;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkResponse(
        onTap: () => setState(() => _liked = !_liked),
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            _liked ? Icons.favorite : Icons.favorite_border,
            size: 26,
            color: _liked ? AppColors.accent : Colors.white,
            shadows: const [
              Shadow(color: Color(0x66000000), blurRadius: 6),
            ],
          ),
        ),
      ),
    );
  }
}
