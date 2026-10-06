import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/services.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(apiClientProvider)));

final dashboardServiceProvider = Provider<DashboardService>(
    (ref) => DashboardService(ref.watch(apiClientProvider)));

final staffServiceProvider = Provider<StaffService>(
    (ref) => StaffService(ref.watch(apiClientProvider)));

final cleaningServiceProvider = Provider<CleaningService>(
    (ref) => CleaningService(ref.watch(apiClientProvider)));

final currentAdminProvider = StateProvider<AdminUser?>((ref) => null);

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  return ref.watch(dashboardServiceProvider).stats();
});

final recentBookingsProvider =
    FutureProvider.autoDispose<List<BookingSummary>>((ref) async {
  return ref.watch(dashboardServiceProvider).recentBookings();
});

final staffListProvider =
    FutureProvider.autoDispose<List<StaffMember>>((ref) async {
  return ref.watch(staffServiceProvider).list();
});

final cleaningTasksProvider =
    FutureProvider.autoDispose<List<TaskSummary>>((ref) async {
  return ref.watch(cleaningServiceProvider).list();
});
