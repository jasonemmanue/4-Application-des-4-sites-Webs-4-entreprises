import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';
import '../providers/providers.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key, required this.location});
  final String location;

  static const _items = <_Item>[
    _Item.section('Administration'),
    _Item.route('/', Icons.dashboard_outlined, 'Dashboard'),
    _Item.route('/residences', Icons.villa_outlined, 'Residences'),
    _Item.route('/bookings', Icons.calendar_month_outlined, 'Reservations'),
    _Item.route('/payments', Icons.payments_outlined, 'Paiements'),
    _Item.route('/reviews', Icons.rate_review_outlined, 'Avis'),
    _Item.route('/settings', Icons.settings_outlined, 'Parametres'),
    _Item.section('Suivi terrain'),
    _Item.route('/staff', Icons.groups_outlined, 'Personnel'),
    _Item.route('/cleaning', Icons.cleaning_services_outlined,
        'Nettoyage & Controle'),
    _Item.route('/performance', Icons.trending_up_rounded, 'Performance'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final admin = ref.watch(currentAdminProvider);
    return Drawer(
      backgroundColor: AppColors.sidebar,
      width: 280,
      child: Column(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primaryDark),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chic Residence',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                  ),
                ),
                const Text(
                  'Backoffice',
                  style: TextStyle(color: Colors.white70),
                ),
                const Spacer(),
                Text(
                  admin?.fullName ?? 'Administrateur',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  admin?.email ?? '',
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                if (item.isSection) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(20, 18, 16, 6),
                    child: Text(
                      item.label!.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.sidebarMuted,
                        fontSize: 11,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                final selected = location == item.path ||
                    (item.path != '/' && location.startsWith('${item.path}/'));
                return ListTile(
                  leading: Icon(item.icon,
                      color:
                          selected ? Colors.white : AppColors.sidebarMuted),
                  title: Text(
                    item.label!,
                    style: TextStyle(
                      color: selected ? Colors.white : AppColors.sidebarMuted,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                  tileColor: selected
                      ? Colors.white.withOpacity(0.06)
                      : Colors.transparent,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go(item.path!);
                  },
                );
              },
            ),
          ),
          const Divider(color: Colors.white24, height: 1),
          ListTile(
            leading: const Icon(Icons.logout_rounded, color: Colors.white),
            title: const Text('Deconnexion',
                style: TextStyle(color: Colors.white)),
            onTap: () async {
              await ref.read(authServiceProvider).logout();
              ref.read(currentAdminProvider.notifier).state = null;
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _Item {
  final bool isSection;
  final String? label;
  final String? path;
  final IconData? icon;

  const _Item.section(this.label)
      : isSection = true,
        path = null,
        icon = null;

  const _Item.route(this.path, this.icon, this.label) : isSection = false;
}
