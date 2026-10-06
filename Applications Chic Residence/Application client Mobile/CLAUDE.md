# CLAUDE.md — Application Mobile Client Chic Residence

## Identite du projet

**Nom** : Chic Residence Mobile
**Type** : Application client Flutter (Android) — style Airbnb
**Entreprise** : CHIC RESIDENCE — Residences meublees
**Slogan** : "Votre chez-vous, ailleurs"
**Localisation** : Dans le dos de l'Ivoire Trade Center (ITC), Abidjan, Cote d'Ivoire
**Contact** : chicresidencemeublee@gmail.com | +225 05 45 07 98 50
**WhatsApp** : +225 05 45 07 98 50
**Devise** : FCFA (XOF) — entiers uniquement, jamais de decimales
**Langue** : Francais (fr)
**Portfolio** : 21 logements meubles, 21 chambres, 21 salles de bain, capacite 42 personnes
**Types** : Studio, Appartement, Villa, Duplex, Chambre

## Inspiration visuelle

L'application s'inspire fortement de **Airbnb** :
- Barre de recherche prominente en haut
- Chips de categories horizontales (Tous, Studios, Appartements, Villas, Duplex, Chambres)
- Cards de residences avec grande photo, titre, prix/nuit, note, badge favori (coeur)
- Bottom navigation bar avec 5 onglets
- Ecran profil minimaliste
- Galerie plein ecran avec navigation
- Calendrier de disponibilite interactif

## Relation avec le site web

L'application mobile est le compagnon du site web Next.js de CHIC RESIDENCE.
Elle consomme la **meme API FastAPI** (backend existant) que le site web.
L'**administration reste sur le site web** (admin Next.js sur port 3006) + l'app backoffice mobile.

**Backend existant** : FastAPI + PostgreSQL 16 + Redis 7
**API base** : `/api/v1`
**Paiement** : GeniusPay (Wave, Orange Money, MTN Mobile Money) — depot 50%

## Architecture technique

```
chic_residence_mobile/
  lib/
    main.dart
    app.dart
    config/
      api_config.dart
      theme.dart               # Theme rouge/sable/orange
      routes.dart
    models/
      residence.dart
      seasonal_price.dart
      availability.dart
      booking.dart
      payment.dart
      article.dart
      video.dart
      review.dart
      faq_item.dart
      favorite.dart
      contact_message.dart
    services/
      api_client.dart
      payment_service.dart
      favorites_service.dart   # Gestion des favoris (session anonyme)
      whatsapp_service.dart
      push_notification_service.dart
      session_service.dart     # ID de session anonyme (UUID)
    screens/
      home/                    # Accueil style Airbnb
      search/                  # Recherche avec autocomplete
      residences/              # Catalogue filtrable + detail
      booking/                 # Tunnel de reservation multi-etapes
      favorites/               # Liste des favoris
      compare/                 # Comparaison cote a cote (max 3)
      articles/                # Blog / articles lifestyle
      videos/                  # Galerie videos
      reviews/                 # Avis clients
      faq/                     # FAQ accordeon par categorie
      contact/                 # Contact + carte
      payment/                 # Ecrans paiement
      profile/                 # Profil / parametres
    widgets/
      residence_card.dart      # Card style Airbnb
      search_autocomplete.dart
      category_chips.dart
      residence_gallery.dart   # Galerie plein ecran
      availability_calendar.dart
      price_calculator.dart
      amenity_icons.dart
      star_rating.dart
      availability_badge.dart
      favorite_button.dart
      booking_form.dart
      payment_step.dart
      operator_grid.dart
      payment_overlay.dart
      payment_countdown.dart
      review_card.dart
      review_form.dart
      article_card.dart
      faq_accordion.dart
      contact_form.dart
      compare_table.dart
      section_heading.dart
      loading_state.dart
      error_state.dart
      empty_state.dart
```

## Design System

### Palette de couleurs (heritee du site web)

| Token | Hex | Usage |
|-------|-----|-------|
| primary-500 (rouge) | `#EF4444` | Couleur primaire |
| primary-600 | `#DC2626` | Boutons principaux |
| primary-700 | `#B91C1C` | Etats presses |
| primary-800 | `#991B1B` | Gradients |
| accent-500 (orange) | `#F97316` | Accent |
| accent-600 | `#EA580C` | Accent fonce |
| sand-500 (beige/or) | `#D4A05A` | Elements decoratifs, badges |
| sand-100 | `#FAF3E8` | Fonds clairs |
| sand-200 | `#F5E6D0` | Surfaces elevees |

### Gradients

- **Primary** : `#991B1B -> #DC2626 -> #EF4444 -> #F97316` (135deg)
- **Accent** : `#EF4444 -> #EA580C` (135deg)
- **Gold** : `#D4A05A -> #E2B97E -> #F5E6D0` (135deg)
- **Dark** : `#1C1917 -> #44403C -> #7F1D1D` (135deg)

### Mode sombre

- Surface : `#111827`
- Cartes : `#1F2937`
- Bordures : `#374151`
- Texte : `#F3F4F6`
- Texte attenue : `#9CA3AF`

### Mode clair

- Surface : `#FFFFFF`
- Cartes : `#FFFFFF`
- Bordures : `#E5E7EB`
- Texte : `#1F2937`
- Texte attenue : `#6B7280`

### Typographie

- **Titres** : Playfair Display (serif, elegance)
- **Corps** : Inter (sans-serif, lisibilite)

### Principes UI — Style Airbnb

- **Barre de recherche** : En haut de l'accueil, arrondie, avec icone loupe, placeholder "Rechercher une residence..."
- **Chips de categories** : Scroll horizontal sous la recherche (Tous, Studios, Appartements, Villas, Duplex, Chambres) avec icones
- **Cards** : Grande photo (ratio 4:3 ou 16:9), coins arrondis 16px, titre en gras, localisation, prix/nuit, note etoiles, bouton coeur favori en overlay
- **Galerie plein ecran** : Navigation horizontale, compteur de photos, bouton retour
- **Bottom sheet** : Pour les filtres avances (type, capacite, prix, equipements)
- **Animations** : Hero transitions entre liste et detail, parallax sur les galeries
- **Coins arrondis** : 16px pour les cartes, 24px pour la barre de recherche
- **Ombres** : Douces, style material elevation

## Ecrans et navigation

### Bottom Navigation Bar (5 onglets)

1. **Explorer** — Recherche, categories, residences populaires, articles lifestyle
2. **Favoris** — Liste des residences favorites (coeur)
3. **Reservations** — Historique et reservations en cours (a creer cote app)
4. **Messages** — Contact / messages (formulaire + historique)
5. **Profil** — Parametres, aide, mentions legales, se connecter/s'inscrire

### Ecran Explorer (Accueil style Airbnb)

- Barre de recherche avec autocomplete (recherche fuzzy Levenshtein)
- Chips de filtres par type de residence
- Section "Residences populaires" (cards horizontales scroll)
- Section "Pour votre prochain sejour" (grid 2 colonnes)
- Section articles/blog

### Ecran Catalogue / Recherche

- Filtres avances en bottom sheet :
  - Type de residence (Studio, Appartement, Villa, Duplex, Chambre)
  - Ville
  - Capacite (nombre de personnes)
  - Fourchette de prix (slider)
  - Equipements (WiFi, piscine, parking, clim, cuisine, TV, lave-linge, gym, jardin, securite, ascenseur, balcon, meuble, groupe electrogene)
- Tri : Recommande, Prix croissant, Prix decroissant, Plus recent
- Resultats en cards style Airbnb

### Ecran Detail Residence

- Galerie photos plein ecran avec navigation
- Titre, localisation, type, capacite
- Badge de disponibilite (Libre / Occupe / Maintenance)
- Section equipements avec icones
- Calendrier de disponibilite interactif (vert = libre, rouge = occupe)
- Calculateur de prix en temps reel (appel API avec tarification saisonniere)
- Section avis avec notes
- Bouton "Reserver" fixe en bas
- Bouton "Comparer" (ajout a la comparaison, max 3)

### Ecran Comparaison

- Comparaison cote a cote de 2-3 residences
- Tableau comparatif : prix, capacite, equipements, note

### Tunnel de reservation (4 etapes)

1. **Dates** : Calendrier interactif, selection arrivee + depart, prix calcule
2. **Informations** : Nom, email, telephone, nombre de personnes, notes
3. **Confirmation** : Recapitulatif complet avec prix total (prix nuitees + frais de service 5%)
4. **Paiement** : Choix operateur Mobile Money, depot 50%

### Ecran Favoris

- Liste des residences favories
- Coeur toggle sur chaque card
- Persistance via session anonyme (UUID localStorage + API)
- Sans compte — le favori est lie a l'appareil

### Ecran Profil (refonte 2026-10-06 — voir `../docs/PROFIL_ET_PASTILLE.md`)

- Cloche + grand titre « Profil »
- Carte d'identite : avatar vert pale + nom de la derniere reservation
  (« Visiteur » sans reservation — il n'y a pas de compte)
- Deux cartes photo : Mes reservations, Mes favoris
- Carte large : Proposer votre logement (WhatsApp)
- Parametres, aide, apparence clair / auto / sombre, mentions legales, version

### Pastille « Aucun frais cache » (accueil)

Pastille flottante en bas de l'Explorer ; un tap ouvre un pop-up (bottom sheet
sur le navigateur racine) avec bouton « J'ai compris ». Masquee pour de bon
une fois lue. **Ne pas ecrire « tous frais inclus »** : le prix par nuit des
cartes est hors frais de service (5 %).

## Endpoints API a consommer

### Residences

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/residences?page=&type=&city=&capacity=&price_min=&price_max=&amenities=&sort=` | Catalogue filtre |
| `GET /api/v1/residences/{slug}` | Detail d'une residence |
| `GET /api/v1/residences/facets` | Filtres disponibles avec compteurs |
| `GET /api/v1/residences/suggestions?q=` | Autocomplete (fuzzy Levenshtein) |

### Disponibilite et prix

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/availability/{residence_id}?month=&year=` | Calendrier mensuel |
| `GET /api/v1/availability/{residence_id}/range?start=&end=` | Plage de dates |
| `GET /api/v1/seasonal-prices/{residence_id}` | Tarifs saisonniers |

### Reservations

| Endpoint | Usage |
|----------|-------|
| `POST /api/v1/bookings` | Creer une reservation |
| `POST /api/v1/bookings/calculate-price` | Calculer le prix (appel avant reservation) |
| `POST /api/v1/bookings/{id}/cancel` | Annuler (si depot non paye) |

### Favoris

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/favorites?session_id=` | Liste des favoris |
| `POST /api/v1/favorites/toggle` | Ajouter/retirer un favori |

### Contenu

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/articles?page=` | Articles |
| `GET /api/v1/articles/{slug}` | Detail article |
| `GET /api/v1/videos` | Videos |
| `GET /api/v1/reviews` | Avis approuves |
| `POST /api/v1/reviews` | Soumettre un avis |
| `GET /api/v1/faq` | FAQ |
| `POST /api/v1/contact` | Envoyer un message |
| `GET /api/v1/settings/public` | Parametres publics |

### Paiement (GeniusPay)

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/payments/config` | Configuration (mode, canaux) |
| `POST /api/v1/payments/init` | Initier un paiement |
| `GET /api/v1/payments/status/{ref}` | Statut du paiement |
| `POST /api/v1/payments/retry/{ref}` | Reessayer (autre operateur, max 10) |
| `POST /api/v1/payments/cancel/{ref}` | Annuler |

## Integration paiement GeniusPay

### Flux

1. Reservation creee -> dates bloquees, statut `pending`
2. Choix operateur : Wave, Orange Money, MTN Mobile Money
3. `POST /payments/init` -> `checkout_url`
4. **Wave** : Ouvrir dans navigateur externe
5. **Orange/MTN** : Notification USSD push, ecran d'attente avec compte a rebours (60 secondes)
6. Poll `GET /payments/status/{ref}` toutes les 3-4 secondes
7. Succes -> reservation confirmee, email/WhatsApp | Echec -> option reessai
8. Reservation non payee expire apres 30 minutes (dates liberees)

### Montant

- **Depot 50%** du total (nuitees + frais de service 5%)
- Calculer via `POST /bookings/calculate-price` avant d'initier le paiement

### Validation telephone

- **Orange** : Prefixe `07`
- **MTN** : Prefixe `05`
- Format : `+225XXXXXXXXXX`

## Notifications

### WhatsApp (remplacement de l'email)

- **Confirmation de reservation** : Recapitulatif (residence, dates, montant, reference)
- **Rappel avant sejour** : 24h avant le check-in
- URL : `https://wa.me/2250545079850?text=...`

### Push Notifications (Firebase Cloud Messaging)

- Confirmation de paiement
- Rappel de check-in (24h avant)
- Rappel de check-out
- Nouvelles residences ajoutees
- Promotions saisonnieres

## Regles metier

- **Pas de compte obligatoire** — favoris via session anonyme (UUID), reservations par email/telephone
- **Capacite max** : 2 personnes par chambre
- **Check-out apres check-in** (validation de dates)
- **Frais de service** : 5% du total des nuitees
- **Depot** : 50% du total (nuitees + frais)
- **Hold 30 min** : Reservation non payee expire et libere les dates
- **Avis moderes** : Validation admin avant publication
- **Disponibilite** : Calculee automatiquement depuis les reservations, surchargeable manuellement (occupe/maintenance)
- **Tarification saisonniere** : Prix par nuit variable selon les periodes definies par l'admin

## Conventions de code

- **Langage** : Dart / Flutter
- **State management** : Riverpod
- **Navigation** : GoRouter
- **Client HTTP** : Dio
- **Architecture** : Feature-first
- **Nommage** : snake_case fichiers, PascalCase classes, camelCase variables
- **Formatage des prix** : FCFA, entiers, separateur milliers espace (`85 000 FCFA / nuit`)
- **Dates** : Format francais (jj/mm/aaaa), fuseau Abidjan (GMT+0)
- **Gestion d'erreurs** : Loading / Error / Empty
- **Session anonyme** : UUID stocke dans SharedPreferences, envoye comme `session_id` pour les favoris

## Dependances Flutter recommandees

```yaml
dependencies:
  flutter_riverpod: ^2.0.0
  go_router: ^14.0.0
  dio: ^5.0.0
  cached_network_image: ^3.0.0
  url_launcher: ^6.0.0
  firebase_messaging: ^15.0.0
  firebase_core: ^3.0.0
  google_fonts: ^6.0.0
  shimmer: ^3.0.0
  flutter_animate: ^4.0.0
  share_plus: ^9.0.0
  intl: ^0.19.0
  uuid: ^4.0.0
  shared_preferences: ^2.0.0
  table_calendar: ^3.0.0

dev_dependencies:
  flutter_lints: ^4.0.0
```

## Structure de navigation

```
BottomNavigationBar
  |-- Explorer (HomeScreen)
  |     |-- SearchScreen (autocomplete)
  |     |-- ResidencesCatalogScreen (filtres)
  |     |-- ResidenceDetailScreen
  |     |     |-- GalleryFullScreen
  |     |     |-- AvailabilityCalendar
  |     |     |-- PriceCalculator
  |     |-- CompareScreen
  |-- Favoris (FavoritesScreen)
  |-- Reservations (BookingsScreen)
  |     |-- BookingTunnel (4 etapes)
  |           |-- DatesStep
  |           |-- InfoStep
  |           |-- ConfirmationStep
  |           |-- PaymentStep
  |                 |-- PaymentWaitScreen
  |                 |-- PaymentResultScreen
  |-- Messages (ContactScreen)
  |-- Profil (ProfileScreen)
        |-- FAQScreen
        |-- LegalScreen
        |-- SettingsScreen
```
