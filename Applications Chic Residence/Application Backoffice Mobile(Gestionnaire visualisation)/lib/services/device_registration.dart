import 'api_client.dart';
import 'push.dart';

/// Rattache ce téléphone au compte connecté pour les notifications push, et
/// l'en détache à la déconnexion (sinon le suivant recevrait les siennes).
class DeviceRegistration {
  DeviceRegistration._();

  static Future<void> register(ApiClient api, String app) async {
    final token = await PushService.token();
    if (token == null) return;
    Future<void> send(String t) async {
      try {
        await api.dio.post('/devices', data: {'token': t, 'app': app});
      } catch (_) {
        // Non bloquant : la boîte de réception reste lue sur l'API.
      }
    }

    await send(token);
    PushService.onTokenRefresh(send);
  }

  static Future<void> unregister(ApiClient api) async {
    final token = await PushService.token();
    if (token == null) return;
    try {
      await api.dio.delete('/devices/${Uri.encodeComponent(token)}');
    } catch (_) {}
  }
}
