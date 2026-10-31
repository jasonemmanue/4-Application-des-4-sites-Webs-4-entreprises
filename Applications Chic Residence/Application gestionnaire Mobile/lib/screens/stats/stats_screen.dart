import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes statistiques')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(myStatsProvider),
        ),
        data: (s) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(myStatsProvider),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TwoColumns(
                children: [
                  StatTile(
                    icon: Icons.task_alt_rounded,
                    color: AppColors.success,
                    value: '${s.completedTasks}',
                    label: 'Nettoyages terminés',
                  ),
                  StatTile(
                    icon: Icons.cleaning_services_rounded,
                    color: AppColors.info,
                    value: '${s.inProgressTasks}',
                    label: 'En cours',
                  ),
                  StatTile(
                    icon: Icons.timer_outlined,
                    color: AppColors.primary,
                    value: s.averageMinutes == null
                        ? '-'
                        : '${s.averageMinutes!.round()} min',
                    label: 'Temps moyen',
                  ),
                  StatTile(
                    icon: Icons.verified_rounded,
                    color: AppColors.success,
                    value: s.firstPassRate == null
                        ? '-'
                        : '${(s.firstPassRate! * 100).round()} %',
                    label: 'Validés du premier coup',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
