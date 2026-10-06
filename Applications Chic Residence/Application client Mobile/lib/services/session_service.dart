import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../config/api_config.dart';

/// Gere l'ID de session anonyme (UUID) pour les favoris et les
/// reservations sans compte.
class SessionService {
  SessionService(this._prefs);

  final SharedPreferences _prefs;
  static const _uuid = Uuid();

  static Future<SessionService> create() async {
    final prefs = await SharedPreferences.getInstance();
    final s = SessionService(prefs);
    await s.ensureSessionId();
    return s;
  }

  String get sessionId {
    return _prefs.getString(ApiConfig.sessionIdKey) ?? '';
  }

  /// Nom saisi lors de la derniere reservation. Il n'y a pas de compte :
  /// c'est la seule source pour personnaliser le Profil. `null` = visiteur.
  String? get guestName {
    final v = _prefs.getString(ApiConfig.guestNameKey)?.trim();
    return (v == null || v.isEmpty) ? null : v;
  }

  Future<void> setGuestName(String name) =>
      _prefs.setString(ApiConfig.guestNameKey, name.trim());

  bool get feesNoticeSeen =>
      _prefs.getBool(ApiConfig.feesNoticeSeenKey) ?? false;

  Future<void> markFeesNoticeSeen() =>
      _prefs.setBool(ApiConfig.feesNoticeSeenKey, true);

  Future<String> ensureSessionId() async {
    var id = _prefs.getString(ApiConfig.sessionIdKey);
    if (id == null || id.isEmpty) {
      id = _uuid.v4();
      await _prefs.setString(ApiConfig.sessionIdKey, id);
    }
    return id;
  }
}
