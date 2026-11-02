import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/api_config.dart';
import '../../config/theme.dart';
import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../services/device_registration.dart';
import '../../widgets/notifications.dart';
import '../../widgets/ui.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    (user?.fullName.isNotEmpty ?? false)
                        ? user!.fullName.characters.first.toUpperCase()
                        : '?',
                    style: const TextStyle(
                      fontSize: 28,
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
                      Text(
                        user?.fullName ?? '',
                        style: const TextStyle(
                            fontSize: 19, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        user?.role.label ?? '',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Panel(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.call_outlined),
                    title: const Text('Téléphone'),
                    subtitle: Text(user?.phone ?? ''),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_none_rounded),
                    title: const Text('Notifications'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => const NotificationsScreen())),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.info_outline_rounded),
                    title: const Text('Version'),
                    subtitle: const Text(ApiConfig.appVersion),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () async {
                await DeviceRegistration.unregister(ref.read(apiClientProvider));
                await ref.read(authServiceProvider).logout();
                ref.read(currentUserProvider.notifier).state = null;
                if (context.mounted) context.go('/login');
              },
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Déconnexion'),
            ),
          ],
        ),
      ),
    );
  }
}
