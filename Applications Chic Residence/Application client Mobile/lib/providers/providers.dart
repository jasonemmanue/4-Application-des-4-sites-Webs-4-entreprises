import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/residence.dart';
import '../services/api_client.dart';
import '../services/booking_service.dart';
import '../services/favorites_service.dart';
import '../services/payment_service.dart';
import '../services/residence_service.dart';
import '../services/session_service.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  throw UnimplementedError(
      'sessionServiceProvider doit etre override au demarrage.');
});

/// Nom du voyageur affiché sur le Profil — `null` tant qu'aucune
/// réservation n'a été faite depuis cet appareil.
final guestNameProvider = StateProvider<String?>(
    (ref) => ref.watch(sessionServiceProvider).guestName);

/// Pastille « Aucun frais caché » de l'accueil — masquée pour de bon une
/// fois le pop-up lu.
final feesNoticeVisibleProvider = StateProvider<bool>(
    (ref) => !ref.watch(sessionServiceProvider).feesNoticeSeen);

final apiClientProvider = Provider<ApiClient>((ref) {
  final session = ref.watch(sessionServiceProvider);
  return ApiClient(sessionId: session.sessionId);
});

final residenceServiceProvider = Provider<ResidenceService>(
    (ref) => ResidenceService(ref.watch(apiClientProvider)));

final bookingServiceProvider = Provider<BookingService>(
    (ref) => BookingService(ref.watch(apiClientProvider)));

final paymentServiceProvider = Provider<PaymentService>(
    (ref) => PaymentService(ref.watch(apiClientProvider)));

final favoritesServiceProvider = Provider<FavoritesService>((ref) =>
    FavoritesService(
        ref.watch(apiClientProvider), ref.watch(sessionServiceProvider)));

final filtersProvider =
    StateProvider<ResidenceFilters>((ref) => const ResidenceFilters());

final residencesProvider =
    FutureProvider.autoDispose<List<Residence>>((ref) async {
  final svc = ref.watch(residenceServiceProvider);
  final filters = ref.watch(filtersProvider);
  return svc.list(filters);
});

/// Detail d'une residence (id UUID ou slug).
final residenceDetailProvider =
    FutureProvider.family<Residence, String>((ref, idOrSlug) async {
  return ref.watch(residenceServiceProvider).detail(idOrSlug);
});

/// Favoris : set d'IDs (UUID string).
final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, Set<String>>((ref) {
  return FavoritesNotifier(ref.watch(favoritesServiceProvider));
});

class FavoritesNotifier extends StateNotifier<Set<String>> {
  FavoritesNotifier(this._svc) : super({}) {
    _load();
  }

  final FavoritesService _svc;

  Future<void> _load() async {
    try {
      final ids = await _svc.list();
      state = ids.toSet();
    } catch (_) {
      // silence : hors reseau
    }
  }

  Future<void> toggle(String residenceId) async {
    final wasFav = state.contains(residenceId);
    // Optimistic
    state = wasFav
        ? (state.toSet()..remove(residenceId))
        : (state.toSet()..add(residenceId));
    try {
      await _svc.toggle(residenceId, isCurrentlyFav: wasFav);
    } catch (_) {
      // rollback
      state = wasFav
          ? (state.toSet()..add(residenceId))
          : (state.toSet()..remove(residenceId));
    }
  }
}

/// Comparaison (max 3)
final compareProvider =
    StateNotifierProvider<CompareNotifier, List<Residence>>((ref) {
  return CompareNotifier();
});

class CompareNotifier extends StateNotifier<List<Residence>> {
  CompareNotifier() : super([]);

  static const int maxCompare = 3;

  bool toggle(Residence r) {
    if (state.any((e) => e.id == r.id)) {
      state = state.where((e) => e.id != r.id).toList();
      return false;
    }
    if (state.length >= maxCompare) return false;
    state = [...state, r];
    return true;
  }

  bool contains(String id) => state.any((e) => e.id == id);
}

// ── Thème clair / sombre / système (persisté via SharedPreferences) ──────

/// Mode de thème choisi par l'utilisateur. `ThemeMode.system` = suit le
/// réglage OS, `light` = soleil, `dark` = lune. Persisté sous la clé
/// `theme_mode` dans SharedPreferences pour survivre au redémarrage.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _restore();
  }

  static const _key = 'theme_mode';

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      switch (raw) {
        case 'light':
          state = ThemeMode.light;
          break;
        case 'dark':
          state = ThemeMode.dark;
          break;
        case 'system':
        default:
          state = ThemeMode.system;
      }
    } catch (_) {
      // premier lancement / prefs indisponibles → laisse `system`
    }
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // écriture opportuniste, l'état en mémoire suffit à la session
    }
  }
}
