import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider = Provider<AuthService>((ref) {
  final api = ref.watch(apiClientProvider);
  return AuthService(api);
});

final taskServiceProvider = Provider<TaskService>(
    (ref) => TaskService(ref.watch(apiClientProvider)));

final currentUserProvider = StateProvider<StaffUser?>((ref) => null);

final tasksFilterProvider = StateProvider<TaskStatus?>((ref) => null);

final tasksProvider = FutureProvider.autoDispose<List<CleaningTask>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final filter = ref.watch(tasksFilterProvider);
  final svc = ref.watch(taskServiceProvider);
  return svc.list(
    status: filter,
    assignedTo: user?.role == StaffRole.agent ? user!.id : null,
  );
});

final myStatsProvider = FutureProvider.autoDispose<StaffStats>((ref) async {
  return ref.watch(taskServiceProvider).myStats();
});
