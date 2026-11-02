import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'services/network.dart';
import 'services/push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Securite : couper TOUS les logs en release (rien dans adb logcat).
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initializeDateFormatting('fr');
  await NetworkStatus.start();
  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(pushBackgroundHandler);
  } catch (_) {
    // Fail-open : si google-services.json n'est pas encore branché ou si
    // Firebase renvoie une erreur, l'app doit continuer de tourner. Les push
    // notifications sont un bonus, pas un pré-requis pour consulter le site.
  }

  runApp(const ProviderScope(child: RuahStatisticsApp()));
  // Après le premier affichage : l'ouverture n'attend pas Firebase.
  PushService.init();
}
