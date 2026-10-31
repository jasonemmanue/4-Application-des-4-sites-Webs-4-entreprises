import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/task_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(apiClientProvider)));

final taskServiceProvider =
    Provider<TaskService>((ref) => TaskService(ref.watch(apiClientProvider)));

final currentUserProvider = StateProvider<StaffUser?>((ref) => null);

final tasksFilterProvider = StateProvider<TaskStatus?>((ref) => null);

/// Les tâches qui concernent ce compte.
///
/// - **Agent** : les siennes, plus celles sans agent (démarrer se les attribue).
/// - **Contrôleur** : les nettoyages à contrôler, plus ce qu'il a déjà contrôlé.
///   `mine=true` de l'API ne suffit pas : une tâche sans contrôleur assigné
///   resterait invisible de tous, alors que valider se l'attribue aussi.
final myTasksProvider =
    FutureProvider.autoDispose<List<CleaningTask>>((ref) async {
  final user = ref.watch(currentUserProvider);
  final all = await ref.watch(taskServiceProvider).all();
  if (user == null) return const [];
  return all.where((t) {
    if (user.role == StaffRole.agent) {
      return t.agentId == user.id ||
          (t.agentId == null && t.status == TaskStatus.pending);
    }
    return t.status == TaskStatus.cleaned || t.controllerId == user.id;
  }).toList();
});

final taskDetailProvider =
    FutureProvider.autoDispose.family<CleaningTask, String>((ref, id) async {
  return ref.watch(taskServiceProvider).detail(id);
});

final myStatsProvider = FutureProvider.autoDispose<StaffStats>((ref) async {
  return ref.watch(taskServiceProvider).myStats();
});
