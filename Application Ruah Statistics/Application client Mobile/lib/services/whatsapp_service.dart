import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';

class WhatsAppService {
  const WhatsAppService();

  Future<bool> sendPreFilledMessage(String message, {String? phone}) async {
    final String target = phone ?? ApiConfig.companyWhatsapp;
    final Uri uri = Uri.parse(
      'https://wa.me/$target?text=${Uri.encodeComponent(message)}',
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<bool> callPhone(String phone) async {
    final Uri uri = Uri(scheme: 'tel', path: phone);
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  Future<bool> sendEmail(String email, {String? subject}) async {
    final Uri uri = Uri(
      scheme: 'mailto',
      path: email,
      query: subject != null ? 'subject=${Uri.encodeComponent(subject)}' : null,
    );
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri);
  }

  Future<bool> openExternalUrl(String url) async {
    final Uri? uri = Uri.tryParse(url);
    if (uri == null) return false;
    if (!await canLaunchUrl(uri)) return false;
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
