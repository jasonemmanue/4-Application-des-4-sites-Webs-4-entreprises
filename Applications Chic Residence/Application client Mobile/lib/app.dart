import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/providers.dart';
import 'services/network.dart';

class ChicResidenceApp extends ConsumerStatefulWidget {
  const ChicResidenceApp({super.key});

  @override
  ConsumerState<ChicResidenceApp> createState() => _ChicResidenceAppState();
}

class _ChicResidenceAppState extends ConsumerState<ChicResidenceApp> {
  late final _router = buildRouter();

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    // Charge les coordonnées réglées dans l'administration.
    ref.watch(publicInfoProvider);
    return MaterialApp.router(
      title: 'Chic Residence',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: _router,
      builder: (context, child) => NetworkBanner(child: child!),
    );
  }
}
