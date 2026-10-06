import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  final container = ProviderContainer();
  await container.read(authServiceProvider).restore();
  final restoredUser = container.read(authServiceProvider).currentUser;
  container.read(currentUserProvider.notifier).state = restoredUser;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GestionnaireApp(),
    ),
  );
}
