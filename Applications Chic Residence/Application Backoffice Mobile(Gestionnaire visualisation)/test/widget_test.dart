import 'package:chic_residence_backoffice/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrat de l'API : l'ancien modèle lisait des identifiants numériques et des
/// champs inexistants, et cassait la connexion après un mot de passe accepté.
void main() {
  test('le profil admin accepte un identifiant UUID', () {
    final u = AdminUser.fromJson({
      'id': '7c9e6679-7425-40de-944b-e07fc1f90ae7',
      'email': 'admin@chicresidence.ci',
      'full_name': 'Admin',
      'role': 'admin',
    });
    expect(u.id, '7c9e6679-7425-40de-944b-e07fc1f90ae7');
  });

  test('une réservation lit les Decimal en texte', () {
    final b = Booking.fromJson({
      'id': 'b',
      'residence_id': 'r',
      'guest_name': 'Awa',
      'guest_phone': '+2250700000000',
      'check_in': '2027-01-10',
      'check_out': '2027-01-12',
      'num_guests': 2,
      'total_price': '140000.00',
      'deposit_amount': '70000.00',
      'deposit_status': 'paid',
      'status': 'confirmed',
    });
    expect(b.total, 140000);
    expect(b.deposit, 70000);
    expect(b.depositPaid, isTrue);
  });

  test('le statut final des tâches est validated', () {
    expect(TaskStatusX.parse('validated'), TaskStatus.validated);
  });
}
