/// Rendez-vous pris depuis cet appareil.
///
/// L'app n'a pas de compte : la liste vit sur le téléphone, mais **l'état vient
/// du back-office**. `refresh` relit `GET /bookings/{id}/status`, si bien qu'un
/// rendez-vous confirmé ou annulé dans l'administration change ici aussi.
/// Ni téléphone ni courriel ne sont conservés dans cette liste.
library;

import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/flora_ui.dart' show frLongDate;
import 'api_client.dart';
import 'inbox.dart';

const _appointmentsKey = 'flora_appointments';
const _pushTokenKey = 'flora_push_token_synced';

class LocalAppointment {
  const LocalAppointment({
    required this.bookingId,
    required this.serviceName,
    required this.memberName,
    required this.date,
    required this.time,
    this.imageUrl,
    this.status = 'pending',
    this.depositStatus = 'unpaid',
    this.depositAmount = 0,
    this.paymentRef,
  });

  final String bookingId;
  final String serviceName;
  final String memberName;
  final String date; // YYYY-MM-DD
  final String time; // HH:MM
  final String? imageUrl;
  final String status; // pending | confirmed | cancelled | completed
  final String depositStatus; // unpaid | pending | paid
  final int depositAmount;
  final String? paymentRef;

  DateTime get startsAt =>
      DateTime.tryParse('${date}T$time:00') ?? DateTime(1970);

  bool get isCancelled => status == 'cancelled';
  bool get isDepositPaid => depositStatus == 'paid';

  bool get isUpcoming =>
      !isCancelled && status != 'completed' && startsAt.isAfter(DateTime.now());

  /// Annulable par la cliente : mêmes conditions que le backend.
  bool get canCancel => isUpcoming && status == 'pending' && !isDepositPaid;

  bool get canPayDeposit => isUpcoming && !isDepositPaid && depositAmount > 0;

  LocalAppointment copyWith({
    String? status,
    String? depositStatus,
    int? depositAmount,
    String? paymentRef,
  }) =>
      LocalAppointment(
        bookingId: bookingId,
        serviceName: serviceName,
        memberName: memberName,
        date: date,
        time: time,
        imageUrl: imageUrl,
        status: status ?? this.status,
        depositStatus: depositStatus ?? this.depositStatus,
        depositAmount: depositAmount ?? this.depositAmount,
        paymentRef: paymentRef ?? this.paymentRef,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'booking_id': bookingId,
        'service_name': serviceName,
        'member_name': memberName,
        'date': date,
        'time': time,
        'image_url': imageUrl,
        'status': status,
        'deposit_status': depositStatus,
        'deposit_amount': depositAmount,
        'payment_ref': paymentRef,
      };

  factory LocalAppointment.fromJson(Map<String, dynamic> json) =>
      LocalAppointment(
        bookingId: json['booking_id'] as String,
        serviceName: (json['service_name'] as String?) ?? '',
        memberName: (json['member_name'] as String?) ?? '',
        date: (json['date'] as String?) ?? '',
        time: (json['time'] as String?) ?? '',
        imageUrl: json['image_url'] as String?,
        status: (json['status'] as String?) ?? 'pending',
        depositStatus: (json['deposit_status'] as String?) ?? 'unpaid',
        depositAmount: (json['deposit_amount'] as num?)?.toInt() ?? 0,
        paymentRef: json['payment_ref'] as String?,
      );
}

final appointmentsProvider =
    StateNotifierProvider<AppointmentsNotifier, List<LocalAppointment>>((ref) {
  final inbox = ref.read(inboxProvider.notifier);
  return AppointmentsNotifier(
    ref.watch(apiClientProvider),
    onChange: (before, after) {
      final notice = appointmentNotice(before, after);
      if (notice != null) inbox.add(notice);
    },
  );
});

/// Message de la boîte de réception pour un changement décidé par le salon.
InboxItem? appointmentNotice(LocalAppointment before, LocalAppointment after) {
  final date = DateTime.tryParse(after.date);
  final when = '${date == null ? after.date : frLongDate(date)} à ${after.time}';
  if (after.status != before.status) {
    switch (after.status) {
      case 'confirmed':
        return InboxItem(
          id: '${after.bookingId}:status:confirmed',
          title: 'Rendez-vous confirmé',
          body: '${after.serviceName}, $when : le salon vous attend.',
          receivedAt: DateTime.now(),
          route: '/appointments',
        );
      case 'cancelled':
        return InboxItem(
          id: '${after.bookingId}:status:cancelled',
          title: 'Rendez-vous annulé',
          body: '${after.serviceName}, $when, a été annulé. Écrivez au salon '
              'pour toute question.',
          receivedAt: DateTime.now(),
          route: '/appointments?tab=history',
        );
      case 'completed':
        return InboxItem(
          id: '${after.bookingId}:status:completed',
          title: 'Merci de votre visite',
          body: "Comment s'est passée votre prestation ${after.serviceName} ? "
              'Votre avis aide le salon.',
          receivedAt: DateTime.now(),
          route: '/reviews',
        );
    }
  }
  if (after.isDepositPaid && !before.isDepositPaid) {
    return InboxItem(
      id: '${after.bookingId}:deposit:paid',
      title: 'Acompte reçu',
      body: 'Votre acompte pour ${after.serviceName}, $when, est bien reçu.',
      receivedAt: DateTime.now(),
      route: '/appointments',
    );
  }
  return null;
}

/// Le prochain rendez-vous à venir, s'il y en a un.
final nextAppointmentProvider = Provider<LocalAppointment?>((ref) {
  final upcoming = ref
      .watch(appointmentsProvider)
      .where((a) => a.isUpcoming)
      .toList()
    ..sort((a, b) => a.startsAt.compareTo(b.startsAt));
  return upcoming.isEmpty ? null : upcoming.first;
});

class AppointmentsNotifier extends StateNotifier<List<LocalAppointment>> {
  AppointmentsNotifier(this._api, {this.onChange})
      : super(const <LocalAppointment>[]) {
    _restore();
  }

  final ApiClient _api;

  /// Appelé pour chaque rendez-vous dont l'état a changé côté salon.
  final void Function(LocalAppointment before, LocalAppointment after)?
      onChange;
  bool _refreshing = false;

  /// Complété une fois la liste relue sur l'appareil.
  final _restored = Completer<void>();

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_appointmentsKey);
      if (raw != null) {
        state = (jsonDecode(raw) as List<dynamic>)
            .whereType<Map<String, dynamic>>()
            .map(LocalAppointment.fromJson)
            .toList();
      }
    } catch (_) {
      // Préférences illisibles : on repart d'une liste vide.
    }
    if (!_restored.isCompleted) _restored.complete();
    await refresh();
  }

  Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _appointmentsKey,
        jsonEncode(state.map((a) => a.toJson()).toList()),
      );
    } catch (_) {}
  }

  Future<void> add(LocalAppointment appointment) async {
    state = <LocalAppointment>[
      appointment,
      ...state.where((a) => a.bookingId != appointment.bookingId),
    ];
    await _persist();
  }

  Future<void> attachPayment(String bookingId, String reference) async {
    state = <LocalAppointment>[
      for (final a in state)
        a.bookingId == bookingId
            ? a.copyWith(paymentRef: reference, depositStatus: 'pending')
            : a,
    ];
    await _persist();
  }

  /// Une relance crée une nouvelle transaction : la référence suivie change.
  Future<void> replacePayment(String oldReference, String reference) async {
    state = <LocalAppointment>[
      for (final a in state)
        a.paymentRef == oldReference ? a.copyWith(paymentRef: reference) : a,
    ];
    await _persist();
  }

  /// Relit l'état de chaque rendez-vous encore ouvert auprès de l'API.
  Future<void> refresh() async {
    // Minuterie, retour au premier plan et retour du réseau peuvent tomber
    // ensemble : une seule relecture à la fois.
    if (_refreshing) return;
    _refreshing = true;
    try {
      await _refresh();
    } finally {
      _refreshing = false;
    }
  }

  Future<void> _refresh() async {
    final next = <LocalAppointment>[];
    final changes = <(LocalAppointment, LocalAppointment)>[];
    var changed = false;
    for (final a in state) {
      if (a.isCancelled || a.status == 'completed') {
        next.add(a);
        continue;
      }
      try {
        final json = await _api.fetchBookingStatus(a.bookingId);
        final updated = a.copyWith(
          status: json['status'] as String?,
          depositStatus: json['deposit_status'] as String?,
          depositAmount: (json['deposit_amount'] as num?)?.toInt(),
        );
        final differs = updated.status != a.status ||
            updated.depositStatus != a.depositStatus ||
            updated.depositAmount != a.depositAmount;
        if (differs) changes.add((a, updated));
        changed = changed || differs;
        next.add(updated);
      } catch (_) {
        next.add(a); // Hors ligne : on garde le dernier état connu.
      }
    }
    if (!mounted || !changed) return;
    // Une réservation ajoutée pendant les appels ne doit pas être perdue.
    final known = next.map((a) => a.bookingId).toSet();
    state = <LocalAppointment>[
      ...state.where((a) => !known.contains(a.bookingId)),
      ...next,
    ];
    await _persist();
    for (final (before, after) in changes) {
      onChange?.call(before, after);
    }
  }

  /// Rattache ce téléphone à ses rendez-vous à venir quand son jeton FCM change
  /// (première ouverture de cette version, renouvellement par Firebase). Les
  /// réservations prises ensuite portent déjà le jeton.
  Future<void> syncPushToken(String token) async {
    if (token.isEmpty) return;
    await _restored.future;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getString(_pushTokenKey) == token) return;
      var allSent = true;
      for (final a in state.where((a) => a.isUpcoming)) {
        try {
          await _api.setPushToken(a.bookingId, token);
        } catch (_) {
          allSent = false; // Réessayé au prochain lancement.
        }
      }
      if (allSent) await prefs.setString(_pushTokenKey, token);
    } catch (_) {}
  }

  /// `POST /bookings/{id}/cancel` : le refus du backend remonte tel quel.
  Future<void> cancel(String bookingId) async {
    await _api.cancelBooking(bookingId);
    state = <LocalAppointment>[
      for (final a in state)
        a.bookingId == bookingId
            ? a.copyWith(status: 'cancelled', depositStatus: 'unpaid')
            : a,
    ];
    await _persist();
  }
}
