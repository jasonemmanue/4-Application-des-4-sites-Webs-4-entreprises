import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/api_config.dart';
import '../../config/format.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/booking_history.dart';
import '../../services/whatsapp_service.dart';
import '../../widgets/residence_card.dart';
import 'faq_screen.dart';
import 'inbox_screen.dart';

/// Profil (maquette du 2026-10-31) : identité, prochain séjour, menu, aide.
///
/// Il n'y a pas de compte : le nom affiché est celui de la dernière réservation
/// faite depuis l'appareil, « Visiteur » sinon. D'où l'absence de « Déconnexion ».
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  /// Ouvre la fiche Play Store dans l'application Play Store, sinon dans le
  /// navigateur.
  static Future<void> _rateApp() async {
    final market =
        Uri.parse('market://details?id=${ApiConfig.playStoreId}');
    try {
      if (await launchUrl(market, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    await launchUrl(Uri.parse(ApiConfig.playStoreUrl),
        mode: LaunchMode.externalApplication);
  }

  void _openSettings(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Apparence', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 14),
              const _ThemeToggle(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _openAbout(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Image.asset('assets/branding/logo-full.png', height: 90),
              ),
              const SizedBox(height: 12),
              const Text(
                'Résidences meublées à Abidjan.\n${ApiConfig.companyAddress}.\n'
                '${ApiConfig.contactPhone}\nVersion ${ApiConfig.appVersion}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13.5, height: 1.5),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse('${ApiConfig.siteBaseUrl}/mentions-legales'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Mentions légales'),
              ),
              TextButton(
                onPressed: () => launchUrl(
                  Uri.parse('${ApiConfig.siteBaseUrl}/confidentialite'),
                  mode: LaunchMode.externalApplication,
                ),
                child: const Text('Politique de confidentialité'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final name = ref.watch(guestNameProvider);
    final upcoming = ref
        .watch(bookingHistoryProvider)
        .where((r) => r.isUpcoming)
        .toList()
      ..sort((a, b) => a.checkIn.compareTo(b.checkIn));

    return Scaffold(
      backgroundColor: t.surface,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: t.brand.withValues(alpha: 0.14),
                  child: name == null
                      ? Icon(Icons.person_rounded, size: 34, color: t.brand)
                      : Text(
                          name.characters.first.toUpperCase(),
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w600,
                            color: t.brand,
                          ),
                        ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name ?? 'Visiteur',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        name == null
                            ? 'Votre nom apparaîtra après votre première réservation'
                            : 'Voyageur',
                        style:
                            TextStyle(fontSize: 12.5, color: t.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Apparence',
                  onPressed: () => _openSettings(context),
                  icon: const Icon(Icons.settings_outlined),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                const Expanded(
                  child: Text('Prochain séjour',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
                TextButton(
                  onPressed: () => context.go('/bookings'),
                  style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('Voir tout', style: TextStyle(fontSize: 12.5)),
                      SizedBox(width: 3),
                      Icon(Icons.arrow_forward_rounded, size: 15),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            if (upcoming.isEmpty)
              _EmptyStay(onExplore: () => context.go('/explore'))
            else
              _StayCard(record: upcoming.first),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: t.surfaceElevated,
                borderRadius: BorderRadius.circular(18),
                border: t.isDark ? Border.all(color: t.border) : null,
              ),
              child: Column(
                children: [
                  _Tile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: (ref.watch(inboxUnreadProvider).valueOrNull ?? 0) > 0
                        ? '${ref.watch(inboxUnreadProvider).valueOrNull} non lue(s)'
                        : null,
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const InboxScreen())),
                  ),
                  _Tile(
                    icon: Icons.calendar_month_outlined,
                    title: 'Mes réservations',
                    onTap: () => context.go('/bookings'),
                  ),
                  _Tile(
                    icon: Icons.favorite_border_rounded,
                    title: 'Mes favoris',
                    onTap: () => context.go('/favorites'),
                  ),
                  _Tile(
                    icon: Icons.headset_mic_outlined,
                    title: 'Assistance',
                    subtitle:
                        ref.watch(publicInfoProvider).valueOrNull?.phone ??
                            ApiConfig.contactPhone,
                    onTap: WhatsAppService.call,
                  ),
                  _Tile(
                    icon: Icons.help_outline_rounded,
                    title: 'Questions fréquentes',
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const FaqScreen())),
                  ),
                  _Tile(
                    icon: Icons.star_outline_rounded,
                    title: 'Noter l\'application',
                    onTap: _rateApp,
                  ),
                  _Tile(
                    icon: Icons.ios_share_rounded,
                    title: 'Partager l\'application',
                    onTap: () => Share.share(
                      'Logements meublés à Abidjan avec CHIC RESIDENCE : '
                      '${ApiConfig.playStoreUrl}',
                    ),
                  ),
                  _Tile(
                    icon: Icons.tune_rounded,
                    title: 'Paramètres',
                    onTap: () => _openSettings(context),
                  ),
                  _Tile(
                    icon: Icons.info_outline_rounded,
                    title: 'À propos de Chic Résidence',
                    onTap: () => _openAbout(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: t.surfaceSunken,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Besoin d\'aide ?',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  const Text('Notre équipe vous répond sur WhatsApp.',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 44,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 44),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      onPressed: () => context.push('/contact'),
                      icon: const Icon(Icons.headset_mic_rounded, size: 18),
                      label: const Text('Nous contacter',
                          style: TextStyle(fontSize: 13.5)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Center(
              child: Text(
                'Version ${ApiConfig.appVersion}',
                style: TextStyle(fontSize: 12, color: t.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyStay extends StatelessWidget {
  const _EmptyStay({required this.onExplore});
  final VoidCallback onExplore;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onExplore,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: t.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: t.border),
        ),
        child: Row(
          children: [
            Icon(Icons.luggage_outlined, color: t.textSecondary),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('Aucun séjour à venir. Trouvez votre logement.',
                  style: TextStyle(fontSize: 13)),
            ),
            Icon(Icons.chevron_right_rounded, color: t.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _StayCard extends StatelessWidget {
  const _StayCard({required this.record});
  final BookingRecord record;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: () => context.go('/bookings'),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: t.surfaceElevated,
          borderRadius: BorderRadius.circular(16),
          border: t.isDark ? Border.all(color: t.border) : null,
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 72,
                height: 72,
                child: ResidencePhoto(url: record.photo),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record.residenceName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w700)),
                  Text(record.city, style: const TextStyle(fontSize: 12)),
                  Text(
                    '${Dates.short(record.checkIn)} au ${Dates.short(record.checkOut)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successSoft,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text('Confirmée',
                        style: TextStyle(
                            color: AppColors.successDeep,
                            fontSize: 11,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Icon(icon, size: 22, color: t.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500)),
                  if (subtitle != null)
                    Text(subtitle!,
                        style:
                            TextStyle(fontSize: 12, color: t.textSecondary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: t.textSecondary),
          ],
        ),
      ),
    );
  }
}

/// Bascule clair / auto / sombre. L'auto suit le réglage système : c'est le
/// défaut au premier lancement.
class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    final notifier = ref.read(themeModeProvider.notifier);
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.light,
          icon: Icon(Icons.wb_sunny_rounded),
          label: Text('Clair'),
        ),
        ButtonSegment(
          value: ThemeMode.system,
          icon: Icon(Icons.brightness_auto_rounded),
          label: Text('Auto'),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          icon: Icon(Icons.nightlight_round),
          label: Text('Sombre'),
        ),
      ],
      selected: {mode},
      onSelectionChanged: (s) => notifier.set(s.first),
      showSelectedIcon: false,
    );
  }
}
