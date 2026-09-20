/// Ouverture de conversations WhatsApp pre-remplies.
///
/// Le backend envoie ses propres notifications WhatsApp Business
/// (voir `app/services/whatsapp_service.py`) — cette classe cote mobile
/// sert uniquement a proposer au membre d'ouvrir sa conversation avec la
/// salle, par exemple apres une inscription reussie.
library;

import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

class WhatsAppService {
  WhatsAppService._();
  static final instance = WhatsAppService._();

  /// Ouvre WhatsApp. `phone` doit etre sans `+` ni espaces (format `2250XXXXXXXX`).
  /// Si null, on retombe sur le numero de la salle.
  Future<bool> sendMessage({String? phone, required String message}) async {
    final target = _sanitize(phone) ?? ApiConfig.whatsappNumber;
    final uri = Uri.parse(
      'https://wa.me/$target?text=${Uri.encodeComponent(message)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> sendEnrollmentConfirmation({
    required String reference,
    required String fullName,
    required String activity,
    required int amount,
  }) {
    final message = '''
Bonjour ${ApiConfig.gymName},

Voici la confirmation de mon inscription :
- Reference : $reference
- Nom : $fullName
- Activite : $activity
- Depot paye : ${_formatAmount(amount)} FCFA

Merci !
''';
    return sendMessage(message: message);
  }

  Future<bool> sendSubscriptionConfirmation({
    required String reference,
    required String fullName,
    required String subscription,
    required int amount,
  }) {
    final message = '''
Bonjour ${ApiConfig.gymName},

Voici la confirmation de ma souscription :
- Reference : $reference
- Nom : $fullName
- Formule : $subscription
- Depot paye : ${_formatAmount(amount)} FCFA

Merci !
''';
    return sendMessage(message: message);
  }

  String? _sanitize(String? phone) {
    if (phone == null) return null;
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.isEmpty ? null : digits;
  }

  String _formatAmount(int amount) {
    final s = amount.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buffer.write(' ');
      buffer.write(s[i]);
    }
    return buffer.toString();
  }
}
