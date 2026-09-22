import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/service.dart';
import '../../models/team_member.dart';

class BookingDraft {
  const BookingDraft({
    this.service,
    this.teamMember,
    this.date,
    this.startTime,
    this.customerName = '',
    this.customerPhone = '',
    this.customerEmail = '',
    this.notes = '',
  });

  final Service? service;
  final TeamMember? teamMember;
  final DateTime? date;
  final String? startTime;
  final String customerName;
  final String customerPhone;
  final String customerEmail;
  final String notes;

  BookingDraft copyWith({
    Service? service,
    TeamMember? teamMember,
    DateTime? date,
    String? startTime,
    String? customerName,
    String? customerPhone,
    String? customerEmail,
    String? notes,
    bool clearTime = false,
  }) {
    return BookingDraft(
      service: service ?? this.service,
      teamMember: teamMember ?? this.teamMember,
      date: date ?? this.date,
      startTime: clearTime ? null : (startTime ?? this.startTime),
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerEmail: customerEmail ?? this.customerEmail,
      notes: notes ?? this.notes,
    );
  }
}

class BookingDraftNotifier extends StateNotifier<BookingDraft> {
  BookingDraftNotifier() : super(const BookingDraft());

  void setService(Service s) =>
      state = state.copyWith(service: s, teamMember: null, clearTime: true);
  void setTeamMember(TeamMember t) =>
      state = state.copyWith(teamMember: t, clearTime: true);
  void setDate(DateTime d) => state = state.copyWith(date: d, clearTime: true);
  void setTime(String t) => state = state.copyWith(startTime: t);
  void setCustomer({
    required String name,
    required String phone,
    required String email,
    required String notes,
  }) =>
      state = state.copyWith(
        customerName: name,
        customerPhone: phone,
        customerEmail: email,
        notes: notes,
      );

  void reset() => state = const BookingDraft();
}

final bookingDraftProvider =
    StateNotifierProvider<BookingDraftNotifier, BookingDraft>(
  (_) => BookingDraftNotifier(),
);

final bookingStepProvider = StateProvider<int>((_) => 0);
