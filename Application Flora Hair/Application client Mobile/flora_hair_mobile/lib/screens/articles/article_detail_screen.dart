import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../config/theme.dart';
import '../../services/providers.dart';
import '../../utils/media.dart';
import '../../widgets/state_widgets.dart';

class ArticleDetailScreen extends ConsumerWidget {
  const ArticleDetailScreen({super.key, required this.slug});
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(articleDetailProvider(slug));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Article'),
        actions: <Widget>[
          async.maybeWhen(
            data: (a) => IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => Share.share('${a.title}\n\n${a.excerpt}'),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: async.when(
        data: (article) => ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            if (article.coverUrl != null && article.coverUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: mediaUrl(article.coverUrl),
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      Container(color: FloraColors.darkLight),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(article.title,
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 12),
                  if (article.author != null || article.publishedAt != null)
                    Text(
                      <String>[
                        if (article.author != null) 'Par ${article.author}',
                        if (article.publishedAt != null)
                          _formatDate(article.publishedAt!),
                      ].join(' — '),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: FloraColors.textMuted),
                    ),
                  const SizedBox(height: 16),
                  Text(article.content ?? article.excerpt,
                      style: Theme.of(context).textTheme.bodyLarge),
                ],
              ),
            ),
          ],
        ),
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: 'Erreur : $e',
          onRetry: () => ref.refresh(articleDetailProvider(slug)),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
}
