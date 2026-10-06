import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/task_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final async = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(user == null ? 'Chic Residence' : 'Salut ${user.firstName}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(tasksProvider),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (tasks) {
          final today = DateTime.now();
          final todays = tasks.where((t) {
            final d = t.nextCheckIn ?? t.startedAt;
            if (d == null) return t.status != TaskStatus.controlled;
            return d.year == today.year &&
                d.month == today.month &&
                d.day == today.day;
          }).toList();

          final pending =
              tasks.where((t) => t.status == TaskStatus.pending).length;
          final inProgress =
              tasks.where((t) => t.status == TaskStatus.inProgress).length;
          final done = tasks
              .where((t) =>
                  t.status == TaskStatus.cleaned ||
                  t.status == TaskStatus.controlled)
              .length;

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(tasksProvider),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('Aujourd\'hui',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatBox(
                        label: 'En attente',
                        count: pending,
                        color: AppColors.pending,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: 'En cours',
                        count: inProgress,
                        color: AppColors.inProgress,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _StatBox(
                        label: 'Terminees',
                        count: done,
                        color: AppColors.completed,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Prochaine tache',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                if (todays.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(
                      child: Text('Aucune tache prevue aujourd\'hui'),
                    ),
                  )
                else
                  ...todays.take(3).map(
                        (t) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: TaskCard(
                            task: t,
                            onTap: () => context.push('/tasks/${t.id}'),
                          ),
                        ),
                      ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.label,
    required this.count,
    required this.color,
  });
  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$count',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  )),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
