import 'api_client.dart';
import 'session_service.dart';

/// Gestion des favoris via session anonyme.
///
/// API reelle : POST /favorites {session_id, residence_id} pour ajouter,
/// DELETE /favorites/{residence_id}?session_id=... pour retirer.
/// Un "toggle" cote client cache cette dualite en decidant selon l'etat local.
class FavoritesService {
  FavoritesService(this._api, this._session);
  final ApiClient _api;
  final SessionService _session;

  /// Backend renvoie `List[ResidenceOut]` — on ne retient ici que l'ID.
  Future<List<String>> list() async {
    final res = await _api.dio.get('/favorites',
        queryParameters: {'session_id': _session.sessionId});
    final items = (res.data as List?) ?? [];
    return items
        .map((e) => (e as Map)['id'].toString())
        .toList();
  }

  /// Backend : `POST /favorites` est un TOGGLE qui renvoie `{added: bool}`.
  /// On respecte le contrat côté client (add décide via l'état local avant
  /// d'appeler ce service, donc ce POST doit toujours *ajouter*). Si la valeur
  /// `added: false` revient, on retire aussitôt pour rester cohérent.
  Future<bool> add(String residenceId) async {
    final res = await _api.dio.post('/favorites', data: {
      'session_id': _session.sessionId,
      'residence_id': residenceId,
    });
    final added = (res.data as Map?)?['added'] == true;
    if (!added) {
      // Le backend a interprété comme un retrait — on rebascule.
      await _api.dio.post('/favorites', data: {
        'session_id': _session.sessionId,
        'residence_id': residenceId,
      });
    }
    return true;
  }

  Future<bool> remove(String residenceId) async {
    await _api.dio.delete('/favorites/$residenceId',
        queryParameters: {'session_id': _session.sessionId});
    return true;
  }

  /// Toggle logique cote client : appelle add ou remove selon [isCurrentlyFav].
  Future<bool> toggle(String residenceId, {required bool isCurrentlyFav}) async {
    if (isCurrentlyFav) {
      await remove(residenceId);
      return false;
    }
    await add(residenceId);
    return true;
  }
}
