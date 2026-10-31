import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/providers.dart';

class GestionnaireApp extends ConsumerStatefulWidget {
  const GestionnaireApp({super.key});

  @override
  ConsumerState<GestionnaireApp> createState() => _GestionnaireAppState();
}

class _GestionnaireAppState extends ConsumerState<GestionnaireApp> {
  late final _router = buildRouter(ref);

  @override
  void initState() {
    super.initState();
    // Jeton expiré ou compte désactivé : retour à la connexion.
    ref.read(apiClientProvider).onSessionExpired = () async {
      await ref.read(authServiceProvider).logout();
      ref.read(currentUserProvider.notifier).state = null;
      _router.go('/login');
    };
  }

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
