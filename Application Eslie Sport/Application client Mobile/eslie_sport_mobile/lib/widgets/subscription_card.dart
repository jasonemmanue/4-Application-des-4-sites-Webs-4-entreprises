import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/subscription.dart';
import '../utils/formatters.dart';

String subscriptionPeriod(Subscription s) => s.durationMonths > 1
    ? '/ ${s.durationMonths} mois'
    : s.durationMonths == 1
        ? '/ mois'
        : '';

/// Ligne compacte : icone, nom, prix, chevron.
class SubscriptionRow extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onTap;
  const SubscriptionRow({
    super.key,
    required this.subscription,
    required this.onTap,
  });

  IconData get _icon {
    final name = subscription.name.toLowerCase();
    if (name.contains('tenue')) return Icons.checkroom_outlined;
    if (name.contains('kung')) return Icons.sports_martial_arts;
    if (name.contains('boxe')) return Icons.sports_mma_outlined;
    if (name.contains('inscription')) return Icons.assignment_outlined;
    return Icons.fitness_center;
  }

  @override
  Widget build(BuildContext context) {
    final period = subscriptionPeriod(subscription);
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
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceSubtle,
                    borderRadius: BorderRadius.circular(AppRadius.md),
                  ),
                  child: Icon(_icon, color: AppColors.primary, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subscription.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: formatFcfa(subscription.price),
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (period.isNotEmpty)
                              TextSpan(
                                text: ' $period',
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: AppColors.primarySoft,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.chevron_right,
                      color: AppColors.primary, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Formule mise en avant, liseret jaune et badge « Populaire ».
class FeaturedSubscriptionCard extends StatelessWidget {
  final Subscription subscription;
  final VoidCallback onSubscribe;
  const FeaturedSubscriptionCard({
    super.key,
    required this.subscription,
    required this.onSubscribe,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.yellow, width: 2),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.workspace_premium,
                      color: AppColors.yellow, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: formatFcfa(subscription.price),
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 23,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(
                                text: ' ${subscriptionPeriod(subscription)}',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (final feature in subscription.features)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check_circle,
                          size: 18, color: AppColors.success),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          feature,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onSubscribe,
                  child: const Text('Choisir cette formule'),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: -11,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.yellow,
              borderRadius: BorderRadius.circular(AppRadius.full),
            ),
            child: const Text(
              'Populaire',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
