import 'dart:async';
import 'dart:io' show Platform;

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
      await Firebase.initializeApp(options: _iosOptions());
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

  /// iOS : pas de `GoogleService-Info.plist` dans le dépôt (comme le
  /// `google-services.json` d'Android, il reste hors de Git). Les identifiants
  /// arrivent au build par Codemagic. Android lit `google-services.json`.
  static FirebaseOptions? _iosOptions() {
    if (!Platform.isIOS) return null;
    const apiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
    const appId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
    if (apiKey.isEmpty || appId.isEmpty) return null;
    return const FirebaseOptions(
      apiKey: apiKey,
      appId: appId,
      messagingSenderId: '1053030542423',
      projectId: 'chic-residence-meuble',
      storageBucket: 'chic-residence-meuble.firebasestorage.app',
      iosBundleId: String.fromEnvironment('FIREBASE_IOS_BUNDLE_ID'),
    );
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
