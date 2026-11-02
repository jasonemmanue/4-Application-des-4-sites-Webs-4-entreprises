import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'notification_inbox.dart';

/// Sujet FCM auquel chaque téléphone s'abonne. Le cabinet envoie ses messages
/// depuis la console Firebase (Messaging > Nouvelle campagne > Sujet
/// `actualites`) : il n'y a ni compte ni enregistrement d'appareil côté API.
const String newsTopic = 'actualites';

InboxItem? inboxItemFrom(RemoteMessage m) {
  final n = m.notification;
  final title = n?.title ?? m.data['title']?.toString() ?? '';
  final body = n?.body ?? m.data['body']?.toString() ?? '';
  if (title.isEmpty && body.isEmpty) return null;
  return InboxItem(
    id: m.messageId ?? '${m.sentTime?.millisecondsSinceEpoch ?? title.hashCode}',
    title: title,
    body: body,
    receivedAt: m.sentTime ?? DateTime.now(),
  );
}

/// Message reçu application fermée ou en arrière-plan : Android affiche la
/// notification, ce gestionnaire la range dans la boîte.
@pragma('vm:entry-point')
Future<void> pushBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  final item = inboxItemFrom(message);
  if (item != null) await InboxStore.add(item);
}

/// Tout est facultatif : sans Firebase ou sans permission, l'application
/// fonctionne normalement et la boîte reste vide.
class PushService {
  PushService._();

  static bool _ready = false;
  static final _messages = StreamController<RemoteMessage>.broadcast();
  static final _opened = StreamController<RemoteMessage>.broadcast();

  /// Message reçu application ouverte (Android ne l'affiche pas tout seul).
  static Stream<RemoteMessage> get onMessage => _messages.stream;

  /// Notification touchée par l'utilisateur.
  static Stream<RemoteMessage> get onOpened => _opened.stream;

  static Future<bool> init() async {
    if (_ready) return true;
    try {
      if (Firebase.apps.isEmpty) await Firebase.initializeApp();
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen(_messages.add);
      FirebaseMessaging.onMessageOpenedApp.listen(_opened.add);
      await fm.subscribeToTopic(newsTopic);
      final initial = await fm.getInitialMessage();
      if (initial != null) _opened.add(initial);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }
}
