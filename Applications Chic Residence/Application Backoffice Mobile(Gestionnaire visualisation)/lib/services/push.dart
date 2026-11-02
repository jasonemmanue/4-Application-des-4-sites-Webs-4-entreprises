import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Notifications push (FCM). Firebase n'était initialisé nulle part : aucun push
/// ne pouvait arriver. La configuration vient de `google-services.json`.
///
/// Tout est facultatif : sans Firebase ou sans permission, l'application lit
/// sa boîte de réception sur l'API et rien d'autre ne change.
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
      await Firebase.initializeApp();
      final fm = FirebaseMessaging.instance;
      await fm.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen(_messages.add);
      FirebaseMessaging.onMessageOpenedApp.listen(_opened.add);
      final initial = await fm.getInitialMessage();
      if (initial != null) _opened.add(initial);
      _ready = true;
    } catch (_) {
      _ready = false;
    }
    return _ready;
  }

  static Future<String?> token() async {
    if (!await init()) return null;
    try {
      return await FirebaseMessaging.instance.getToken();
    } catch (_) {
      return null;
    }
  }

  /// Rappelé à chaque renouvellement du jeton par Firebase.
  static void onTokenRefresh(Future<void> Function(String) register) {
    if (!_ready) return;
    FirebaseMessaging.instance.onTokenRefresh.listen((t) => register(t));
  }
}
