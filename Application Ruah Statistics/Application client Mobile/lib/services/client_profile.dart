import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Profil local — l'app n'a pas de compte.
///
/// Le nom (et l'entreprise) affichés sur l'écran Profil sont ceux saisis
/// lors de la dernière demande de devis envoyée depuis cet appareil. Sans
/// demande, l'écran affiche « Visiteur ».
class ClientProfile {
  final String? name;
  final String? company;
  const ClientProfile({this.name, this.company});
}

const _nameKey = 'ruah_client_name';
const _companyKey = 'ruah_client_company';

final clientProfileProvider =
    StateNotifierProvider<ClientProfileNotifier, ClientProfile>((ref) {
  return ClientProfileNotifier();
});

class ClientProfileNotifier extends StateNotifier<ClientProfile> {
  ClientProfileNotifier() : super(const ClientProfile()) {
    _restore();
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      state = ClientProfile(
        name: _clean(prefs.getString(_nameKey)),
        company: _clean(prefs.getString(_companyKey)),
      );
    } catch (_) {
      // prefs indisponibles : reste « Visiteur »
    }
  }

  Future<void> save({required String name, String? company}) async {
    final n = _clean(name);
    if (n == null) return;
    final c = _clean(company);
    state = ClientProfile(name: n, company: c);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_nameKey, n);
      if (c == null) {
        await prefs.remove(_companyKey);
      } else {
        await prefs.setString(_companyKey, c);
      }
    } catch (_) {}
  }

  static String? _clean(String? v) {
    final t = v?.trim();
    return (t == null || t.isEmpty) ? null : t;
  }
}
