import 'package:intl/intl.dart';

String formatFcfa(num? amount) {
  if (amount == null) return '-';
  final formatter = NumberFormat('#,##0', 'fr_FR');
  return '${formatter.format(amount).replaceAll(',', ' ')} FCFA';
}

String formatDate(DateTime? date) {
  if (date == null) return '';
  return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
}

const List<String> weekDaysShort = [
  'Lun',
  'Mar',
  'Mer',
  'Jeu',
  'Ven',
  'Sam',
  'Dim',
];

const List<String> weekDaysLong = [
  'Lundi',
  'Mardi',
  'Mercredi',
  'Jeudi',
  'Vendredi',
  'Samedi',
  'Dimanche',
];

String weekDayName(int dayOfWeek, {bool short = false}) {
  final idx = dayOfWeek.clamp(0, 6);
  return short ? weekDaysShort[idx] : weekDaysLong[idx];
}
