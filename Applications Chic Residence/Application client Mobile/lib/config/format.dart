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

/// Numéros ivoiriens. La valeur envoyée à l'API porte toujours `+225`.
class Phones {
  Phones._();

  /// Les dix chiffres nationaux, quel que soit le format saisi ou collé.
  static String localDigits(String raw) {
    final d = raw.replaceAll(RegExp(r'\D'), '');
    if (d.startsWith('225') && d.length == 13) return d.substring(3);
    return d;
  }

  static String toApi(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return '';
    // Un numéro étranger (+33…) reste tel quel : il sert au reçu WhatsApp.
    if (trimmed.startsWith('+') && !trimmed.startsWith('+225')) {
      return '+${trimmed.replaceAll(RegExp(r'\D'), '')}';
    }
    return '+225${localDigits(trimmed)}';
  }
}

/// Formatage dates francais (jj/mm/aaaa).
class Dates {
  Dates._();

  static String short(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  /// « 15 nov. »
  static String dayMonth(DateTime d) => DateFormat('d MMM', 'fr_FR').format(d);

  /// « 15 nov. 2026 »
  static String dayMonthYear(DateTime d) =>
      DateFormat('d MMM y', 'fr_FR').format(d);

  static String long(DateTime d) => DateFormat("EEEE d MMMM y", 'fr_FR').format(d);

  static int nightsBetween(DateTime start, DateTime end) {
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return e.difference(s).inDays;
  }
}
