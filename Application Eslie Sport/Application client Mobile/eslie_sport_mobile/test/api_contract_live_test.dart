/// Verifie, contre la VRAIE API, que chaque route consommee par l'application
/// repond et que sa reponse se lit avec les modeles Dart.
///
///   flutter test test/api_contract_live_test.dart --tags live
///   flutter test test/api_contract_live_test.dart --dart-define=API_ENV=local
///
/// ⚠️ Aucune ecriture : les POST sont envoyes volontairement invalides, pour
/// verifier le contrat sans creer de reservation au back-office ni ouvrir de
/// paiement.
@Tags(['live'])
library;

import 'package:dio/dio.dart';
import 'package:eslie_sport_mobile/config/api_config.dart';
import 'package:eslie_sport_mobile/services/api_client.dart';
import 'package:eslie_sport_mobile/services/payment_service.dart';
import 'package:eslie_sport_mobile/models/payment.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final api = ApiClient();
  const uuidInconnu = '00000000-0000-4000-8000-000000000000';

  test('GET /health', () async {
    expect(await api.ping(), isTrue);
  });

  test('catalogue : activites, filtres et fiche', () async {
    final all = await api.getActivities();
    expect(all, isNotEmpty);
    final first = all.first;
    expect((await api.getActivityBySlug(first.slug))?.id, first.id);
    expect(await api.getActivityBySlug('slug-inexistant'), isNull);

    final parCategorie = await api.getActivities(category: first.category);
    expect(parCategorie, isNotEmpty,
        reason: 'le filtre doit utiliser les valeurs stockees par le back-office');
  });

  test('toutes les categories proposees par l\'app existent en base', () async {
    const proposees = {'force', 'cardio', 'martial_arts', 'flexibility'};
    final categories = (await api.getActivities()).map((a) => a.category).toSet();
    expect(categories.difference(proposees), isEmpty);
  });

  test('planning, activite imbriquee et places restantes', () async {
    final slots = await api.getSchedule();
    expect(slots, isNotEmpty);
    expect(slots.first.activity, isNotNull);
    expect(slots.every((s) => s.dayOfWeek >= 0 && s.dayOfWeek <= 6), isTrue);
    expect(await api.getWeeklySchedule(), isNotEmpty);

    final a = await api.getSlotAvailability(slots.first.id,
        specificDate: DateTime.now().add(const Duration(days: 1)));
    expect(a['available'], isA<num>());
  });

  test('formules, dont celles qui portent le tarif de l\'acompte', () async {
    final list = await api.getSubscriptions();
    final names = list.map((s) => s.name).toSet();
    expect(names, containsAll(<String>[
      'Mensualite',
      'Seance individuelle / collective',
      'Kung-Fu Wushu — Mensuel',
      'Boxe & Kick Boxing — Mensuel',
    ]));
  });

  test('contenus : coachs, equipements, articles, videos, avis, avant/apres',
      () async {
    final coaches = await api.getCoaches();
    expect(coaches, isNotEmpty);
    expect((await api.getCoachById(coaches.first.id))?.id, coaches.first.id);
    expect(await api.getEquipment(), isNotEmpty);
    final articles = await api.getArticles();
    expect(articles, isNotEmpty);
    expect(await api.getArticleBySlug(articles.first.slug), isNotNull);
    await api.getVideos();
    await api.getReviews();
    await api.getTransformations();
    await api.getTransformations(featuredOnly: true);
  });

  test('parametres du back-office', () async {
    final s = await api.getPublicSettings();
    expect(s.gymName, isNotEmpty);
    expect(s.phone, isNotNull);
  });

  test('moyens de paiement : tous reconnus par l\'application', () async {
    final raw = await api.getPaymentConfig();
    final config = PaymentConfig.fromJson(raw);
    expect(config.enabled, isTrue);
    expect(config.depositRate, 0.5);
    expect(config.operators.length, config.methods.length);
    for (final op in config.operators) {
      expect(op.logoAsset != null || op.isCard, isTrue, reason: op.code);
    }
  });

  test('images du catalogue accessibles', () async {
    final dio = Dio();
    final activities = await api.getActivities();
    for (final a in activities) {
      final r = await dio.head<void>(a.imageUrl!);
      expect(r.statusCode, 200, reason: a.imageUrl);
    }
  });

  group('POST sans effet de bord', () {
    Future<int?> statusOf(Future<void> Function() call) async {
      try {
        await call();
        return null;
      } on ApiException catch (e) {
        return e.statusCode;
      }
    }

    test('POST /payments/init : paiement d\'un objet inconnu -> 404', () async {
      final status = await statusOf(() => api.initPayment(
            enrollmentId: uuidInconnu,
            operator: PaymentOperator.wave,
          ));
      expect(status, 404);
    });

    test('GET et cancel d\'une reference inconnue -> 404', () async {
      expect(await statusOf(() => api.getPaymentStatus('ESLIE-INCONNUE00')), 404);
      expect(await statusOf(() => api.cancelPayment('ESLIE-INCONNUE00')), 404);
      expect(await statusOf(() => api.resendPush('ESLIE-INCONNUE00')), 404);
    });

    test('POST /subscriptions/orders : formule inconnue -> 404', () async {
      final status = await statusOf(() => api.createSubscriptionOrder(
            subscriptionId: uuidInconnu,
            userName: 'Test contrat',
            userWhatsapp: '+2250700000000',
          ));
      expect(status, 404);
    });

    test('POST /enrollments, /contact, /reviews : corps invalide -> 422',
        () async {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.apiBase,
        validateStatus: (_) => true,
      ));
      for (final path in ['/enrollments/', '/contact/', '/reviews/']) {
        final r = await dio.post<dynamic>(path, data: const {});
        expect(r.statusCode, 422, reason: path);
      }
    });

    test('les routes d\'administration refusent sans jeton', () async {
      final dio = Dio(BaseOptions(
        baseUrl: ApiConfig.apiBase,
        validateStatus: (_) => true,
      ));
      for (final path in [
        '/enrollments/',
        '/subscriptions/orders',
        '/payments/',
        '/contact/',
        '/reviews/all',
        '/stats/',
      ]) {
        final r = await dio.get<dynamic>(path);
        expect(r.statusCode, anyOf(401, 403), reason: path);
      }
    });
  });
}
