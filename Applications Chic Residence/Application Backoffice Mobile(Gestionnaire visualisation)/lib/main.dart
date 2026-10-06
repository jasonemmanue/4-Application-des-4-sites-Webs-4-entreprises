import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'providers/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR');

  final container = ProviderContainer();
  final auth = container.read(authServiceProvider);
  final admin = await auth.restore();
  container.read(currentAdminProvider.notifier).state = admin;

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BackofficeApp(),
    ),
  );
}
