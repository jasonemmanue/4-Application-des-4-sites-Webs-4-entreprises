import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../models/models.dart';
import 'ui.dart';

Color taskColor(TaskStatus s) {
  switch (s) {
    case TaskStatus.pending:
      return AppColors.warning;
    case TaskStatus.inProgress:
      return AppColors.info;
    case TaskStatus.cleaned:
      return AppColors.primary;
    case TaskStatus.validated:
      return AppColors.success;
    case TaskStatus.rejected:
      return AppColors.error;
  }
}

class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.task, required this.onTap});
  final CleaningTask task;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = taskColor(task.status);
    return Panel(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.cleaning_services_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.residenceTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                if (task.residence != null)
                  Text(
                    task.residence!.city,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted),
                  ),
                const SizedBox(height: 5),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    StatusPill(label: task.status.label, color: color),
                    if (task.wasRejected)
                      const StatusPill(
                          label: 'À refaire', color: AppColors.error),
                    if (task.nextCheckIn != null)
                      StatusPill(
                        label:
                            'Arrivée ${DateFormat('d MMM', 'fr_FR').format(task.nextCheckIn!)}',
                        color: AppColors.navy,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
    );
  }
}
