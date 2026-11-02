import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/models.dart';
import '../providers/providers.dart';
import '../widgets/ui.dart';

/// Onglets selon le rôle : le personnel de terrain (agent, contrôleur) suit ses
/// tâches ; le gérant gère logements, réservations et accueil, sans le
/// nettoyage.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _fieldPaths = ['/', '/tasks', '/stats', '/profile'];
  static const _fieldItems = [
    AppBottomItem(Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    AppBottomItem(Icons.checklist_rounded, Icons.checklist_rounded, 'Tâches'),
    AppBottomItem(Icons.bar_chart_rounded, Icons.bar_chart_rounded, 'Stats'),
    AppBottomItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  static const _managerPaths = [
    '/m',
    '/m/residences',
    '/m/bookings',
    '/m/guests',
    '/profile',
  ];
  static const _managerItems = [
    AppBottomItem(Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    AppBottomItem(Icons.villa_outlined, Icons.villa_rounded, 'Logements'),
    AppBottomItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded,
        'Réservations'),
    AppBottomItem(Icons.badge_outlined, Icons.badge_rounded, 'Voyageurs'),
    AppBottomItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  int _index(List<String> paths) {
    for (var i = paths.length - 1; i > 0; i--) {
      if (location.startsWith(paths[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final manager = ref.watch(currentUserProvider)?.role == StaffRole.manager;
    final paths = manager ? _managerPaths : _fieldPaths;
    return Scaffold(
      body: child,
      bottomNavigationBar: AppBottomBar(
        items: manager ? _managerItems : _fieldItems,
        index: _index(paths),
        onTap: (i) => context.go(paths[i]),
      ),
    );
  }
}
