import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations(<DeviceOrientation>[
    DeviceOrientation.portraitUp,
  ]);

  // Firebase / FCM (best-effort — l'app doit demarrer meme sans Firebase).
  await PushNotificationService.instance.initialize();

  runApp(const ProviderScope(child: FloraHairApp()));
}
