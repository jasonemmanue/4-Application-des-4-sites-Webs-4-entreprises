import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Wrapper Firebase Cloud Messaging.
/// L'initialisation est "best-effort" — si Firebase n'est pas configure,
/// l'application demarre quand meme.
class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  bool _initialized = false;
  String? _fcmToken;
  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(alert: true, badge: true, sound: true);
      _fcmToken = await messaging.getToken();
      FirebaseMessaging.onMessage.listen((msg) {
        debugPrint('[FCM] foreground: ${msg.notification?.title}');
      });
      _initialized = true;
    } catch (e) {
      debugPrint('[FCM] init failed: $e');
    }
  }
}
