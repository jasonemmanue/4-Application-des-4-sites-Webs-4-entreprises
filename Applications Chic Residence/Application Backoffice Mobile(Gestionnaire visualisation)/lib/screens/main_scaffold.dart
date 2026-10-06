import 'package:flutter/material.dart';

import '../widgets/app_drawer.dart';

/// Enveloppe chaque ecran admin avec le drawer lateral.
class MainScaffold extends StatelessWidget {
  const MainScaffold({
    super.key,
    required this.title,
    required this.body,
    required this.location,
    this.actions,
  });

  final String title;
  final Widget body;
  final String location;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      drawer: AppDrawer(location: location),
      body: body,
    );
  }
}
