import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/models.dart';
import '../services/api_client.dart';
import '../services/services.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authServiceProvider =
    Provider<AuthService>((ref) => AuthService(ref.watch(apiClientProvider)));

final adminApiProvider =
    Provider<AdminApi>((ref) => AdminApi(ref.watch(apiClientProvider)));

final currentAdminProvider = StateProvider<AdminUser?>((ref) => null);

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  return ref.watch(adminApiProvider).stats();
});

final residencesProvider =
    FutureProvider.autoDispose<List<Residence>>((ref) async {
  return ref.watch(adminApiProvider).residences();
});

/// id → titre, pour nommer les logements des réservations (l'API ne porte que
/// l'identifiant).
final residenceTitlesProvider =
    FutureProvider.autoDispose<Map<String, String>>((ref) async {
  final list = await ref.watch(residencesProvider.future);
  return {for (final r in list) r.id: r.title};
});

final bookingFilterProvider = StateProvider<String?>((ref) => null);

final bookingsProvider = FutureProvider.autoDispose<Paged<Booking>>((ref) async {
  return ref
      .watch(adminApiProvider)
      .bookings(status: ref.watch(bookingFilterProvider));
});

final paymentFilterProvider = StateProvider<String?>((ref) => null);

final paymentsProvider = FutureProvider.autoDispose<Paged<Payment>>((ref) async {
  return ref
      .watch(adminApiProvider)
      .payments(status: ref.watch(paymentFilterProvider));
});

final reviewStateProvider = StateProvider<String>((ref) => 'pending');

final reviewsProvider = FutureProvider.autoDispose<Paged<Review>>((ref) async {
  return ref.watch(adminApiProvider).reviews(ref.watch(reviewStateProvider));
});

final contactsProvider =
    FutureProvider.autoDispose<Paged<ContactMessage>>((ref) async {
  return ref.watch(adminApiProvider).contacts();
});

final settingsProvider =
    FutureProvider.autoDispose<List<SettingItem>>((ref) async {
  return ref.watch(adminApiProvider).settings();
});

final staffProvider =
    FutureProvider.autoDispose<List<StaffMember>>((ref) async {
  return ref.watch(adminApiProvider).staff();
});

final tasksProvider =
    FutureProvider.autoDispose<List<CleaningTask>>((ref) async {
  return ref.watch(adminApiProvider).tasks();
});

final overviewProvider =
    FutureProvider.autoDispose<CleaningOverview>((ref) async {
  return ref.watch(adminApiProvider).overview();
});

final performancePeriodProvider = StateProvider<String>((ref) => '30d');

final performanceProvider =
    FutureProvider.autoDispose<List<PerformancePoint>>((ref) async {
  return ref
      .watch(adminApiProvider)
      .performance(ref.watch(performancePeriodProvider));
});

final staffStatsProvider =
    FutureProvider.autoDispose.family<StaffStats, String>((ref, id) async {
  return ref.watch(adminApiProvider).staffStats(id);
});
