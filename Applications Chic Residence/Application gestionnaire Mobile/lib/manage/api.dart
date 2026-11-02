import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../services/api_client.dart';
import 'models.dart';

/// Routes de gestion ouvertes au gérant (jeton staff de rôle `manager`) :
/// logements, calendrier, réservations, messages, fiches voyageurs. Même code
/// que l'API du backoffice ; le serveur refuse le reste (comptes, réglages,
/// nettoyage).
class AdminApi {
  AdminApi(this._api);
  final ApiClient _api;

  Dio get _d => _api.dio;

  Paged<T> _paged<T>(
      Response<dynamic> res, T Function(Map<String, dynamic>) parse) {
    final m = (res.data as Map).cast<String, dynamic>();
    final items = ((m['items'] as List?) ?? const [])
        .map((e) => parse((e as Map).cast<String, dynamic>()))
        .toList();
    return Paged(items, asInt(m['total']));
  }

  // ── Tableau de bord ──
  Future<DashboardStats> stats() async {
    final res = await _d.get('/stats/dashboard');
    return DashboardStats.fromJson((res.data as Map).cast<String, dynamic>());
  }

  // ── Logements ──
  Future<List<Residence>> residences() async {
    final res = await _d.get('/residences', queryParameters: {'limit': 100});
    return _paged(res, Residence.fromJson).items;
  }

  Future<Residence> residence(String id) async {
    final res = await _d.get('/residences/$id');
    return Residence.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<void> saveResidence(String? id, Map<String, dynamic> body) async {
    if (id == null) {
      await _d.post('/residences', data: body);
    } else {
      await _d.put('/residences/$id', data: body);
    }
  }

  Future<void> deleteResidence(String id) async {
    await _d.delete('/residences/$id');
  }

  Future<void> setResidenceStatus(String id, String status,
      {String? availableFrom, String note = ''}) async {
    await _d.patch('/residences/$id/status', data: {
      'availability_status': status,
      if (availableFrom != null) 'available_from': availableFrom,
      'status_note': note,
    });
  }

  Future<String> upload(XFile file) async {
    final name = file.name.contains('.') ? file.name : '${file.name}.jpg';
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: name),
    });
    final res = await _d.post('/upload', data: form);
    return (res.data as Map)['url'].toString();
  }

  /// Jours indisponibles sur une plage (366 jours au plus côté API).
  Future<Set<DateTime>> blockedDays(
      String id, DateTime start, DateTime end) async {
    String f(DateTime d) => d.toIso8601String().substring(0, 10);
    final res = await _d.get('/availability/$id',
        queryParameters: {'start': f(start), 'end': f(end)});
    return ((res.data as List?) ?? const [])
        .map((e) => (e as Map).cast<String, dynamic>())
        .where((e) => e['is_available'] == false)
        .map((e) {
      final d = DateTime.parse(e['date'].toString());
      return DateTime(d.year, d.month, d.day);
    }).toSet();
  }

  Future<void> setAvailability(
      String id, List<DateTime> dates, bool available) async {
    await _d.put('/availability/$id', data: {
      'dates': dates.map((d) => d.toIso8601String().substring(0, 10)).toList(),
      'is_available': available,
    });
  }

  // ── Réservations ──
  Future<Paged<Booking>> bookings({String? status, int limit = 100}) async {
    final res = await _d.get('/bookings', queryParameters: {
      'limit': limit,
      if (status != null) 'status': status,
    });
    return _paged(res, Booking.fromJson);
  }

  Future<void> setBookingStatus(String id, String status) async {
    await _d.put('/bookings/$id/status', data: {'status': status});
  }

  // ── Paiements ──
  Future<Paged<Payment>> payments({String? status}) async {
    final res = await _d.get('/payments', queryParameters: {
      'limit': 100,
      if (status != null) 'status': status,
    });
    return _paged(res, Payment.fromJson);
  }

  // ── Avis ──
  Future<Paged<Review>> reviews(String state) async {
    final res = await _d.get('/reviews/moderation',
        queryParameters: {'state': state, 'limit': 100});
    return _paged(res, Review.fromJson);
  }

  Future<void> moderateReview(String id, bool approved) async {
    await _d.put('/reviews/$id/moderate', data: {'is_approved': approved});
  }

  Future<void> deleteReview(String id) async {
    await _d.delete('/reviews/$id');
  }

  // ── Messages ──
  Future<Paged<ContactMessage>> contacts() async {
    final res = await _d.get('/contact', queryParameters: {'limit': 100});
    return _paged(res, ContactMessage.fromJson);
  }

  Future<void> markRead(String id) async {
    await _d.put('/contact/$id/read');
  }

  // ── Paramètres ──
  Future<List<SettingItem>> settings() async {
    final res = await _d.get('/settings');
    return ((res.data as List?) ?? const [])
        .map((e) => SettingItem.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> saveSetting(String key, String value) async {
    await _d.put('/settings/$key', data: {'value': value});
  }

  // ── Personnel ──
  Future<List<StaffMember>> staff() async {
    final res = await _d.get('/staff');
    return ((res.data as List?) ?? const [])
        .map((e) => StaffMember.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> createStaff({
    required String fullName,
    required String phone,
    required String pin,
    required StaffRole role,
  }) async {
    await _d.post('/staff', data: {
      'full_name': fullName,
      'phone': phone,
      'pin': pin,
      'role': role.name,
    });
  }

  Future<void> updateStaff(String id, Map<String, dynamic> body) async {
    await _d.put('/staff/$id', data: body);
  }

  Future<StaffStats> staffStats(String id) async {
    final res = await _d.get('/staff/stats/$id');
    return StaffStats.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<CleaningOverview> overview() async {
    final res = await _d.get('/staff/stats/overview');
    return CleaningOverview.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<List<PerformancePoint>> performance(String period) async {
    final res = await _d.get('/staff/stats/performance',
        queryParameters: {'period': period});
    return (((res.data as Map)['points'] as List?) ?? const [])
        .map((e) =>
            PerformancePoint.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  // ── Tâches ──
  Future<List<CleaningTask>> tasks() async {
    final res = await _d.get('/cleaning-tasks');
    return ((res.data as List?) ?? const [])
        .map((e) => CleaningTask.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<void> createTask({
    required String residenceId,
    String? agentId,
    String? controllerId,
    String? nextCheckIn,
    String notes = '',
  }) async {
    await _d.post('/cleaning-tasks', data: {
      'residence_id': residenceId,
      if (agentId != null) 'assigned_agent_id': agentId,
      if (controllerId != null) 'assigned_controller_id': controllerId,
      if (nextCheckIn != null) 'next_checkin': nextCheckIn,
      'notes': notes,
    });
  }

  Future<void> assignTask(String id,
      {String? agentId, String? controllerId}) async {
    await _d.put('/cleaning-tasks/$id/assign', data: {
      if (agentId != null) 'assigned_agent_id': agentId,
      if (controllerId != null) 'assigned_controller_id': controllerId,
    });
  }

  Future<void> forceValidate(String id) async {
    await _d.put('/cleaning-tasks/$id/force-validate');
  }

  Future<void> deleteTask(String id) async {
    await _d.delete('/cleaning-tasks/$id');
  }


  // ── Fiches voyageurs ──
  Future<List<GuestIdentity>> guests({String? q, String? bookingId}) async {
    final res = await _d.get('/guests', queryParameters: {
      if (q != null && q.isNotEmpty) 'q': q,
      if (bookingId != null) 'booking_id': bookingId,
    });
    return ((res.data as List?) ?? const [])
        .map((e) => GuestIdentity.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<GuestIdentity> saveGuest(String? id, Map<String, dynamic> body) async {
    final res = id == null
        ? await _d.post('/guests', data: body)
        : await _d.put('/guests/$id', data: body);
    return GuestIdentity.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<GuestIdentity> uploadGuestPhoto(
      String id, String face, XFile file) async {
    final name = file.name.contains('.') ? file.name : '${file.name}.jpg';
    final lower = name.toLowerCase();
    final type = lower.endsWith('.png')
        ? 'png'
        : lower.endsWith('.webp')
            ? 'webp'
            : 'jpeg';
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path,
          filename: name, contentType: DioMediaType('image', type)),
    });
    final res = await _d.post('/guests/$id/photos/$face', data: form);
    return GuestIdentity.fromJson((res.data as Map).cast<String, dynamic>());
  }

  /// Les photos de pièce ne sont servies qu'avec le jeton : on les lit par Dio,
  /// jamais par une URL d'image.
  Future<List<int>> guestPhoto(String id, String face) async {
    final res = await _d.get<List<int>>('/guests/$id/photos/$face',
        options: Options(responseType: ResponseType.bytes));
    return res.data ?? const [];
  }

  Future<void> deleteGuest(String id) async {
    await _d.delete('/guests/$id');
  }
}
