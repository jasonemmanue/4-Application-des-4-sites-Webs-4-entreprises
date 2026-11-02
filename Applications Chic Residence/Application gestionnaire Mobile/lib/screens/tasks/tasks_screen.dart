import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/task_card.dart';
import '../../widgets/notifications.dart';
import '../../widgets/ui.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  static const _filters = <TaskStatus?>[
    null,
    TaskStatus.pending,
    TaskStatus.inProgress,
    TaskStatus.cleaned,
    TaskStatus.validated,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(tasksFilterProvider);
    final async = ref.watch(myTasksProvider);

    return AutoRefresh(
      refresh: (ref) => ref.invalidate(myTasksProvider),
      child: Scaffold(
      appBar: AppBar(title: const Text('Tâches')),
      body: Column(
        children: [
          SizedBox(
            height: 46,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                for (final f in _filters)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(
                        f == null ? 'Toutes' : f.label,
                        style: TextStyle(
                          color: filter == f ? Colors.white : null,
                        ),
                      ),
                      selected: filter == f,
                      showCheckmark: false,
                      onSelected: (_) =>
                          ref.read(tasksFilterProvider.notifier).state = f,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(myTasksProvider),
              ),
              data: (all) {
                final list = filter == null
                    ? all
                    : all.where((t) => t.status == filter).toList();
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.task_alt_rounded,
                    title: 'Aucune tâche',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myTasksProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => TaskCard(
                      task: list[i],
                      onTap: () => context.push('/tasks/${list[i].id}'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    ),
    );
  }
}
