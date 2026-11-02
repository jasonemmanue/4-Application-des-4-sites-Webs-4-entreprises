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
  final auth = container.read(authServiceProvider);
  await NetworkStatus.start();
  final admin = await auth.restore();
  container.read(currentAdminProvider.notifier).state = admin;
  PushService.init().then((_) {
    if (admin != null) {
      DeviceRegistration.register(container.read(apiClientProvider), 'backoffice');
    }
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const BackofficeApp(),
    ),
  );
}
