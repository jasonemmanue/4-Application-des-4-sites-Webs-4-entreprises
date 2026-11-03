# v2.1.0 : gérant, fiches voyageurs, notifications, relances (2026-11-02)

| App | Version | APK (racine du dépôt) |
|---|---|---|
| Client | 2.1.0+4 | `Chic-Residence-Client-v2.1.0.apk` |
| Gestionnaire | 2.1.0+3 | `Chic-Residence-Gestionnaire-v2.1.0.apk` |
| Backoffice | 2.1.0+3 | `Chic-Residence-Backoffice-v2.1.0.apk` |

Backend : commit `49eced7` de `Site-residence-meublees`, déployé sur Railway le
2026-11-02 (migration `a3e9c5d7f1b4`).

## « Les routes des tâches et du personnel ne marchent pas »

Les journaux de production depuis le 31/10 ne montrent **aucune erreur serveur**
sur ces routes : création, assignation, démarrage, photos, rejet, validation
forcée ont tous répondu 200/201. Ce qui ne marchait pas venait des applications :

- **Rien ne se rafraîchissait** : le travail d'un agent n'apparaissait au
  backoffice qu'en tirant l'écran. `AutoRefresh` recharge maintenant toutes les
  30 s, au retour de l'application, au retour du réseau et à chaque push.
- **Aucune notification ne pouvait arriver** : Firebase n'était initialisé dans
  aucune des 3 apps, et le serveur n'avait aucun envoi push.
- Un segment choisi (Agent / Contrôleur) s'affichait **noir sur bleu nuit** :
  `onSecondary` du thème valait noir par défaut.

## Rôle « gérant »

Nouveau rôle du personnel (`manager`), créé dans Backoffice > Plus > Personnel.
Il se connecte à l'**application gestionnaire** (téléphone + PIN) et y trouve :
Accueil (arrivées et départs du jour, demandes, messages), Logements (voir,
ajouter, modifier, calendrier, statut), Réservations, Voyageurs, Profil.

| Le gérant peut | Le gérant ne peut pas |
|---|---|
| logements : créer, modifier, statut, calendrier, photos | supprimer un logement |
| réservations : voir, confirmer, terminer, annuler | gérer les comptes du personnel |
| fiches voyageurs : créer, modifier, photographier | supprimer une fiche |
| messages, avis (modération), paiements (lecture) | réglages, campagnes |
| tableau de bord | **nettoyage** (tâches, assignation, validation) |

Côté API, ces routes passent par `get_current_manager_or_admin` ; le reste
garde `get_current_admin`. Un agent ou un contrôleur reçoit 403.

## Fiches voyageurs (pièce d'identité)

Depuis une réservation (« Enregistrer l'arrivée ») ou l'onglet Voyageurs : nom,
type et numéro de pièce, dates de délivrance et d'expiration, naissance,
nationalité, téléphone, adresse, photos recto et verso prises à l'appareil.

⚠️ **Les photos sont en base** (`guest_identities.photo_front/back`), jamais dans
`/uploads`, qui est public. Elles ne sortent que par
`GET /guests/{id}/photos/{face}` avec un jeton gérant ou admin, sans cache. Les
applications les lisent par Dio, pas par une URL d'image.

## Notifications

Une notification est **toujours** écrite en base, puis poussée par FCM si le
serveur est configuré. Chaque app a sa boîte de réception (cloche avec pastille) :

| Qui | Reçoit |
|---|---|
| Administrateur | nouvelle demande, acompte reçu, message, avis à modérer, arrivée enregistrée, nettoyage terminé, **logement prêt**, fin de séjour |
| Gérant | nouvelle demande, acompte reçu, message, avis, logement prêt |
| Agent | tâche assignée, nettoyage à reprendre |
| Contrôleur | logement à contrôler |
| Client (par téléphone) | réservation confirmée, relance d'acompte, veille d'arrivée, demande d'avis, campagnes |

**Campagnes** (Backoffice > Plus > Campagnes et relances) : un message aux
clients, au personnel, aux administrateurs ou à tous, tout de suite ou à une
date. Annulable tant qu'il n'est pas parti.

**Relances automatiques** (tâches de fond de l'API, toutes les 60 s) : acompte
non réglé après 12 min, veille d'arrivée, demande d'avis le lendemain du
départ. Chacune ne part qu'une fois (`dedup_key`).

### Brancher le push (à faire par l'exploitant)

Sans clé, tout fonctionne mais les messages restent dans les boîtes de
réception, sans s'afficher sur l'écran du téléphone.

1. Console Firebase, projet `chic-residence-meuble` > Paramètres du projet >
   Comptes de service > **Générer une nouvelle clé privée** (fichier JSON).
2. Railway, service `api` > Variables : `FIREBASE_CREDENTIALS_JSON` = le contenu
   du fichier, sur une ligne. Ou en ligne de commande, depuis le dossier du
   fichier :

   ```bash
   railway variables --service api --set "FIREBASE_CREDENTIALS_JSON=$(cat cle.json | tr -d '\n')"
   ```
3. Vérifier : Backoffice > Plus > Campagnes ne montre plus l'avertissement
   « Push non configuré ».

Ne jamais commiter ce fichier : c'est une clé privée.

## Nettoyage automatique à la date de départ

Backoffice > Plus > Nettoyage automatique : activer, choisir l'agent et le
contrôleur assignés d'office. Le jour du départ, la réservation confirmée passe
« terminée », la tâche est créée et assignée, l'agent est prévenu ; quand le
contrôleur valide, l'administrateur et les gérants reçoivent « Logement prêt ».
Réglages : clés `auto_cleaning_enabled`, `auto_cleaning_agent_id`,
`auto_cleaning_controller_id` de `settings`.

## Application cliente

- Cloche de l'accueil et Profil > Notifications : boîte de réception du téléphone.
- Profil : Questions fréquentes (`GET /faq`), **Noter l'application** (fiche
  Play Store), Partager l'application.
- La réservation transmet la session du téléphone (`bookings.session_id`), qui
  sert aux relances et rappels.
- Mode sombre : segment et puce choisis lisibles (texte blanc).

## Carte bancaire et Wave : retour dans l'application (client 2.1.1)

Après la page Stripe, la passerelle renvoyait le client de l'application sur
la page « succès » du **site**, faite pour la fenêtre annexe du navigateur : il
restait bloqué dans le navigateur, loin de l'app. Comme Prepaxia :

- l'app envoie `return_to: "app"` à `POST /payments/init` et `/retry` ;
- la passerelle renvoie alors sur `GET /payments/retour?r=…` (API), qui
  vérifie le paiement auprès de GeniusPay, l'applique, et propose « Revenir
  dans l'application » (lien `chicresidence://paiement`, déclaré dans le
  manifeste ; `flutter_deeplinking_enabled` à `false` pour que go_router ne le
  prenne pas pour une route) ;
- la page de paiement s'ouvre dans un **onglet intégré** (Chrome) et non le
  navigateur externe ; l'app le referme dès qu'elle lit le verdict.

Le site garde son parcours (`return_to: "site"` par défaut).

## Coupure et retour du réseau (les 3 apps)

Repris de Prepaxia (`reprise_reseau.dart`), simplifié : bandeau « Hors
connexion » ; une lecture coupée est retentée toutes les 3 s pendant 2 minutes,
et dès que le réseau revient ; un enregistrement n'est **jamais** rejoué seul
(une réservation ou un paiement ne doit pas partir deux fois). Au retour du
réseau, les écrans se rechargent. Session : un 401 fait vérifier `/auth/me`
avant toute déconnexion (backoffice) ; la déconnexion détache le téléphone des
notifications du compte.

## Vérifications

- Production, sans compte : 18 contrôles (boîte client, appareils, gardes
  d'accès des nouvelles routes), tous passés après déploiement.
- Production, avec compte : `backend/tests/recette_mobile.py` du dépôt backend,
  à lancer par l'exploitant (il demande le mot de passe admin) : gérant, fiche
  CNI et confidentialité des photos, tâche complète avec les notifications de
  chaque rôle, campagnes. Il crée des données « TEST » et les retire.
- `flutter analyze` sans erreur, `flutter test` sur les 3 apps.

**Non vérifié** : le push réel (clé Firebase absente), les écrans sur un
téléphone, les tâches de fond le jour d'un vrai départ.
