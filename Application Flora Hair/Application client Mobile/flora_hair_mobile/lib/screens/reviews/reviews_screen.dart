import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/providers.dart';
import '../../widgets/review_card.dart';
import '../../widgets/review_form.dart';
import '../../widgets/state_widgets.dart';

class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reviewsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Avis clients')),
      body: async.when(
        data: (list) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            if (list.isEmpty)
              const EmptyState(message: 'Soyez la premiere a laisser un avis'),
            for (final r in list)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReviewCard(review: r),
              ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            ReviewForm(
              onSubmitted: () => ref.refresh(reviewsProvider),
            ),
          ],
        ),
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'Erreur : $e',
          onRetry: () => ref.refresh(reviewsProvider),
        ),
      ),
    );
  }
}
