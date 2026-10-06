import '../models/booking.dart';
import 'api_client.dart';

class BookingService {
  BookingService(this._api);
  final ApiClient _api;

  /// Le backend attend juste residence_id + dates ; les invites ne servent pas
  /// au calcul du prix (tarif par nuit, pas par personne).
  Future<BookingPriceBreakdown> calculatePrice({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
  }) async {
    final res = await _api.dio.post('/bookings/calculate-price', data: {
      'residence_id': residenceId,
      'check_in': checkIn.toIso8601String().substring(0, 10),
      'check_out': checkOut.toIso8601String().substring(0, 10),
    });
    return BookingPriceBreakdown.fromJson(
        (res.data as Map).cast<String, dynamic>());
  }

  /// BookingCreate : residence_id + guest_name + guest_phone + dates + num_guests.
  /// Le backend NE prend PAS d'email cote client (confirmations WhatsApp).
  Future<Booking> create({
    required String residenceId,
    required DateTime checkIn,
    required DateTime checkOut,
    required int guests,
    required String guestName,
    required String guestPhone,
    String? notes,
  }) async {
    final res = await _api.dio.post('/bookings', data: {
      'residence_id': residenceId,
      'check_in': checkIn.toIso8601String().substring(0, 10),
      'check_out': checkOut.toIso8601String().substring(0, 10),
      'num_guests': guests,
      'guest_name': guestName,
      'guest_phone': guestPhone,
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return Booking.fromJson((res.data as Map).cast<String, dynamic>());
  }

  /// Annulation client — le backend exige le téléphone stocké dans la réservation
  /// (preuve de possession, route publique).
  Future<void> cancel(String bookingId, {required String phone}) async {
    await _api.dio.post('/bookings/$bookingId/cancel', data: {'phone': phone});
  }
}
