import 'package:dio/dio.dart' show DioException;

import 'api_client.dart' show ApiException;

abstract final class InputSanitizer {
  static String safeErrorMessage(Object error) {
    if (error is DioException) {
      final inner = error.error;
      if (inner is ApiException) return inner.message;
    }
    if (error is ApiException) return error.message;
    return 'Une erreur est survenue.';
  }

  static final _htmlTag = RegExp(r'<[^>]*>');

  static String stripHtml(String input) => input.replaceAll(_htmlTag, '');

  static String sanitize(String input, {int maxLength = 500}) {
    var s = stripHtml(input.trim());
    if (s.length > maxLength) s = s.substring(0, maxLength);
    return s;
  }

  static String? validateName(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requis';
    final s = v.trim();
    if (s.length < 2) return '2 caractères minimum';
    if (s.length > 100) return '100 caractères maximum';
    if (_htmlTag.hasMatch(s)) return 'Caractères non autorisés';
    return null;
  }

  static String? validatePhone(String? v) {
    if (v == null || v.trim().isEmpty) return 'Requis';
    final s = v.trim();
    if (s.length < 8) return 'Numéro trop court';
    if (s.length > 20) return 'Numéro trop long';
    final cleaned = s.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?\d{8,15}$').hasMatch(cleaned)) {
      return 'Format invalide (ex: +225 07 00 00 00)';
    }
    return null;
  }

  static String? validateMessage(String? v, {int min = 10, int max = 2000}) {
    if (v == null || v.trim().isEmpty) return 'Requis';
    final s = v.trim();
    if (s.length < min) return '$min caractères minimum';
    if (s.length > max) return '$max caractères maximum';
    return null;
  }

  static String? validateOptionalText(String? v, {int max = 200}) {
    if (v == null || v.trim().isEmpty) return null;
    if (v.trim().length > max) return '$max caractères maximum';
    if (_htmlTag.hasMatch(v)) return 'Caractères non autorisés';
    return null;
  }
}
