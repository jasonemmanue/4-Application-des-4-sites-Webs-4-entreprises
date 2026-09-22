import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/theme.dart';
import '../../models/article.dart';
import '../../providers/providers.dart';
import '../../widgets/download_modal.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class ArticleDetailScreen extends ConsumerWidget {
  final String slug;

  const ArticleDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final article = ref.watch(articleDetailProvider(slug));
    return Scaffold(
      body: article.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(articleDetailProvider(slug)),
        ),
        data: (a) => _Body(article: a),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Article article;
  const _Body({required this.article});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.share_outlined),
              onPressed: () => Share.share(
                '${article.title} - RUAH STATISTICS',
              ),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: article.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: article.coverImage!,
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.4),
                    colorBlendMode: BlendMode.darken,
                  )
                : Container(
                    decoration: const BoxDecoration(
                        gradient: AppColors.heroGradient)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: article.isWhitepaper
                            ? AppColors.accent500.withValues(alpha: 0.2)
                            : AppColors.brand500.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        article.isWhitepaper ? 'Livre blanc' : 'Article',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(
                              color: article.isWhitepaper
                                  ? AppColors.accent500
                                  : AppColors.brand400,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                    const Spacer(),
                    if (article.publishedAt != null)
                      Text(
                        DateFormat('dd MMM yyyy', 'fr')
                            .format(article.publishedAt!),
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(article.title,
                    style: Theme.of(context).textTheme.headlineMedium),
                if (article.author != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text('Par ${article.author!}',
                      style: Theme.of(context).textTheme.labelMedium),
                ],
                if (article.excerpt != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(article.excerpt!,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
                if (article.content != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(article.content!,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(height: 1.6)),
                ],
                if (article.isWhitepaper) ...[
                  const SizedBox(height: AppSpacing.lg),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          DownloadModal.show(context, article),
                      icon: const Icon(Icons.download),
                      label: const Text('Telecharger le livre blanc'),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
