import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/task_card.dart';
import '../../widgets/notifications.dart';
import '../../widgets/ui.dart';

class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});
  final String taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action, {String? done}) async {
    setState(() => _busy = true);
    try {
      await action();
      ref.invalidate(taskDetailProvider(widget.taskId));
      ref.invalidate(myTasksProvider);
      ref.invalidate(myStatsProvider);
      if (done != null && mounted) showMessage(context, done);
    } catch (e) {
      if (mounted) showMessage(context, readableError(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addPhoto(String label) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
    } on PlatformException {
      if (mounted) {
        showMessage(context, 'Autorisez l\'accès à l\'appareil photo.');
      }
      return;
    }
    if (file == null) return;
    final picked = file;
    await _run(
      () => ref
          .read(taskServiceProvider)
          .uploadPhoto(widget.taskId, picked, label: label),
      done: 'Photo ajoutée.',
    );
  }

  Future<void> _reject() async {
    final reason = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Rejeter le nettoyage'),
          content: TextField(
            controller: reason,
            maxLines: 4,
            autofocus: true,
            onChanged: (_) => setD(() {}),
            decoration: const InputDecoration(
              hintText: 'Ce qui doit être refait (obligatoire)',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: reason.text.trim().length < 3
                  ? null
                  : () => Navigator.of(ctx).pop(true),
              child: const Text('Rejeter'),
            ),
          ],
        ),
      ),
    );
    final text = reason.text.trim();
    reason.dispose();
    if (ok != true) return;
    await _run(
      () => ref.read(taskServiceProvider).reject(widget.taskId, text),
      done: 'Tâche renvoyée à l\'agent.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(taskDetailProvider(widget.taskId));
    final user = ref.watch(currentUserProvider);
    return AutoRefresh(
      refresh: (ref) => ref.invalidate(taskDetailProvider(widget.taskId)),
      child: Scaffold(
      appBar: AppBar(title: const Text('Détail de la tâche')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(taskDetailProvider(widget.taskId)),
        ),
        data: (task) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(taskDetailProvider(widget.taskId)),
                child: _details(task, user),
              ),
            ),
            _actions(task, user),
          ],
        ),
      ),
    ),
    );
  }

  Widget _details(CleaningTask t, StaffUser? user) {
    final df = DateFormat('d MMM à HH:mm', 'fr_FR');
    final r = t.residence;
    final isAgent = user?.role == StaffRole.agent;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      children: [
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.residenceTitle,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  StatusPill(
                      label: t.status.label, color: taskColor(t.status)),
                ],
              ),
              if (r != null) ...[
                const SizedBox(height: 4),
                Text(
                  [r.typeLabel, r.city, if (r.address.isNotEmpty) r.address]
                      .join(' · '),
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textMuted),
                ),
              ],
              const SizedBox(height: 10),
              if (t.nextCheckIn != null)
                _Line(
                  Icons.event_rounded,
                  'Prochaine arrivée : '
                  '${DateFormat('EEEE d MMMM', 'fr_FR').format(t.nextCheckIn!)}',
                ),
              if (t.agentName != null)
                _Line(Icons.person_outline_rounded, 'Agent : ${t.agentName}'),
              if (t.controllerName != null)
                _Line(Icons.verified_user_outlined,
                    'Contrôleur : ${t.controllerName}'),
              if (t.startedAt != null)
                _Line(Icons.play_circle_outline_rounded,
                    'Commencé le ${df.format(t.startedAt!.toLocal())}'),
              if (t.completedAt != null)
                _Line(Icons.check_circle_outline_rounded,
                    'Terminé le ${df.format(t.completedAt!.toLocal())}'),
              if (t.validatedAt != null)
                _Line(Icons.verified_rounded,
                    'Validé le ${df.format(t.validatedAt!.toLocal())}'),
            ],
          ),
        ),
        if (t.wasRejected) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.09),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text('À refaire : ${t.rejectionReason}',
                style: const TextStyle(color: AppColors.error)),
          ),
        ],
        if (t.notes.isNotEmpty) ...[
          const SizedBox(height: 12),
          Panel(child: Text(t.notes)),
        ],
        const SizedBox(height: 18),
        _PhotoSection(
          title: 'Photos avant',
          photos: t.photos.where((p) => p.label == 'before').toList(),
          onAdd: isAgent && t.status == TaskStatus.inProgress && !_busy
              ? () => _addPhoto('before')
              : null,
        ),
        const SizedBox(height: 14),
        _PhotoSection(
          title: 'Photos après (au moins une)',
          photos: t.photos.where((p) => p.label == 'after').toList(),
          onAdd: isAgent && t.status == TaskStatus.inProgress && !_busy
              ? () => _addPhoto('after')
              : null,
        ),
        if (t.hasPhoto('rejection') || !isAgent) ...[
          const SizedBox(height: 14),
          _PhotoSection(
            title: 'Photos du contrôle',
            photos: t.photos.where((p) => p.label == 'rejection').toList(),
            onAdd: !isAgent &&
                    t.status == TaskStatus.cleaned &&
                    t.controllerId == user?.id &&
                    !_busy
                ? () => _addPhoto('rejection')
                : null,
          ),
        ],
      ],
    );
  }

  Widget _actions(CleaningTask t, StaffUser? user) {
    final svc = ref.read(taskServiceProvider);
    final buttons = <Widget>[];
    if (user?.role == StaffRole.agent) {
      if (t.status == TaskStatus.pending) {
        buttons.add(FilledButton.icon(
          onPressed:
              _busy ? null : () => _run(() => svc.start(t.id), done: 'C\'est parti !'),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Commencer le nettoyage'),
        ));
      } else if (t.status == TaskStatus.inProgress) {
        buttons.add(FilledButton.icon(
          onPressed: _busy || !t.hasPhoto('after')
              ? null
              : () => _run(() => svc.complete(t.id),
                  done: 'Envoyé au contrôle.'),
          icon: const Icon(Icons.check_rounded),
          label: Text(t.hasPhoto('after')
              ? 'Terminer le nettoyage'
              : 'Ajoutez une photo après'),
        ));
      }
    } else if (t.status == TaskStatus.cleaned) {
      buttons.add(FilledButton.icon(
        onPressed: _busy
            ? null
            : () => _run(() => svc.validate(t.id), done: 'Logement validé.'),
        icon: const Icon(Icons.verified_rounded),
        label: const Text('Valider le contrôle'),
      ));
      buttons.add(const SizedBox(height: 8));
      buttons.add(OutlinedButton.icon(
        onPressed: _busy ? null : _reject,
        icon: const Icon(Icons.close_rounded),
        label: const Text('Rejeter'),
      ));
    }
    if (buttons.isEmpty) return const SizedBox.shrink();
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: buttons,
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  const _Line(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: AppColors.textMuted),
          const SizedBox(width: 7),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.title,
    required this.photos,
    this.onAdd,
  });
  final String title;
  final List<TaskPhoto> photos;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        SizedBox(
          height: 96,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              if (onAdd != null)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: onAdd,
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: 96,
                      decoration: BoxDecoration(
                        color: AppColors.primaryLight,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.add_a_photo_outlined,
                          color: AppColors.primary),
                    ),
                  ),
                ),
              for (final p in photos)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: CachedNetworkImage(
                      imageUrl: ApiConfig.resolve(p.url),
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => Container(
                        width: 96,
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.broken_image_outlined),
                      ),
                    ),
                  ),
                ),
              if (photos.isEmpty && onAdd == null)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Aucune photo',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMuted)),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
