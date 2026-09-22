import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';
import '../../widgets/project_card.dart';

class ProjectsListScreen extends ConsumerWidget {
  const ProjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(projectFilterProvider);
    final projects = ref.watch(projectsProvider(filter));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Realisations'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => _showFilters(context, ref),
          ),
        ],
      ),
      body: projects.when(
        loading: () => const LoadingState(),
        error: (e, _) => ErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(projectsProvider),
        ),
        data: (page) {
          if (page.items.isEmpty) {
            return const EmptyState(
              title: 'Aucune realisation ne correspond',
              subtitle: 'Essayez de retirer les filtres',
              icon: Icons.folder_open,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(projectsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: page.items.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.md),
              itemBuilder: (_, i) => ProjectCard(
                project: page.items[i],
                onTap: () =>
                    context.push('${AppRoutes.projects}/${page.items[i].slug}'),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showFilters(BuildContext context, WidgetRef ref) async {
    final ProjectFilter current = ref.read(projectFilterProvider);
    final TextEditingController sector =
        TextEditingController(text: current.sector ?? '');
    final TextEditingController country =
        TextEditingController(text: current.country ?? '');
    final TextEditingController year =
        TextEditingController(text: current.year?.toString() ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filtrer les realisations',
                style: Theme.of(ctx).textTheme.headlineSmall),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: sector,
              decoration: const InputDecoration(labelText: 'Secteur'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: country,
              decoration: const InputDecoration(labelText: 'Pays'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: year,
              decoration: const InputDecoration(labelText: 'Annee'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(projectFilterProvider.notifier).state =
                          const ProjectFilter();
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Reinitialiser'),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(projectFilterProvider.notifier).state =
                          ProjectFilter(
                        page: 1,
                        sector: sector.text.trim().isEmpty
                            ? null
                            : sector.text.trim(),
                        country: country.text.trim().isEmpty
                            ? null
                            : country.text.trim(),
                        year: int.tryParse(year.text.trim()),
                      );
                      Navigator.of(ctx).pop();
                    },
                    child: const Text('Appliquer'),
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
