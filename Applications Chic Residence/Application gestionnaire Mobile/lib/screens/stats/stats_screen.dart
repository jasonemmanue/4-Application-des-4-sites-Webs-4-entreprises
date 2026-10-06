import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(myStatsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Mes statistiques')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _StatCard(
              icon: Icons.check_circle_outline,
              color: AppColors.completed,
              value: '${s.completedCount}',
              label: 'Taches terminees',
            ),
            const SizedBox(height: 10),
            _StatCard(
              icon: Icons.timer_outlined,
              color: AppColors.inProgress,
              value: '${s.averageDuration.inMinutes} min',
              label: 'Temps moyen de nettoyage',
            ),
            const SizedBox(height: 10),
            _StatCard(
              icon: Icons.thumb_up_outlined,
              color: AppColors.primary,
              value: '${(s.validationRate * 100).round()}%',
              label: 'Taux de validation au premier passage',
            ),
            const SizedBox(height: 10),
            _StatCard(
              icon: Icons.error_outline,
              color: AppColors.rejected,
              value: '${s.rejectedCount}',
              label: 'Rejets a refaire',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color color;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: Theme.of(context)
                          .textTheme
                          .headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  Text(label,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: AppColors.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
