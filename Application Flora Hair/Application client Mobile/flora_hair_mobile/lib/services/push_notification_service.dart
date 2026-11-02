import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Notifications push (FCM), configuration lue dans `google-services.json`.
///
/// Le backend du salon envoie les décisions sur les rendez-vous au jeton reçu
/// avec la réservation (`app/services/push_service.py`) ; la console Firebase
/// peut aussi envoyer des campagnes. Tout est facultatif, et l'initialisation
/// ne bloque pas l'ouverture de l'application.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  final _messages = StreamController<RemoteMessage>.broadcast();
  final _tokens = StreamController<String>.broadcast();

  /// Jeton obtenu à l'initialisation, puis à chaque renouvellement par Firebase.
  Stream<String> get onToken => _tokens.stream;

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
      if (_fcmToken != null) _tokens.add(_fcmToken!);
      messaging.onTokenRefresh.listen((t) {
        _fcmToken = t;
        _tokens.add(t);
      });
      _initialized = true;
    } catch (_) {
      // Best-effort : l'app fonctionne sans Firebase.
    }
  }
}
