# Integration Mobile ↔ API — Eslie Sport

Ce document decrit comment l'application Flutter `eslie_sport_mobile` consomme
l'API FastAPI du site `salle-de-sport`. **Il n'existe qu'une seule API** ;
l'admin web, le site public et l'application mobile pointent tous vers la meme
instance (Postgres partagee).

## Environnements

| Environnement | Base URL | Utilise pour |
|---------------|----------|--------------|
| `production` (defaut) | `https://api-production-fc58.up.railway.app` | Boutique de Play Store, releases signees |
| `staging` | idem `production` (a distinguer si un deploiement de preview est cree) | QA avant release |
| `local` | `http://10.0.2.2:8010` (emulateur) / `http://<ip-hote>:8010` (telephone reel) | Developpement contre `docker-compose.yml` du site |

Le choix d'environnement se fait au build :

```bash
# Production (defaut)
flutter run

# Docker local
flutter run --dart-define=API_ENV=local

# URL personnalisee (tunnel ngrok, staging dedie...)
flutter run --dart-define=API_BASE_URL=https://ma-preview.up.railway.app
```

## Endpoints consommes

Tous prefixes par `/api/v1`.

| Verbe | Chemin | Methode Dart |
|-------|--------|--------------|
| GET | `/activities/?category=&level=&page=&limit=` | `ApiClient.getActivities` |
| GET | `/activities/{slug}` | `ApiClient.getActivityBySlug` |
| GET | `/schedule/?date=` | `ApiClient.getSchedule` |
| GET | `/schedule/weekly` | `ApiClient.getWeeklySchedule` |
| GET | `/subscriptions/` | `ApiClient.getSubscriptions` |
| POST | `/subscriptions/orders` | `ApiClient.createSubscriptionOrder` |
| GET | `/coaches/` `/coaches/{id}` | `ApiClient.getCoaches` / `getCoachById` |
| GET | `/equipment/?zone=` | `ApiClient.getEquipment` |
| GET | `/articles/?page=&limit=` | `ApiClient.getArticles` |
| GET | `/articles/{slug}` | `ApiClient.getArticleBySlug` |
| GET | `/videos/?category=` | `ApiClient.getVideos` |
| GET | `/transformations/?featured_only=` | `ApiClient.getTransformations` |
| GET | `/reviews/` | `ApiClient.getReviews` |
| POST | `/reviews/` | `ApiClient.submitReview` |
| POST | `/contact/` | `ApiClient.sendContact` |
| GET | `/settings/public` | `ApiClient.getPublicSettings` |
| POST | `/enrollments/` | `ApiClient.createEnrollment` |
| GET | `/enrollments/slot/{id}/availability?specific_date=` | `ApiClient.getSlotAvailability` |
| GET | `/payments/config` | `ApiClient.getPaymentConfig` |
| POST | `/payments/init` | `ApiClient.initPayment` |
| GET | `/payments/{ref}` | `ApiClient.getPaymentStatus` |
| POST | `/payments/{ref}/cancel` | `ApiClient.cancelPayment` |
| POST | `/payments/{ref}/push/resend` | `ApiClient.resendPush` |
| GET | `/health` | `ApiClient.ping` |

**A noter :**

- `/settings/public` retourne `list[{id, key, value}]` cote backend. L'ApiClient
  aplatit cette liste en `Map<String,String>` avant de construire `PublicSettings`.
- `/enrollments/slot/{id}/availability` (singulier). L'ancien code utilisait
  `/enrollments/slots/...` — c'est corrige.
- `/activities/{slug}` est appelee directement (l'ancien code parcourait toute
  la liste des activites).
- `/subscriptions/orders` (sans trailing slash). FastAPI acceptait aussi
  `/orders/` via un 307, mais l'appel direct evite l'aller-retour.

## Contrat paiement

Le montant n'est jamais transmis par le client — c'est le backend qui recalcule
l'acompte de 50 % depuis la formule choisie (`PAYMENT_DEPOSIT_RATE`).

Codes operateurs acceptes (`method` dans `POST /payments/init`) :

| Enum Dart | Code envoye | Notes |
|-----------|-------------|-------|
| `PaymentOperator.wave` | `wave` | Portefeuille QR (URL a ouvrir dans le navigateur externe) |
| `PaymentOperator.orangeMoney` | `orange_money` | Numero `07XXXXXXXX` |
| `PaymentOperator.mtnMobileMoney` | `mtn_mobile_money` | Numero `05XXXXXXXX` |

Le polling cote client (`PaymentService.pollStatus`) sonde `/payments/{ref}`
toutes les 3 s pendant 90 s au maximum. Passe ce delai, le paiement n'est PAS
annule cote serveur : la notification GeniusPay peut toujours arriver.

## Codes d'erreur

`ApiException` porte le `statusCode` HTTP. Traduction cote UI :

| Code | Comportement mobile |
|------|---------------------|
| 400 / 422 | `SnackBar` avec le message renvoye par le backend |
| 404 | Ecran vide / `EmptyState`, PAS d'erreur |
| 409 | Conflit metier (reservation deja reglee) — message clair |
| 429 | « Trop de tentatives, patientez un instant » |
| 5xx | Bandeau reseau, bouton `Reessayer` |

## Configuration Android

Le build de debug charge `network_security_config_debug.xml` qui autorise
le HTTP en clair uniquement vers `10.0.2.2`, `localhost` et `127.0.0.1`.
Le build release ne l'inclut pas — HTTPS obligatoire vers Railway.

## Tests locaux avec Docker

Depuis le repertoire `salle-de-sport/` :

```bash
docker compose up -d db redis api
curl http://localhost:8010/health
# => {"status":"ok"}
```

Puis dans `eslie_sport_mobile/` :

```bash
flutter run --dart-define=API_ENV=local
```

Pour tester sur un telephone reel branche en USB (meme reseau que l'hote),
remplace `10.0.2.2` par l'IP LAN de la machine :

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8010
```

## Push notifications (Firebase Cloud Messaging)

`PushNotificationService.initialize()` est defensif : si
`google-services.json` n'est pas encore fourni, l'app demarre quand meme.
Le backend n'expose pas encore d'endpoint pour enregistrer le token FCM —
cette integration reste a faire quand la salle voudra pousser des rappels.
