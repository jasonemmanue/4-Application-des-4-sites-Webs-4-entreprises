import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/article.dart';

class ArticleCard extends StatelessWidget {
  final Article article;
  final VoidCallback? onTap;

  const ArticleCard({super.key, required this.article, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (article.coverImage != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: article.coverImage!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _fallback(),
                  placeholder: (_, __) => _fallback(),
                ),
              ),
            Padding(
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
                      style: Theme.of(context).textTheme.titleMedium),
                  if (article.excerpt != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      article.excerpt!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.charcoal700,
        alignment: Alignment.center,
        child: const Icon(Icons.article_outlined, color: Colors.white70),
      );
}
