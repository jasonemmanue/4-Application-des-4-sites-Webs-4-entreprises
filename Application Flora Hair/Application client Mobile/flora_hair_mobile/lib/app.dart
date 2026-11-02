import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'services/appointments.dart';
import 'services/inbox.dart';
import 'services/network.dart';
import 'services/payment_service.dart';
import 'services/providers.dart';
import 'services/push_notification_service.dart';

class FloraHairApp extends ConsumerStatefulWidget {
  const FloraHairApp({super.key});

  @override
  ConsumerState<FloraHairApp> createState() => _FloraHairAppState();
}

/// Rafraîchissement automatique, repris de Chic Residence : les rendez-vous
/// sont relus toutes les 60 s, au retour au premier plan et au retour du
/// réseau, qui recharge aussi le catalogue. Les messages push vont dans la
/// boîte de réception.
class _FloraHairAppState extends ConsumerState<FloraHairApp>
    with WidgetsBindingObserver {
  static const _refreshEvery = Duration(seconds: 60);

  Timer? _timer;
  StreamSubscription<void>? _reconnect;
  StreamSubscription<dynamic>? _push;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(_refreshEvery, (_) => _refreshAppointments());
    _reconnect = NetworkStatus.onReconnect.listen((_) => _reloadAll());
    final push = PushNotificationService.instance;
    // Abonné avant l'initialisation : la notification qui a ouvert l'app
    // n'est pas perdue.
    _push = push.onMessage.listen((msg) {
      final n = msg.notification;
      if (n == null) return;
      ref.read(inboxProvider.notifier).add(InboxItem(
            id: msg.messageId ?? '${DateTime.now().millisecondsSinceEpoch}',
            title: n.title ?? 'Flora Hair',
            body: n.body ?? '',
            receivedAt: msg.sentTime ?? DateTime.now(),
          ));
      _refreshAppointments();
    });
    push.initialize();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _reconnect?.cancel();
    _push?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refreshAppointments();
  }

  void _refreshAppointments() =>
      ref.read(appointmentsProvider.notifier).refresh();

  void _reloadAll() {
    ref.invalidate(servicesProvider);
    ref.invalidate(categoriesProvider);
    ref.invalidate(teamProvider);
    ref.invalidate(galleryProvider);
    ref.invalidate(articlesProvider);
    ref.invalidate(reviewsProvider);
    ref.invalidate(paymentConfigProvider);
    _refreshAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Flora Hair',
      debugShowCheckedModeBanner: false,
      theme: FloraTheme.light,
      darkTheme: FloraTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => NetworkBanner(child: child!),
    );
  }
}
