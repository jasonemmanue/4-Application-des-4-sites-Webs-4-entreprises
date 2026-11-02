import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

const _audiences = {
  'clients': 'Clients (application)',
  'staff': 'Personnel',
  'admins': 'Administrateurs',
  'all': 'Tout le monde',
};

final campaignsProvider = FutureProvider.autoDispose<List<Campaign>>((ref) async {
  return ref.watch(adminApiProvider).campaigns();
});

final pushEnabledProvider = FutureProvider.autoDispose<bool>((ref) async {
  return ref.watch(adminApiProvider).pushEnabled();
});

/// Notifications rédigées par l'administrateur : tout de suite ou programmées.
/// Elles arrivent dans la boîte de chaque application, et en push si Firebase
/// est branché côté serveur.
class CampaignsScreen extends ConsumerWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(campaignsProvider);
    final push = ref.watch(pushEnabledProvider).valueOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Campagnes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _NewCampaign.open(context, ref),
        icon: const Icon(Icons.campaign_outlined),
        label: const Text('Nouvelle'),
      ),
      body: Column(
        children: [
          if (push == false)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text(
                'Push non configuré sur le serveur : les messages arrivent dans '
                'les boîtes de réception des applications, sans notification '
                'sur l\'écran du téléphone.',
                style: TextStyle(fontSize: 12.5),
              ),
            ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(campaignsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'Aucune campagne',
                    description:
                        'Prévenez vos clients d\'une offre, ou votre personnel d\'une consigne.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(campaignsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final c = list[i];
                      final color = switch (c.status) {
                        'sent' => AppColors.success,
                        'cancelled' => AppColors.textMuted,
                        _ => AppColors.warning,
                      };
                      final label = switch (c.status) {
                        'sent' => 'Envoyée (${c.recipients})',
                        'cancelled' => 'Annulée',
                        _ => 'Programmée',
                      };
                      return Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(c.title,
                                      style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600)),
                                ),
                                StatusPill(label: label, color: color),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(c.body, style: const TextStyle(fontSize: 13)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${_audiences[c.audience] ?? c.audience} · ${dateTime(c.sendAt)}',
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textMuted),
                                  ),
                                ),
                                if (c.status == 'scheduled')
                                  TextButton(
                                    onPressed: () async {
                                      try {
                                        await ref
                                            .read(adminApiProvider)
                                            .cancelCampaign(c.id);
                                        ref.invalidate(campaignsProvider);
                                      } catch (e) {
                                        if (context.mounted) {
                                          showMessage(
                                              context, readableError(e));
                                        }
                                      }
                                    },
                                    child: const Text('Annuler'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _NewCampaign extends ConsumerStatefulWidget {
  const _NewCampaign();

  static Future<void> open(BuildContext context, WidgetRef ref) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _NewCampaign(),
    );
    if (ok == true) ref.invalidate(campaignsProvider);
  }

  @override
  ConsumerState<_NewCampaign> createState() => _NewCampaignState();
}

class _NewCampaignState extends ConsumerState<_NewCampaign> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  String _audience = 'clients';
  DateTime? _sendAt;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 180)),
    );
    if (d == null || !mounted) return;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))),
    );
    if (t == null) return;
    setState(() => _sendAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _save() async {
    if (_title.text.trim().length < 2 || _body.text.trim().length < 2) {
      setState(() => _error = 'Titre et message obligatoires.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(adminApiProvider).createCampaign(
            title: _title.text.trim(),
            body: _body.text.trim(),
            audience: _audience,
            sendAt: _sendAt,
          );
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Nouvelle campagne',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _audience,
              decoration: const InputDecoration(labelText: 'Destinataires'),
              items: [
                for (final e in _audiences.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (v) => setState(() => _audience = v ?? _audience),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _title,
              maxLength: 80,
              decoration: const InputDecoration(labelText: 'Titre'),
            ),
            TextField(
              controller: _body,
              maxLines: 3,
              maxLength: 300,
              decoration: const InputDecoration(labelText: 'Message'),
            ),
            OutlinedButton.icon(
              onPressed: _pickTime,
              icon: const Icon(Icons.schedule_rounded),
              label: Text(_sendAt == null
                  ? 'Envoyer maintenant (ou programmer)'
                  : 'Programmée le ${dateTime(_sendAt!)}'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_sendAt == null ? 'Envoyer' : 'Programmer'),
            ),
          ],
        ),
      ),
    );
  }
}
