import 'dart:async';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/task_card.dart';

/// Detail d'une tache : les actions varient selon le role (agent / controleur).
class TaskDetailScreen extends ConsumerStatefulWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final int taskId;

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  CleaningTask? _task;
  bool _loading = true;
  String? _error;
  bool _acting = false;
  Timer? _timer;
  Duration _elapsed = Duration.zero;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final t = await ref.read(taskServiceProvider).detail(widget.taskId);
      if (!mounted) return;
      setState(() => _task = t);
      _ensureTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _ensureTimer() {
    _timer?.cancel();
    if (_task?.status == TaskStatus.inProgress && _task?.startedAt != null) {
      _elapsed = DateTime.now().difference(_task!.startedAt!);
      _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() =>
            _elapsed = DateTime.now().difference(_task!.startedAt!));
      });
    }
  }

  Future<void> _act(Future<CleaningTask> Function() action) async {
    setState(() => _acting = true);
    try {
      final t = await action();
      setState(() => _task = t);
      _ensureTimer();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _uploadPhoto(String phase) async {
    final file = await _picker.pickImage(
        source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    setState(() => _acting = true);
    try {
      await ref
          .read(taskServiceProvider)
          .uploadPhoto(widget.taskId, File(file.path), phase: phase);
      await _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _rejectDialog() async {
    final ctrl = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rejeter le nettoyage'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Precisez ce qui doit etre refait. Le commentaire est obligatoire.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: 'Ex : Salle de bain non nettoyee, poubelle a vider...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (ctrl.text.trim().length < 5) return;
              Navigator.of(context).pop(ctrl.text.trim());
            },
            child: const Text('Rejeter'),
          ),
        ],
      ),
    );
    if (reason != null) {
      await _act(
          () => ref.read(taskServiceProvider).reject(widget.taskId, reason));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _task == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(child: Text(_error ?? 'Introuvable')),
      );
    }
    final t = _task!;
    final me = ref.watch(currentUserProvider);
    final isController = me?.role == StaffRole.controller;
    final beforePhotos = t.photos.where((p) => p.phase == 'before').toList();
    final afterPhotos = t.photos.where((p) => p.phase == 'after').toList();

    return Scaffold(
      appBar: AppBar(title: Text(t.residence.name)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(t.residence.name,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      StatusBadge(status: t.status),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(t.residence.address,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          )),
                  const SizedBox(height: 6),
                  Text(
                      '${t.residence.type} • ${t.residence.capacity} personne(s)'),
                ],
              ),
            ),
          ),
          if (t.status == TaskStatus.inProgress) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.inProgress.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.inProgress.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer, color: AppColors.inProgress),
                  const SizedBox(width: 8),
                  Text('Temps ecoule : ${_fmt(_elapsed)}',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
          if (t.rejectionReason != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.rejected.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.rejected.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Motif de rejet',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(t.rejectionReason!),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          _PhotoSection(
            label: 'Photos avant',
            photos: beforePhotos,
            canAdd: !isController && t.status == TaskStatus.inProgress,
            onAdd: () => _uploadPhoto('before'),
          ),
          const SizedBox(height: 12),
          _PhotoSection(
            label: 'Photos apres',
            photos: afterPhotos,
            canAdd: !isController &&
                (t.status == TaskStatus.inProgress ||
                    t.status == TaskStatus.cleaned),
            onAdd: () => _uploadPhoto('after'),
          ),
          const SizedBox(height: 24),
          _buildActions(t, isController, afterPhotos.isNotEmpty),
        ],
      ),
    );
  }

  Widget _buildActions(
      CleaningTask t, bool isController, bool hasAfterPhotos) {
    if (isController) {
      if (t.status == TaskStatus.cleaned) {
        return Column(
          children: [
            FilledButton.icon(
              onPressed: _acting
                  ? null
                  : () => _act(() =>
                      ref.read(taskServiceProvider).validate(widget.taskId)),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Valider le controle'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _acting ? null : _rejectDialog,
              icon: const Icon(Icons.close_rounded),
              label: const Text('Rejeter'),
            ),
          ],
        );
      }
      return const Center(child: Text('Aucune action disponible'));
    }

    switch (t.status) {
      case TaskStatus.pending:
      case TaskStatus.rejected:
        return FilledButton.icon(
          onPressed: _acting
              ? null
              : () => _act(
                  () => ref.read(taskServiceProvider).start(widget.taskId)),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Commencer'),
        );
      case TaskStatus.inProgress:
        return FilledButton.icon(
          onPressed: !hasAfterPhotos || _acting
              ? null
              : () => _act(
                  () => ref.read(taskServiceProvider).complete(widget.taskId)),
          icon: const Icon(Icons.done_rounded),
          label: Text(hasAfterPhotos
              ? 'Terminer le nettoyage'
              : 'Ajoutez au moins 1 photo apres'),
        );
      default:
        return const Center(child: Text('Nettoyage termine.'));
    }
  }

  String _fmt(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    final s = d.inSeconds % 60;
    if (h > 0) {
      return '${h}h ${m.toString().padLeft(2, '0')}m';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _PhotoSection extends StatelessWidget {
  const _PhotoSection({
    required this.label,
    required this.photos,
    required this.canAdd,
    required this.onAdd,
  });
  final String label;
  final List<TaskPhoto> photos;
  final bool canAdd;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('$label (${photos.length})',
                  style: Theme.of(context).textTheme.titleMedium),
            ),
            if (canAdd)
              IconButton.filled(
                onPressed: onAdd,
                icon: const Icon(Icons.add_a_photo_rounded),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (photos.isEmpty)
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text('Aucune photo pour le moment',
                  style: TextStyle(color: AppColors.textMuted)),
            ),
          )
        else
          SizedBox(
            height: 100,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) => ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CachedNetworkImage(
                  imageUrl: photos[i].url,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
