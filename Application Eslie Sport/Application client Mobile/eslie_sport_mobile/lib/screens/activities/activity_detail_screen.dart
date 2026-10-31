import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/activity_card.dart';
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
            return Scaffold(
              appBar: AppBar(),
              body: const EmptyState(
                icon: Icons.fitness_center,
                title: 'Activité introuvable',
              ),
            );
          }
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 260,
                pinned: true,
                foregroundColor: AppColors.onPrimary,
                backgroundColor: AppColors.primaryDark,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    a.name,
                    style: const TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      ActivityPhoto(url: a.imageUrl, category: a.category),
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Color(0x4D07382A), Color(0xE607382A)],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (a.category.isNotEmpty)
                          _chip(activityCategoryLabel(a.category)),
                        _chip(activityLevelLabel(a.level)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (a.description.isNotEmpty)
                      Text(
                        a.description,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          height: 1.55,
                        ),
                      ),
                    const SizedBox(height: 16),
                    _infoRow(Icons.schedule, '${a.durationMinutes} minutes'),
                    _infoRow(Icons.groups_outlined,
                        '${a.maxCapacity} places par séance'),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            context.go('/schedule?activity=${a.id}'),
                        icon: const Icon(Icons.event_available),
                        label: const Text('Réserver ma place'),
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

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primarySoft,
          borderRadius: BorderRadius.circular(AppRadius.full),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );

  Widget _infoRow(IconData icon, String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                text,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      );
}
