import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

/// Nettoyage automatique : le jour du départ, la réservation se termine et la
/// tâche de préparation est créée et assignée sans intervention. L'agent est
/// prévenu ; l'administrateur reçoit « Logement prêt » quand le contrôleur
/// valide.
///
/// Réglages stockés dans `settings` (clés `auto_cleaning_*`), lus par les
/// tâches de fond de l'API toutes les minutes.
class AutoCleaningScreen extends ConsumerStatefulWidget {
  const AutoCleaningScreen({super.key});

  @override
  ConsumerState<AutoCleaningScreen> createState() => _AutoCleaningScreenState();
}

class _AutoCleaningScreenState extends ConsumerState<AutoCleaningScreen> {
  bool? _enabled;
  String? _agent;
  String? _controller;
  bool _saving = false;

  void _init(List<SettingItem> settings) {
    if (_enabled != null) return;
    String v(String k) => settings
        .firstWhere((s) => s.key == k, orElse: () => SettingItem(k, ''))
        .value;
    _enabled = ['1', 'true', 'oui'].contains(v('auto_cleaning_enabled').toLowerCase());
    _agent = v('auto_cleaning_agent_id').isEmpty ? null : v('auto_cleaning_agent_id');
    _controller = v('auto_cleaning_controller_id').isEmpty
        ? null
        : v('auto_cleaning_controller_id');
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final api = ref.read(adminApiProvider);
    try {
      await api.saveSetting('auto_cleaning_enabled', _enabled == true ? 'true' : 'false');
      await api.saveSetting('auto_cleaning_agent_id', _agent ?? '');
      await api.saveSetting('auto_cleaning_controller_id', _controller ?? '');
      ref.invalidate(settingsProvider);
      if (mounted) showMessage(context, 'Réglages enregistrés.');
    } catch (e) {
      if (mounted) showMessage(context, readableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final staff = ref.watch(staffProvider).valueOrNull ?? const <StaffMember>[];
    final agents =
        staff.where((s) => s.role == StaffRole.agent && s.isActive).toList();
    final controllers = staff
        .where((s) => s.role == StaffRole.controller && s.isActive)
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Nettoyage automatique')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(settingsProvider),
        ),
        data: (list) {
          _init(list);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Panel(
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Créer la tâche à la date de départ'),
                  subtitle: const Text(
                    'Le jour du départ, le séjour passe « terminé » et le '
                    'logement est mis en préparation.',
                    style: TextStyle(fontSize: 12.5),
                  ),
                  value: _enabled ?? false,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                initialValue: agents.any((a) => a.id == _agent) ? _agent : null,
                isExpanded: true,
                decoration:
                    const InputDecoration(labelText: 'Agent assigné d\'office'),
                items: [
                  for (final a in agents)
                    DropdownMenuItem(value: a.id, child: Text(a.fullName)),
                ],
                onChanged: (v) => setState(() => _agent = v),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: controllers.any((a) => a.id == _controller)
                    ? _controller
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(
                    labelText: 'Contrôleur assigné d\'office'),
                items: [
                  for (final a in controllers)
                    DropdownMenuItem(value: a.id, child: Text(a.fullName)),
                ],
                onChanged: (v) => setState(() => _controller = v),
              ),
              const SizedBox(height: 10),
              const Text(
                'Sans agent choisi, la tâche reste à attribuer et le premier '
                'agent qui la démarre la prend. Vous recevez « Logement prêt » '
                'quand le contrôle est validé.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
              const SizedBox(height: 18),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }
}
