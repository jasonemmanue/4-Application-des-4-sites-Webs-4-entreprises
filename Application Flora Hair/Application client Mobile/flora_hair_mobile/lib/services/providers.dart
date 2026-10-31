import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../models/category.dart';
import '../models/gallery_item.dart';
import '../models/review.dart';
import '../models/service.dart';
import '../models/team_member.dart';
import '../models/video.dart';
import 'api_client.dart';

final servicesProvider = FutureProvider<List<Service>>((ref) async {
  return ref.watch(apiClientProvider).fetchServices();
});

final categoriesProvider = FutureProvider<List<Category>>((ref) async {
  return ref.watch(apiClientProvider).fetchCategories();
});

final teamProvider = FutureProvider<List<TeamMember>>((ref) async {
  return ref.watch(apiClientProvider).fetchTeam();
});

final galleryProvider = FutureProvider<List<GalleryItem>>((ref) async {
  return ref.watch(apiClientProvider).fetchGallery();
});

final articlesProvider = FutureProvider<List<Article>>((ref) async {
  return ref.watch(apiClientProvider).fetchArticles();
});

final videosProvider = FutureProvider<List<Video>>((ref) async {
  return ref.watch(apiClientProvider).fetchVideos();
});

final reviewsProvider = FutureProvider<List<Review>>((ref) async {
  return ref.watch(apiClientProvider).fetchReviews();
});

final serviceDetailProvider =
    FutureProvider.family<Service, String>((ref, slug) async {
  return ref.watch(apiClientProvider).fetchServiceBySlug(slug);
});

final articleDetailProvider =
    FutureProvider.family<Article, String>((ref, slug) async {
  return ref.watch(apiClientProvider).fetchArticleBySlug(slug);
});

/// Catégorie filtrée sur l'écran Prestations — posée aussi depuis l'accueil.
final selectedCategoryProvider = StateProvider<String?>((_) => null);

/// Note moyenne réelle du salon, sur les avis approuvés dans l'administration.
final salonRatingProvider = Provider<({double average, int count})?>((ref) {
  final reviews = ref.watch(reviewsProvider).valueOrNull ?? const <Review>[];
  if (reviews.isEmpty) return null;
  final total = reviews.fold<int>(0, (sum, r) => sum + r.rating);
  return (average: total / reviews.length, count: reviews.length);
});
