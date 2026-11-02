# v1.2.0+3 : reprise réseau, notifications, FAQ (2026-11-02)

Transposition de la v2.1 de Chic Residence (`Applications Chic Residence/docs/V2_1_GERANT_NOTIFICATIONS.md`),
limitée à ce que permet le backend du salon **sans le modifier**.

## Repris

| Chic Residence v2.1 | Flora Hair v1.2 |
|---|---|
| Bandeau « Hors connexion », lectures (GET) retentées 2 min, envois jamais rejoués | Identique (`lib/services/network.dart`, intercepteur `RetryOnNetwork` du client Dio) |
| Rafraîchissement automatique | Rendez-vous relus toutes les 60 s, au retour au premier plan, au retour du réseau et à chaque push ; catalogue rechargé au retour du réseau (`lib/app.dart`) |
| Push Firebase initialisé | Initialisé sans bloquer l'ouverture ; les messages reçus vont dans la boîte |
| Boîte de notifications (cloche + pastille) | Cloche de l'accueil et « Mon espace » > Notifications (`lib/screens/inbox/`) |
| FAQ | « Mon espace » > Questions fréquentes (`lib/screens/more/faq_screen.dart`) |
| Noter et partager l'application | « Mon espace », plus la version de l'app |
| Contraste des puces choisies | Puces de la galerie en blanc sur bordeaux ; texte brun sur l'or |

## D'où viennent les notifications

Le backend du salon n'a **ni table de notifications ni envoi push**. La boîte est
donc alimentée par l'application elle-même :

- **Décisions du salon** : quand `GET /bookings/{id}/status` montre un rendez-vous
  confirmé, annulé (par le salon ou faute d'acompte), terminé, ou un acompte reçu.
  Un même événement n'est noté qu'une fois.
- **Push** : messages envoyés depuis la console Firebase (Messaging > Campagnes),
  projet du `google-services.json`. Seuls ceux reçus application ouverte, ou
  touchés depuis la barre de notifications, entrent dans la boîte.

## Pas repris, et pourquoi

- **Relances et rappels envoyés par le serveur** (acompte, veille du rendez-vous,
  demande d'avis), **campagnes depuis l'administration**, **enregistrement des
  téléphones** : il faudrait au backend du salon des routes `/devices`, une table
  de notifications, des tâches de fond et une clé de compte de service Firebase.
- **FAQ administrable** : il n'y a pas de route `/faq` ; les réponses sont écrites
  dans l'application, d'après les règles appliquées par l'API.
- **Rôle gérant, fiches voyageurs, nettoyage** : propres à la résidence.

## Non vérifié

- « Noter l'application » ouvre la fiche Play Store de `com.florahair.flora_hair_mobile` :
  elle n'existe que si l'application y est publiée.
- Le push réel, et le rendu sur un téléphone.
