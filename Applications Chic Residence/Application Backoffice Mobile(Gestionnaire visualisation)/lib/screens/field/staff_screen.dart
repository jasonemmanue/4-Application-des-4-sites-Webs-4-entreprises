import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

/// Comptes de l'application gestionnaire (téléphone + PIN).
class StaffScreen extends ConsumerWidget {
  const StaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Personnel')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _StaffForm.open(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('Ajouter'),
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(staffProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.groups_outlined,
              title: 'Aucun membre du personnel',
              description:
                  'Créez un compte : la personne se connecte à l\'application '
                  'gestionnaire avec son téléphone et son code PIN.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(staffProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) => _StaffTile(member: list[i]),
            ),
          );
        },
      ),
    );
  }
}

class _StaffTile extends ConsumerWidget {
  const _StaffTile({required this.member});
  final StaffMember member;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = member;
    final color = switch (s.role) {
      StaffRole.controller => AppColors.info,
      StaffRole.manager => AppColors.success,
      StaffRole.agent => AppColors.primary,
    };
    return Panel(
      onTap: () => _StaffForm.open(context, ref, member: s),
      child: Row(
        children: [
          CircleAvatar(
            radius: 23,
            backgroundColor: color.withValues(alpha: 0.13),
            child: Icon(
              switch (s.role) {
                StaffRole.controller => Icons.verified_user_outlined,
                StaffRole.manager => Icons.manage_accounts_outlined,
                StaffRole.agent => Icons.cleaning_services_outlined,
              },
              color: color,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.fullName,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w600)),
                Text('${s.role.label} · ${s.phone}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
                Text(
                  s.lastLoginAt == null
                      ? 'Jamais connecté'
                      : 'Dernière connexion : ${dateTime(s.lastLoginAt!)}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          if (!s.isActive)
            const StatusPill(label: 'Inactif', color: AppColors.textMuted),
        ],
      ),
    );
  }
}

class _StaffForm extends ConsumerStatefulWidget {
  const _StaffForm({this.member});
  final StaffMember? member;

  static Future<void> open(BuildContext context, WidgetRef ref,
      {StaffMember? member}) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _StaffForm(member: member),
    );
    if (ok == true) ref.invalidate(staffProvider);
  }

  @override
  ConsumerState<_StaffForm> createState() => _StaffFormState();
}

class _StaffFormState extends ConsumerState<_StaffForm> {
  late final _name = TextEditingController(text: widget.member?.fullName ?? '');
  late final _phone = TextEditingController(text: widget.member?.phone ?? '');
  final _pin = TextEditingController();
  late StaffRole _role = widget.member?.role ?? StaffRole.agent;
  late bool _active = widget.member?.isActive ?? true;
  bool _saving = false;
  String? _error;

  bool get _editing => widget.member != null;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pin = _pin.text.trim();
    if (_name.text.trim().length < 2) {
      setState(() => _error = 'Saisissez le nom complet.');
      return;
    }
    if (!_editing && _phone.text.replaceAll(RegExp(r'\D'), '').length < 8) {
      setState(() => _error = 'Saisissez un numéro de téléphone valide.');
      return;
    }
    if ((!_editing || pin.isNotEmpty) && (pin.length < 4 || pin.length > 6)) {
      setState(() => _error = 'Le code PIN compte 4 à 6 chiffres.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final api = ref.read(adminApiProvider);
    try {
      if (_editing) {
        await api.updateStaff(widget.member!.id, {
          'full_name': _name.text.trim(),
          'role': _role.name,
          'is_active': _active,
          if (pin.isNotEmpty) 'pin': pin,
        });
      } else {
        await api.createStaff(
          fullName: _name.text.trim(),
          phone: _phone.text.trim(),
          pin: pin,
          role: _role,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stats = _editing
        ? ref.watch(staffStatsProvider(widget.member!.id)).valueOrNull
        : null;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.viewInsetsOf(context).bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_editing ? widget.member!.fullName : 'Nouveau membre',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            if (stats != null) ...[
              const SizedBox(height: 6),
              Text(
                '${stats.completed} nettoyages · '
                '${stats.averageMinutes == null ? '-' : '${stats.averageMinutes!.round()} min en moyenne'} · '
                '${stats.firstPassRate == null ? '-' : '${(stats.firstPassRate! * 100).round()} % validés du premier coup'}',
                style:
                    const TextStyle(fontSize: 12.5, color: AppColors.textMuted),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Nom complet'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _phone,
              enabled: !_editing,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Téléphone'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText:
                    _editing ? 'Nouveau code PIN (facultatif)' : 'Code PIN',
                counterText: '',
              ),
            ),
            const SizedBox(height: 10),
            SegmentedButton<StaffRole>(
              segments: const [
                ButtonSegment(value: StaffRole.agent, label: Text('Agent')),
                ButtonSegment(
                    value: StaffRole.controller, label: Text('Contrôleur')),
                ButtonSegment(value: StaffRole.manager, label: Text('Gérant')),
              ],
              selected: {_role},
              onSelectionChanged: (s) => setState(() => _role = s.first),
            ),
            if (_editing)
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Compte actif'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: AppColors.error)),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_editing ? 'Enregistrer' : 'Créer le compte'),
            ),
          ],
        ),
      ),
    );
  }
}
