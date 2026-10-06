import '../config/api_config.dart';

enum BookingStatus { pending, confirmed, cancelled, completed, expired }

extension BookingStatusX on BookingStatus {
  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'En attente';
      case BookingStatus.confirmed:
        return 'Confirmee';
      case BookingStatus.cancelled:
        return 'Annulee';
      case BookingStatus.completed:
        return 'Terminee';
      case BookingStatus.expired:
        return 'Expiree';
    }
  }

  static BookingStatus parse(String? v) => BookingStatus.values.firstWhere(
        (e) => e.name == (v ?? '').toLowerCase(),
        orElse: () => BookingStatus.pending,
      );
}

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().split('.').first) ?? 0;
}

/// Reponse BookingCalculation du backend :
///   check_in, check_out, num_nights, subtotal(str), service_fee(str), total_price(str)
/// Le depot 50% est calcule cote client (constante API).
class BookingPriceBreakdown {
  final int nights;
  final int nightsTotal; // subtotal
  final int serviceFee;
  final int totalAmount;
  final int depositAmount;

  const BookingPriceBreakdown({
    required this.nights,
    required this.nightsTotal,
    required this.serviceFee,
    required this.totalAmount,
    required this.depositAmount,
  });

  factory BookingPriceBreakdown.fromJson(Map<String, dynamic> json) {
    final subtotal = _toInt(json['subtotal'] ?? json['nights_total']);
    final fee = _toInt(json['service_fee']);
    final total = _toInt(json['total_price'] ?? json['total_amount']);
    final deposit = _toInt(json['deposit_amount']) > 0
        ? _toInt(json['deposit_amount'])
        : (total * ApiConfig.depositRatio).round();
    return BookingPriceBreakdown(
      nights: _toInt(json['num_nights'] ?? json['nights']),
      nightsTotal: subtotal,
      serviceFee: fee,
      totalAmount: total,
      depositAmount: deposit,
    );
  }
}

class Booking {
  final String id;
  final String reference;
  final String residenceId;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final String guestName;
  final String guestPhone;
  final String? notes;
  final BookingStatus status;
  final BookingPriceBreakdown price;

  const Booking({
    required this.id,
    required this.reference,
    required this.residenceId,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.guestName,
    required this.guestPhone,
    required this.status,
    required this.price,
    this.notes,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id']?.toString() ?? '',
        reference: (json['reference'] ?? json['booking_reference'] ?? '')
            .toString(),
        residenceId: json['residence_id']?.toString() ?? '',
        checkIn: DateTime.parse(json['check_in'].toString()),
        checkOut: DateTime.parse(json['check_out'].toString()),
        guests: _toInt(json['num_guests'] ?? json['guests']),
        guestName: json['guest_name']?.toString() ?? '',
        guestPhone: json['guest_phone']?.toString() ?? '',
        notes: json['notes']?.toString(),
        status: BookingStatusX.parse(json['status']?.toString()),
        price: BookingPriceBreakdown.fromJson(
          (json['price'] as Map?)?.cast<String, dynamic>() ?? json,
        ),
      );
}
