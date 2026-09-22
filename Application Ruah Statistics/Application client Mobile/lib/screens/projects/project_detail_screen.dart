import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/project.dart';
import '../../providers/providers.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class ProjectDetailScreen extends ConsumerWidget {
  final String slug;

  const ProjectDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(projectDetailProvider(slug));
    return Scaffold(
      body: project.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(projectDetailProvider(slug)),
        ),
        data: (p) => _Body(project: p),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Project project;
  const _Body({required this.project});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 260,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(project.title,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
            background: project.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: project.coverImage!,
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.4),
                    colorBlendMode: BlendMode.darken,
                  )
                : Container(
                    decoration: const BoxDecoration(
                        gradient: AppColors.heroGradient),
                  ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    if (project.client != null)
                      _tag(context, Icons.business, project.client!),
                    if (project.sector != null)
                      _tag(context, Icons.category, project.sector!),
                    if (project.country != null)
                      _tag(context, Icons.public, project.country!),
                    if (project.year != null)
                      _tag(context, Icons.calendar_today,
                          project.year!.toString()),
                  ],
                ),
                if (project.summary != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(project.summary!,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
                if (project.figures.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  GridView.count(
                    crossAxisCount: 2,
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    mainAxisSpacing: AppSpacing.sm,
                    crossAxisSpacing: AppSpacing.sm,
                    childAspectRatio: 1.8,
                    children: [
                      for (final f in project.figures)
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            gradient: AppColors.ctaGradient,
                            borderRadius: BorderRadius.circular(AppRadius.card),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(f.value,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800)),
                              const Spacer(),
                              Text(f.label,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
                _section(context, 'Contexte', project.context),
                _section(context, 'Solution deployee', project.solution),
                _section(context, 'Resultats', project.results),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _tag(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.charcoal700,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brand400),
          const SizedBox(width: 6),
          Text(label,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, String? content) {
    if (content == null || content.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.sm),
          Text(content, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
