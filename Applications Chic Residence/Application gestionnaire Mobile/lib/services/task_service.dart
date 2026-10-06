import 'dart:io';

import 'package:dio/dio.dart';

import '../models/models.dart';
import 'api_client.dart';

class TaskService {
  TaskService(this._api);
  final ApiClient _api;

  Future<List<CleaningTask>> list({TaskStatus? status, int? assignedTo}) async {
    final res = await _api.dio.get('/cleaning-tasks', queryParameters: {
      if (status != null) 'status': status.apiValue,
      if (assignedTo != null) 'assigned_to': assignedTo,
    });
    final items = (res.data as List?) ?? [];
    return items
        .map((e) =>
            CleaningTask.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  Future<CleaningTask> detail(int id) async {
    final res = await _api.dio.get('/cleaning-tasks/$id');
    return CleaningTask.fromJson(
        (res.data as Map).cast<String, dynamic>());
  }

  Future<CleaningTask> start(int id) async {
    final res = await _api.dio.put('/cleaning-tasks/$id/start');
    return CleaningTask.fromJson(
        (res.data as Map).cast<String, dynamic>());
  }

  Future<CleaningTask> complete(int id) async {
    final res = await _api.dio.put('/cleaning-tasks/$id/complete');
    return CleaningTask.fromJson(
        (res.data as Map).cast<String, dynamic>());
  }

  Future<CleaningTask> validate(int id) async {
    final res = await _api.dio.put('/cleaning-tasks/$id/validate');
    return CleaningTask.fromJson(
        (res.data as Map).cast<String, dynamic>());
  }

  Future<CleaningTask> reject(int id, String reason) async {
    final res = await _api.dio
        .put('/cleaning-tasks/$id/reject', data: {'reason': reason});
    return CleaningTask.fromJson(
        (res.data as Map).cast<String, dynamic>());
  }

  Future<TaskPhoto> uploadPhoto(int taskId, File file,
      {required String phase}) async {
    final form = FormData.fromMap({
      'phase': phase,
      'file': await MultipartFile.fromFile(file.path),
    });
    final res =
        await _api.dio.post('/cleaning-tasks/$taskId/photos', data: form);
    return TaskPhoto.fromJson((res.data as Map).cast<String, dynamic>());
  }

  Future<StaffStats> myStats() async {
    final res = await _api.dio.get('/staff/stats');
    return StaffStats.fromJson((res.data as Map).cast<String, dynamic>());
  }
}
