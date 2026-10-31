import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../config/api_config.dart';
import '../../config/format.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

Color availabilityColor(String state) {
  switch (state) {
    case 'busy':
      return AppColors.primary;
    case 'maintenance':
      return AppColors.warning;
    default:
      return AppColors.success;
  }
}

class ResidencesScreen extends ConsumerStatefulWidget {
  const ResidencesScreen({super.key});

  @override
  ConsumerState<ResidencesScreen> createState() => _ResidencesScreenState();
}

class _ResidencesScreenState extends ConsumerState<ResidencesScreen> {
  String _query = '';

  Future<void> _openForm({String? id}) async {
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(
      builder: (_) => ResidenceFormScreen(residenceId: id),
    ));
    if (saved == true) ref.invalidate(residencesProvider);
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(residencesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Logements')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              decoration: const InputDecoration(
                hintText: 'Rechercher un logement...',
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
                onRetry: () => ref.invalidate(residencesProvider),
              ),
              data: (all) {
                final list = all
                    .where((r) =>
                        _query.isEmpty ||
                        r.title.toLowerCase().contains(_query) ||
                        r.city.toLowerCase().contains(_query) ||
                        (r.unitNumber ?? '').contains(_query))
                    .toList();
                if (list.isEmpty) {
                  return const EmptyState(
                    icon: Icons.villa_outlined,
                    title: 'Aucun logement',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(residencesProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 90),
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _ResidenceTile(
                      residence: list[i],
                      onEdit: () => _openForm(id: list[i].id),
                    ),
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

class _ResidenceTile extends ConsumerWidget {
  const _ResidenceTile({required this.residence, required this.onEdit});
  final Residence residence;
  final VoidCallback onEdit;

  Future<void> _changeStatus(BuildContext context, WidgetRef ref) async {
    const options = {
      'auto': 'Automatique (selon le calendrier)',
      'occupied': 'Forcer « Occupé »',
      'maintenance': 'Forcer « En entretien »',
    };
    final picked = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final e in options.entries)
              ListTile(
                title: Text(e.value),
                trailing: residence.availabilityStatus == e.key
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(ctx).pop(e.key),
              ),
          ],
        ),
      ),
    );
    if (picked == null || picked == residence.availabilityStatus) return;
    try {
      await ref.read(adminApiProvider).setResidenceStatus(residence.id, picked);
      ref.invalidate(residencesProvider);
    } catch (e) {
      if (context.mounted) showMessage(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = residence;
    return Panel(
      padding: const EdgeInsets.all(10),
      onTap: onEdit,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: r.photo == null
                ? Container(
                    width: 82,
                    height: 82,
                    color: AppColors.surfaceAlt,
                    child: const Icon(Icons.image_outlined),
                  )
                : CachedNetworkImage(
                    imageUrl: ApiConfig.resolve(r.photo!),
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) => Container(
                      width: 82,
                      color: AppColors.surfaceAlt,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  r.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${r.typeLabel} · ${r.city}'
                  '${r.unitNumber == null ? '' : ' · n° ${r.unitNumber}'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
                const SizedBox(height: 2),
                Text(
                  '${fcfa(r.price)} / nuit',
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                InkWell(
                  onTap: () => _changeStatus(context, ref),
                  child: StatusPill(
                    label: r.availabilityLabel,
                    color: availabilityColor(r.availabilityState),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Calendrier',
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AvailabilityScreen(residence: r),
            )),
            icon: const Icon(Icons.event_note_rounded),
          ),
        ],
      ),
    );
  }
}

/// Formulaire de logement, mêmes champs que l'admin web.
class ResidenceFormScreen extends ConsumerStatefulWidget {
  const ResidenceFormScreen({super.key, this.residenceId});
  final String? residenceId;

  @override
  ConsumerState<ResidenceFormScreen> createState() =>
      _ResidenceFormScreenState();
}

class _ResidenceFormScreenState extends ConsumerState<ResidenceFormScreen> {
  final _title = TextEditingController();
  final _unit = TextEditingController();
  final _city = TextEditingController(text: 'Abidjan');
  final _address = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _capacity = TextEditingController(text: '2');
  final _bedrooms = TextEditingController(text: '1');
  final _bathrooms = TextEditingController(text: '1');
  final _area = TextEditingController();
  String _type = 'apartment';
  bool _active = true;
  bool _featured = false;
  Set<String> _amenities = {};
  List<String> _images = [];

  bool _loading = false;
  bool _saving = false;
  bool _uploading = false;
  String? _error;

  bool get _editing => widget.residenceId != null;

  @override
  void initState() {
    super.initState();
    if (_editing) _load();
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _unit,
      _city,
      _address,
      _description,
      _price,
      _capacity,
      _bedrooms,
      _bathrooms,
      _area,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final r =
          await ref.read(adminApiProvider).residence(widget.residenceId!);
      _title.text = r.title;
      _unit.text = r.unitNumber ?? '';
      _city.text = r.city;
      _address.text = r.address;
      _description.text = r.description;
      _price.text = '${r.price}';
      _capacity.text = '${r.capacity}';
      _bedrooms.text = '${r.bedrooms}';
      _bathrooms.text = '${r.bathrooms}';
      _area.text = r.areaSqm?.toString() ?? '';
      _type = r.type;
      _active = r.isActive;
      _featured = r.isFeatured;
      _amenities = r.amenities.toSet();
      _images = [...r.images];
    } catch (e) {
      _error = readableError(e);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addPhotos() async {
    List<XFile> files;
    try {
      files = await ImagePicker().pickMultiImage(
        imageQuality: 80,
        maxWidth: 2000,
      );
    } on PlatformException {
      if (mounted) showMessage(context, 'Accès aux photos refusé.');
      return;
    }
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      final api = ref.read(adminApiProvider);
      for (final f in files) {
        final url = await api.upload(f);
        if (mounted) setState(() => _images = [..._images, url]);
      }
    } catch (e) {
      if (mounted) showMessage(context, readableError(e));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _save() async {
    final price = int.tryParse(_price.text.replaceAll(RegExp(r'\D'), ''));
    if (_title.text.trim().length < 2 ||
        _city.text.trim().isEmpty ||
        price == null) {
      setState(() => _error = 'Titre, ville et prix par nuit sont obligatoires.');
      return;
    }
    if (_unit.text.trim().isEmpty) {
      setState(() => _error = 'Le numéro du logement est obligatoire.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final body = {
      'title': _title.text.trim(),
      'unit_number': _unit.text.trim(),
      'city': _city.text.trim(),
      'address': _address.text.trim(),
      'description': _description.text.trim(),
      'residence_type': _type,
      'capacity': int.tryParse(_capacity.text) ?? 2,
      'bedrooms': int.tryParse(_bedrooms.text) ?? 1,
      'bathrooms': int.tryParse(_bathrooms.text) ?? 1,
      'area_sqm': int.tryParse(_area.text),
      'base_price_per_night': price,
      'amenities': _amenities.toList(),
      'images': _images,
      'is_active': _active,
      'is_featured': _featured,
    };
    try {
      await ref.read(adminApiProvider).saveResidence(widget.residenceId, body);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer ce logement ?'),
        content: const Text('Cette action est définitive.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref.read(adminApiProvider).deleteResidence(widget.residenceId!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    }
  }

  Widget _number(TextEditingController c, String label) => Expanded(
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_editing ? 'Modifier le logement' : 'Nouveau logement'),
        actions: [
          if (_editing)
            IconButton(
              tooltip: 'Supprimer',
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      TextField(
                        controller: _title,
                        decoration:
                            const InputDecoration(labelText: 'Titre'),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _unit,
                              decoration: const InputDecoration(
                                  labelText: 'Numéro du logement'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _type,
                              isExpanded: true,
                              decoration:
                                  const InputDecoration(labelText: 'Type'),
                              items: [
                                for (final e in residenceTypes.entries)
                                  DropdownMenuItem(
                                      value: e.key, child: Text(e.value)),
                              ],
                              onChanged: (v) =>
                                  setState(() => _type = v ?? _type),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _city,
                        decoration: const InputDecoration(labelText: 'Ville'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _address,
                        decoration:
                            const InputDecoration(labelText: 'Adresse'),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _description,
                        minLines: 3,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          alignLabelWithHint: true,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _number(_capacity, 'Capacité'),
                          const SizedBox(width: 10),
                          _number(_bedrooms, 'Chambres'),
                          const SizedBox(width: 10),
                          _number(_bathrooms, 'Sdb'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _number(_price, 'Prix par nuit (F)'),
                          const SizedBox(width: 10),
                          _number(_area, 'Surface (m²)'),
                        ],
                      ),
                      const SizedBox(height: 18),
                      const SectionTitle('Photos'),
                      SizedBox(
                        height: 96,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            InkWell(
                              onTap: _uploading ? null : _addPhotos,
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 96,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: _uploading
                                    ? const Center(
                                        child: CircularProgressIndicator())
                                    : const Icon(Icons.add_a_photo_outlined,
                                        color: AppColors.primary),
                              ),
                            ),
                            for (final url in _images)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: CachedNetworkImage(
                                        imageUrl: ApiConfig.resolve(url),
                                        width: 96,
                                        height: 96,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      right: 2,
                                      top: 2,
                                      child: InkWell(
                                        onTap: () => setState(() => _images =
                                            _images
                                                .where((i) => i != url)
                                                .toList()),
                                        child: const CircleAvatar(
                                          radius: 12,
                                          backgroundColor: Colors.black54,
                                          child: Icon(Icons.close_rounded,
                                              size: 15, color: Colors.white),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const SectionTitle('Équipements'),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: [
                          for (final e in amenityLabels.entries)
                            FilterChip(
                              label: Text(
                                e.value,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  color: _amenities.contains(e.key)
                                      ? Colors.white
                                      : null,
                                ),
                              ),
                              selected: _amenities.contains(e.key),
                              showCheckmark: false,
                              onSelected: (on) => setState(() {
                                on
                                    ? _amenities.add(e.key)
                                    : _amenities.remove(e.key);
                              }),
                            ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('En ligne'),
                        value: _active,
                        onChanged: (v) => setState(() => _active = v),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Coup de cœur'),
                        value: _featured,
                        onChanged: (v) => setState(() => _featured = v),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 6),
                        Text(_error!,
                            style: const TextStyle(color: AppColors.error)),
                      ],
                    ],
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving || _uploading ? null : _save,
                        child: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

/// Calendrier : toucher un jour le bloque ou le débloque. Les dates bloquées ici
/// ne sont plus cliquables dans l'application cliente ni sur le site.
class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key, required this.residence});
  final Residence residence;

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  final _today = DateTime(
      DateTime.now().year, DateTime.now().month, DateTime.now().day);
  late DateTime _focused = _today;
  Set<DateTime> _blocked = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final days = await ref.read(adminApiProvider).blockedDays(
          widget.residence.id, _today, _today.add(const Duration(days: 365)));
      if (mounted) setState(() => _blocked = days);
    } catch (e) {
      if (mounted) setState(() => _error = readableError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggle(DateTime day) async {
    final d = DateTime(day.year, day.month, day.day);
    final wasBlocked = _blocked.contains(d);
    setState(() {
      wasBlocked ? _blocked.remove(d) : _blocked.add(d);
      _focused = d;
    });
    try {
      await ref
          .read(adminApiProvider)
          .setAvailability(widget.residence.id, [d], wasBlocked);
      ref.invalidate(residencesProvider);
    } catch (e) {
      if (!mounted) return;
      setState(() => wasBlocked ? _blocked.add(d) : _blocked.remove(d));
      showMessage(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.residence.title)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? ErrorState(error: _error!)
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Panel(
                      child: TableCalendar(
                        locale: 'fr_FR',
                        firstDay: _today,
                        lastDay: _today.add(const Duration(days: 365)),
                        focusedDay: _focused,
                        startingDayOfWeek: StartingDayOfWeek.monday,
                        availableCalendarFormats: const {
                          CalendarFormat.month: 'Mois'
                        },
                        headerStyle: const HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                        ),
                        selectedDayPredicate: (d) => _blocked
                            .contains(DateTime(d.year, d.month, d.day)),
                        calendarStyle: const CalendarStyle(
                          outsideDaysVisible: false,
                          selectedDecoration: BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: AppColors.surfaceAlt,
                            shape: BoxShape.circle,
                          ),
                          todayTextStyle: TextStyle(color: AppColors.navy),
                        ),
                        onPageChanged: (d) => _focused = d,
                        onDaySelected: (d, _) => _toggle(d),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Touchez un jour pour le bloquer ou le libérer. En rouge : '
                      'jours indisponibles (réservés ou bloqués).',
                      style:
                          TextStyle(fontSize: 13, color: AppColors.textMuted),
                    ),
                  ],
                ),
    );
  }
}
