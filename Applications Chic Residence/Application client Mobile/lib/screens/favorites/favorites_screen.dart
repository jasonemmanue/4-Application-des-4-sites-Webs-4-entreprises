import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/residence_card.dart';
import '../../widgets/state_views.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favs = ref.watch(favoritesProvider);
    final async = ref.watch(residencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Mes favoris')),
      body: async.when(
        loading: () => const LoadingCards(),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(residencesProvider),
        ),
        data: (list) {
          final filtered = list.where((r) => favs.contains(r.id)).toList();
          if (filtered.isEmpty) {
            return const EmptyView(
              icon: Icons.favorite_border,
              title: 'Aucun favori pour le moment',
              description: 'Explorez nos residences et ajoutez celles qui vous plaisent.',
            );
          }
          return ListView.separated(
            padding: EdgeInsets.fromLTRB(16, 16, 16, context.bottomInset()),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 24),
            itemBuilder: (context, i) => ResidenceCard(
              residence: filtered[i],
              onTap: () => context.push('/residence/${filtered[i].slug}'),
            ),
          );
        },
      ),
    );
  }
}
