import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

class WhatsAppService {
  WhatsAppService._();

  static Future<bool> send(String message) async {
    final uri = Uri.parse(
      'https://wa.me/${ApiConfig.whatsappNumber}?text=${Uri.encodeComponent(message)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> call() async {
    final uri = Uri(scheme: 'tel', path: ApiConfig.contactPhone);
    return launchUrl(uri);
  }

  static Future<bool> email() async {
    final uri = Uri(scheme: 'mailto', path: ApiConfig.contactEmail);
    return launchUrl(uri);
  }
}
