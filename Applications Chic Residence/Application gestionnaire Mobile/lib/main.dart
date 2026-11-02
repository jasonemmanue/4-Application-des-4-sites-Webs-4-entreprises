import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'providers/providers.dart';
import 'services/device_registration.dart';
import 'services/network.dart';
import 'services/push.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await initializeDateFormatting('fr_FR');

  final container = ProviderContainer();
  await NetworkStatus.start();
  final restoredUser = await container.read(authServiceProvider).restore();
  container.read(currentUserProvider.notifier).state = restoredUser;
  // Push : en arrière-plan, l'ouverture de l'application n'attend pas Firebase.
  PushService.init().then((_) {
    if (restoredUser != null) {
      DeviceRegistration.register(container.read(apiClientProvider), 'gestionnaire');
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const GestionnaireApp(),
    ),
  );
}
