# v1.2.0 : réseau, notifications, partage (2026-11-02)

Report dans Ruah des évolutions de Chic Résidences v2.1.0, limité à ce qui a
du sens pour une app vitrine sans comptes. APK :
`ruah-statistics-v1.2.0-release.apk` à la racine du dossier Ruah, hors Git.

| Chic Résidences v2.1 | Ruah 1.2 |
|---|---|
| Bandeau hors connexion, lectures retentées | Repris (`lib/services/network.dart`) |
| Rechargement automatique | Au retour du réseau, et au retour dans l'app après 5 min |
| Push Firebase initialisé | Repris, abonnement au sujet FCM `actualites` |
| Boîte de notifications (API) | Boîte **locale** des push reçus, cloche avec pastille |
| Partager l'application | Repris, avec le lien du site |
| Noter l'application | **Non** : l'app n'est pas sur le Play Store (404) |
| FAQ (`GET /faq`) | **Non** : ni l'API ni le site du cabinet n'ont de FAQ |
| Contraste des puces choisies | Corrigé : en clair, une puce choisie avait la même couleur qu'une puce normale |
| Gérant, fiches CNI, nettoyage, campagnes | Sans objet chez Ruah |

## Réseau

- Une lecture (GET) coupée est retentée toutes les 3 s pendant 2 min, et dès
  que le réseau revient.
- Un envoi (devis, contact, témoignage, livre blanc) n'est **jamais** rejoué
  seul : il a pu arriver au serveur, le rejouer créerait un doublon.
- Au retour du réseau, tous les contenus se rechargent sans écran de chargement.

## Notifications

Le backend du cabinet n'a ni comptes ni enregistrement d'appareils. Chaque
téléphone s'abonne donc au sujet FCM `actualites`, et le cabinet envoie depuis
la **console Firebase** (projet `ruah-statistics-mobile`) :

1. Messaging > Nouvelle campagne > Notifications Firebase.
2. Titre et texte, puis Cible > **Sujet** > `actualites`.
3. Publier.

Le message s'affiche sur le téléphone. Il est aussi rangé dans la boîte de
l'app (Accueil > cloche, ou Profil > Notifications), que l'app soit ouverte,
en arrière-plan ou fermée. La boîte garde 50 messages, sur le téléphone
uniquement.

Les réponses aux devis restent sur WhatsApp. Une notification ciblée (« votre
devis a reçu une réponse ») demanderait d'enregistrer les appareils côté API,
comme `POST /devices` chez Chic Résidences.

## Vérifié

- `flutter test` : 14 tests, dont la boîte (doublons, limite, lecture),
  la non-répétition d'un envoi coupé et le bandeau.
- `flutter analyze` sans erreur.

**Non vérifié** : la réception réelle d'un push, et les écrans sur un téléphone.
