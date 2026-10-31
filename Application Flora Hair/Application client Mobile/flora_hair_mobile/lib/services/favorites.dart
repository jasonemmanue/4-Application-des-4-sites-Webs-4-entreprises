/// Favoris de la cliente — conservés sur l'appareil, l'app n'a pas de compte.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _favoritesKey = 'flora_favorites';

/// Clés : `service:<slug>` pour une prestation, `gallery:<id>` pour une
/// réalisation de la galerie.
String favoriteServiceKey(String slug) => 'service:$slug';
String favoriteGalleryKey(String id) => 'gallery:$id';

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier();
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier() : super(const <String>{}) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = (prefs.getStringList(_favoritesKey) ?? const <String>[]).toSet();
    } catch (_) {
      // prefs indisponibles : liste vide pour cette session.
    }
  }

  Future<void> toggle(String key) async {
    final next = Set<String>.of(state);
    if (!next.remove(key)) next.add(key);
    state = next;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, next.toList());
    } catch (_) {}
  }
}
