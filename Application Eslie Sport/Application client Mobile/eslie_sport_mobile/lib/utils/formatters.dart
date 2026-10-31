import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

String formatFcfa(num? amount) {
  if (amount == null) return '-';
  final formatter = NumberFormat('#,##0', 'en_US');
  return '${formatter.format(amount).replaceAll(',', ' ')} FCFA';
}

const List<String> _monthsShort = [
  'janv.',
  'févr.',
  'mars',
  'avr.',
  'mai',
  'juin',
  'juil.',
  'août',
  'sept.',
  'oct.',
  'nov.',
  'déc.',
];

String formatDate(DateTime? date) {
  if (date == null) return '';
  return '${weekDaysLong[date.weekday - 1]} ${date.day} '
      '${_monthsShort[date.month - 1]} ${date.year}';
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

/// Prochaine date (aujourd'hui inclus) tombant sur ce jour de semaine,
/// 0 = lundi comme cote API.
DateTime nextDateForWeekday(int dayOfWeek, {DateTime? from}) {
  final start = from ?? DateTime.now();
  final today = DateTime(start.year, start.month, start.day);
  final delta = (dayOfWeek - (today.weekday - 1)) % 7;
  return today.add(Duration(days: delta));
}

// Valeurs stockees par le back-office (`category`, `level` des activites).
const List<(String, String)> activityCategories = [
  ('force', 'Force'),
  ('cardio', 'Cardio'),
  ('martial_arts', 'Arts martiaux'),
  ('flexibility', 'Souplesse'),
];

const List<(String, String)> activityLevels = [
  ('all', 'Tous niveaux'),
  ('beginner', 'Débutant'),
  ('intermediate', 'Intermédiaire'),
  ('advanced', 'Avancé'),
];

String _labelOf(List<(String, String)> table, String value) {
  for (final (key, label) in table) {
    if (key == value) return label;
  }
  if (value.isEmpty) return '';
  return value[0].toUpperCase() + value.substring(1).replaceAll('_', ' ');
}

String activityCategoryLabel(String category) =>
    _labelOf(activityCategories, category);

String activityLevelLabel(String level) =>
    level.isEmpty ? 'Tous niveaux' : _labelOf(activityLevels, level);

IconData activityCategoryIcon(String? category) => switch (category) {
      'force' => Icons.fitness_center,
      'cardio' => Icons.favorite,
      'martial_arts' => Icons.sports_martial_arts,
      'flexibility' => Icons.self_improvement,
      null => Icons.apps_rounded,
      _ => Icons.bolt,
    };
