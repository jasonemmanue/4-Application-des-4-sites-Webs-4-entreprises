import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/subscription_card.dart';

class SubscriptionsScreen extends ConsumerWidget {
  const SubscriptionsScreen({super.key});

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
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (_, i) => SubscriptionCard(
              subscription: list[i],
              featured: i == 1 && list.length >= 3,
              onSubscribe: () =>
                  context.push('/subscriptions/order/${list[i].id}'),
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
