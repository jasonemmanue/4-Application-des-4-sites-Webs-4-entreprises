import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';
import '../config/theme.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const MainScaffold({super.key, required this.child, required this.state});

  static const List<_NavItem> _items = [
    _NavItem(AppRoutes.home, Icons.home_outlined, Icons.home, 'Accueil'),
    _NavItem(AppRoutes.services, Icons.business_center_outlined,
        Icons.business_center, 'Services'),
    _NavItem(AppRoutes.projects, Icons.folder_special_outlined,
        Icons.folder_special, 'Realisations'),
    _NavItem(AppRoutes.publications, Icons.menu_book_outlined,
        Icons.menu_book, 'Publications'),
    _NavItem(AppRoutes.more, Icons.grid_view_outlined, Icons.grid_view, 'Plus'),
  ];

  int _currentIndex(String location) {
    for (int i = _items.length - 1; i >= 0; i--) {
      if (location == _items[i].route ||
          location.startsWith('${_items[i].route}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final int index = _currentIndex(state.matchedLocation);
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => context.go(_items[i].route),
        items: [
          for (final item in _items)
            BottomNavigationBarItem(
              icon: Icon(item.icon),
              activeIcon: Icon(item.activeIcon, color: AppColors.brand400),
              label: item.label,
            ),
        ],
      ),
    );
  }
}

class _NavItem {
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.route, this.icon, this.activeIcon, this.label);
}
