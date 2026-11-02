import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/providers.dart';
import 'services/network.dart';

class BackofficeApp extends ConsumerStatefulWidget {
  const BackofficeApp({super.key});

  @override
  ConsumerState<BackofficeApp> createState() => _BackofficeAppState();
}

class _BackofficeAppState extends ConsumerState<BackofficeApp> {
  late final _router = buildRouter(ref);
  bool _checkingSession = false;

  @override
  void initState() {
    super.initState();
    // Un 401 sur une route ne prouve pas que la session est morte : on demande à
    // `/auth/me`. Seul son refus renvoie à la connexion, et une coupure réseau
    // n'y renvoie pas.
    ref.read(apiClientProvider).onSessionExpired = () async {
      if (_checkingSession) return;
      _checkingSession = true;
      try {
        final auth = ref.read(authServiceProvider);
        final token = await ref.read(apiClientProvider).readToken();
        if (token == null) return;
        await auth.restore();
        if (await ref.read(apiClientProvider).readToken() == null) {
          await auth.logout();
          ref.read(currentAdminProvider.notifier).state = null;
          _router.go('/login');
        }
      } finally {
        _checkingSession = false;
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Chic Residence Backoffice',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      routerConfig: _router,
      builder: (context, child) => NetworkBanner(child: child!),
    );
  }
}
