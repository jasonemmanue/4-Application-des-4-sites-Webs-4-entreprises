import 'package:flutter_test/flutter_test.dart';

import 'package:flora_hair_mobile/config/api_config.dart';
import 'package:flora_hair_mobile/services/appointments.dart';

/// Messages de la boîte de réception nés d'une décision du salon.
void main() {
  const base = LocalAppointment(
    bookingId: 'b1',
    serviceName: 'Tresses',
    memberName: 'Aïssatou',
    date: '2030-01-07',
    time: '10:30',
  );

  test('confirmation par le salon', () {
    final n = appointmentNotice(base, base.copyWith(status: 'confirmed'))!;
    expect(n.title, 'Rendez-vous confirmé');
    expect(n.id, 'b1:status:confirmed');
    expect(n.body, contains('10:30'));
    expect(n.route, '/appointments');
  });

  test('annulation et fin de prestation', () {
    expect(appointmentNotice(base, base.copyWith(status: 'cancelled'))!.title,
        'Rendez-vous annulé');
    expect(appointmentNotice(base, base.copyWith(status: 'completed'))!.route,
        '/reviews');
  });

  test('acompte reçu', () {
    final n = appointmentNotice(base, base.copyWith(depositStatus: 'paid'))!;
    expect(n.title, 'Acompte reçu');
  });

  test("rien quand rien ne change", () {
    expect(appointmentNotice(base, base.copyWith(depositAmount: 2500)), isNull);
    expect(appointmentNotice(base, base.copyWith(depositStatus: 'pending')),
        isNull);
  });

  test('version affichée tirée de X-App-Source', () {
    expect(ApiConfig.appVersion, '1.3.0');
  });
}
