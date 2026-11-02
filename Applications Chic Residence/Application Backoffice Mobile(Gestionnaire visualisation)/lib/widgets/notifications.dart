import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../config/theme.dart';
import '../providers/providers.dart';
import '../services/network.dart';
import '../services/push.dart';
import 'ui.dart';

/// Boîte de réception du compte connecté (admin ou personnel : le jeton dit
/// laquelle) et pastille du nombre de non-lues.

class AppNotification {
  final String id;
  final String kind;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  const AppNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  factory AppNotification.fromJson(Map<String, dynamic> j) => AppNotification(
        id: j['id'].toString(),
        kind: j['kind']?.toString() ?? 'info',
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        isRead: j['is_read'] == true,
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
        data: (j['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>((ref) async {
  final res = await ref.watch(apiClientProvider).dio.get('/notifications');
  return ((res.data as List?) ?? const [])
      .map((e) => AppNotification.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
});

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final res =
      await ref.watch(apiClientProvider).dio.get('/notifications/unread-count');
  return ((res.data as Map)['count'] as num?)?.toInt() ?? 0;
});

IconData _icon(String kind) {
  if (kind.startsWith('task')) return Icons.cleaning_services_rounded;
  if (kind.startsWith('payment')) return Icons.payments_rounded;
  if (kind.startsWith('booking')) return Icons.event_available_rounded;
  if (kind.startsWith('contact')) return Icons.mail_rounded;
  if (kind.startsWith('review')) return Icons.star_rounded;
  if (kind.startsWith('guest')) return Icons.badge_rounded;
  return Icons.notifications_rounded;
}

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  Future<void> _readAll(WidgetRef ref) async {
    try {
      await ref.read(apiClientProvider).dio.post('/notifications/read-all');
    } catch (_) {}
    ref.invalidate(notificationsProvider);
    ref.invalidate(unreadCountProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(notificationsProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () => _readAll(ref),
            child: const Text('Tout lu'),
          ),
        ],
      ),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorState(
          error: e,
          onRetry: () => ref.invalidate(notificationsProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyState(
              icon: Icons.notifications_none_rounded,
              title: 'Aucune notification',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = list[i];
                return Panel(
                  onTap: n.isRead
                      ? null
                      : () async {
                          try {
                            await ref
                                .read(apiClientProvider)
                                .dio
                                .put('/notifications/${n.id}/read');
                          } catch (_) {}
                          ref.invalidate(notificationsProvider);
                          ref.invalidate(unreadCountProvider);
                        },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 19,
                        backgroundColor: AppColors.primaryLight,
                        child: Icon(_icon(n.kind),
                            size: 19, color: AppColors.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              n.title,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                    n.isRead ? FontWeight.w500 : FontWeight.w700,
                              ),
                            ),
                            if (n.body.isNotEmpty)
                              Text(n.body,
                                  style: const TextStyle(
                                      fontSize: 13, height: 1.35)),
                            const SizedBox(height: 3),
                            Text(
                              DateFormat('d MMM, HH:mm', 'fr_FR')
                                  .format(n.createdAt.toLocal()),
                              style: const TextStyle(
                                  fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      if (!n.isRead)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: CircleAvatar(
                              radius: 4, backgroundColor: AppColors.primary),
                        ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

/// Cloche avec pastille, à poser dans une barre d'en-tête.
class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key, required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(unreadCountProvider).valueOrNull ?? 0;
    return IconButton(
      tooltip: 'Notifications',
      onPressed: onTap,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 9 ? '9+' : '$count'),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.notifications_none_rounded),
      ),
    );
  }
}

/// Recharge des écrans : toutes les [interval], au retour de l'application au
/// premier plan, au retour du réseau et à l'arrivée d'une notification push.
/// C'est ce qui manquait pour voir le travail des autres sans tirer l'écran.
class AutoRefresh extends ConsumerStatefulWidget {
  const AutoRefresh({
    super.key,
    required this.child,
    required this.refresh,
    this.interval = const Duration(seconds: 30),
  });

  final Widget child;
  final void Function(WidgetRef ref) refresh;
  final Duration interval;

  @override
  ConsumerState<AutoRefresh> createState() => _AutoRefreshState();
}

class _AutoRefreshState extends ConsumerState<AutoRefresh>
    with WidgetsBindingObserver {
  Timer? _timer;
  final _subs = <StreamSubscription<dynamic>>[];

  void _run() {
    if (!mounted) return;
    widget.refresh(ref);
    ref.invalidate(unreadCountProvider);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timer = Timer.periodic(widget.interval, (_) => _run());
    _subs.add(NetworkStatus.onReconnect.listen((_) => _run()));
    _subs.add(PushService.onMessage.listen((_) => _run()));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _run();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    for (final s in _subs) {
      s.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
