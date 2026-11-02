import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Notifications push (FCM), configuration lue dans `google-services.json`.
///
/// Le backend du salon n'envoie pas encore de push : les messages arrivent
/// aujourd'hui des campagnes de la console Firebase. Tout est facultatif, et
/// l'initialisation ne bloque plus l'ouverture de l'application.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final _messages = StreamController<RemoteMessage>.broadcast();

  /// Message reçu application ouverte, ou notification touchée par la cliente.
  Stream<RemoteMessage> get onMessage => _messages.stream;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      FirebaseMessaging.onMessage.listen(_messages.add);
      FirebaseMessaging.onMessageOpenedApp.listen(_messages.add);
      final initial = await messaging.getInitialMessage();
      if (initial != null) _messages.add(initial);
      _fcmToken = await messaging.getToken();
      _initialized = true;
    } catch (_) {
      // Best-effort : l'app fonctionne sans Firebase.
    }
  }
}
