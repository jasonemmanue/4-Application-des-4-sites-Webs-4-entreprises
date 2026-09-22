import 'dart:io';

class QuoteRequest {
  const QuoteRequest({
    required this.customerName,
    required this.customerPhone,
    required this.description,
    this.customerEmail,
    this.photo,
  });

  final String customerName;
  final String customerPhone;
  final String description;
  final String? customerEmail;
  final File? photo;
}
