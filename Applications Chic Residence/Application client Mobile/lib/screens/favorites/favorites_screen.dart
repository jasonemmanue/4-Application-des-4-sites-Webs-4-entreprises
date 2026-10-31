import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/residence_card.dart';
import '../../widgets/state_views.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  Future<void> _clear(
      BuildContext context, WidgetRef ref, List<String> ids) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Vider vos favoris ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Oui, vider'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final notifier = ref.read(favoritesProvider.notifier);
    for (final id in ids) {
      await notifier.toggle(id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final favs = ref.watch(favoritesProvider);
    final async = ref.watch(allResidencesProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Icon(Icons.favorite_rounded, color: t.brand),
            const SizedBox(width: 8),
            const Text('Mes favoris'),
          ],
        ),
        actions: [
          if (favs.isNotEmpty)
            IconButton(
              tooltip: 'Vider les favoris',
              onPressed: () => _clear(context, ref, favs.toList()),
              icon: const Icon(Icons.delete_outline_rounded),
            ),
          const SizedBox(width: 6),
        ],
      ),
      body: async.when(
        loading: () => const LoadingCards(count: 2),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(allResidencesProvider),
        ),
        data: (list) {
          final filtered = list.where((r) => favs.contains(r.id)).toList();
          if (filtered.isEmpty) {
            return const EmptyView(
              icon: Icons.favorite_border_rounded,
              title: 'Aucun favori pour le moment',
              description:
                  'Touchez le cœur d\'un logement pour le retrouver ici.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 14),
            itemBuilder: (context, i) => ResidenceCard(
              residence: filtered[i],
              imageHeight: 165,
              onTap: () => context.push('/residence/${filtered[i].slug}'),
            ),
          );
        },
      ),
    );
  }
}
