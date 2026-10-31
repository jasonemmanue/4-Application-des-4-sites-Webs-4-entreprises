import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/subscription.dart';
import '../../services/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/subscription_card.dart';

/// Formules du catalogue, modifiables au back-office. La mensualite generale
/// est mise en avant ; les disciplines sont regroupees sous leur nom.
class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

  static bool _isFeatured(Subscription s) =>
      s.name.toLowerCase().startsWith('mensualit');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(subscriptionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Abonnements')),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.card_membership,
              title: 'Aucune formule',
              subtitle: 'Revenez plus tard.',
            );
          }
          void open(Subscription s) =>
              context.push('/subscriptions/order/${s.id}');

          final kungFu = list
              .where((s) => s.name.toLowerCase().startsWith('kung'))
              .toList();
          final boxing = list
              .where((s) => s.name.toLowerCase().startsWith('boxe'))
              .toList();
          final general = list
              .where((s) => !kungFu.contains(s) && !boxing.contains(s))
              .toList();
          final featured = general.where(_isFeatured).toList();
          final others = general.where((s) => !_isFeatured(s)).toList();

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async => ref.invalidate(subscriptionsProvider),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                for (final s in others) ...[
                  SubscriptionRow(subscription: s, onTap: () => open(s)),
                  const SizedBox(height: 12),
                ],
                for (final s in featured) ...[
                  const SizedBox(height: 10),
                  FeaturedSubscriptionCard(
                    subscription: s,
                    onSubscribe: () => open(s),
                  ),
                  const SizedBox(height: 12),
                ],
                _Group(title: 'Kung-Fu Wushu', items: kungFu, onOpen: open),
                _Group(title: 'Boxe & Kick-boxing', items: boxing, onOpen: open),
                const SizedBox(height: 4),
                const Text(
                  'Payez 50 % en ligne pour réserver, le reste à la salle.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                ),
              ],
            ),
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(subscriptionsProvider),
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Subscription> items;
  final ValueChanged<Subscription> onOpen;
  const _Group({required this.title, required this.items, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 10, left: 4),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        for (final s in items) ...[
          SubscriptionRow(subscription: s, onTap: () => onOpen(s)),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}
