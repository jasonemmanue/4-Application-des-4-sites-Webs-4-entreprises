import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../config/theme.dart';

/// Calendrier de séjour (arrivée puis départ).
///
/// Deux règles reprises du site : une date déjà prise n'est pas cliquable, et
/// un séjour ne peut pas **enjamber** une période réservée. `checkOut` n'est
/// pas une nuit louée : il peut tomber sur le premier jour pris.
class StayCalendar extends StatefulWidget {
  const StayCalendar({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.onChanged,
    this.blocked = const {},
  });

  final DateTime? checkIn;
  final DateTime? checkOut;
  final void Function(DateTime? checkIn, DateTime? checkOut) onChanged;
  final Set<DateTime> blocked;

  @override
  State<StayCalendar> createState() => _StayCalendarState();
}

class _StayCalendarState extends State<StayCalendar> {
  late DateTime _focused = widget.checkIn ?? DateTime.now();
  String? _warning;

  static DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

  bool _isBlocked(DateTime d) => widget.blocked.contains(_day(d));

  bool _spansBlocked(DateTime start, DateTime end) {
    for (var d = _day(start);
        d.isBefore(_day(end));
        d = d.add(const Duration(days: 1))) {
      if (widget.blocked.contains(d)) return true;
    }
    return false;
  }

  void _onRange(DateTime? start, DateTime? end, DateTime focused) {
    setState(() {
      _focused = focused;
      _warning = null;
    });
    if (start != null && end != null && _spansBlocked(start, end)) {
      setState(() => _warning =
          'Ce séjour enjambe des dates déjà réservées. Choisissez une autre '
          'période.');
      widget.onChanged(start, null);
      return;
    }
    widget.onChanged(start, end);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final today = _day(DateTime.now());
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TableCalendar(
          locale: 'fr_FR',
          firstDay: today,
          lastDay: today.add(const Duration(days: 365)),
          focusedDay: _focused.isBefore(today) ? today : _focused,
          rangeStartDay: widget.checkIn,
          rangeEndDay: widget.checkOut,
          rangeSelectionMode: RangeSelectionMode.toggledOn,
          startingDayOfWeek: StartingDayOfWeek.monday,
          availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
          enabledDayPredicate: (d) =>
              !_isBlocked(d) ||
              (widget.checkIn != null &&
                  widget.checkOut == null &&
                  d.isAfter(widget.checkIn!)),
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: t.textPrimary,
            ),
            leftChevronIcon:
                Icon(Icons.chevron_left_rounded, color: t.textPrimary),
            rightChevronIcon:
                Icon(Icons.chevron_right_rounded, color: t.textPrimary),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: TextStyle(fontSize: 12, color: t.textSecondary),
            weekendStyle: TextStyle(fontSize: 12, color: t.textSecondary),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: TextStyle(color: t.textPrimary),
            weekendTextStyle: TextStyle(color: t.textPrimary),
            disabledTextStyle: TextStyle(
              color: t.textSecondary.withValues(alpha: 0.45),
              decoration: TextDecoration.lineThrough,
            ),
            rangeHighlightColor: t.brand.withValues(alpha: 0.14),
            withinRangeTextStyle: TextStyle(color: t.textPrimary),
            rangeStartDecoration:
                BoxDecoration(color: t.brand, shape: BoxShape.circle),
            rangeEndDecoration:
                BoxDecoration(color: t.brand, shape: BoxShape.circle),
            todayDecoration:
                BoxDecoration(color: t.surfaceSunken, shape: BoxShape.circle),
            todayTextStyle: TextStyle(
              color: t.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          onPageChanged: (d) => _focused = d,
          onRangeSelected: _onRange,
        ),
        if (_warning != null)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(_warning!,
                style: const TextStyle(color: AppColors.error, fontSize: 12.5)),
          ),
      ],
    );
  }
}
