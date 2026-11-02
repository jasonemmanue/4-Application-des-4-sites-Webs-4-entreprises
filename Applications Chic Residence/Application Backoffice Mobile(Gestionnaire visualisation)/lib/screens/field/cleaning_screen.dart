import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/api_config.dart';
import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/notifications.dart';
import '../../widgets/ui.dart';

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

/// Le suivi du travail fait dans l'application gestionnaire. Sur téléphone, des
/// onglets par statut se lisent mieux qu'un Kanban à cinq colonnes défilantes.
class CleaningScreen extends ConsumerWidget {
  const CleaningScreen({super.key});

  static const _tabs = [
    TaskStatus.pending,
    TaskStatus.inProgress,
    TaskStatus.cleaned,
    TaskStatus.validated,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(tasksProvider);
    return AutoRefresh(
      refresh: (ref) {
        ref.invalidate(tasksProvider);
        ref.invalidate(staffProvider);
      },
      child: DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Suivi terrain'),
          bottom: TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            tabs: [
              for (final s in _tabs)
                Tab(
                  text:
                      '${s.label} (${async.valueOrNull?.where((t) => t.status == s).length ?? 0})',
                ),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _NewTaskSheet.open(context, ref),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Tâche'),
        ),
        body: async.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorState(
            error: e,
            onRetry: () => ref.invalidate(tasksProvider),
          ),
          data: (tasks) => TabBarView(
            children: [
              for (final s in _tabs)
                _TaskList(tasks: tasks.where((t) => t.status == s).toList()),
            ],
          ),
        ),
      ),
    ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  const _TaskList({required this.tasks});
  final List<CleaningTask> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.task_alt_rounded,
        title: 'Aucune tâche ici',
      );
    }
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(tasksProvider),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
        itemCount: tasks.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, i) {
          final t = tasks[i];
          return Panel(
            onTap: () => _TaskSheet.open(context, t),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.residenceTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                      Text(
                        'Agent : ${t.agentName ?? 'non assigné'}',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted),
                      ),
                      if (t.nextCheckIn != null)
                        Text(
                          'Prochaine arrivée : ${dayMonth(t.nextCheckIn!)}',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      if (t.rejectionReason.isNotEmpty &&
                          t.status == TaskStatus.pending)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: StatusPill(
                              label: 'À refaire', color: AppColors.error),
                        ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.textMuted),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TaskSheet extends ConsumerStatefulWidget {
  const _TaskSheet({required this.task});
  final CleaningTask task;

  static Future<void> open(BuildContext context, CleaningTask task) =>
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => _TaskSheet(task: task),
      );

  @override
  ConsumerState<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends ConsumerState<_TaskSheet> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(tasksProvider);
      ref.invalidate(overviewProvider);
      if (mounted) {
        Navigator.of(context).pop();
        showMessage(context, done);
      }
    } catch (e) {
      if (mounted) showMessage(context, readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final api = ref.read(adminApiProvider);
    final staff = ref.watch(staffProvider).valueOrNull ?? const <StaffMember>[];
    final agents = staff
        .where((s) => s.role == StaffRole.agent && s.isActive)
        .toList();
    final controllers = staff
        .where((s) => s.role == StaffRole.controller && s.isActive)
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(t.residenceTitle,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w700)),
              ),
              StatusPill(label: t.status.label, color: taskColor(t.status)),
            ],
          ),
          const SizedBox(height: 8),
          if (t.startedAt != null)
            Text('Commencé : ${dateTime(t.startedAt!)}',
                style: const TextStyle(fontSize: 13)),
          if (t.completedAt != null)
            Text('Terminé : ${dateTime(t.completedAt!)}',
                style: const TextStyle(fontSize: 13)),
          if (t.validatedAt != null)
            Text('Validé : ${dateTime(t.validatedAt!)}',
                style: const TextStyle(fontSize: 13)),
          if (t.rejectionReason.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('Motif du rejet : ${t.rejectionReason}',
                  style:
                      const TextStyle(fontSize: 13, color: AppColors.error)),
            ),
          if (t.notes.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(t.notes, style: const TextStyle(fontSize: 13)),
            ),
          if (t.photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in t.photos)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(13),
                            child: CachedNetworkImage(
                              imageUrl: ApiConfig.resolve(p.$1),
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            left: 5,
                            bottom: 5,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                {
                                      'before': 'Avant',
                                      'after': 'Après',
                                      'rejection': 'Contrôle',
                                    }[p.$2] ??
                                    p.$2,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 10.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue:
                agents.any((a) => a.id == t.agentId) ? t.agentId : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Agent'),
            items: [
              for (final a in agents)
                DropdownMenuItem(value: a.id, child: Text(a.fullName)),
            ],
            onChanged: _busy
                ? null
                : (v) => _run(
                      () => api.assignTask(t.id, agentId: v),
                      'Agent assigné.',
                    ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: controllers.any((a) => a.id == t.controllerId)
                ? t.controllerId
                : null,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Contrôleur'),
            items: [
              for (final a in controllers)
                DropdownMenuItem(value: a.id, child: Text(a.fullName)),
            ],
            onChanged: _busy
                ? null
                : (v) => _run(
                      () => api.assignTask(t.id, controllerId: v),
                      'Contrôleur assigné.',
                    ),
          ),
          const SizedBox(height: 14),
          if (t.status != TaskStatus.validated)
            FilledButton(
              onPressed: _busy
                  ? null
                  : () => _run(() => api.forceValidate(t.id), 'Tâche validée.'),
              child: const Text('Forcer la validation'),
            ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _busy
                ? null
                : () async {
                    final ok = await showDialog<bool>(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: const Text('Supprimer cette tâche ?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(d).pop(false),
                            child: const Text('Annuler'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(d).pop(true),
                            child: const Text('Supprimer'),
                          ),
                        ],
                      ),
                    );
                    if (ok == true) {
                      await _run(() => api.deleteTask(t.id), 'Tâche supprimée.');
                    }
                  },
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}

class _NewTaskSheet extends ConsumerStatefulWidget {
  const _NewTaskSheet();

  static Future<void> open(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewTaskSheet(),
    );
    if (ok == true) {
      ref.invalidate(tasksProvider);
      ref.invalidate(overviewProvider);
    }
  }

  @override
  ConsumerState<_NewTaskSheet> createState() => _NewTaskSheetState();
}

class _NewTaskSheetState extends ConsumerState<_NewTaskSheet> {
  String? _residence;
  String? _agent;
  bool _saving = false;
  String? _error;

  Future<void> _create() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminApiProvider).createTask(
            residenceId: _residence!,
            agentId: _agent,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final residences =
        ref.watch(residencesProvider).valueOrNull ?? const <Residence>[];
    final staff = ref.watch(staffProvider).valueOrNull ?? const <StaffMember>[];
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Nouvelle tâche de préparation',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _residence,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Logement'),
            items: [
              for (final r in residences)
                DropdownMenuItem(
                  value: r.id,
                  child: Text(r.title, overflow: TextOverflow.ellipsis),
                ),
            ],
            onChanged: (v) => setState(() => _residence = v),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _agent,
            isExpanded: true,
            decoration:
                const InputDecoration(labelText: 'Agent (facultatif)'),
            items: [
              for (final s in staff.where(
                  (s) => s.role == StaffRole.agent && s.isActive))
                DropdownMenuItem(value: s.id, child: Text(s.fullName)),
            ],
            onChanged: (v) => setState(() => _agent = v),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _residence == null || _saving ? null : _create,
            child: const Text('Créer la tâche'),
          ),
        ],
      ),
    );
  }
}
