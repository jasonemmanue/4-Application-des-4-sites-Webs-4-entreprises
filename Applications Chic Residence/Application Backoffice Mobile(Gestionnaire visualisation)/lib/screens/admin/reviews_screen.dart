import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

/// Modération : un avis laissé dans l'application ou sur le site n'y est publié
/// qu'une fois approuvé ici ou dans l'admin web.
class ReviewsScreen extends ConsumerWidget {
  const ReviewsScreen({super.key});

  static const _states = {
    'pending': 'À modérer',
    'approved': 'Publiés',
    'all': 'Tous',
  };

  Future<void> _act(BuildContext context, WidgetRef ref,
      Future<void> Function() action) async {
    try {
      await action();
      ref.invalidate(reviewsProvider);
      ref.invalidate(dashboardStatsProvider);
    } catch (e) {
      if (context.mounted) showMessage(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(reviewStateProvider);
    final async = ref.watch(reviewsProvider);
    final api = ref.read(adminApiProvider);
    final titles = ref.watch(residenceTitlesProvider).valueOrNull ?? const {};

    return Scaffold(
      appBar: AppBar(title: const Text('Avis')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final e in _states.entries)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(e.value,
                          style: TextStyle(
                              color: state == e.key ? Colors.white : null)),
                      selected: state == e.key,
                      showCheckmark: false,
                      onSelected: (_) =>
                          ref.read(reviewStateProvider.notifier).state = e.key,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(reviewsProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    icon: Icons.rate_review_outlined,
                    title: 'Aucun avis ici',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(reviewsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: page.items.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final Review r = page.items[i];
                      return Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(r.author,
                                      style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600)),
                                ),
                                for (var s = 0; s < 5; s++)
                                  Icon(
                                    s < r.rating
                                        ? Icons.star_rounded
                                        : Icons.star_outline_rounded,
                                    size: 16,
                                    color: AppColors.accent,
                                  ),
                              ],
                            ),
                            if (r.residenceId != null &&
                                titles[r.residenceId] != null)
                              Text(titles[r.residenceId]!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted)),
                            if (r.comment.isNotEmpty) ...[
                              const SizedBox(height: 5),
                              Text(r.comment,
                                  style: const TextStyle(
                                      fontSize: 13.5, height: 1.35)),
                            ],
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () => _act(context, ref,
                                      () => api.deleteReview(r.id)),
                                  style: TextButton.styleFrom(
                                      foregroundColor: AppColors.error),
                                  child: const Text('Supprimer'),
                                ),
                                TextButton(
                                  onPressed: () => _act(
                                      context,
                                      ref,
                                      () => api.moderateReview(
                                          r.id, !r.approved)),
                                  child: Text(
                                      r.approved ? 'Dépublier' : 'Approuver'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
