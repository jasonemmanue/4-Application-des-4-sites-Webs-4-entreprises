import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/subscription.dart';
import '../utils/formatters.dart';

class SubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onSubscribe;
  final bool featured;

  const SubscriptionCard({
    super.key,
    required this.subscription,
    required this.onSubscribe,
    this.featured = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: featured ? AppColors.goldGradient : null,
        color: featured ? null : AppColors.darkCard,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: featured ? Colors.transparent : AppColors.darkBorder,
        ),
        boxShadow: featured
            ? [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (featured)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.dark,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Text(
                'RECOMMANDE',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          if (featured) const SizedBox(height: 12),
          Text(
            subscription.name,
            style: TextStyle(
              color: featured ? AppColors.dark : Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formatFcfa(subscription.price),
                style: TextStyle(
                  color: featured ? AppColors.dark : AppColors.primary,
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                subscription.durationMonths == 1
                    ? '/ mois'
                    : '/ ${subscription.durationMonths} mois',
                style: TextStyle(
                  color: featured ? AppColors.dark : AppColors.darkMuted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          if (subscription.features.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...subscription.features.map(
              (f) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: featured ? AppColors.dark : AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        f,
                        style: TextStyle(
                          color: featured ? AppColors.dark : Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSubscribe,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    featured ? AppColors.dark : AppColors.primary,
                foregroundColor:
                    featured ? AppColors.primary : AppColors.dark,
              ),
              child: const Text('Souscrire'),
            ),
          ),
        ],
      ),
    );
  }
}
