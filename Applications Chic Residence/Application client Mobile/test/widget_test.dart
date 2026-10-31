import 'package:chic_residence_mobile/config/format.dart';
import 'package:chic_residence_mobile/models/payment.dart';
import 'package:chic_residence_mobile/models/residence.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrat de l'API : chacun de ces champs a déjà cassé l'application en silence.
void main() {
  test('un paiement « succeeded » est reconnu comme réussi', () {
    expect(PaymentStatusX.parse('succeeded'), PaymentStatus.success);
    expect(PaymentStatusX.parse('inconnu'), PaymentStatus.pending);
  });

  test('la réponse de paiement lit payment_url et le montant en texte', () {
    final a = PaymentAttempt.fromJson({
      'reference': 'CR-1',
      'payment_url': 'https://pay.wave.com/c/x',
      'amount': '42500.00',
      'channel': 'orange_money',
      'status': 'pending',
      'mode': 'live',
    });
    expect(a.paymentUrl, 'https://pay.wave.com/c/x');
    expect(a.amount, 42500);
    expect(a.channel, PaymentChannel.orangeMoney);
  });

  test('les moyens proposés viennent de /payments/config', () {
    final o = PaymentOptions.fromJson({
      'enabled': true,
      'mode': 'live',
      'deposit_percent': 50,
      'channels': [
        {'key': 'mtn_money', 'requires_phone': true, 'phone_prefixes': ['05']},
        {'key': 'card', 'requires_phone': false, 'phone_prefixes': []},
      ],
    });
    expect(o.channels, [PaymentChannel.mtnMoney, PaymentChannel.card]);
    expect(o.requiresPhone, {PaymentChannel.mtnMoney});
    expect(o.prefixes[PaymentChannel.mtnMoney], ['05']);
  });

  test('un logement lit note et disponibilité aux bons champs', () {
    final r = Residence.fromJson({
      'id': 'a',
      'slug': 's',
      'title': 'Studio',
      'residence_type': 'studio',
      'base_price_per_night': '25000.00',
      'rating_average': 4.5,
      'rating_count': 3,
      'availability_status': 'auto',
      'availability_summary': {
        'state': 'busy',
        'label': 'Occupé',
        'is_bookable': true,
        'booked_ranges': [
          {'start': '2027-01-10', 'end': '2027-01-12'},
        ],
      },
    });
    expect(r.pricePerNight, 25000);
    expect(r.reviewsCount, 3);
    expect(r.availability, AvailabilityStatus.occupied);
    expect(r.isFreeBetween(DateTime(2027, 1, 12), DateTime(2027, 1, 14)), isFalse);
    // Le départ n'est pas une nuit : on peut partir le jour où ça se remplit.
    expect(r.isFreeBetween(DateTime(2027, 1, 8), DateTime(2027, 1, 10)), isTrue);
  });

  test('les numéros partent en +225', () {
    expect(Phones.toApi('07 00 00 00 00'), '+2250700000000');
    expect(Phones.toApi('+225 07 00 00 00 00'), '+2250700000000');
    expect(Phones.localDigits('+2250700000000'), '0700000000');
    expect(Phones.toApi('+33 6 12 34 56 78'), '+33612345678');
  });
}
