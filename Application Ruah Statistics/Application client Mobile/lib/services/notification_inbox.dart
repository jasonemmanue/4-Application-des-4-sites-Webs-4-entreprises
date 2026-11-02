import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boîte de notifications du téléphone.
///
/// Le backend du cabinet n'a ni comptes ni table de notifications : la boîte
/// garde localement les messages push reçus (sujet FCM `actualites`, envoyés
/// depuis la console Firebase). 50 au plus, du plus récent au plus ancien.
class InboxItem {
  final String id;
  final String title;
  final String body;
  final DateTime receivedAt;
  final bool read;

  const InboxItem({
    required this.id,
    required this.title,
    required this.body,
    required this.receivedAt,
    this.read = false,
  });

  InboxItem copyWith({bool? read}) => InboxItem(
        id: id,
        title: title,
        body: body,
        receivedAt: receivedAt,
        read: read ?? this.read,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'received_at': receivedAt.toIso8601String(),
        'read': read,
      };

  static InboxItem? fromJson(Object? raw) {
    if (raw is! Map) return null;
    final id = raw['id'];
    final at = DateTime.tryParse('${raw['received_at']}');
    if (id is! String || at == null) return null;
    return InboxItem(
      id: id,
      title: '${raw['title'] ?? ''}',
      body: '${raw['body'] ?? ''}',
      receivedAt: at,
      read: raw['read'] == true,
    );
  }
}

class InboxStore {
  InboxStore._();

  static const _key = 'ruah_inbox';
  static const _max = 50;

  static Future<List<InboxItem>> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.reload();
      final raw = prefs.getString(_key);
      if (raw == null) return [];
      final list = jsonDecode(raw);
      if (list is! List) return [];
      return list.map(InboxItem.fromJson).whereType<InboxItem>().toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> save(List<InboxItem> items) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _key,
        jsonEncode(items.take(_max).map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  /// Ajoute un message, sans doublon : un même push peut arriver par le
  /// gestionnaire d'arrière-plan puis par l'ouverture de la notification.
  static Future<List<InboxItem>> add(InboxItem item) async {
    final items = await load();
    if (items.any((e) => e.id == item.id)) return items;
    final next = [item, ...items];
    await save(next);
    return next;
  }
}

final inboxProvider =
    StateNotifierProvider<InboxNotifier, List<InboxItem>>((ref) {
  return InboxNotifier();
});

final inboxUnreadProvider = Provider<int>(
    (ref) => ref.watch(inboxProvider).where((e) => !e.read).length);

class InboxNotifier extends StateNotifier<List<InboxItem>> {
  InboxNotifier() : super(const []) {
    reload();
  }

  /// Relit le stockage : le gestionnaire d'arrière-plan y écrit pendant que
  /// l'application est fermée.
  Future<void> reload() async => state = await InboxStore.load();

  Future<void> add(InboxItem item) async => state = await InboxStore.add(item);

  Future<void> markAllRead() async {
    if (state.every((e) => e.read)) return;
    state = [for (final e in state) e.copyWith(read: true)];
    await InboxStore.save(state);
  }

  Future<void> clear() async {
    state = const [];
    await InboxStore.save(state);
  }
}
