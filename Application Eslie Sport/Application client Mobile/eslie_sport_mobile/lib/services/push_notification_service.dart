/// Firebase Cloud Messaging cote client.
///
/// L'init est defensive : l'app doit demarrer meme sans `google-services.json`
/// (developpement local, tests d'UI). Le vrai token FCM est recupere apres
/// `Firebase.initializeApp()` — quand la config est presente, on demande la
/// permission puis on lit le token.
///
/// Le backend n'expose pas encore d'endpoint pour enregistrer le token —
/// quand il le fera, `registerToken` sera l'endroit ou l'appeler.
library;

import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  PushNotificationService._();
  static final instance = PushNotificationService._();

  String? _fcmToken;
  bool _initialized = false;

  String? get token => _fcmToken;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      if (settings.authorizationStatus == AuthorizationStatus.denied) {
        if (kDebugMode) {
          debugPrint('[Push] permission refusee, notifications ignorees.');
        }
      }
      _fcmToken = await messaging.getToken();
      _initialized = true;
      if (kDebugMode) debugPrint('[Push] token=$_fcmToken');
    } catch (e) {
      // Firebase non configure (dev local, absence de google-services.json).
      if (kDebugMode) debugPrint('[Push] init skipped: $e');
    }
  }

  Future<String?> getToken() async {
    if (!_initialized) await initialize();
    return _fcmToken;
  }

  Stream<RemoteMessage> onForegroundMessage() {
    return _initialized
        ? FirebaseMessaging.onMessage
        : const Stream.empty();
  }
}
