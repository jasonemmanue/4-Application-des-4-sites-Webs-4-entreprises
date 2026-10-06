import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'providers/providers.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  // Firebase et FCM sont volontairement optionnels au demarrage : ils sont
  // initialises apres coup pour ne pas bloquer l'app si la config est absente.

  final session = await SessionService.create();

  runApp(
    ProviderScope(
      overrides: [
        sessionServiceProvider.overrideWithValue(session),
      ],
      child: const ChicResidenceApp(),
    ),
  );
}
