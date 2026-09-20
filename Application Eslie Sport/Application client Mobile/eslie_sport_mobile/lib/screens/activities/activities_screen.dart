import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../services/providers.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_state.dart';
import '../../widgets/loading_state.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  String? _category;
  String? _level;

  static const _categories = [
    ('force', 'Force'),
    ('cardio', 'Cardio'),
    ('souplesse', 'Souplesse'),
    ('arts_martiaux', 'Arts martiaux'),
    ('danse', 'Danse'),
  ];

  static const _levels = [
    ('debutant', 'Debutant'),
    ('intermediaire', 'Intermediaire'),
    ('avance', 'Avance'),
  ];

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(activitiesProvider((category: _category, level: _level)));

    return Scaffold(
      appBar: AppBar(title: const Text('Activites')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _filterRow('Categorie', _categories, _category,
                    (v) => setState(() => _category = v)),
                const SizedBox(height: 6),
                _filterRow('Niveau', _levels, _level,
                    (v) => setState(() => _level = v)),
              ],
            ),
          ),
          Expanded(
            child: async.when(
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.fitness_center,
                    title: 'Aucune activite',
                    subtitle: 'Modifiez vos filtres.',
                  );
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.68,
                  ),
                  itemCount: list.length,
                  itemBuilder: (_, i) => ActivityCard(
                    activity: list[i],
                    onTap: () => context.push('/activities/${list[i].slug}'),
                  ),
                );
              },
              loading: () => const LoadingState(message: 'Chargement des activites...'),
              error: (e, _) => ErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(activitiesProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterRow(
    String label,
    List<(String, String)> options,
    String? selected,
    ValueChanged<String?> onChange,
  ) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.darkMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _chip('Tous', selected == null, () => onChange(null)),
                for (final opt in options)
                  _chip(opt.$2, selected == opt.$1, () => onChange(opt.$1)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: active ? AppColors.primary : AppColors.darkCard,
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: active ? AppColors.primary : AppColors.darkBorder,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: active ? AppColors.dark : Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
