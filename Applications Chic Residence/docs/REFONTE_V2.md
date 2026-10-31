# Refonte v2.0.0 des 3 applications (2026-10-31)

Refonte UI/UX d'après la maquette de l'exploitant, et remise en conformité des
3 applications avec le contrat réel de l'API FastAPI.

| Application | Version | APK à la racine du dépôt |
|---|---|---|
| Client | 2.0.0+3 | `Chic-Residence-Client-v2.0.0.apk` |
| Gestionnaire | 2.0.0+2 | `Chic-Residence-Gestionnaire-v2.0.0.apk` |
| Backoffice | 2.0.0+2 | `Chic-Residence-Backoffice-v2.0.0.apk` |

Les `*.apk` sont exclus de Git (`.gitignore`) : ils restent sur le poste.

## Design

- Fond crème `#FFF9F2`, titres bleu nuit `#12294B`, actions rouge-orangé
  `#F04E2E`, étoiles `#F5A623`, police Poppins. Mêmes valeurs dans les 3 apps.
- **Logo** : celui de l'application (`assets/branding/logo-full.png`, doré), en
  haut à gauche de l'accueil. Le logo de la maquette n'a pas été repris.
- Navigation client : Accueil, Explorer, Favoris, Réservations, Profil.
- Navigation backoffice : Accueil, Logements, Réservations, Terrain, Plus. Le
  menu latéral de `CLAUDE.md` est remplacé par ces onglets.

## Moyens de paiement

Fichiers officiels copiés de `residences-meublees/frontend/public/images/paiement/`
vers `Application client Mobile/assets/paiement/` : `wave.png`,
`orange-money.svg`, `mtn-momo.png`, `carte-bancaire.svg`. Ils sont posés sur une
tuile blanche, groupés comme sur le site : « Mobile Money (Côte d'Ivoire) » et
« Carte bancaire (partout dans le monde) ».

La liste affichée vient de `GET /payments/config` : retirer un moyen par
`PAYMENT_CHANNELS` côté serveur le retire de l'application.

## Pourquoi le backoffice mobile refusait les identifiants du web

Le mot de passe était **accepté** par le serveur. C'est l'application qui
échouait ensuite, et tout échec s'affichait « Identifiant ou mot de passe
incorrect » :

1. `POST /auth/login` répond `{access_token, token_type}`. L'application lisait
   `token` et `user`.
2. Le profil se lit à part (`GET /auth/me`) et son `id` est un UUID. Le modèle
   faisait `(json['id'] as num)`.

Le message d'erreur distingue maintenant un vrai refus (401) d'une panne réseau
ou serveur. Un compte qui n'a pas le rôle `admin` reçoit un message dédié, car
toutes les routes d'administration lui répondraient 403.

## Backend

`GET /cleaning-tasks`, `GET /cleaning-tasks/{id}` et `.../photos` exigeaient un
jeton de personnel : l'écran Terrain du backoffice, connecté avec un jeton admin,
recevait 401. Nouvelle garde `get_current_staff_or_admin`, en lecture seule : les
actions de terrain (démarrer, terminer, valider) restent réservées au personnel.

⚠️ **À déployer** : commit `fbb765c` poussé sur `Site-residence-meublees`, mais
le service `api` ne se déploie pas au push (dernier déploiement : 2026-10-11, par
`railway up`). Tant que ce n'est pas fait, l'écran Terrain du backoffice affiche
une erreur ; le reste fonctionne. Depuis la racine du dépôt backend :
`railway up --service api`.

## Corrections de contrat

| App | Avant | Maintenant |
|---|---|---|
| Client | statut `success` attendu : un paiement réussi restait « en attente » | `succeeded` reconnu |
| Client | `checkout_url` lu : la page Wave / carte ne s'ouvrait jamais | `payment_url` |
| Client | `amount as num` plantait sur le `Decimal` texte de l'API | montant reparsé |
| Client | décompte de 90 s : la tentative expirait pendant `*133#` | 5 minutes, comme le site |
| Client | champ email obligatoire, que l'API ne prend plus | retiré |
| Client | préfixe contrôlé sur `+22507…` : refus à tort | 10 chiffres nationaux |
| Client | 12 logements sur 21 (limite par défaut de l'API) | `limit=100` |
| Client | note et disponibilité lues aux mauvais champs | `rating_average`, `availability_summary` |
| Client | date déjà prise cliquable | dates prises désactivées, séjour enjambant refusé |
| Client | formulaire de contact factice (aucun envoi) | `POST /contact` |
| Client | WhatsApp ouvert d'office après paiement | retiré : le reçu part du serveur |
| Gestionnaire | `token`, `user`, ids entiers, `controlled`, `phase`, `/staff/stats`, `token` FCM | `access_token`, `staff`, UUID, `validated`, `?label=`, `/staff/stats/me`, `fcm_token` |
| Backoffice | écrans « en construction », performance inventée | écrans réels, chiffres de l'API |

## Ce qui circule entre les applications

Une seule API, une seule base : l'application cliente, le site, l'admin web, le
backoffice mobile et le gestionnaire voient les mêmes données.

| Action | Route | Visible dans |
|---|---|---|
| Réservation depuis l'app | `POST /bookings` | Réservations (web + mobile) |
| Paiement | `POST /payments/init` | Paiements ; réservation confirmée |
| Message | `POST /contact` | Messages (web + mobile) |
| Avis | `POST /reviews` | Modération, puis l'app une fois approuvé |
| Logement fermé, date bloquée | `PATCH /residences/{id}/status`, `PUT /availability/{id}` | App et site |
| Téléphone, WhatsApp, adresse | `PUT /settings/{clé}` | App (`GET /settings/public`), sans nouvelle version |
| Séjour marqué terminé | `PUT /bookings/{id}/status` | Tâche créée pour le gestionnaire |
| Travail du gestionnaire | `/cleaning-tasks/...` | Écran Terrain du backoffice |

**Réservations du client** : il n'a pas de compte et l'API ne les liste qu'à
l'administrateur. L'onglet lit donc une liste locale (`booking_history.dart`) et
relit l'état de l'acompte sur `GET /payments/{référence}`. Elles ne suivent pas
le client sur un autre téléphone.

## Reste sur l'admin web uniquement

Le backoffice mobile ne couvre pas encore : articles, vidéos, FAQ, tarifs
saisonniers, export Excel, et les champs en anglais des fiches.

⚠️ Le formulaire de logement mobile ne touche pas à ces champs anglais : `PUT
/residences/{id}` n'écrase que les champs envoyés.

## Vérifications

- `flutter analyze` sans erreur et `flutter test` sur les 3 apps.
- Circuit de 34 contrôles sur le vrai backend, lancé en local sur une base SQLite
  jetable : connexion admin, réservation, message, avis, statut, calendrier,
  coordonnées, personnel, tâches, statistiques.

**Non vérifié** : aucun APK lancé sur un appareil ni un émulateur (à la demande de
l'exploitant), connexion avec le vrai compte admin de production, paiement réel.

## Compiler

Le chemin du dépôt contient un accent, qui fait échouer la compilation : copier
chaque application dans `C:\CR-build\` (voir `SETUP.md` § 9), puis
`flutter build apk --release`. La signature vient de `android/key.properties`.
