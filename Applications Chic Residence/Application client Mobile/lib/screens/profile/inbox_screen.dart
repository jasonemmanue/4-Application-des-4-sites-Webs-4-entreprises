import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../config/theme.dart';
import '../../providers/providers.dart';
import '../../widgets/state_views.dart';

/// Boîte de réception de l'appareil (le client n'a pas de compte : la session
/// anonyme du téléphone sert d'adresse). Confirmations, relances, rappels de
/// séjour et messages de CHIC RESIDENCE.
class ClientNotification {
  final String id;
  final String kind;
  final String title;
  final String body;
  final bool isRead;
  final DateTime createdAt;
  final Map<String, dynamic> data;

  const ClientNotification({
    required this.id,
    required this.kind,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.data,
  });

  factory ClientNotification.fromJson(Map<String, dynamic> j) =>
      ClientNotification(
        id: j['id'].toString(),
        kind: j['kind']?.toString() ?? 'info',
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        isRead: j['is_read'] == true,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
        data: (j['data'] as Map?)?.cast<String, dynamic>() ?? const {},
      );
}

final inboxProvider =
    FutureProvider.autoDispose<List<ClientNotification>>((ref) async {
  final session = ref.watch(sessionServiceProvider).sessionId;
  final res = await ref
      .watch(apiClientProvider)
      .dio
      .get('/notifications', queryParameters: {'session_id': session});
  return ((res.data as List?) ?? const [])
      .map((e) => ClientNotification.fromJson((e as Map).cast<String, dynamic>()))
      .toList();
});

final inboxUnreadProvider = FutureProvider.autoDispose<int>((ref) async {
  final session = ref.watch(sessionServiceProvider).sessionId;
  final res = await ref.watch(apiClientProvider).dio.get(
      '/notifications/unread-count',
      queryParameters: {'session_id': session});
  return ((res.data as Map)['count'] as num?)?.toInt() ?? 0;
});

class InboxScreen extends ConsumerWidget {
  const InboxScreen({super.key});

  Future<void> _readAll(WidgetRef ref) async {
    final session = ref.read(sessionServiceProvider).sessionId;
    try {
      await ref.read(apiClientProvider).dio.post('/notifications/read-all',
          queryParameters: {'session_id': session});
    } catch (_) {}
    ref.invalidate(inboxProvider);
    ref.invalidate(inboxUnreadProvider);
  }

  Future<void> _open(
      BuildContext context, WidgetRef ref, ClientNotification n) async {
    final session = ref.read(sessionServiceProvider).sessionId;
    if (!n.isRead) {
      try {
        await ref.read(apiClientProvider).dio.put(
            '/notifications/${n.id}/read',
            queryParameters: {'session_id': session});
      } catch (_) {}
      ref.invalidate(inboxProvider);
      ref.invalidate(inboxUnreadProvider);
    }
    if (!context.mounted) return;
    if (n.kind.startsWith('payment') ||
        n.kind.startsWith('booking') ||
        n.kind.endsWith('reminder') ||
        n.kind == 'review_request') {
      context.go('/bookings');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final async = ref.watch(inboxProvider);
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
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(inboxProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              icon: Icons.notifications_none_rounded,
              title: 'Aucune notification',
              description:
                  'Confirmations, rappels de séjour et offres arrivent ici.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(inboxProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final n = list[i];
                return Material(
                  color: t.surfaceElevated,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _open(context, ref, n),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 19,
                            backgroundColor: t.brand.withValues(alpha: 0.14),
                            child: Icon(Icons.notifications_rounded,
                                size: 19, color: t.brand),
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
                                    color: t.textPrimary,
                                    fontWeight: n.isRead
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                  ),
                                ),
                                if (n.body.isNotEmpty)
                                  Text(n.body,
                                      style: TextStyle(
                                          fontSize: 13,
                                          height: 1.35,
                                          color: t.textPrimary)),
                                const SizedBox(height: 3),
                                Text(
                                  DateFormat('d MMM, HH:mm', 'fr_FR')
                                      .format(n.createdAt.toLocal()),
                                  style: TextStyle(
                                      fontSize: 11.5, color: t.textSecondary),
                                ),
                              ],
                            ),
                          ),
                          if (!n.isRead)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child:
                                  CircleAvatar(radius: 4, backgroundColor: t.brand),
                            ),
                        ],
                      ),
                    ),
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
