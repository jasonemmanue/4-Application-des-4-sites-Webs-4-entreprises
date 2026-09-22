import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final VoidCallback? onTap;

  const ProjectCard({super.key, required this.project, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: project.coverImage != null
                  ? CachedNetworkImage(
                      imageUrl: project.coverImage!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _fallback(context),
                      placeholder: (_, __) => _fallback(context),
                    )
                  : _fallback(context),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (project.sector != null)
                        _pill(context, project.sector!),
                      if (project.country != null)
                        _pill(context, project.country!),
                      if (project.year != null)
                        _pill(context, project.year!.toString()),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(project.title,
                      style: Theme.of(context).textTheme.titleLarge),
                  if (project.summary != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      project.summary!,
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

  Widget _pill(BuildContext context, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.brand500.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: AppColors.brand400, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _fallback(BuildContext context) => Container(
        decoration: const BoxDecoration(gradient: AppColors.heroGradient),
        alignment: Alignment.center,
        child: const Icon(Icons.folder_open, color: Colors.white, size: 40),
      );
}
