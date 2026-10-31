import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/ui.dart';

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child, required this.location});

  final Widget child;
  final String location;

  static const _paths = ['/', '/tasks', '/stats', '/profile'];
  static const _items = [
    AppBottomItem(Icons.home_outlined, Icons.home_rounded, 'Accueil'),
    AppBottomItem(Icons.checklist_rounded, Icons.checklist_rounded, 'Tâches'),
    AppBottomItem(Icons.bar_chart_rounded, Icons.bar_chart_rounded, 'Stats'),
    AppBottomItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
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
