import 'package:intl/intl.dart';

/// Formatage FCFA (entier, separateur milliers = espace).
class Money {
  Money._();

  static final _fmt = NumberFormat('#,##0', 'fr_FR');

  static String fcfa(num value) {
    final v = value.round();
    // Substitue les separateurs " " et "," par des espaces francais
    return '${_fmt.format(v).replaceAll(',', ' ').replaceAll(' ', ' ')} FCFA';
  }

  static String perNight(num value) => '${fcfa(value)} / nuit';
}

/// Formatage dates francais (jj/mm/aaaa).
class Dates {
  Dates._();

  static String short(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String long(DateTime d) => DateFormat("EEEE d MMMM y", 'fr_FR').format(d);

  static int nightsBetween(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return e.difference(s).inDays;
  }
}
