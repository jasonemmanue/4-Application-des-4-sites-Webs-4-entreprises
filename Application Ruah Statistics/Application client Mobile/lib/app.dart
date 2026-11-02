import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'config/theme.dart';
import 'providers/providers.dart';
import 'services/network.dart';
import 'services/notification_inbox.dart';
import 'services/push.dart';

final GlobalKey<ScaffoldMessengerState> messengerKey =
    GlobalKey<ScaffoldMessengerState>();

class RuahStatisticsApp extends ConsumerStatefulWidget {
  const RuahStatisticsApp({super.key});

  @override
  ConsumerState<RuahStatisticsApp> createState() => _RuahStatisticsAppState();
}

class _RuahStatisticsAppState extends ConsumerState<RuahStatisticsApp> {
  final List<StreamSubscription<Object?>> _subs = [];
  late final AppLifecycleListener _lifecycle;
  DateTime _lastRefresh = DateTime.now();

  @override
  void initState() {
    super.initState();
    _subs
      ..add(NetworkStatus.onReconnect.listen((_) => _refreshContent()))
      ..add(PushService.onMessage.listen((m) async {
        final item = inboxItemFrom(m);
        if (item == null) return;
        await ref.read(inboxProvider.notifier).add(item);
        messengerKey.currentState?.showSnackBar(SnackBar(
          content: Text(item.title.isNotEmpty ? item.title : item.body),
          action: SnackBarAction(
            label: 'Voir',
            onPressed: () => appRouter.push(AppRoutes.notifications),
          ),
        ));
      }))
      ..add(PushService.onOpened.listen((m) async {
        final item = inboxItemFrom(m);
        if (item != null) await ref.read(inboxProvider.notifier).add(item);
        appRouter.push(AppRoutes.notifications);
      }));
    _lifecycle = AppLifecycleListener(onResume: () {
      ref.read(inboxProvider.notifier).reload();
      // Contenu éditorial : un rechargement au retour, au plus toutes les
      // 5 minutes, suffit à refléter les modifications faites dans l'admin.
      if (DateTime.now().difference(_lastRefresh) >
          const Duration(minutes: 5)) {
        _refreshContent();
      }
    });
  }

  void _refreshContent() {
    _lastRefresh = DateTime.now();
    ref
      ..invalidate(servicesProvider)
      ..invalidate(serviceDetailProvider)
      ..invalidate(projectsProvider)
      ..invalidate(projectDetailProvider)
      ..invalidate(articlesProvider)
      ..invalidate(articleDetailProvider)
      ..invalidate(teamProvider)
      ..invalidate(teamMemberProvider)
      ..invalidate(videosProvider)
      ..invalidate(testimonialsProvider)
      ..invalidate(partnersProvider)
      ..invalidate(keyFiguresProvider);
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Ruah Statistics',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: messengerKey,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      routerConfig: appRouter,
      builder: (context, child) => NetworkBanner(child: child!),
    );
  }
}
