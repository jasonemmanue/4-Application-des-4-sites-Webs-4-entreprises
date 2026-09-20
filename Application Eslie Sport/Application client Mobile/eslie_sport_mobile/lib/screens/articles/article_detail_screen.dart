import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../services/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

String _stripHtml(String html) {
  var text = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</h[1-6]>', caseSensitive: false), '\n\n')
      .replaceAll(RegExp(r'</li>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<li[^>]*>', caseSensitive: false), '• ')
      .replaceAll(RegExp(r'<[^>]+>'), '');
  text = text
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  return text.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
}

class ArticleDetailScreen extends ConsumerWidget {
  final String slug;
  const ArticleDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(articleBySlugProvider(slug));
    return Scaffold(
      appBar: AppBar(title: const Text('Article')),
      body: async.when(
        data: (a) {
          if (a == null) {
            return const EmptyState(
              icon: Icons.article_outlined,
              title: 'Article introuvable',
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (a.coverImageUrl != null && a.coverImageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    child: CachedNetworkImage(
                      imageUrl: a.coverImageUrl!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                const SizedBox(height: 14),
                Text(a.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      height: 1.2,
                    )),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (a.authorName != null) ...[
                      const Icon(Icons.person_outline,
                          size: 14, color: AppColors.darkMuted),
                      const SizedBox(width: 4),
                      Text(a.authorName!,
                          style: const TextStyle(
                              color: AppColors.darkMuted, fontSize: 12)),
                      const SizedBox(width: 12),
                    ],
                    if (a.publishedAt != null) ...[
                      const Icon(Icons.calendar_today,
                          size: 12, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(formatDate(a.publishedAt),
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                if (a.content.isNotEmpty)
                  Text(
                    _stripHtml(a.content),
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14.5, height: 1.6),
                  ),
              ],
            ),
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(articleBySlugProvider(slug)),
        ),
      ),
    );
  }
}
