import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../services/device_registration.dart';
import '../../widgets/notifications.dart';
import '../field/auto_cleaning_screen.dart';
import 'campaigns_screen.dart';
import 'guests_screen.dart';
import '../../widgets/ui.dart';

class MoreScreen extends ConsumerWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(currentAdminProvider);
    final name = admin?.fullName ?? '';
    final stats = ref.watch(dashboardStatsProvider).valueOrNull;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    name.isEmpty ? '?' : name.characters.first.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w700)),
                      Text(admin?.email ?? '',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const SectionTitle('Administration'),
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _PageTile(Icons.notifications_none_rounded, 'Notifications',
                      (_) => const NotificationsScreen()),
                  _PageTile(Icons.campaign_outlined, 'Campagnes et relances',
                      (_) => const CampaignsScreen()),
                  _PageTile(Icons.badge_outlined, 'Fiches voyageurs',
                      (_) => const GuestsScreen()),
                  _Tile(Icons.payments_outlined, 'Paiements', '/payments'),
                  _Tile(
                    Icons.rate_review_outlined,
                    'Avis',
                    '/reviews',
                    badge: stats?.pendingReviews ?? 0,
                  ),
                  _Tile(
                    Icons.mail_outline_rounded,
                    'Messages',
                    '/contacts',
                    badge: stats?.unreadContacts ?? 0,
                  ),
                  _Tile(Icons.tune_rounded, 'Paramètres', '/settings'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionTitle('Suivi terrain'),
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _Tile(Icons.groups_outlined, 'Personnel', '/staff'),
                  _Tile(Icons.insights_rounded, 'Performance', '/performance'),
                  _PageTile(Icons.auto_mode_rounded, 'Nettoyage automatique',
                      (_) => const AutoCleaningScreen()),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                await DeviceRegistration.unregister(ref.read(apiClientProvider));
                await ref.read(authServiceProvider).logout();
                ref.read(currentAdminProvider.notifier).state = null;
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Déconnexion'),
            ),
            const SizedBox(height: 12),
            const Center(
              child: Text(
                'Version ${ApiConfig.appVersion}',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile(this.icon, this.title, this.path, {this.badge = 0});
  final IconData icon;
  final String title;
  final String path;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navy),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (badge > 0)
            StatusPill(label: '$badge', color: AppColors.primary),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
        ],
      ),
      onTap: () => context.push(path),
    );
  }
}

class _PageTile extends StatelessWidget {
  const _PageTile(this.icon, this.title, this.builder);
  final IconData icon;
  final String title;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: AppColors.navy),
      title: Text(title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
      trailing:
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: builder)),
    );
  }
}
