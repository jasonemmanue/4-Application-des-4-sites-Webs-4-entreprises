import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  final FirebaseMessaging _messaging;

  PushNotificationService([FirebaseMessaging? messaging])
      : _messaging = messaging ?? FirebaseMessaging.instance;

  Future<void> initialize() async {
    try {
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final String? token = await _messaging.getToken();
      if (kDebugMode) debugPrint('FCM token: $token');

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    } catch (e) {
      if (kDebugMode) debugPrint('Push init failed: $e');
    }
  }

  Future<String?> getToken() => _messaging.getToken();

  void _handleForegroundMessage(RemoteMessage message) {
    if (kDebugMode) {
      debugPrint('Push received: ${message.notification?.title}');
    }
  }
}
