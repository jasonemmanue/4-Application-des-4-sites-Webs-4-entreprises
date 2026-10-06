import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';

/// Bottom navigation Airbnb-like : icone au dessus d'un petit libelle,
/// couleur d'accent sur l'onglet actif (rouge Airbnb), 5 destinations
/// couvrant l'essentiel de l'app.
class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static const _tabs = <_TabItem>[
    _TabItem(
      path: '/',
      icon: Icons.search,
      activeIcon: Icons.search,
      label: 'Explorer',
    ),
    _TabItem(
      path: '/schedule',
      icon: Icons.calendar_today_outlined,
      activeIcon: Icons.calendar_today,
      label: 'Planning',
    ),
    _TabItem(
      path: '/subscriptions',
      icon: Icons.workspace_premium_outlined,
      activeIcon: Icons.workspace_premium,
      label: 'Formules',
    ),
    _TabItem(
      path: '/activities',
      icon: Icons.fitness_center_outlined,
      activeIcon: Icons.fitness_center,
      label: 'Activites',
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
          color: AppColors.bg,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: BottomNavigationBar(
            currentIndex: idx,
            onTap: (i) => context.go(_tabs[i].path),
            items: [
              for (var i = 0; i < _tabs.length; i++)
                BottomNavigationBarItem(
                  icon: Icon(_tabs[i].icon, size: 24),
                  activeIcon: Icon(_tabs[i].activeIcon, size: 24),
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
