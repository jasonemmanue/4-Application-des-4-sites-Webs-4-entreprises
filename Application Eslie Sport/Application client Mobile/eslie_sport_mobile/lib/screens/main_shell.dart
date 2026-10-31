import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';

/// Navigation basse : Accueil, Activites, Planning, Abonnements, Profil.
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = <_TabItem>[
    _TabItem(
      path: '/',
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Accueil',
    ),
    _TabItem(
      path: '/activities',
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Activités',
    ),
    _TabItem(
      path: '/schedule',
      icon: Icons.calendar_month_outlined,
      activeIcon: Icons.calendar_month,
      label: 'Planning',
    ),
    _TabItem(
      path: '/subscriptions',
      icon: Icons.workspace_premium_outlined,
      activeIcon: Icons.workspace_premium,
      label: 'Abonnements',
    ),
    _TabItem(
      path: '/more',
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
    ),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 1; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 64,
            child: Row(
              children: [
                for (var i = 0; i < _tabs.length; i++)
                  Expanded(
                    child: _NavItem(
                      item: _tabs[i],
                      active: i == idx,
                      onTap: () => context.go(_tabs[i].path),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final _TabItem item;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({
    required this.item,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textMuted;
    return Semantics(
      button: true,
      selected: active,
      label: item.label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(active ? item.activeIcon : item.icon, size: 25, color: color),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.label,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  color: color,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TabItem {
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _TabItem({
    required this.path,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}
