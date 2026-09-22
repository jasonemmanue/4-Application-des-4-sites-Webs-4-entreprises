import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/article.dart';
import '../models/key_figure.dart';
import '../models/partner.dart';
import '../models/project.dart';
import '../models/service.dart';
import '../models/team_member.dart';
import '../models/testimonial.dart';
import '../models/video.dart';
import '../services/api_client.dart';
import '../services/whatsapp_service.dart';

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
final whatsAppServiceProvider =
    Provider<WhatsAppService>((ref) => const WhatsAppService());

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);

final servicesProvider = FutureProvider<List<Service>>((ref) async {
  return ref.watch(apiClientProvider).fetchServices();
});

final serviceDetailProvider =
    FutureProvider.family<Service, String>((ref, slug) async {
  return ref.watch(apiClientProvider).fetchServiceBySlug(slug);
});

class ProjectFilter {
  final int page;
  final String? sector;
  final String? country;
  final int? year;

  const ProjectFilter({
    this.page = 1,
    this.sector,
    this.country,
    this.year,
  });

  ProjectFilter copyWith({
    int? page,
    Object? sector = _sentinel,
    Object? country = _sentinel,
    Object? year = _sentinel,
  }) {
    return ProjectFilter(
      page: page ?? this.page,
      sector: sector == _sentinel ? this.sector : sector as String?,
      country: country == _sentinel ? this.country : country as String?,
      year: year == _sentinel ? this.year : year as int?,
    );
  }

  static const Object _sentinel = Object();

  @override
  bool operator ==(Object other) =>
      other is ProjectFilter &&
      other.page == page &&
      other.sector == sector &&
      other.country == country &&
      other.year == year;

  @override
  int get hashCode => Object.hash(page, sector, country, year);
}

final projectFilterProvider =
    StateProvider<ProjectFilter>((ref) => const ProjectFilter());

final projectsProvider =
    FutureProvider.family<PagedResult<Project>, ProjectFilter>(
        (ref, filter) async {
  return ref.watch(apiClientProvider).fetchProjects(
        page: filter.page,
        sector: filter.sector,
        country: filter.country,
        year: filter.year,
      );
});

final projectDetailProvider =
    FutureProvider.family<Project, String>((ref, slug) async {
  return ref.watch(apiClientProvider).fetchProjectBySlug(slug);
});

final teamProvider = FutureProvider<List<TeamMember>>((ref) async {
  return ref.watch(apiClientProvider).fetchTeam();
});

final teamMemberProvider =
    FutureProvider.family<TeamMember?, String>((ref, id) async {
  return ref.watch(apiClientProvider).fetchTeamMember(id);
});

final articleTypeFilterProvider = StateProvider<ArticleType?>((ref) => null);

final articlesProvider =
    FutureProvider.family<PagedResult<Article>, ArticleType?>(
        (ref, type) async {
  return ref.watch(apiClientProvider).fetchArticles(type: type);
});

final articleDetailProvider =
    FutureProvider.family<Article, String>((ref, slug) async {
  return ref.watch(apiClientProvider).fetchArticleBySlug(slug);
});

final videosProvider = FutureProvider<List<Video>>((ref) async {
  return ref.watch(apiClientProvider).fetchVideos();
});

final testimonialsProvider = FutureProvider<List<Testimonial>>((ref) async {
  return ref.watch(apiClientProvider).fetchTestimonials();
});

final partnersProvider = FutureProvider<List<Partner>>((ref) async {
  return ref.watch(apiClientProvider).fetchPartners();
});

final keyFiguresProvider = FutureProvider<List<KeyFigure>>((ref) async {
  return ref.watch(apiClientProvider).fetchKeyFigures();
});
