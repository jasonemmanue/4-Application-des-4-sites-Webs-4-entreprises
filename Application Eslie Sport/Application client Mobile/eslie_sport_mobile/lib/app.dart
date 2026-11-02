import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'services/network.dart';
import 'services/payment_service.dart';
import 'services/providers.dart';

class EslieSportApp extends ConsumerStatefulWidget {
  const EslieSportApp({super.key});

  @override
  ConsumerState<EslieSportApp> createState() => _EslieSportAppState();
}

/// Recharge les donnees du back-office au retour du reseau et quand l'app
/// revient au premier plan apres une absence : planning, places restantes,
/// tarifs et coordonnees restent a jour sans tirer l'ecran.
class _EslieSportAppState extends ConsumerState<EslieSportApp>
    with WidgetsBindingObserver {
  static const _staleAfter = Duration(seconds: 30);

  StreamSubscription<void>? _reconnect;
  DateTime? _pausedAt;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _reconnect = NetworkStatus.onReconnect.listen((_) => _reload());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedAt = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      final away = _pausedAt;
      _pausedAt = null;
      if (away != null && DateTime.now().difference(away) > _staleAfter) {
        _reload();
      }
    }
  }

  void _reload() {
    ref.invalidate(scheduleProvider);
    ref.invalidate(slotAvailabilityProvider);
    ref.invalidate(activitiesProvider);
    ref.invalidate(subscriptionsProvider);
    ref.invalidate(coachesProvider);
    ref.invalidate(featuredTransformationsProvider);
    ref.invalidate(publicSettingsProvider);
    ref.invalidate(paymentConfigProvider);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _reconnect?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Eslie Sport',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      routerConfig: router,
      builder: (context, child) => NetworkBanner(child: child!),
    );
  }
}
