import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';

class GestionnaireApp extends ConsumerStatefulWidget {
  const GestionnaireApp({super.key});

  @override
  ConsumerState<GestionnaireApp> createState() => _GestionnaireAppState();
}

class _GestionnaireAppState extends ConsumerState<GestionnaireApp> {
  late final _router = buildRouter(ref);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Chic Residence Gestionnaire',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
    );
  }
}
