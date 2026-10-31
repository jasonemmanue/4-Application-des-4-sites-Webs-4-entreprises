// Parse les vraies réponses de production dans les modèles de l'app :
//   flutter test test/api_contract_live_test.dart --dart-define=LIVE_API=true
import 'package:flutter_test/flutter_test.dart';
import 'package:ruah_statistics_mobile/models/article.dart';
import 'package:ruah_statistics_mobile/services/api_client.dart';

const bool _live = bool.fromEnvironment('LIVE_API');

void main() {
  final api = ApiClient();
  const Object? skip = _live ? null : 'Passer --dart-define=LIVE_API=true';

  test('services et detail', () async {
    final items = await api.fetchServices();
    expect(items, isNotEmpty);
    expect((await api.fetchServiceBySlug(items.first.slug)).id, items.first.id);
  }, skip: skip);

  test('projets et detail', () async {
    final page = await api.fetchProjects();
    expect(page.items, isNotEmpty);
    expect((await api.fetchProjectBySlug(page.items.first.slug)).id,
        page.items.first.id);
  }, skip: skip);

  test('articles : le filtre de type est applique', () async {
    final all = await api.fetchArticles();
    final white = await api.fetchArticles(type: ArticleType.whitepaper);
    expect(white.items, isNotEmpty);
    expect(white.items.every((a) => a.isWhitepaper), isTrue);
    expect(white.items.length, lessThan(all.items.length));
    expect((await api.fetchArticleBySlug(all.items.first.slug)).id,
        all.items.first.id);
  }, skip: skip);

  test('equipe, videos, temoignages, partenaires, chiffres cles', () async {
    expect(await api.fetchTeam(), isNotEmpty);
    expect(await api.fetchVideos(), isNotEmpty);
    expect(await api.fetchTestimonials(), isNotEmpty);
    expect(await api.fetchPartners(), isNotEmpty);
    expect(await api.fetchKeyFigures(), isNotEmpty);
  }, skip: skip);
}
