import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/theme.dart';

/// Barre de navigation basse de la maquette : Accueil, Explorer, Favoris,
/// Réservations, Profil.
///
/// Police 10.5 pt et `MediaQuery.withNoTextScaling` pour que « Réservations »
/// tienne sur une ligne quelle que soit la taille de police système.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _tabs = <_TabInfo>[
    _TabInfo('/', Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    _TabInfo('/explore', Icons.search_rounded, Icons.search_rounded, 'Explorer'),
    _TabInfo('/favorites', Icons.favorite_border_rounded,
        Icons.favorite_rounded, 'Favoris'),
    _TabInfo('/bookings', Icons.calendar_month_outlined,
        Icons.calendar_month_rounded, 'Réservations'),
    _TabInfo('/profile', Icons.person_outline_rounded, Icons.person_rounded,
        'Profil'),
  ];

  int _indexFromLocation() {
    for (var i = _tabs.length - 1; i > 0; i--) {
      if (location == _tabs[i].path ||
          location.startsWith('${_tabs[i].path}/')) {
        return i;
      }
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final index = _indexFromLocation();

    return Scaffold(
      backgroundColor: t.surface,
      body: child,
      bottomNavigationBar: MediaQuery.withNoTextScaling(
        child: Container(
          decoration: BoxDecoration(
            color: t.navBg,
            boxShadow: [
              BoxShadow(
                color: t.shadow,
                blurRadius: 12,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: kBottomNavHeight,
              child: Row(
                children: [
                  for (var i = 0; i < _tabs.length; i++)
                    Expanded(
                      child: _NavItem(
                        tab: _tabs[i],
                        selected: i == index,
                        onTap: () => context.go(_tabs[i].path),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final _TabInfo tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final color = selected ? t.brand : t.textPrimary;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(selected ? tab.selectedIcon : tab.icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            tab.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            style: TextStyle(
              fontSize: 10.5,
              height: 1.0,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TabInfo {
  final String path;
  final IconData icon;
  final IconData selectedIcon;
  final String label;
  const _TabInfo(this.path, this.icon, this.selectedIcon, this.label);
}
