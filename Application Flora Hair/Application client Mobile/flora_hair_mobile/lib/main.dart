import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/network.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Couper TOUS les logs en release (rien dans adb logcat).
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Firebase / FCM : initialisé par FloraHairApp, sans bloquer l'ouverture.
  await NetworkStatus.start();

  runApp(const ProviderScope(child: FloraHairApp()));
}
