import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/routes.dart';
import '../config/theme.dart';
import '../widgets/ruah_ui.dart';

class MainScaffold extends StatelessWidget {
  final Widget child;
  final GoRouterState state;

  const MainScaffold({super.key, required this.child, required this.state});

  static const List<_NavItem> _items = [
    _NavItem(AppRoutes.home, Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    _NavItem(AppRoutes.services, Icons.grid_view_outlined,
        Icons.grid_view_rounded, 'Services'),
    _NavItem(AppRoutes.projects, Icons.folder_outlined, Icons.folder_rounded,
        'Projets'),
    _NavItem(
        AppRoutes.contact, Icons.mail_outline_rounded, Icons.mail_rounded, 'Contact'),
  ];

  /// -1 sur Publications et Profil : ces pages s'ouvrent depuis l'accueil et
  /// ne correspondent à aucun onglet.
  int _currentIndex(String location) {
    for (int i = _items.length - 1; i >= 1; i--) {
      if (location == _items[i].route ||
          location.startsWith('${_items[i].route}/')) {
        return i;
      }
    }
    return location == AppRoutes.home ? 0 : -1;
  }

  @override
  Widget build(BuildContext context) {
    final int index = _currentIndex(state.matchedLocation);
    final bool dark = isDarkOf(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: dark ? AppColors.charcoal800 : Colors.white,
          border: Border(
            top: BorderSide(
                color: dark ? AppColors.charcoal700 : AppColors.lightBorder),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 66,
            child: Row(
              children: [
                for (int i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavButton(
                      item: _items[i],
                      selected: i == index,
                      onTap: () => context.go(_items[i].route),
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

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool dark = isDarkOf(context);
    final Color active = dark ? Colors.white : AppColors.brand600;
    final Color color = selected ? active : mutedOf(context);
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: ExcludeSemantics(
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(selected ? item.activeIcon : item.icon,
                  color: color, size: 26),
              const SizedBox(height: 3),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    item.label,
                    maxLines: 1,
                    style: TextStyle(
                      color: color,
                      fontSize: 12.5,
                      fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: selected ? 56 : 0,
                height: 3,
                decoration: BoxDecoration(
                  color: active,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ],
          ),
        ),
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
