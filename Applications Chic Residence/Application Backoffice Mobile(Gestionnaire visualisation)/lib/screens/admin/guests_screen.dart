import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

/// Fiches voyageurs : la pièce d'identité de chaque occupant, relevée à
/// l'accueil, en présentiel. Données sensibles : les photos ne sortent que par
/// l'API, avec le jeton du gérant ou de l'administrateur.

final guestSearchProvider = StateProvider.autoDispose<String>((ref) => '');

final guestsProvider =
    FutureProvider.autoDispose<List<GuestIdentity>>((ref) async {
  return ref
      .watch(adminApiProvider)
      .guests(q: ref.watch(guestSearchProvider));
});

class GuestsScreen extends ConsumerWidget {
  const GuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(guestsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Fiches voyageurs')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => GuestFormScreen.open(context, ref),
        icon: const Icon(Icons.badge_outlined),
        label: const Text('Nouvelle fiche'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onSubmitted: (v) =>
                  ref.read(guestSearchProvider.notifier).state = v.trim(),
              textInputAction: TextInputAction.search,
              decoration: const InputDecoration(
                hintText: 'Nom, numéro de pièce, téléphone',
                prefixIcon: Icon(Icons.search_rounded),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorState(
                error: e,
                onRetry: () => ref.invalidate(guestsProvider),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.badge_outlined,
                    title: 'Aucune fiche',
                    description:
                        'Relevez la pièce d\'identité de chaque occupant à son arrivée.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(guestsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) {
                      final g = list[i];
                      return Panel(
                        onTap: () =>
                            GuestFormScreen.open(context, ref, guest: g),
                        child: Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: AppColors.primaryLight,
                              child: Icon(Icons.badge_rounded,
                                  color: AppColors.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(g.fullName,
                                      style: const TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w600)),
                                  Text('${g.idTypeLabel} · ${g.idNumber}',
                                      style: const TextStyle(fontSize: 12.5)),
                                  Text(
                                    [
                                      if (g.residenceTitle.isNotEmpty)
                                        g.residenceTitle,
                                      if (g.arrivalDate != null)
                                        'arrivée ${dayMonth(g.arrivalDate!)}',
                                    ].join(' · '),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted),
                                  ),
                                ],
                              ),
                            ),
                            if (!g.hasFront)
                              const StatusPill(
                                  label: 'Sans photo',
                                  color: AppColors.warning),
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

class GuestFormScreen extends ConsumerStatefulWidget {
  const GuestFormScreen({
    super.key,
    this.guest,
    this.bookingId,
    this.prefillName,
    this.prefillPhone,
    this.residenceTitle,
  });

  final GuestIdentity? guest;
  final String? bookingId;
  final String? prefillName;
  final String? prefillPhone;
  final String? residenceTitle;

  static Future<void> open(
    BuildContext context,
    WidgetRef ref, {
    GuestIdentity? guest,
    String? bookingId,
    String? prefillName,
    String? prefillPhone,
    String? residenceTitle,
  }) async {
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => GuestFormScreen(
        guest: guest,
        bookingId: bookingId,
        prefillName: prefillName,
        prefillPhone: prefillPhone,
        residenceTitle: residenceTitle,
      ),
    ));
    ref.invalidate(guestsProvider);
  }

  @override
  ConsumerState<GuestFormScreen> createState() => _GuestFormScreenState();
}

class _GuestFormScreenState extends ConsumerState<GuestFormScreen> {
  late GuestIdentity? _guest = widget.guest;
  late final _name =
      TextEditingController(text: widget.guest?.fullName ?? widget.prefillName ?? '');
  late final _number = TextEditingController(text: widget.guest?.idNumber ?? '');
  late final _nationality = TextEditingController(
      text: widget.guest?.nationality ?? 'Ivoirienne');
  late final _birthPlace =
      TextEditingController(text: widget.guest?.birthPlace ?? '');
  late final _phone =
      TextEditingController(text: widget.guest?.phone ?? widget.prefillPhone ?? '');
  late final _address = TextEditingController(text: widget.guest?.address ?? '');
  late final _notes = TextEditingController(text: widget.guest?.notes ?? '');
  late String _idType = widget.guest?.idType ?? 'cni';
  late DateTime? _birth = widget.guest?.birthDate;
  late DateTime? _issued = widget.guest?.idIssuedOn;
  late DateTime? _expires = widget.guest?.idExpiresOn;
  bool _saving = false;
  String? _uploading;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _number, _nationality, _birthPlace, _phone, _address, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _iso(DateTime? d) => d?.toIso8601String().substring(0, 10);

  Future<void> _save() async {
    if (_name.text.trim().length < 2 || _number.text.trim().length < 3) {
      setState(() => _error = 'Nom et numéro de pièce obligatoires.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = {
      'booking_id': _guest?.bookingId ?? widget.bookingId,
      'residence_id': _guest?.residenceId,
      'full_name': _name.text.trim(),
      'id_type': _idType,
      'id_number': _number.text.trim(),
      'nationality': _nationality.text.trim(),
      'birth_place': _birthPlace.text.trim(),
      'birth_date': _iso(_birth),
      'id_issued_on': _iso(_issued),
      'id_expires_on': _iso(_expires),
      'phone': _phone.text.trim(),
      'address': _address.text.trim(),
      'arrival_date': _iso(_guest?.arrivalDate),
      'departure_date': _iso(_guest?.departureDate),
      'notes': _notes.text.trim(),
    };
    try {
      final saved =
          await ref.read(adminApiProvider).saveGuest(_guest?.id, body);
      setState(() => _guest = saved);
      if (mounted) {
        showMessage(context,
            saved.hasFront ? 'Fiche enregistrée.' : 'Fiche enregistrée. Photographiez la pièce.');
      }
    } catch (e) {
      setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _photo(String face) async {
    final g = _guest;
    if (g == null) return;
    XFile? file;
    try {
      file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        imageQuality: 75,
        maxWidth: 1800,
      );
    } on PlatformException {
      if (mounted) showMessage(context, 'Autorisez l\'appareil photo.');
      return;
    }
    if (file == null) return;
    setState(() => _uploading = face);
    try {
      final saved =
          await ref.read(adminApiProvider).uploadGuestPhoto(g.id, face, file);
      setState(() => _guest = saved);
    } catch (e) {
      if (mounted) showMessage(context, readableError(e));
    } finally {
      if (mounted) setState(() => _uploading = null);
    }
  }

  Future<void> _pickDate(DateTime? current, ValueChanged<DateTime> set,
      {bool past = true}) async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: current ?? (past ? DateTime(now.year - 30) : now),
      firstDate: DateTime(1920),
      lastDate: DateTime(now.year + 20),
    );
    if (d != null) setState(() => set(d));
  }

  Widget _dateField(String label, DateTime? value, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: InputDecorator(
          decoration: InputDecoration(labelText: label),
          child: Text(value == null ? '-' : dayMonthYear(value)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final g = _guest;
    return Scaffold(
      appBar: AppBar(
        title: Text(g == null ? 'Nouvelle fiche voyageur' : 'Fiche voyageur'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (widget.residenceTitle != null || (g?.residenceTitle ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: StatusPill(
                label: widget.residenceTitle ?? g!.residenceTitle,
                color: AppColors.navy,
              ),
            ),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nom et prénoms'),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _idType,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Type de pièce'),
            items: [
              for (final e in guestIdTypes.entries)
                DropdownMenuItem(value: e.key, child: Text(e.value)),
            ],
            onChanged: (v) => setState(() => _idType = v ?? _idType),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _number,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(labelText: 'Numéro de la pièce'),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _dateField('Délivrée le', _issued,
                  () => _pickDate(_issued, (d) => _issued = d)),
              const SizedBox(width: 10),
              _dateField('Expire le', _expires,
                  () => _pickDate(_expires, (d) => _expires = d, past: false)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _dateField('Né(e) le', _birth,
                  () => _pickDate(_birth, (d) => _birth = d)),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _birthPlace,
                  decoration: const InputDecoration(labelText: 'Lieu'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _nationality,
            decoration: const InputDecoration(labelText: 'Nationalité'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(labelText: 'Téléphone'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _address,
            decoration: const InputDecoration(labelText: 'Adresse habituelle'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notes,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Remarques'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(color: AppColors.error)),
          ],
          const SizedBox(height: 14),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: Text(g == null ? 'Enregistrer la fiche' : 'Mettre à jour'),
          ),
          if (g != null) ...[
            const SizedBox(height: 22),
            const SectionTitle('Photos de la pièce'),
            Row(
              children: [
                Expanded(
                  child: _PhotoSlot(
                    label: 'Recto',
                    guestId: g.id,
                    face: 'front',
                    present: g.hasFront,
                    busy: _uploading == 'front',
                    onCapture: () => _photo('front'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _PhotoSlot(
                    label: 'Verso',
                    guestId: g.id,
                    face: 'back',
                    present: g.hasBack,
                    busy: _uploading == 'back',
                    onCapture: () => _photo('back'),
                  ),
                ),
              ],
            ),
            if (g.recordedByName.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text('Relevée par ${g.recordedByName}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ],
        ],
      ),
    );
  }
}

class _PhotoSlot extends ConsumerWidget {
  const _PhotoSlot({
    required this.label,
    required this.guestId,
    required this.face,
    required this.present,
    required this.busy,
    required this.onCapture,
  });

  final String label;
  final String guestId;
  final String face;
  final bool present;
  final bool busy;
  final VoidCallback onCapture;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1.58,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: busy
                ? const ColoredBox(
                    color: AppColors.surfaceAlt,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : present
                    ? FutureBuilder<List<int>>(
                        key: ValueKey('$guestId-$face-$present-${DateTime.now().minute}'),
                        future: ref
                            .read(adminApiProvider)
                            .guestPhoto(guestId, face),
                        builder: (_, snap) => snap.hasData
                            ? Image.memory(Uint8List.fromList(snap.data!),
                                fit: BoxFit.cover)
                            : const ColoredBox(color: AppColors.surfaceAlt),
                      )
                    : const ColoredBox(
                        color: AppColors.surfaceAlt,
                        child: Icon(Icons.credit_card_rounded,
                            color: AppColors.textMuted, size: 36),
                      ),
          ),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: busy ? null : onCapture,
          icon: const Icon(Icons.photo_camera_outlined, size: 18),
          label: Text(present ? '$label : reprendre' : label),
        ),
      ],
    );
  }
}
