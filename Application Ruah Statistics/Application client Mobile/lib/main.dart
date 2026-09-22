import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initializeDateFormatting('fr');
  try {
    await Firebase.initializeApp();
  } catch (_) {
    // Fail-open : si google-services.json n'est pas encore branché ou si
    // Firebase renvoie une erreur, l'app doit continuer de tourner. Les push
    // notifications sont un bonus, pas un pré-requis pour consulter le site.
  }
  runApp(const ProviderScope(child: RuahStatisticsApp()));
}
