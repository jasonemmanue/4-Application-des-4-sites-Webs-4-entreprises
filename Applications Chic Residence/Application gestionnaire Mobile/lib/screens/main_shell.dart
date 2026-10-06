import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _tabs = <_Tab>[
    _Tab('/', Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    _Tab('/tasks', Icons.checklist_outlined, Icons.checklist_rounded, 'Taches'),
    _Tab('/stats', Icons.bar_chart_outlined, Icons.bar_chart_rounded, 'Stats'),
    _Tab('/profile', Icons.person_outline, Icons.person_rounded, 'Profil'),
  ];

  int _index() {
    for (var i = _tabs.length - 1; i >= 0; i--) {
      if (location == _tabs[i].path || location.startsWith('${_tabs[i].path}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index(),
        onDestinationSelected: (i) => context.go(_tabs[i].path),
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.primary.withOpacity(0.15),
        destinations: [
          for (final t in _tabs)
            NavigationDestination(
              icon: Icon(t.icon),
              selectedIcon: Icon(t.selectedIcon, color: AppColors.primary),
              label: t.label,
            ),
        ],
      ),
    );
  }
}

class _Tab {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _Tab(this.path, this.icon, this.selectedIcon, this.label);
}
