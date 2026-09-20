import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/activity.dart';

class ActivityCard extends StatelessWidget {
  final Activity activity;
  final VoidCallback onTap;

  const ActivityCard({
    super.key,
    required this.activity,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.lg)),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: activity.imageUrl != null && activity.imageUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: activity.imageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) =>
                              Container(color: AppColors.darkLighter),
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.darkLighter,
                            child: const Icon(Icons.fitness_center,
                                color: AppColors.darkMuted, size: 40),
                          ),
                        )
                      : Container(
                          color: AppColors.darkLighter,
                          child: const Icon(Icons.fitness_center,
                              color: AppColors.darkMuted, size: 40),
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (activity.category.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: Text(
                          activity.category.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    Text(
                      activity.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (activity.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        activity.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.darkMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            color: AppColors.darkMuted, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${activity.durationMinutes} min',
                          style: const TextStyle(
                              color: AppColors.darkMuted, fontSize: 12),
                        ),
                        const Spacer(),
                        if (activity.level.isNotEmpty)
                          Text(
                            activity.level,
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
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
    );
  }
}
