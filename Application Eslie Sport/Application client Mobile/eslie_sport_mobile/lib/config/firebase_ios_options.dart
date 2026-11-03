import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Configuration Firebase de l'app iOS, passee au build par Codemagic
/// (`--dart-define`), au lieu de `GoogleService-Info.plist` que le depot ignore.
///
/// Valeurs a recopier depuis le `GoogleService-Info.plist` de l'app iOS
/// enregistree dans le projet Firebase `eslie-sport-application` :
/// `API_KEY` -> FIREBASE_IOS_API_KEY, `GOOGLE_APP_ID` -> FIREBASE_IOS_APP_ID.
///
/// Android garde `google-services.json` : cette classe ne sert que sur iOS.
class FirebaseIosOptions {
  FirebaseIosOptions._();

  static const _apiKey = String.fromEnvironment('FIREBASE_IOS_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const _senderId = String.fromEnvironment(
    'FIREBASE_SENDER_ID',
    defaultValue: '889399533098',
  );
  static const _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'eslie-sport-application',
  );
  static const _bundleId = 'com.esliesport.eslieSportMobile';

  static bool get isIos =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  /// Null hors iOS, ou si les cles n'ont pas ete fournies au build : l'app
  /// demarre alors sans push, comme avant.
  static FirebaseOptions? get current {
    if (!isIos || _apiKey.isEmpty || _appId.isEmpty) return null;
    return const FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _senderId,
      projectId: _projectId,
      iosBundleId: _bundleId,
    );
  }
}
