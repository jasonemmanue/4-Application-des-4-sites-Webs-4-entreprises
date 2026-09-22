# Intégration API — Flora Hair Mobile

## Principe

L'application mobile **ne dispose pas de sa propre API**. Elle consomme
directement la **même API FastAPI que le site web** et que l'administration
Next.js. Un seul backend, une seule base PostgreSQL, une seule administration.

```
┌──────────────────┐   ┌──────────────────┐   ┌──────────────────┐
│  Site public     │   │  Admin Next.js   │   │  App mobile      │
│  (Next.js 16)    │   │  (Next.js 15)    │   │  (Flutter)       │
└────────┬─────────┘   └────────┬─────────┘   └────────┬─────────┘
         │                      │                      │
         └──────────────────────┼──────────────────────┘
                                ▼
                      ┌───────────────────┐
                      │  API FastAPI      │  ← salon-coiffure/backend/
                      │  /api/v1          │     Railway en prod
                      └────────┬──────────┘
                               │
                      ┌────────┴──────────┐
                      │  PostgreSQL 16    │
                      │  + Redis 7        │
                      └───────────────────┘
```

Toute administration (services, coiffeuses, articles, réservations, avis,
devis) se fait via l'**admin Next.js**, jamais depuis l'application mobile.

## Adresse de l'API — quel `API_BASE_URL` selon le contexte

`lib/config/api_config.dart` lit `API_BASE_URL` via `String.fromEnvironment`,
avec **`https://api.florahair.online`** (API Railway de production) comme
valeur par défaut. Une application compilée en release atterrit chez une
cliente qui n'a rien à configurer.

| Contexte de test | Valeur à passer                                    |
|------------------|----------------------------------------------------|
| Production (release, cliente)     | *(défaut)* `https://api.florahair.online` |
| Émulateur Android + Docker local  | `http://10.0.2.2:8000`                |
| Simulateur iOS + Docker local     | `http://localhost:8000`               |
| Appareil physique (Wi-Fi commun)  | `http://<IP-du-poste-dev>:8000`       |

```bash
# Lancement, en fonction du contexte
flutter run                                                          # → prod (défaut)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000          # émulateur Android + Docker
flutter run --dart-define=API_BASE_URL=http://localhost:8000         # iOS + Docker
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8000      # appareil physique
flutter build apk --release                                          # release prod
```

## Démarrer la stack en local (Docker)

Le backend, la base PostgreSQL, Redis et Mailpit (SMTP de simulation) se
lancent d'un seul `docker compose up`. Depuis la racine du dépôt du site :

```bash
cd "C:/Users/hp/StudioProjects/Sites WEB Prestations de Services/salon-coiffure"
docker compose up -d db redis api
# Optionnel : + mailpit si vous voulez inspecter les courriels
```

Vérifications :

```bash
curl http://localhost:8000/                    # → { "message": "…", "docs": "/docs" }
curl http://localhost:8000/api/v1/services     # → liste JSON
open  http://localhost:8000/docs               # Swagger UI
```

**Alimentation de la base** — le seed est idempotent, il ignore ce qui est
déjà en base :

```bash
docker compose exec api python seed.py
```

**Réinitialisation complète** (perte de données) :

```bash
docker compose down -v            # supprime le volume PostgreSQL
docker compose up -d db redis api
docker compose exec api python seed.py
```

## Routes API consommées par l'application

Toutes préfixées par `/api/v1`. Ce que le mobile appelle, où c'est appelé.

### Public — aucune authentification

| Méthode | Route | Client Dart | Notes |
|---------|-------|-------------|-------|
| GET  | `/services?category=<slug>` | `ApiClient.fetchServices` | Filtre serveur, pas local |
| GET  | `/services/{slug}`          | `ApiClient.fetchServiceBySlug` | 404 si inconnu |
| GET  | `/categories`               | `ApiClient.fetchCategories` | |
| GET  | `/team`                     | `ApiClient.fetchTeam` | |
| GET  | `/team/{id}`                | `ApiClient.fetchTeamMember` | |
| GET  | `/bookings/available-slots` | `ApiClient.fetchAvailableSlots` | Requiert `service_id`, `team_member_id`, `date` |
| POST | `/bookings`                 | `ApiClient.createBooking` | Corps `BookingCreate` |
| POST | `/bookings/{id}/cancel`     | `ApiClient.cancelBooking` | Refus 409 si acompte payé |
| GET  | `/gallery`                  | `ApiClient.fetchGallery` | |
| GET  | `/articles?page=&per_page=` | `ApiClient.fetchArticles` | Publiés uniquement |
| GET  | `/articles/{slug}`          | `ApiClient.fetchArticleBySlug` | 404 si brouillon |
| GET  | `/videos`                   | `ApiClient.fetchVideos` | |
| GET  | `/reviews`                  | `ApiClient.fetchReviews` | Approuvés uniquement |
| POST | `/reviews`                  | `ApiClient.submitReview` | `rating` borné 1–5 |
| POST | `/contact`                  | `ApiClient.sendContactMessage` | |
| POST | `/quotes`                   | `ApiClient.submitQuoteRequest` | **Multipart**, photo obligatoire |

### Paiement (GeniusPay — Wave, Orange Money, MTN, Moov)

| Méthode | Route | Client Dart | Notes |
|---------|-------|-------------|-------|
| GET  | `/payments/config`            | `PaymentService.fetchConfig` | Consulter avant d'afficher l'étape de paiement |
| POST | `/payments/init`              | `PaymentService.initPayment` | Corps `{ booking_id, method?, phone? }` |
| GET  | `/payments/{transaction_id}`  | `PaymentService.checkStatus` | Polling toutes les 3 s |
| POST | `/payments/{tx}/retry`        | `PaymentService.retry` | Changement d'opérateur possible |
| POST | `/payments/{tx}/cancel`       | `PaymentService.cancel` | Vérifie d'abord auprès de GeniusPay |

`method` accepte : `wave`, `orange_money`, `mtn_money`, `moov_money`.

## Contrat des données

Le backend est la source de vérité. Les modèles Dart sous `lib/models/`
recopient fidèlement les schémas Pydantic de `backend/app/schemas/schemas.py` :

| Modèle Dart      | Schéma Pydantic       | Table SQL         |
|------------------|-----------------------|-------------------|
| `Service`        | `ServiceResponse`     | `services`        |
| `Category`       | `CategoryResponse`    | `categories`      |
| `TeamMember`     | `TeamMemberResponse`  | `team_members`    |
| `Booking`        | `BookingResponse`     | `bookings`        |
| `Article`        | `ArticleResponse`     | `articles`        |
| `Video`          | `VideoResponse`       | `videos`          |
| `GalleryItem`    | `GalleryItemResponse` | `gallery_items`   |
| `Review`         | `ReviewResponse`      | `reviews`         |
| `PaymentInit`    | `PaymentInitResponse` | `payments`        |
| `PaymentStatus…` | `PaymentStatusResponse` | `payments`      |

**Prix** : `price` et `price_max` sont des `float` côté API ; le franc CFA
n'ayant pas de subdivision, le formatage `_fmt` (dans `Service.formattedPrice`)
tronque à l'entier — un tarif enregistré avec des centimes n'affiche jamais
« 15 000,5 FCFA ».

**Créneaux** : `/bookings/available-slots` renvoie **tous** les créneaux du
salon (09:00 → 19:00 par pas de 30 min) avec un drapeau `available`. Le client
mobile ne remonte que ceux dont `available == true`.

**Erreurs** : l'API renvoie systématiquement `{ "detail": "…" }` sur 4xx/5xx.
`ApiClient._wrap` extrait ce détail pour afficher un message utile plutôt que
« DioException [receive timeout] ».

## En-tête `X-App-Source` — distinction mobile / web dans l'admin

Chaque requête sortante de l'application est marquée par un en-tête HTTP :

```
X-App-Source: android/1.0.0+1
```

La valeur est définie par [`ApiConfig.appSource`](../lib/config/api_config.dart)
et posée en dur dans le `BaseOptions` de Dio ([api_client.dart](../lib/services/api_client.dart)).
Elle doit rester **alignée sur `pubspec.yaml`** (`version: 1.0.0+1`) à chaque
sortie : c'est ce qui apparaîtra dans l'administration à côté des demandes.

Côté backend :
- Une dépendance `get_client_source` (dans
  `backend/app/core/dependencies.py`) valide l'en-tête (regex stricte,
  32 caractères max) et retombe sur chaîne vide s'il manque ou est mal formé.
- Les 4 routes publiques d'écriture (`POST /bookings`, `POST /reviews`,
  `POST /contact`, `POST /quotes`) l'injectent dans une colonne `source` de la
  ligne créée.
- Les 4 schémas de réponse (`BookingResponse`, `ReviewResponse`,
  `ContactResponse`, `QuoteRequestResponse`) exposent le champ ; l'admin lit
  simplement l'attribut.

Côté administration Next.js :
- Un composant partagé `<SourceBadge source={…} />` (dans
  `admin/components/SourceBadge.tsx`) rend une pastille compacte :
  - **📱 Android v1.0.0+1** (or, discret) si la valeur commence par
    `android/` ou `ios/`
  - **🌐 Site** (gris) si `source` est vide (demandes issues du site web)
- Une colonne « Canal » est ajoutée en tête des listes *Réservations*,
  *Avis*, *Contacts* et *Devis*.

**Ce que ce n'est pas** : ni un mécanisme d'authentification, ni un
contrôle d'accès. L'en-tête est facile à ajouter à la main avec `curl` ;
la valeur sert uniquement d'audit et de repère visuel. Toute règle
métier doit continuer à passer par les gardes habituelles
(`require_admin`, tokens JWT).

**Pour ajouter un nouveau canal** (ex. futur iOS, ou une intégration
Facebook) : rien à changer côté backend ni côté badge — seul le client
change son `X-App-Source`, le badge le rendra automatiquement.

## Déployer les changements en ligne de commande

Le projet salon-coiffure est branché sur Railway via son dépôt GitHub :
tout push sur `main` déclenche un redéploiement automatique des services
`api`, `admin` et `frontend`. Depuis le dépôt du site :

```bash
cd "C:/Users/hp/StudioProjects/Sites WEB Prestations de Services/salon-coiffure"
git add <fichiers modifiés>
git commit -m "…"
git push origin main
# Suivre le déploiement :
railway logs --service api    # ou : --service admin
```

Pour un déploiement direct sans passer par git (utile pour un test rapide) :

```bash
railway up --service admin    # depuis salon-coiffure/
```

⚠️ Le service `api` embarque désormais un rattrapage de schéma au démarrage
(`_apply_schema_patches_safely` dans `backend/app/main.py`) : les colonnes
ajoutées côté modèle sont créées automatiquement au premier redémarrage,
sans besoin de lancer `python seed.py` à la main.

## Ce qui n'est **pas** exposé au mobile

Ces routes existent mais restent réservées à l'admin :

- `POST/PUT/DELETE` sur `/services`, `/categories`, `/team`, `/articles`,
  `/videos`, `/gallery`, `/reviews`, `/settings`
- `/bookings` (listing, mise à jour, export.xlsx)
- `/quotes/{id}/reply`, `/quotes/{id}/decline`, `/quotes/{id}/gallery`
- `/stats/dashboard`, `/export/database.xlsx`
- `/auth/*`, `/upload`, `/registrations/*`, `/whatsapp/*`

L'application mobile **n'a pas de compte utilisateur** : elle n'a jamais de
jeton à envoyer, et ne devrait jamais tenter d'appeler ces routes.

## Recette locale — checklist bout-en-bout

1. `docker compose up -d db redis api` dans `salon-coiffure/`, puis
   `docker compose exec api python seed.py` si base neuve.
2. `curl http://localhost:8000/api/v1/services` → doit renvoyer une liste
   non vide.
3. Émulateur Android démarré, puis dans `flora_hair_mobile/` :
   ```bash
   flutter pub get
   flutter run
   ```
4. Écran d'accueil : services et coiffeuses s'affichent (preuve que
   `/services` et `/team` répondent).
5. Réservation → choisir un service, une coiffeuse, une date → l'écran des
   créneaux doit se peupler (`/bookings/available-slots`).
6. Compléter les infos client → confirmer → un `POST /bookings` doit
   apparaître dans les journaux :
   ```bash
   docker compose logs -f api
   ```
7. Admin (`http://localhost:3600` si l'admin tourne aussi) → la réservation
   apparaît dans le tableau *Réservations*.
8. Devis photo → envoyer une photo depuis la galerie du téléphone →
   `POST /quotes` en multipart → la demande apparaît dans l'admin section
   *Estimations*.

## Débogage courant

| Symptôme | Cause probable |
|----------|----------------|
| `Connection refused` sur émulateur | `API_BASE_URL` non défini, ou pointant `localhost` au lieu de `10.0.2.2` |
| `Connection refused` sur appareil physique | IP du poste changé, ou pare-feu Windows qui bloque le port 8000 |
| Réservation créée mais planning vide côté admin | Rafraîchir : le seed a peut-être ignoré vos services (`slug` déjà pris) |
| `/payments/init` renvoie 503 | `GENIUSPAY_*` non renseignés dans `.env` — normal en dev, l'app doit basculer sur « acompte à régler sur place » |
| CORS bloqué… | Dio n'utilise pas CORS. Si le message vient du navigateur (tests web Flutter), ajouter l'origine à `CORS_ORIGINS` dans `.env` du backend |
| Créneaux tous marqués `available: false` | `service.duration_minutes` supérieur à la plage d'ouverture, ou coiffeuse en congé — vérifier `team_availability` |

## Mises à jour côté backend — quoi vérifier avant de casser le mobile

Avant tout changement de `backend/app/api/v1/routes/` ou
`backend/app/schemas/schemas.py`, considérer que **le mobile lit aussi**. En
particulier :

- Retirer un champ d'une `*Response` (ex. `deposit_amount` de
  `BookingResponse`) casse le parsing Dart.
- Renommer une route publique (`/services/{slug}`, `/bookings/…`,
  `/payments/…`) casse le mobile silencieusement — le site sera migré, pas
  l'app en circulation.
- Restreindre une route publique à `require_admin` empêche le mobile de
  s'en servir : il n'a pas de jeton.

Ajouter des champs facultatifs et des routes est en revanche sans risque : le
parsing Dart ignore les clés inconnues.
