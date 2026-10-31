import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import 'api_client.dart';

/// Connexion du personnel : téléphone + PIN (`POST /staff/login`).
class AuthService {
  AuthService(this._api);
  final ApiClient _api;
  final _storage = const FlutterSecureStorage();

  StaffUser? currentUser;

  /// Reprend la session : le profil est relu sur l'API, un compte désactivé
  /// entre-temps ne reste donc pas connecté.
  Future<StaffUser?> restore() async {
    final token = await _storage.read(key: ApiConfig.tokenKey);
    if (token == null || token.isEmpty) return null;
    _api.setToken(token);
    try {
      final res = await _api.dio.get('/staff/me');
      currentUser =
          StaffUser.fromJson((res.data as Map).cast<String, dynamic>());
      return currentUser;
    } catch (_) {
      await logout();
      return null;
    }
  }

  Future<StaffUser> login({required String phone, required String pin}) async {
    final res = await _api.dio
        .post('/staff/login', data: {'phone': phone, 'pin': pin});
    final data = (res.data as Map).cast<String, dynamic>();
    final token = data['access_token'].toString();
    _api.setToken(token);
    await _storage.write(key: ApiConfig.tokenKey, value: token);
    currentUser =
        StaffUser.fromJson((data['staff'] as Map).cast<String, dynamic>());
    return currentUser!;
  }

  Future<void> logout() async {
    currentUser = null;
    _api.setToken(null);
    await _storage.delete(key: ApiConfig.tokenKey);
  }

  Future<void> registerFcmToken(String token) async {
    try {
      await _api.dio.put('/staff/me/fcm-token', data: {'fcm_token': token});
    } catch (_) {
      // Non bloquant.
    }
  }
}
