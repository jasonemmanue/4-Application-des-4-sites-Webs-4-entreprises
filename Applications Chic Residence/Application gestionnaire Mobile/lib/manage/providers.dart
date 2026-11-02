import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/providers.dart' show apiClientProvider;
import 'api.dart';
import 'models.dart';

final adminApiProvider =
    Provider<AdminApi>((ref) => AdminApi(ref.watch(apiClientProvider)));

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats>((ref) async {
  return ref.watch(adminApiProvider).stats();
});

final residencesProvider =
    FutureProvider.autoDispose<List<Residence>>((ref) async {
  return ref.watch(adminApiProvider).residences();
});

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

final contactsProvider =
    FutureProvider.autoDispose<Paged<ContactMessage>>((ref) async {
  return ref.watch(adminApiProvider).contacts();
});
