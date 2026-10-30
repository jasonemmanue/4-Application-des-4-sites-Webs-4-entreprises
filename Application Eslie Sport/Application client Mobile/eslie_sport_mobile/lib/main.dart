import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'services/push_notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // En release : aucun log dans logcat / console.
  if (!kDebugMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
    developer.log('', name: 'SILENCED');
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF0F1724),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  await PushNotificationService.instance.initialize();

  runApp(const ProviderScope(child: EslieSportApp()));
}
