import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/service.dart';

class ServiceCard extends StatelessWidget {
  final Service service;
  final VoidCallback? onTap;

  const ServiceCard({super.key, required this.service, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (service.coverImage != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: CachedNetworkImage(
                  imageUrl: service.coverImage!,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _fallback(context),
                  placeholder: (_, __) => _fallback(context),
                ),
              )
            else
              _fallback(context),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(service.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  if (service.summary != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      service.summary!,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Text('En savoir plus',
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(color: AppColors.brand500)),
                      const SizedBox(width: AppSpacing.xs),
                      const Icon(Icons.arrow_forward,
                          size: 16, color: AppColors.brand500),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) => Container(
        height: 140,
        decoration: const BoxDecoration(gradient: AppColors.ctaGradient),
        alignment: Alignment.center,
        child: const Icon(Icons.insights, color: Colors.white, size: 40),
      );
}
