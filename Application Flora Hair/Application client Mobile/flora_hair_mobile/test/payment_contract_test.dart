import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:flora_hair_mobile/config/api_config.dart';
import 'package:flora_hair_mobile/models/booking.dart';
import 'package:flora_hair_mobile/models/payment.dart';
import 'package:flora_hair_mobile/models/service.dart';
import 'package:flora_hair_mobile/services/payment_service.dart';

/// Contrat avec le backend : les valeurs ci-dessous sont celles de
/// `backend/app/schemas/schemas.py` et de `GET /payments/config`.
void main() {
  group('statuts de paiement', () {
    test('« succeeded » du backend est un succès', () {
      expect(paymentStatusFromString('succeeded'), PaymentStatus.success);
      expect(PaymentStatus.success.isFinal, isTrue);
    });

    test('chaque statut du backend a sa signification', () {
      const expected = <String, PaymentStatus>{
        'initiated': PaymentStatus.pending,
        'pending': PaymentStatus.pending,
        'succeeded': PaymentStatus.success,
        'failed': PaymentStatus.failed,
        'cancelled': PaymentStatus.cancelled,
        'expired': PaymentStatus.expired,
        'refunded': PaymentStatus.cancelled,
      };
      expected.forEach((raw, status) {
        expect(paymentStatusFromString(raw), status, reason: raw);
      });
    });

    test("l'attente ne s'arrête que sur un statut final", () {
      expect(paymentStatusFromString('initiated').isFinal, isFalse);
      expect(paymentStatusFromString('pending').isFinal, isFalse);
      expect(paymentStatusFromString('failed').isFinal, isTrue);
    });
  });

  group('configuration du back-office', () {
    test('lit la réponse réelle de /payments/config', () {
      final config = PaymentConfig.fromJson(<String, dynamic>{
        'configured': true,
        'deposit_percent': 50,
        'operators': <Map<String, dynamic>>[
          {'key': 'wave', 'label': 'Wave'},
          {'key': 'orange_money', 'label': 'Orange Money'},
          {'key': 'mtn_money', 'label': 'MTN Mobile Money'},
          {'key': 'card', 'label': 'Carte bancaire'},
        ],
      });
      expect(config.configured, isTrue);
      expect(config.depositPercent, 50);
      expect(config.operators, PaymentOperator.values);
    });

    test('un moyen coupé ou inconnu ne s\'affiche pas', () {
      final config = PaymentConfig.fromJson(<String, dynamic>{
        'configured': true,
        'operators': <Map<String, dynamic>>[
          {'key': 'wave'},
          {'key': 'moov_money'},
        ],
      });
      expect(config.operators, <PaymentOperator>[PaymentOperator.wave]);
    });
  });

  group('logos de paiement', () {
    test('chaque moyen a son image embarquée', () {
      for (final op in PaymentOperator.values) {
        expect(File(op.logoAsset).existsSync(), isTrue, reason: op.logoAsset);
      }
    });

    test('Wave et la carte passent par le navigateur externe', () {
      expect(PaymentOperator.wave.opensExternally, isTrue);
      expect(PaymentOperator.card.opensExternally, isTrue);
      expect(PaymentOperator.orangeMoney.opensExternally, isFalse);
      expect(PaymentOperator.mtnMoney.opensExternally, isFalse);
    });
  });

  group('numéro à débiter', () {
    test('dix chiffres, sous toutes les écritures', () {
      expect(PaymentService.validatePhone('07 07 07 07 07'), isNull);
      expect(PaymentService.validatePhone('+225 0707070707'), isNull);
      expect(PaymentService.validatePhone('002250707070707'), isNull);
    });

    test('le préfixe ne bloque pas : la portabilité existe', () {
      expect(PaymentService.validatePhone('0102030405'), isNull);
    });

    test('un numéro incomplet est refusé', () {
      expect(PaymentService.validatePhone('07070707'), isNotNull);
    });

    test('format international', () {
      expect(PaymentService.toInternational('07 07 07 07 07'), '+2250707070707');
      expect(PaymentService.toInternational('+2250707070707'), '+2250707070707');
      expect(PaymentService.toInternational('002250707070707'), '+2250707070707');
    });
  });

  group('réservation', () {
    Booking booking({String? method}) => Booking(
          serviceId: 's',
          teamMemberId: 't',
          date: DateTime(2026, 11, 4),
          timeSlot: '10:30',
          customerName: 'Cliente',
          customerPhone: '0707070707',
          paymentMethod: method,
        );

    test('le corps correspond à BookingCreate', () {
      final json = booking(method: Booking.onlinePayment).toCreateJson();
      expect(json['date'], '2026-11-04');
      expect(json['time_slot'], '10:30');
      expect(json['client_email'], '');
      // Libellé exact : c'est lui qui fait expirer une demande non payée.
      expect(json['payment_method'], 'Payement electronique');
    });

    test('la modalité reste facultative', () {
      expect(booking().toCreateJson().containsKey('payment_method'), isFalse);
    });
  });

  group('prix', () {
    Service service({int? max, bool from = false}) => Service(
          id: '1',
          slug: 'tresses',
          name: 'Tresses',
          categoryId: 'c',
          priceMin: 5000,
          priceMax: max,
          priceFrom: from,
          durationMinutes: 90,
        );

    test('affichage FCFA', () {
      expect(service().formattedPrice(), '5 000 FCFA');
      expect(service(max: 8000).formattedPrice(), '5 000 – 8 000 FCFA');
      expect(service(from: true).formattedPrice(), 'À partir de 5 000 FCFA');
      expect(service(from: true).shortPrice, 'dès 5 000 FCFA');
      expect(service().formattedDuration, '1 h 30');
    });
  });

  test('X-App-Source est aligné sur pubspec.yaml', () {
    final version = RegExp(r'^version:\s*(\S+)', multiLine: true)
        .firstMatch(File('pubspec.yaml').readAsStringSync())!
        .group(1);
    expect(ApiConfig.appSource, 'android/$version');
  });
}
