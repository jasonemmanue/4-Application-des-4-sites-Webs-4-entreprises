import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = <_TabItem>[
    _TabItem(path: '/', icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Accueil'),
    _TabItem(
        path: '/activities',
        icon: Icons.fitness_center_outlined,
        activeIcon: Icons.fitness_center,
        label: 'Activites'),
    _TabItem(
        path: '/schedule',
        icon: Icons.calendar_month_outlined,
        activeIcon: Icons.calendar_month,
        label: 'Planning'),
    _TabItem(
        path: '/subscriptions',
        icon: Icons.card_membership_outlined,
        activeIcon: Icons.card_membership,
        label: 'Formules'),
    _TabItem(
        path: '/more',
        icon: Icons.grid_view_outlined,
        activeIcon: Icons.grid_view,
        label: 'Plus'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    for (var i = 0; i < _tabs.length; i++) {
      if (location == _tabs[i].path ||
          (i != 0 && location.startsWith(_tabs[i].path))) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final idx = _currentIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: AppColors.darkCard,
          border: Border(top: BorderSide(color: AppColors.darkBorder)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: idx,
            onTap: (i) => context.go(_tabs[i].path),
            items: [
              for (var i = 0; i < _tabs.length; i++)
                BottomNavigationBarItem(
                  icon: Icon(_tabs[i].icon),
                  activeIcon: Icon(_tabs[i].activeIcon),
                  label: _tabs[i].label,
                ),
            ],
          ),
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
