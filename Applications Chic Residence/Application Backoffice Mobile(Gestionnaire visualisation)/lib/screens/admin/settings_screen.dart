import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../widgets/ui.dart';

/// Coordonnées et textes de l'entreprise : le site et l'application cliente les
/// lisent sur l'API, une modification ici s'y répercute sans nouvelle version.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _labels = {
    'company_name': 'Nom de l\'entreprise',
    'company_slogan': 'Slogan',
    'company_about': 'Présentation',
    'company_phone': 'Téléphone',
    'whatsapp_number': 'WhatsApp',
    'company_address': 'Adresse',
    'company_map_url': 'Lien Google Maps',
    'booking_terms': 'Conditions de réservation',
    'facebook_url': 'Facebook',
    'instagram_url': 'Instagram',
    'twitter_url': 'Twitter',
    'airbnb_url': 'Airbnb',
    'booking_url': 'Booking',
  };

  Future<void> _edit(
      BuildContext context, WidgetRef ref, SettingItem item) async {
    final ctrl = TextEditingController(text: item.value);
    final saved = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.viewInsetsOf(ctx).bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(_labels[item.key] ?? item.key,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              minLines: 1,
              maxLines: 8,
              autofocus: true,
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(ctrl.text),
              child: const Text('Enregistrer'),
            ),
          ],
        ),
      ),
    );
    ctrl.dispose();
    if (saved == null) return;
    try {
      await ref.read(adminApiProvider).saveSetting(item.key, saved);
      ref.invalidate(settingsProvider);
      if (context.mounted) showMessage(context, 'Enregistré.');
    } catch (e) {
      if (context.mounted) showMessage(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(settingsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(settingsProvider),
        ),
        data: (all) {
          final byKey = {for (final s in all) s.key: s};
          final items = [
            for (final k in _labels.keys) byKey[k] ?? SettingItem(k, ''),
          ];
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) => Panel(
              onTap: () => _edit(context, ref, items[i]),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_labels[items[i].key] ?? items[i].key,
                            style: const TextStyle(
                                fontSize: 13.5, fontWeight: FontWeight.w600)),
                        Text(
                          items[i].value.isEmpty ? '-' : items[i].value,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.edit_outlined,
                      size: 18, color: AppColors.textMuted),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
