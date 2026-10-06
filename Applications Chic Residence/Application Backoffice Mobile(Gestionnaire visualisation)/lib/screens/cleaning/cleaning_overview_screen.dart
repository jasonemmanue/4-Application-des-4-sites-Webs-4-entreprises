import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';

/// Vue Kanban des taches de nettoyage.
class CleaningOverviewScreen extends ConsumerWidget {
  const CleaningOverviewScreen({super.key});

  static const _columns = <_Col>[
    _Col(TaskStatus.pending, 'A faire', AppColors.warning),
    _Col(TaskStatus.inProgress, 'En cours', AppColors.info),
    _Col(TaskStatus.cleaned, 'A controler', AppColors.accent),
    _Col(TaskStatus.controlled, 'Termine', AppColors.success),
    _Col(TaskStatus.rejected, 'Rejete', AppColors.error),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(cleaningTasksProvider);
    return Scaffold(
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (tasks) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(cleaningTasksProvider),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final col in _columns)
                  _KanbanColumn(
                    col: col,
                    tasks:
                        tasks.where((t) => t.status == col.status).toList(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Col {
  final TaskStatus status;
  final String label;
  final Color color;
  const _Col(this.status, this.label, this.color);
}

class _KanbanColumn extends StatelessWidget {
  const _KanbanColumn({required this.col, required this.tasks});
  final _Col col;
  final List<TaskSummary> tasks;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: col.color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration:
                    BoxDecoration(color: col.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(col.label,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: col.color,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text('${tasks.length}',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final t in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _TaskTile(task: t),
            ),
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Aucune tache',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});
  final TaskSummary task;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(task.residenceName,
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 4),
          if (task.assignedToName != null)
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(task.assignedToName!,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall),
                ),
              ],
            ),
          if (task.nextCheckIn != null)
            Text('Check-in ${task.nextCheckIn!.day}/${task.nextCheckIn!.month}',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.textMuted)),
        ],
      ),
    );
  }
}
