import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/article.dart';
import '../../providers/providers.dart';
import '../../widgets/article_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class PublicationsScreen extends ConsumerWidget {
  const PublicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typeFilter = ref.watch(articleTypeFilterProvider);
    final articles = ref.watch(articlesProvider(typeFilter));

    return Scaffold(
      appBar: AppBar(title: const Text('Publications')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: Row(
              children: [
                _chip(context, ref, null, 'Tout'),
                const SizedBox(width: 8),
                _chip(context, ref, ArticleType.article, 'Articles'),
                const SizedBox(width: 8),
                _chip(context, ref, ArticleType.whitepaper, 'Livres blancs'),
              ],
            ),
          ),
          Expanded(
            child: articles.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(articlesProvider),
              ),
              data: (page) {
                if (page.items.isEmpty) {
                  return const EmptyState(
                    title: 'Aucune publication',
                    icon: Icons.menu_book_outlined,
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(articlesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: page.items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (_, i) => ArticleCard(
                      article: page.items[i],
                      onTap: () => context.push(
                          '${AppRoutes.publications}/${page.items[i].slug}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(
      BuildContext context, WidgetRef ref, ArticleType? value, String label) {
    final current = ref.watch(articleTypeFilterProvider);
    final bool selected = current == value;
    return ChoiceChip(
      selected: selected,
      label: Text(label),
      onSelected: (_) =>
          ref.read(articleTypeFilterProvider.notifier).state = value,
    );
  }
}
