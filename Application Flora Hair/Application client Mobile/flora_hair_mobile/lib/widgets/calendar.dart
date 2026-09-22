import 'package:flutter/material.dart';

import '../config/theme.dart';

typedef DateSelected = void Function(DateTime date);

class BookingCalendar extends StatefulWidget {
  const BookingCalendar({
    super.key,
    required this.selectedDate,
    required this.onSelect,
    this.minDate,
    this.closedWeekdays = const <int>{DateTime.sunday},
  });

  final DateTime? selectedDate;
  final DateSelected onSelect;
  final DateTime? minDate;
  final Set<int> closedWeekdays;

  @override
  State<BookingCalendar> createState() => _BookingCalendarState();
}

class _BookingCalendarState extends State<BookingCalendar> {
  late DateTime _current;

  static const _monthNames = <String>[
    'Janvier',
    'Fevrier',
    'Mars',
    'Avril',
    'Mai',
    'Juin',
    'Juillet',
    'Aout',
    'Septembre',
    'Octobre',
    'Novembre',
    'Decembre',
  ];
  static const _dayInitials = <String>['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    final s = widget.selectedDate ?? today;
    _current = DateTime(s.year, s.month, 1);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isClosed(DateTime d) => widget.closedWeekdays.contains(d.weekday);

  bool _isPast(DateTime d) {
    final min = widget.minDate ?? DateTime.now();
    final today = DateTime(min.year, min.month, min.day);
    return d.isBefore(today);
  }

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(_current.year, _current.month, 1);
    final firstWeekday = firstDay.weekday; // 1..7
    final lead = firstWeekday - 1; // decalage pour lundi=colonne0
    final now = DateTime.now();

    final cells = <Widget>[];
    for (int i = 0; i < 42; i++) {
      final dayIndex = i - lead + 1;
      final date = DateTime(_current.year, _current.month, dayIndex);
      final inMonth = date.month == _current.month;
      final closed = _isClosed(date);
      final past = _isPast(date);
      final disabled = !inMonth || closed || past;
      final selected =
          widget.selectedDate != null && _isSameDay(date, widget.selectedDate!);
      final isToday = _isSameDay(date, now);

      cells.add(
        Semantics(
          button: !disabled,
          label:
              '${date.day} ${_monthNames[date.month - 1]}${closed ? ' (ferme)' : ''}',
          selected: selected,
          child: InkWell(
            onTap: disabled ? null : () => widget.onSelect(date),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: selected ? FloraColors.lime : Colors.transparent,
                border: isToday && !selected
                    ? Border.all(color: FloraColors.lime)
                    : null,
              ),
              child: Center(
                child: Text(
                  '${date.day}',
                  style: TextStyle(
                    color: selected
                        ? FloraColors.dark
                        : disabled
                            ? FloraColors.textMuted.withValues(alpha: 0.4)
                            : FloraColors.cream,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            IconButton(
              onPressed: () => setState(
                () => _current = DateTime(_current.year, _current.month - 1, 1),
              ),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '${_monthNames[_current.month - 1]} ${_current.year}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(
                () => _current = DateTime(_current.year, _current.month + 1, 1),
              ),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          children: _dayInitials
              .map(
                (d) => Expanded(
                  child: Center(
                    child: Text(
                      d,
                      style: const TextStyle(
                        color: FloraColors.textMuted,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 4),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 7,
          childAspectRatio: 1,
          children: cells,
        ),
      ],
    );
  }
}
