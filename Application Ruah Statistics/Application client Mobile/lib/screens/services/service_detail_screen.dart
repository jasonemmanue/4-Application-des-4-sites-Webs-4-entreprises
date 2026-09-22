import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../models/service.dart';
import '../../providers/providers.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class ServiceDetailScreen extends ConsumerWidget {
  final String slug;

  const ServiceDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(serviceDetailProvider(slug));

    return Scaffold(
      body: service.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(serviceDetailProvider(slug)),
        ),
        data: (s) => _Body(service: s),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Service service;
  const _Body({required this.service});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 240,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(service.title,
                style: const TextStyle(fontSize: 16, color: Colors.white)),
            background: service.coverImage != null
                ? CachedNetworkImage(
                    imageUrl: service.coverImage!,
                    fit: BoxFit.cover,
                    color: Colors.black.withValues(alpha: 0.4),
                    colorBlendMode: BlendMode.darken,
                  )
                : Container(decoration:
                    const BoxDecoration(gradient: AppColors.heroGradient)),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (service.summary != null) ...[
                  Text(service.summary!,
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.md),
                ],
                if (service.description != null) ...[
                  Text(service.description!,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (service.methodology != null) ...[
                  Text('Methodologie',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Text(service.methodology!,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (service.deliverables.isNotEmpty) ...[
                  Text('Livrables',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  ...service.deliverables.map((d) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.brand400, size: 18),
                            const SizedBox(width: 8),
                            Expanded(child: Text(d)),
                          ],
                        ),
                      )),
                  const SizedBox(height: AppSpacing.lg),
                ],
                if (service.sectors.isNotEmpty) ...[
                  Text("Secteurs d'intervention",
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final s in service.sectors) Chip(label: Text(s)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.go(AppRoutes.quote),
                    icon: const Icon(Icons.request_quote_outlined),
                    label: const Text('Demander un devis'),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
