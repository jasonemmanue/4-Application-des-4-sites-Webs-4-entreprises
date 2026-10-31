import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/ui.dart';

/// Barre d'onglets de la maquette. Le reste (paiements, avis, messages,
/// personnel, performance, paramètres) est dans « Plus ».
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _paths = ['/', '/residences', '/bookings', '/cleaning', '/more'];
  static const _items = [
    AppBottomItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Accueil'),
    AppBottomItem(Icons.villa_outlined, Icons.villa_rounded, 'Logements'),
    AppBottomItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded,
        'Réservations'),
    AppBottomItem(Icons.cleaning_services_outlined,
        Icons.cleaning_services_rounded, 'Terrain'),
    AppBottomItem(Icons.menu_rounded, Icons.menu_rounded, 'Plus'),
  ];

  int _index() {
    for (var i = _paths.length - 1; i > 0; i--) {
      if (location.startsWith(_paths[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomBar(
        items: _items,
        index: _index(),
        onTap: (i) => context.go(_paths[i]),
      ),
    );
  }
}
