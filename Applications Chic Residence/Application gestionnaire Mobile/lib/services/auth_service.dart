import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../config/api_config.dart';
import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._api);
  final ApiClient _api;
  final _storage = const FlutterSecureStorage();

  StaffUser? currentUser;
  String? _token;

  String? get token => _token;

  Future<void> restore() async {
    _token = await _storage.read(key: ApiConfig.tokenKey);
    _api.setToken(_token);
    final userJson = await _storage.read(key: ApiConfig.userKey);
    if (userJson != null) {
      try {
        currentUser =
            StaffUser.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
      } catch (_) {}
    }
  }

  Future<StaffUser> login({required String phone, required String pin}) async {
    final res = await _api.dio
        .post('/staff/login', data: {'phone': phone, 'pin': pin});
    final data = (res.data as Map).cast<String, dynamic>();
    _token = data['token']?.toString();
    _api.setToken(_token);
    if (_token != null) {
      await _storage.write(key: ApiConfig.tokenKey, value: _token);
    }
    final user = StaffUser.fromJson(
        (data['user'] as Map).cast<String, dynamic>());
    currentUser = user;
    await _storage.write(
      key: ApiConfig.userKey,
      value: jsonEncode({
        'id': user.id,
        'phone': user.phone,
        'full_name': user.fullName,
        'role': user.role.name,
        'active': user.active,
      }),
    );
    return user;
  }

  Future<void> logout() async {
    _token = null;
    currentUser = null;
    _api.setToken(null);
    await _storage.delete(key: ApiConfig.tokenKey);
    await _storage.delete(key: ApiConfig.userKey);
  }

  Future<void> registerFcmToken(String token) async {
    try {
      await _api.dio.put('/staff/me/fcm-token', data: {'token': token});
    } catch (_) {
      // ignore silently — non bloquant
    }
  }
}
