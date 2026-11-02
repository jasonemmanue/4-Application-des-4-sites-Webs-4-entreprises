/// Boîte de notifications de la cliente, conservée sur l'appareil.
///
/// Le backend du salon n'a pas de notifications ; la boîte est remplie par ce
/// que l'application constate elle-même :
/// - un changement d'état d'un rendez-vous décidé dans l'administration
///   (confirmé, annulé, terminé, acompte reçu), lu par `GET /bookings/{id}/status` ;
/// - les messages push reçus (campagnes de la console Firebase).
library;

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _inboxKey = 'flora_inbox';
const _maxItems = 50;

class InboxItem {
  const InboxItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.read = false,
    this.route,
  });

  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool read;

  /// Écran à ouvrir au toucher (`/appointments`…), facultatif.
  final String? route;

  InboxItem markRead() => InboxItem(
        id: id,
        title: title,
        body: body,
        receivedAt: receivedAt,
        read: true,
        route: route,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'id': id,
        'title': title,
        'body': body,
        'received_at': receivedAt.toIso8601String(),
        'read': read,
        'route': route,
      };

  factory InboxItem.fromJson(Map<String, dynamic> json) => InboxItem(
        id: json['id'] as String,
        title: (json['title'] as String?) ?? '',
        body: (json['body'] as String?) ?? '',
        receivedAt: DateTime.tryParse(json['received_at'] as String? ?? '') ??
            DateTime.now(),
        read: (json['read'] as bool?) ?? false,
        route: json['route'] as String?,
      );
}

final inboxProvider =
    StateNotifierProvider<InboxNotifier, List<InboxItem>>((ref) {
  return InboxNotifier();
});

final unreadInboxCountProvider = Provider<int>(
  (ref) => ref.watch(inboxProvider).where((i) => !i.read).length,
);

class InboxNotifier extends StateNotifier<List<InboxItem>> {
  InboxNotifier() : super(const <InboxItem>[]) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_inboxKey);
      if (raw == null) return;
      final restored = (jsonDecode(raw) as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(InboxItem.fromJson)
          .toList();
      // Un message arrivé pendant la lecture ne doit pas être perdu.
      final ids = state.map((i) => i.id).toSet();
      state = <InboxItem>[
        ...state,
        ...restored.where((i) => !ids.contains(i.id)),
      ];
    } catch (_) {}
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _inboxKey, jsonEncode(state.map((i) => i.toJson()).toList()));
    } catch (_) {}
  }

  /// Ajoute un message ; un même `id` n'est jamais enregistré deux fois.
  Future<void> add(InboxItem item) async {
    if (state.any((i) => i.id == item.id)) return;
    state = <InboxItem>[item, ...state].take(_maxItems).toList();
    await _persist();
  }

  Future<void> markAllRead() async {
    if (state.every((i) => i.read)) return;
    state = <InboxItem>[for (final i in state) i.markRead()];
    await _persist();
  }

  Future<void> clear() async {
    state = const <InboxItem>[];
    await _persist();
  }
}
