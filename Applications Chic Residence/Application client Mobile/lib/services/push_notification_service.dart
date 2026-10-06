import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

/// Firebase Cloud Messaging wrapper. Firebase doit etre initialise dans main().
class PushNotificationService {
  PushNotificationService._();

  static Future<String?> init() async {
    try {
      final fm = FirebaseMessaging.instance;
      final settings = await fm.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        return null;
      }
      final token = await fm.getToken();
      if (kDebugMode) {
        debugPrint('FCM token: $token');
      }
      return token;
    } catch (e) {
      debugPrint('FCM init failed: $e');
      return null;
    }
  }
}
