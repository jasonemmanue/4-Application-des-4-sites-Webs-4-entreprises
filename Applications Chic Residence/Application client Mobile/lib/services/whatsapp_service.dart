import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

/// Contacts rapides. Le numéro vient de l'administration (« Paramètres ») dès
/// que `publicInfoProvider` l'a lu ; la valeur compilée n'est qu'un repli hors
/// réseau.
class WhatsAppService {
  WhatsAppService._();

  static String _whatsapp = ApiConfig.whatsappNumber;
  static String _phone = ApiConfig.contactPhone;

  static void configure({required String whatsapp, required String phone}) {
    final digits = whatsapp.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 8) _whatsapp = digits;
    if (phone.trim().isNotEmpty) _phone = phone.trim();
  }

  static Future<bool> send(String message) async {
    final uri = Uri.parse(
      'https://wa.me/$_whatsapp?text=${Uri.encodeComponent(message)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> call() async {
    final uri = Uri(scheme: 'tel', path: _phone.replaceAll(' ', ''));
    return launchUrl(uri);
  }
}
