import 'package:intl/intl.dart';

final _money = NumberFormat('#,##0', 'fr_FR');

/// « 45 000 F » : entier, séparateur de milliers en espace.
String fcfa(num v) =>
    '${_money.format(v.round()).replaceAll(RegExp(r'[,  ]'), ' ')} F';

String dayMonth(DateTime d) => DateFormat('d MMM', 'fr_FR').format(d);

String dayMonthYear(DateTime d) => DateFormat('d MMM y', 'fr_FR').format(d);

String dateTime(DateTime d) =>
    DateFormat('d MMM y, HH:mm', 'fr_FR').format(d.toLocal());
