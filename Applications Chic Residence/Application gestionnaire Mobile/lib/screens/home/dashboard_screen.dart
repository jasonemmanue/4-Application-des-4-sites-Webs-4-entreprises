import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/task_card.dart';
import '../../widgets/ui.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final async = ref.watch(myTasksProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () async => ref.invalidate(myTasksProvider),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            children: [
              Row(
                children: [
                  Image.asset('assets/branding/logo-full.png',
                      height: 58, semanticLabel: 'Chic Résidence Meublée'),
                  const Spacer(),
                  if (user != null)
                    StatusPill(label: user.role.label, color: AppColors.navy),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                'Bonjour ${user?.firstName ?? ''} !',
                style:
                    const TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              Text(
                user?.role == StaffRole.controller
                    ? 'Voici les logements à contrôler'
                    : 'Voici les logements à préparer',
                style:
                    const TextStyle(fontSize: 13.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              async.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => ErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(myTasksProvider),
                ),
                data: (tasks) => _Content(tasks: tasks, role: user?.role),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.tasks, required this.role});
  final List<CleaningTask> tasks;
  final StaffRole? role;

  @override
  Widget build(BuildContext context) {
    int count(TaskStatus s) => tasks.where((t) => t.status == s).length;
    final open = tasks
        .where((t) => role == StaffRole.controller
            ? t.status == TaskStatus.cleaned
            : t.status == TaskStatus.pending ||
                t.status == TaskStatus.inProgress)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TwoColumns(
          children: role == StaffRole.controller
              ? [
                  StatTile(
                    icon: Icons.rule_rounded,
                    color: AppColors.primary,
                    value: '${count(TaskStatus.cleaned)}',
                    label: 'À contrôler',
                  ),
                  StatTile(
                    icon: Icons.verified_rounded,
                    color: AppColors.success,
                    value: '${count(TaskStatus.validated)}',
                    label: 'Validées',
                  ),
                ]
              : [
                  StatTile(
                    icon: Icons.pending_actions_rounded,
                    color: AppColors.warning,
                    value: '${count(TaskStatus.pending)}',
                    label: 'À faire',
                  ),
                  StatTile(
                    icon: Icons.cleaning_services_rounded,
                    color: AppColors.info,
                    value: '${count(TaskStatus.inProgress)}',
                    label: 'En cours',
                  ),
                  StatTile(
                    icon: Icons.rule_rounded,
                    color: AppColors.primary,
                    value: '${count(TaskStatus.cleaned)}',
                    label: 'En contrôle',
                  ),
                  StatTile(
                    icon: Icons.verified_rounded,
                    color: AppColors.success,
                    value: '${count(TaskStatus.validated)}',
                    label: 'Validées',
                  ),
                ],
        ),
        const SizedBox(height: 22),
        SectionTitle(
          'Prochaines tâches',
          action: TextButton(
            onPressed: () => context.go('/tasks'),
            child: const Text('Voir tout'),
          ),
        ),
        if (open.isEmpty)
          const Panel(
            child: EmptyState(
              icon: Icons.task_alt_rounded,
              title: 'Rien à faire pour le moment',
            ),
          )
        else
          for (final t in open.take(4))
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TaskCard(
                task: t,
                onTap: () => context.push('/tasks/${t.id}'),
              ),
            ),
      ],
    );
  }
}
