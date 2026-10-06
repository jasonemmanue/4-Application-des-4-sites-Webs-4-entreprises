/// Profil local du membre — l'app n'a pas de compte.
///
/// Le nom affiché sur l'écran Profil est celui saisi lors de la dernière
/// inscription à un cours ou commande de formule, sur cet appareil. Sans
/// inscription, l'écran affiche « Visiteur ».
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _nameKey = 'eslie_member_name';
const _depositNoticeKey = 'eslie_deposit_notice_seen';

final memberNameProvider =
    StateNotifierProvider<MemberNameNotifier, String?>((ref) {
  return MemberNameNotifier();
});

class MemberNameNotifier extends StateNotifier<String?> {
  MemberNameNotifier() : super(null) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_nameKey)?.trim();
      if (v != null && v.isNotEmpty) state = v;
    } catch (_) {
      // prefs indisponibles : reste « Visiteur »
    }
  }

  Future<void> save(String name) async {
    final v = name.trim();
    if (v.isEmpty) return;
    state = v;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, v);
    } catch (_) {}
  }
}

/// Pastille « acompte 50 % » de l'accueil — masquée pour de bon une fois
/// le pop-up lu. `false` tant que la préférence n'est pas relue, pour ne pas
/// la faire clignoter chez qui l'a déjà fermée.
final depositNoticeVisibleProvider =
    StateNotifierProvider<DepositNoticeNotifier, bool>((ref) {
  return DepositNoticeNotifier();
});

class DepositNoticeNotifier extends StateNotifier<bool> {
  DepositNoticeNotifier() : super(false) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = !(prefs.getBool(_depositNoticeKey) ?? false);
    } catch (_) {
      state = true;
    }
  }

  Future<void> dismiss() async {
    state = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_depositNoticeKey, true);
    } catch (_) {}
  }
}
