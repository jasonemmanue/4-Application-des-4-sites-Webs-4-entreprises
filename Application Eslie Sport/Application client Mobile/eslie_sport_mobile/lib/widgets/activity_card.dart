import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/activity.dart';
import '../utils/formatters.dart';
import 'brand_logo.dart';

/// Photo d'activite avec repli sur l'icone de sa categorie.
class ActivityPhoto extends StatelessWidget {
  final String? url;
  final String category;
  final double? width;
  final double? height;
  const ActivityPhoto({
    super.key,
    required this.url,
    this.category = '',
    this.width,
    this.height,
  });

  @override
  Widget build(BuildContext context) {
    final fallback = Container(
      width: width,
      height: height,
      color: AppColors.primarySoft,
      child: Icon(activityCategoryIcon(category),
          color: AppColors.primary, size: 32),
    );
    if (url == null || url!.isEmpty) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      width: width,
      height: height,
      fit: BoxFit.cover,
      placeholder: (_, __) => Container(
        width: width,
        height: height,
        color: AppColors.surfaceSubtle,
      ),
      errorWidget: (_, __, ___) => fallback,
    );
  }
}

/// Ligne du catalogue : photo a gauche, nom, accroche, duree | niveau, fleche.
class ActivityRow extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;
  const ActivityRow({super.key, required this.activity, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.card,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Semantics(
                    label: 'Photo de l\'activité ${activity.name}',
                    child: ActivityPhoto(
                      url: activity.imageUrl,
                      category: activity.category,
                      width: 104,
                      height: 84,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        activity.description,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.schedule,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              '${activity.durationMinutes} min  |  '
                              '${activityLevelLabel(activity.level)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const RoundArrow(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
