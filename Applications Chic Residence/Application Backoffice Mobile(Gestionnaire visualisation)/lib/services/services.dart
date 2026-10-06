import '../models/models.dart';
import 'api_client.dart';

class AuthService {
  AuthService(this._api);
  final ApiClient _api;
  AdminUser? current;

  Future<AdminUser> login(String email, String password) async {
    final res = await _api.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = (res.data as Map).cast<String, dynamic>();
    await _api.setToken(data['token'].toString());
    current = AdminUser.fromJson((data['user'] as Map).cast<String, dynamic>());
    return current!;
  }

  Future<AdminUser?> restore() async {
    final t = await _api.readToken();
    if (t == null || t.isEmpty) return null;
    try {
      final res = await _api.dio.get('/auth/me');
      current = AdminUser.fromJson(
          (res.data as Map).cast<String, dynamic>());
      return current;
    } catch (_) {
      await _api.clearToken();
      return null;
    }
  }

  Future<void> logout() async {
    current = null;
    await _api.clearToken();
  }
}

class DashboardService {
  DashboardService(this._api);
  final ApiClient _api;

  Future<DashboardStats> stats() async {
    final res = await _api.dio.get('/stats/dashboard');
    return DashboardStats.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<List<BookingSummary>> recentBookings() async {
    final res = await _api.dio
        .get('/bookings', queryParameters: {'limit': 10, 'sort': '-created_at'});
    final data = res.data;
    final items = (data is Map ? data['items'] : data) as List? ?? [];
    return items
        .map((e) =>
            BookingSummary.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }
}

class StaffService {
  StaffService(this._api);
  final ApiClient _api;

  Future<List<StaffMember>> list() async {
    final res = await _api.dio.get('/staff');
    final items = (res.data as List?) ?? [];
    return items
        .map((e) => StaffMember.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<StaffMember> create({
    required String fullName,
    required String phone,
    required String pin,
    required StaffRole role,
  }) async {
    final res = await _api.dio.post('/staff', data: {
      'full_name': fullName,
      'phone': phone,
      'pin': pin,
      'role': role.name,
    });
    return StaffMember.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> deactivate(int id) async {
    await _api.dio.delete('/staff/$id');
  }
}

class CleaningService {
  CleaningService(this._api);
  final ApiClient _api;

  Future<List<TaskSummary>> list({TaskStatus? status}) async {
    final res = await _api.dio.get('/cleaning-tasks',
        queryParameters: status == null ? null : {'status': status.apiValue});
    final items = (res.data as List?) ?? [];
    return items
        .map((e) =>
            TaskSummary.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> assign(int id, int staffId) async {
    await _api.dio.put('/cleaning-tasks/$id/assign', data: {'staff_id': staffId});
  }

  Future<void> forceValidate(int id) async {
    await _api.dio.put('/cleaning-tasks/$id/force-validate');
  }

  Future<void> delete(int id) async {
    await _api.dio.delete('/cleaning-tasks/$id');
  }
}
