import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../services/providers.dart';
import '../../widgets/article_card.dart';
import '../../widgets/state_widgets.dart';

class ArticlesScreen extends ConsumerWidget {
  const ArticlesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(articlesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Articles beaute')),
      body: async.when(
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(message: 'Aucun article publie');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => ArticleCard(
              article: list[i],
              onTap: () => context.push('/articles/${list[i].slug}'),
            ),
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'Erreur : $e',
          onRetry: () => ref.refresh(articlesProvider),
        ),
      ),
    );
  }
}
