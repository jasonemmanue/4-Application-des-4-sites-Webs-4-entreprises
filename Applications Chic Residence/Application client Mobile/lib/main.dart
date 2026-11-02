import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app.dart';
import 'providers/providers.dart';
import 'services/api_client.dart';
import 'services/network.dart';
import 'services/push.dart';
import 'services/session_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Couper TOUS les logs en release (rien dans adb logcat).
  if (kReleaseMode) {
    debugPrint = (String? message, {int? wrapWidth}) {};
  }

  await initializeDateFormatting('fr_FR');

  // Firebase et FCM sont volontairement optionnels au demarrage : ils sont
  // initialises apres coup pour ne pas bloquer l'app si la config est absente.

  final session = await SessionService.create();
  await NetworkStatus.start();
  // Push en arrière-plan : l'ouverture n'attend pas Firebase.
  PushService.init().then((_) => registerClientDevice(session.sessionId));

  runApp(
    ProviderScope(
      overrides: [
        sessionServiceProvider.overrideWithValue(session),
      ],
      child: const ChicResidenceApp(),
    ),
  );
}

/// Rattache le téléphone à sa session anonyme : relances et rappels de séjour.
Future<void> registerClientDevice(String sessionId) async {
  final token = await PushService.token();
  if (token == null) return;
  Future<void> send(String t) async {
    try {
      await ApiClient(sessionId: sessionId).dio.post('/devices', data: {
        'token': t,
        'app': 'client',
        'session_id': sessionId,
      });
    } catch (_) {}
  }

  await send(token);
  PushService.onTokenRefresh(send);
}
