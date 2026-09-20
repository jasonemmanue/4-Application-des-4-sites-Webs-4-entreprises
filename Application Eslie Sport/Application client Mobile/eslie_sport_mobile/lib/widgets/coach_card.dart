import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/coach.dart';

class CoachCard extends StatelessWidget {
  final Coach coach;
  final VoidCallback? onTap;

  const CoachCard({super.key, required this.coach, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.darkBorder),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.md),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: coach.photoUrl != null && coach.photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: coach.photoUrl!,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => Container(
                            color: AppColors.darkLighter,
                            child: const Icon(Icons.person,
                                color: AppColors.darkMuted),
                          ),
                        )
                      : Container(
                          color: AppColors.darkLighter,
                          child: const Icon(Icons.person,
                              color: AppColors.darkMuted, size: 32),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      coach.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    if (coach.specialties.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: coach.specialties.take(3).map((s) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.darkLighter,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.sm),
                              ),
                              child: Text(
                                s,
                                style: const TextStyle(
                                  color: AppColors.darkMuted,
                                  fontSize: 10,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
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
