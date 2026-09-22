class ContactMessage {
  final String name;
  final String whatsappNumber;
  final String message;
  final String? subject;
  final String? company;

  const ContactMessage({
    required this.name,
    required this.whatsappNumber,
    required this.message,
    this.subject,
    this.company,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'whatsapp_number': whatsappNumber,
        'message': message,
        if (subject != null && subject!.isNotEmpty) 'subject': subject,
        if (company != null && company!.isNotEmpty) 'company': company,
      };

  String get whatsappSummary => '''
Message via l'application - RUAH STATISTICS

De: $name
WhatsApp: $whatsappNumber
${company != null && company!.isNotEmpty ? 'Entreprise: $company\n' : ''}${subject != null && subject!.isNotEmpty ? 'Objet: $subject\n' : ''}
$message
''';
}

class TestimonialSubmission {
  final String clientName;
  final String clientWhatsapp;
  final String quote;
  final int rating;
  final String? clientPosition;
  final String? clientCompany;

  const TestimonialSubmission({
    required this.clientName,
    required this.clientWhatsapp,
    required this.quote,
    required this.rating,
    this.clientPosition,
    this.clientCompany,
  });

  Map<String, dynamic> toJson() => {
        'client_name': clientName,
        'client_whatsapp': clientWhatsapp,
        'quote': quote,
        'rating': rating,
        if (clientPosition != null && clientPosition!.isNotEmpty)
          'client_position': clientPosition,
        if (clientCompany != null && clientCompany!.isNotEmpty)
          'client_company': clientCompany,
      };
}
