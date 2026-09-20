import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class ActivityDetailScreen extends ConsumerWidget {
  final String slug;
  const ActivityDetailScreen({super.key, required this.slug});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(activityBySlugProvider(slug));
    return Scaffold(
      body: async.when(
        data: (a) {
          if (a == null) {
            return const EmptyState(
              icon: Icons.fitness_center,
              title: 'Activite introuvable',
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                foregroundColor: Colors.white,
                backgroundColor: AppColors.dark,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(a.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700)),
                  background: a.imageUrl != null && a.imageUrl!.isNotEmpty
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                                imageUrl: a.imageUrl!, fit: BoxFit.cover),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.dark.withOpacity(0.9),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(color: AppColors.darkLighter),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      children: [
                        if (a.category.isNotEmpty)
                          _chip(a.category.toUpperCase(), AppColors.primary),
                        const SizedBox(width: 8),
                        if (a.level.isNotEmpty)
                          _chip(a.level.toUpperCase(), AppColors.success),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (a.description.isNotEmpty)
                      Text(a.description,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              height: 1.5)),
                    const SizedBox(height: 16),
                    _infoRow(Icons.schedule, '${a.durationMinutes} minutes'),
                    _infoRow(Icons.groups,
                        'Capacite max : ${a.maxCapacity} personnes'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.push(
                          '/schedule',
                        ),
                        icon: const Icon(Icons.event_available),
                        label: const Text('Voir les creneaux dans le planning'),
                      ),
                    ),
                  ]),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(activityBySlugProvider(slug)),
        ),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Text(text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            )),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text,
                  style: const TextStyle(color: Colors.white, fontSize: 13)),
            ),
          ],
        ),
      );
}
