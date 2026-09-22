import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootShell extends StatelessWidget {
  const RootShell({super.key, required this.child});
  final Widget child;

  static const _tabs = <_TabItem>[
    _TabItem('/home', Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    _TabItem('/services', Icons.spa_outlined, Icons.spa_rounded, 'Services'),
    _TabItem(
      '/booking',
      Icons.calendar_month_outlined,
      Icons.calendar_month_rounded,
      'RDV',
    ),
    _TabItem(
      '/gallery',
      Icons.photo_library_outlined,
      Icons.photo_library_rounded,
      'Galerie',
    ),
    _TabItem('/more', Icons.grid_view_outlined, Icons.grid_view_rounded, 'Plus'),
  ];

  int _indexFromLocation(String location) {
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexFromLocation(location);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => context.go(_tabs[i].path),
        items: <BottomNavigationBarItem>[
          for (int i = 0; i < _tabs.length; i++)
            BottomNavigationBarItem(
              icon: Icon(_tabs[i].icon),
              activeIcon: Icon(_tabs[i].activeIcon),
              label: _tabs[i].label,
            ),
        ],
      ),
    );
  }
}

class _TabItem {
  const _TabItem(this.path, this.icon, this.activeIcon, this.label);
  final String path;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
