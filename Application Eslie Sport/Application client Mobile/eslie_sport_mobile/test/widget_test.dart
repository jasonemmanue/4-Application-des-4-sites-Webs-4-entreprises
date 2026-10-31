import 'package:eslie_sport_mobile/models/enrollment.dart';
import 'package:eslie_sport_mobile/models/payment.dart';
import 'package:eslie_sport_mobile/models/public_settings.dart';
import 'package:eslie_sport_mobile/models/video.dart';
import 'package:eslie_sport_mobile/services/api_client.dart';
import 'package:eslie_sport_mobile/services/payment_service.dart';
import 'package:eslie_sport_mobile/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = PaymentService(ApiClient());

  group('numero de paiement (aligne sur le backend)', () {
    test('Orange accepte 07, 08, 09', () {
      for (final n in ['0707123456', '0807123456', '0907123456']) {
        expect(service.phoneError(PaymentOperator.orangeMoney, n), isNull);
      }
      expect(service.phoneError(PaymentOperator.orangeMoney, '0507123456'),
          isNotNull);
    });

    test('MTN accepte 05, 06, 04', () {
      for (final n in ['0505123456', '0605123456', '0405123456']) {
        expect(service.phoneError(PaymentOperator.mtnMobileMoney, n), isNull);
      }
      expect(service.phoneError(PaymentOperator.mtnMobileMoney, '0705123456'),
          isNotNull);
    });

    test('Wave accepte tout numero a 10 chiffres, pas moins', () {
      expect(service.phoneError(PaymentOperator.wave, '0107123456'), isNull);
      expect(service.phoneError(PaymentOperator.wave, '12345'), isNotNull);
    });

    test('normalisation au format international', () {
      expect(service.normalizePhone('07 07 12 34 56'), '+2250707123456');
      expect(service.normalizePhone('+225 0707123456'), '+2250707123456');
      expect(service.normalizePhone('002250707123456'), '+2250707123456');
    });
  });

  group('contrat API', () {
    test('les codes de moyen correspondent a PaymentMethod', () {
      expect(PaymentOperator.values.map((o) => o.code), [
        'wave',
        'orange_money',
        'mtn_mobile_money',
        'card',
        'stripe',
      ]);
    });

    test('la reservation envoie la formule, dont depend l\'acompte', () {
      final json = EnrollmentRequest(
        userName: 'Test',
        userWhatsapp: '+2250707123456',
        slotId: 'slot',
        specificDate: DateTime(2026, 11, 2),
        sessionType: 'Collectif',
        paymentType: EnrollmentFormula.session.apiValue,
      ).toJson();
      expect(json['payment_type'], 'Séance');
      expect(json['session_type'], 'Collectif');
      expect(json['specific_date'], '2026-11-02');
    });

    test('opening_hours est une chaine, pas une map', () {
      final s = PublicSettings.fromJson({
        'gym_name': 'ESLIE SPORT',
        'phone': '+225 0545079850',
        'opening_hours': 'Lundi - Dimanche : 07h - 20h',
        'facebook_url': '',
      });
      expect(s.openingHours, 'Lundi - Dimanche : 07h - 20h');
      expect(s.whatsappDigits, '2250545079850');
    });

    test('une video sans fichier heberge n\'est pas lisible', () {
      Video video(String url) => Video.fromJson(
          {'id': '1', 'title': 'T', 'video_url': url});
      expect(video('musculation-demo.mp4').isPlayable, isFalse);
      expect(video('/uploads/a.mp4').isPlayable, isTrue);
      expect(video('https://youtu.be/x').isPlayable, isTrue);
    });
  });

  group('formatage', () {
    test('prix en FCFA, espace comme separateur de milliers', () {
      expect(formatFcfa(30000), '30 000 FCFA');
      expect(formatFcfa(1500), '1 500 FCFA');
    });

    test('date lisible sans initialisation de locale', () {
      expect(formatDate(DateTime(2026, 11, 2)), 'Lundi 2 nov. 2026');
    });

    test('la date proposee tombe sur le jour du creneau', () {
      // 2026-10-31 est un samedi (5).
      final from = DateTime(2026, 10, 31, 15);
      expect(nextDateForWeekday(5, from: from), DateTime(2026, 10, 31));
      expect(nextDateForWeekday(0, from: from), DateTime(2026, 11, 2));
      expect(nextDateForWeekday(4, from: from), DateTime(2026, 11, 6));
    });

    test('libelles traduits depuis les valeurs du back-office', () {
      expect(activityCategoryLabel('martial_arts'), 'Arts martiaux');
      expect(activityLevelLabel('all'), 'Tous niveaux');
      expect(activityLevelLabel('beginner'), 'Débutant');
    });
  });
}
