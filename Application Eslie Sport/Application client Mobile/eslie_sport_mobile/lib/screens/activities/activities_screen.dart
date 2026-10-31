import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/providers.dart';
import '../../utils/formatters.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/search_pill.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  String? _category;

  @override
  Widget build(BuildContext context) {
    final async =
        ref.watch(activitiesProvider((category: _category, level: null)));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activités'),
        actions: [
          IconButton(
            tooltip: 'Rechercher',
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => const SearchScreen(),
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(activitiesProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SliverPadding(
              padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
              sliver: SliverToBoxAdapter(
                child: UnderlinedTitle('Trouve ton rythme'),
              ),
            ),
            SliverToBoxAdapter(
              child: _CategoryStrip(
                current: _category,
                onSelect: (c) => setState(() => _category = c),
              ),
            ),
            ...async.when(
              data: (list) => list.isEmpty
                  ? [
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: EmptyState(
                          icon: Icons.fitness_center,
                          title: 'Aucune activité',
                          subtitle: 'Essayez une autre catégorie.',
                        ),
                      ),
                    ]
                  : [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        sliver: SliverList.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => ActivityRow(
                            activity: list[i],
                            onTap: () =>
                                context.push('/activities/${list[i].slug}'),
                          ),
                        ),
                      ),
                    ],
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: LoadingState(message: 'Chargement des activités...'),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: ErrorState(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(activitiesProvider),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryStrip extends StatelessWidget {
  final String? current;
  final ValueChanged<String?> onSelect;
  const _CategoryStrip({required this.current, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final entries = <(String?, String)>[
      (null, 'Toutes'),
      ...activityCategories,
    ];
    return SizedBox(
      height: 96,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: entries.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final (key, label) = entries[i];
          final active = key == current;
          return InkWell(
            borderRadius: BorderRadius.circular(AppRadius.md),
            onTap: () => onSelect(key),
            child: SizedBox(
              width: 78,
              child: Column(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: active ? AppColors.yellow : AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      activityCategoryIcon(key),
                      color:
                          active ? AppColors.textPrimary : AppColors.onPrimary,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11.5,
                      height: 1.15,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
