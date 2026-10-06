/// Profil local de la cliente — l'app n'a pas de compte.
///
/// Le nom affiché sur l'écran Profil est celui saisi lors du dernier
/// rendez-vous pris depuis cet appareil. Sans rendez-vous, l'écran affiche
/// « Visiteuse ».
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _nameKey = 'flora_client_name';
const _depositNoticeKey = 'flora_deposit_notice_seen';

final clientNameProvider =
    StateNotifierProvider<ClientNameNotifier, String?>((ref) {
  return ClientNameNotifier();
});

class ClientNameNotifier extends StateNotifier<String?> {
  ClientNameNotifier() : super(null) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final v = prefs.getString(_nameKey)?.trim();
      if (v != null && v.isNotEmpty) state = v;
    } catch (_) {
      // prefs indisponibles : reste « Visiteuse »
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
