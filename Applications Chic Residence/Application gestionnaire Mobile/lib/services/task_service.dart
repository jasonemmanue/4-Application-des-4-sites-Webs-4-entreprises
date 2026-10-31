import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../models/models.dart';
import 'api_client.dart';

class TaskService {
  TaskService(this._api);
  final ApiClient _api;

  Future<List<CleaningTask>> all() async {
    final res = await _api.dio.get('/cleaning-tasks');
    return ((res.data as List?) ?? const [])
        .map((e) => CleaningTask.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  CleaningTask _one(Response<dynamic> res) =>
      CleaningTask.fromJson((res.data as Map).cast<String, dynamic>());

  Future<CleaningTask> detail(String id) async =>
      _one(await _api.dio.get('/cleaning-tasks/$id'));

  Future<CleaningTask> start(String id) async =>
      _one(await _api.dio.put('/cleaning-tasks/$id/start'));

  Future<CleaningTask> complete(String id) async =>
      _one(await _api.dio.put('/cleaning-tasks/$id/complete'));

  Future<CleaningTask> validate(String id) async =>
      _one(await _api.dio.put('/cleaning-tasks/$id/validate'));

  Future<CleaningTask> reject(String id, String reason) async => _one(
      await _api.dio.put('/cleaning-tasks/$id/reject', data: {'reason': reason}));

  /// `label` est un paramètre de requête : before, after ou rejection.
  Future<void> uploadPhoto(String taskId, XFile file,
      {required String label}) async {
    final name = file.name.contains('.') ? file.name : '${file.name}.jpg';
    final form = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: name),
    });
    await _api.dio.post(
      '/cleaning-tasks/$taskId/photos',
      queryParameters: {'label': label},
      data: form,
    );
  }

  Future<StaffStats> myStats() async {
    final res = await _api.dio.get('/staff/stats/me');
    return StaffStats.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
