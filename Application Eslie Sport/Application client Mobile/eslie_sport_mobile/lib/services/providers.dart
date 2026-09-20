/// Providers Riverpod pour exposer l'API aux ecrans.
///
/// On garde une famille par ressource, avec quelques variantes filtrables
/// (activites par categorie/niveau, videos par categorie, transformations
/// vedettes). Les providers sont delibrement `FutureProvider` : les ecrans
/// utilisent `ref.invalidate` pour rafraichir a la demande (pull-to-refresh).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity.dart';
import '../models/article.dart';
import '../models/coach.dart';
import '../models/equipment.dart';
import '../models/public_settings.dart';
import '../models/review.dart';
import '../models/schedule_slot.dart';
import '../models/subscription.dart';
import '../models/transformation.dart';
import '../models/video.dart';
import 'api_client.dart';

typedef ActivityFilter = ({String? category, String? level});

final activitiesProvider =
    FutureProvider.family<List<Activity>, ActivityFilter>((ref, params) {
  final api = ref.watch(apiClientProvider);
  return api.getActivities(category: params.category, level: params.level);
});

final activityBySlugProvider =
    FutureProvider.family<Activity?, String>((ref, slug) {
  return ref.watch(apiClientProvider).getActivityBySlug(slug);
});

final scheduleProvider = FutureProvider<List<ScheduleSlot>>((ref) {
  return ref.watch(apiClientProvider).getSchedule();
});

final subscriptionsProvider = FutureProvider<List<Subscription>>((ref) {
  return ref.watch(apiClientProvider).getSubscriptions();
});

final coachesProvider = FutureProvider<List<Coach>>((ref) {
  return ref.watch(apiClientProvider).getCoaches();
});

final coachByIdProvider =
    FutureProvider.family<Coach?, String>((ref, id) {
  return ref.watch(apiClientProvider).getCoachById(id);
});

final equipmentProvider = FutureProvider<List<Equipment>>((ref) {
  return ref.watch(apiClientProvider).getEquipment();
});

final equipmentByZoneProvider =
    FutureProvider.family<List<Equipment>, String>((ref, zone) {
  return ref.watch(apiClientProvider).getEquipment(zone: zone);
});

final articlesProvider = FutureProvider<List<Article>>((ref) {
  return ref.watch(apiClientProvider).getArticles();
});

final articleBySlugProvider =
    FutureProvider.family<Article?, String>((ref, slug) {
  return ref.watch(apiClientProvider).getArticleBySlug(slug);
});

final videosProvider = FutureProvider<List<Video>>((ref) {
  return ref.watch(apiClientProvider).getVideos();
});

final videosByCategoryProvider =
    FutureProvider.family<List<Video>, String>((ref, category) {
  return ref.watch(apiClientProvider).getVideos(category: category);
});

final transformationsProvider = FutureProvider<List<Transformation>>((ref) {
  return ref.watch(apiClientProvider).getTransformations();
});

final featuredTransformationsProvider =
    FutureProvider<List<Transformation>>((ref) {
  return ref.watch(apiClientProvider).getTransformations(featuredOnly: true);
});

final reviewsProvider = FutureProvider<List<Review>>((ref) {
  return ref.watch(apiClientProvider).getReviews();
});

final publicSettingsProvider = FutureProvider<PublicSettings>((ref) {
  return ref.watch(apiClientProvider).getPublicSettings();
});

final paymentConfigProvider =
    FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(apiClientProvider).getPaymentConfig();
});

final apiHealthProvider = FutureProvider<bool>((ref) {
  return ref.watch(apiClientProvider).ping();
});
