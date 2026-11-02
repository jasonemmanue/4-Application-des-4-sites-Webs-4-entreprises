# v1.3.0+4 : notifications push du salon (2026-11-02)

Le salon prévient désormais le téléphone de la cliente, même application fermée.

| Événement | Déclenché par | Message |
|---|---|---|
| Rendez-vous confirmé | statut changé dans l'administration, ou acompte payé | « Rendez-vous confirmé » |
| Rendez-vous annulé | administration | « Rendez-vous annulé » |
| Demande expirée faute d'acompte | balayage automatique (30 min) | « Rendez-vous annulé » |
| Prestation terminée | administration | « Merci de votre visite » (ouvre les avis) |
| Acompte reçu | encaissement constaté | « Acompte reçu » |

## Fonctionnement

```
App ── POST /bookings { push_token } ──────────► API (bookings.push_token)
App ── PUT /bookings/{id}/push-token ──────────► API   (jeton renouvelé)
Admin ── change le statut ──► API ── FCM HTTP v1 ──► téléphone
```

- **Backend** : `backend/app/services/push_service.py` du dépôt du site. Clé :
  variable Railway `FIREBASE_CREDENTIALS_JSON` (compte de service du projet
  `flora-hair-app`), enregistrée et vérifiée le 2026-11-02. Envoi en arrière-plan :
  une panne de Firebase ne ralentit jamais l'administration ni un paiement.
- **Application** : le jeton FCM part avec la réservation ; à la première ouverture
  de cette version, et à chaque renouvellement par Firebase, il est rattaché aux
  rendez-vous à venir déjà pris.
- **Pas de doublon** : la notification porte le même identifiant que celui que
  l'application calcule quand elle constate le changement par
  `GET /bookings/{id}/status`. Elle n'apparaît qu'une fois dans la boîte.
- **Confidentialité** : le jeton n'est jamais renvoyé par l'API ; un jeton refusé
  par Google (application désinstallée) est effacé.

## Pas fait

- **Rappel la veille du rendez-vous** : le backend n'a pas de tâche planifiée ; il
  en faudrait une (processus séparé ou ordonnanceur Railway).
- **Campagnes depuis l'administration** : possibles depuis la console Firebase
  en attendant.
- Les rendez-vous pris depuis le **site web** ne reçoivent rien : pas d'application,
  pas de jeton.

## Vérifié / non vérifié

- Tests backend `tests/test_push_service.py` (format FCM v1, réutilisation du
  jeton OAuth, jeton périmé effacé, panne réseau, clé absente ou mal formée,
  route du jeton) ; tests Flutter (jeton envoyé avec la réservation).
- La clé est acceptée par Google (jeton d'accès FCM obtenu).
- **Non vérifié** : la réception réelle sur un téléphone. Recette : réserver depuis
  l'app, confirmer le rendez-vous dans l'administration, la notification doit
  arriver application fermée.
