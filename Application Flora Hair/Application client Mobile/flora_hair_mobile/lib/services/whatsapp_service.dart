import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/api_config.dart';
import '../models/booking.dart';
import '../models/service.dart';

class WhatsappService {
  const WhatsappService();

  Future<bool> openChat({String? message, String? phone}) async {
    final target = phone ?? ApiConfig.salonWhatsapp;
    final uri = Uri.parse(
      'https://wa.me/$target${message != null ? '?text=${Uri.encodeComponent(message)}' : ''}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String bookingConfirmationMessage({
    required Booking booking,
    required Service service,
    required String teamMemberName,
    required int amountPaid,
  }) {
    final buffer = StringBuffer()
      ..writeln('Bonjour Flora Hair,')
      ..writeln(
        'Je viens de reserver via l\'application mobile. Voici les details :',
      )
      ..writeln('- Service : ${service.name}')
      ..writeln('- Coiffeuse : $teamMemberName')
      ..writeln(
        '- Date : ${booking.date.day.toString().padLeft(2, '0')}/${booking.date.month.toString().padLeft(2, '0')}/${booking.date.year}',
      )
      ..writeln('- Heure : ${booking.startTime}')
      ..writeln('- Depot paye : ${_fmt(amountPaid)} FCFA')
      ..writeln('- Nom : ${booking.customerName}')
      ..writeln('- Telephone : ${booking.customerPhone}');
    if (booking.reference != null) {
      buffer.writeln('- Reference : ${booking.reference}');
    }
    return buffer.toString();
  }

  String quoteConfirmationMessage({
    required String customerName,
    required String description,
  }) {
    return 'Bonjour Flora Hair, je viens de vous envoyer une demande de devis via l\'application.\nNom : $customerName\nSouhait : $description';
  }

  static String _fmt(int amount) {
    final s = amount.toString();
    final b = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) b.write(' ');
      b.write(s[i]);
    }
    return b.toString();
  }
}

final whatsappServiceProvider =
    Provider<WhatsappService>((_) => const WhatsappService());
