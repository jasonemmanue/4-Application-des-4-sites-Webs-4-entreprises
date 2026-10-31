import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/payment.dart';

/// Réservation faite depuis cet appareil.
///
/// Le client n'a pas de compte et l'API ne liste les réservations qu'à
/// l'administrateur : l'onglet « Réservations » lit donc cette liste locale,
/// et redemande à l'API (`GET /payments/{ref}`, public) l'état de l'acompte.
class BookingRecord {
  final String bookingId;
  final String? paymentReference;
  final String residenceSlug;
  final String residenceName;
  final String city;
  final String photo;
  final DateTime checkIn;
  final DateTime checkOut;
  final int guests;
  final int total;
  final int deposit;
  final String guestPhone;
  final PaymentStatus? paymentStatus;
  final bool cancelled;

  const BookingRecord({
    required this.bookingId,
    required this.residenceSlug,
    required this.residenceName,
    required this.city,
    required this.photo,
    required this.checkIn,
    required this.checkOut,
    required this.guests,
    required this.total,
    required this.deposit,
    required this.guestPhone,
    this.paymentReference,
    this.paymentStatus,
    this.cancelled = false,
  });

  bool get isPaid => paymentStatus == PaymentStatus.success;

  /// À venir : réglé et pas encore terminé.
  bool get isUpcoming =>
      isPaid && !cancelled && checkOut.isAfter(DateTime.now());

  BookingRecord copyWith({
    String? paymentReference,
    PaymentStatus? paymentStatus,
    bool? cancelled,
  }) =>
      BookingRecord(
        bookingId: bookingId,
        residenceSlug: residenceSlug,
        residenceName: residenceName,
        city: city,
        photo: photo,
        checkIn: checkIn,
        checkOut: checkOut,
        guests: guests,
        total: total,
        deposit: deposit,
        guestPhone: guestPhone,
        paymentReference: paymentReference ?? this.paymentReference,
        paymentStatus: paymentStatus ?? this.paymentStatus,
        cancelled: cancelled ?? this.cancelled,
      );

  Map<String, dynamic> toJson() => {
        'booking_id': bookingId,
        'payment_reference': paymentReference,
        'residence_slug': residenceSlug,
        'residence_name': residenceName,
        'city': city,
        'photo': photo,
        'check_in': checkIn.toIso8601String(),
        'check_out': checkOut.toIso8601String(),
        'guests': guests,
        'total': total,
        'deposit': deposit,
        'guest_phone': guestPhone,
        'payment_status': paymentStatus?.name,
        'cancelled': cancelled,
      };

  factory BookingRecord.fromJson(Map<String, dynamic> j) => BookingRecord(
        bookingId: j['booking_id'].toString(),
        paymentReference: j['payment_reference']?.toString(),
        residenceSlug: j['residence_slug'].toString(),
        residenceName: j['residence_name'].toString(),
        city: j['city']?.toString() ?? '',
        photo: j['photo']?.toString() ?? '',
        checkIn: DateTime.parse(j['check_in'].toString()),
        checkOut: DateTime.parse(j['check_out'].toString()),
        guests: (j['guests'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        deposit: (j['deposit'] as num).toInt(),
        guestPhone: j['guest_phone']?.toString() ?? '',
        paymentStatus: j['payment_status'] == null
            ? null
            : PaymentStatusX.parse(j['payment_status'].toString()),
        cancelled: j['cancelled'] == true,
      );
}

class BookingHistoryNotifier extends StateNotifier<List<BookingRecord>> {
  BookingHistoryNotifier() : super(const []) {
    _load();
  }

  static const _key = 'chic_booking_history';

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      state = (jsonDecode(raw) as List)
          .map((e) => BookingRecord.fromJson((e as Map).cast<String, dynamic>()))
          .toList();
    } catch (_) {
      // Liste locale illisible : on repart de zéro plutôt que de planter.
    }
  }

  Future<void> upsert(BookingRecord record) async {
    state = [
      record,
      ...state.where((r) => r.bookingId != record.bookingId),
    ];
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _key, jsonEncode(state.map((r) => r.toJson()).toList()));
    } catch (_) {
      // Écriture opportuniste : l'état en mémoire suffit à la session.
    }
  }

  BookingRecord? find(String bookingId) {
    for (final r in state) {
      if (r.bookingId == bookingId) return r;
    }
    return null;
  }
}
