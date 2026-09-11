# CLAUDE.md — Application Mobile Flora Hair

## Identite du projet

**Nom** : Flora Hair Mobile
**Type** : Application client Flutter (Android)
**Entreprise** : FLORA HAIR — Salon de Coiffure & Beaute
**Localisation** : Abidjan, Cote d'Ivoire
**Contact** : contact@florahair.com | +225 05 45 07 98 50
**Infoline tarifs/formations** : +225 05 45 19 67 65
**WhatsApp** : +225 05 45 07 98 50
**Reseaux** : @florahair.ci (Instagram, Facebook, TikTok)
**Devise** : FCFA (XOF) — entiers uniquement
**Langue** : Francais (fr)

## Relation avec le site web

L'application mobile est le compagnon du site web Next.js du salon de coiffure FLORA HAIR.
Elle consomme la **meme API FastAPI** (backend existant) que le site web.
L'**administration reste sur le site web** (admin Next.js sur port 3500) — il n'y a pas d'admin mobile.

**Backend existant** : FastAPI + PostgreSQL 16 + Redis 7
**API base** : `/api/v1`
**Paiement** : GeniusPay (Wave, Orange Money, MTN Mobile Money) — depot 50%

## Architecture technique

```
flora_hair_mobile/
  lib/
    main.dart
    app.dart
    config/
      api_config.dart
      theme.dart               # Theme or/chocolat
      routes.dart
    models/
      service.dart
      category.dart
      team_member.dart
      team_availability.dart
      booking.dart
      payment.dart
      article.dart
      video.dart
      gallery_item.dart
      review.dart
      quote_request.dart
    services/
      api_client.dart
      payment_service.dart
      whatsapp_service.dart
      push_notification_service.dart
    screens/
      home/
      services/                # Catalogue avec filtres par categorie + tarifs
      booking/                 # Reservation multi-etapes
      gallery/                 # Galerie photos + avant/apres
      team/                    # Equipe / coiffeuses
      articles/                # Blog beaute
      videos/                  # Videos
      reviews/                 # Avis clients
      quote/                   # Demande de devis (photo + description)
      training/                # Page formations
      contact/                 # Contact + WhatsApp
      payment/                 # Ecrans paiement
    widgets/
      service_card.dart
      team_card.dart
      article_card.dart
      gallery_grid.dart
      before_after_slider.dart
      review_card.dart
      review_form.dart
      booking_form.dart
      calendar.dart
      operator_grid.dart
      payment_overlay.dart
      payment_countdown.dart
      section_heading.dart
      page_hero.dart
      loading_state.dart
      error_state.dart
      empty_state.dart
```

## Design System

### Palette de couleurs (heritee du site web)

| Token | Hex | Usage |
|-------|-----|-------|
| lime (gold) | `#C5A55A` | Couleur primaire (or) |
| lime-light | `#D4BA78` | Etats hover |
| lime-dark | `#A88B3D` | Etats presses |
| mint | `#D4A853` | Or secondaire |
| cream | `#F5F0E1` | Texte principal (mode sombre) |
| charcoal | `#1E1B16` | Fond cartes |
| dark | `#1A1510` | Fond principal (chocolat sombre) |
| dark-light | `#2A2318` | Surfaces elevees |
| gray-warm | `#3A3328` | Bordures, separateurs |
| text-muted | `#94A3B8` | Texte attenue |

### Mode clair

- lime : `#8B6914` (or fonce pour contraste)
- cream : `#1A1510` (texte sombre)
- dark : `#FBF8F0` (fond creme)
- charcoal : `#FFFFFF` (cartes blanches)

### Typographie

- **Titres** : Playfair Display (serif, elegance beaute)
- **Corps** : Inter (sans-serif, lisibilite)

### Principes UI

- **Style** : Elegant, feminin, luxe accessible — mode sombre par defaut
- **Glassmorphism** discret sur les cartes
- **Gradient or** pour les boutons principaux
- **Animations** : CSS pures (slide-up, fade-in, scale-in, float, shimmer)
- **Coins arrondis** : 12-16px
- **Photos** : Overlays contraste avec classes `.photo-scrim-*` pour texte lisible sur photos

## Ecrans et navigation

### Bottom Navigation Bar (5 onglets)

1. **Accueil** — Hero avec stats, services vedettes, galerie, equipe, avis, articles
2. **Services** — Catalogue filtrable par categorie avec tableau de prix
3. **Reservation** — Formulaire multi-etapes avec calendrier et paiement
4. **Galerie** — Grille masonry + filtres tags + avant/apres interactif
5. **Plus** — Equipe, Articles, Videos, Avis, Devis photo, Formations, Contact

### Flux de reservation (4 etapes)

1. **Service** : Selection du service souhaite (avec prix affiche)
2. **Coiffeuse** : Selection de la coiffeuse (avec disponibilites)
3. **Date & Heure** : Calendrier personnalise (jours fermes grises, creneaux disponibles calcules selon duree du service et disponibilite de la coiffeuse)
4. **Informations client** : Nom, telephone, email, notes + choix paiement depot 50%

### Calendrier de reservation

- Grille 42 cellules (6 semaines), navigation mois par mois
- Jours fermes (dimanche) grises et non-cliquables
- Creneaux bases sur les intervalles (pas juste l'heure de debut), selon la duree du service
- Respect des disponibilites de la coiffeuse par jour de la semaine
- Navigation clavier + WAI-ARIA (accessibilite)

### Horaires d'ouverture

- Lundi-Mercredi : 09:00 - 19:00
- Jeudi-Vendredi : 09:00 - 20:00
- Samedi : 08:00 - 18:00
- Dimanche : Ferme

### Ecran Devis photo

- Upload d'une photo de la coiffure souhaitee
- Description textuelle
- Informations de contact
- Le salon repond par email/WhatsApp avec le prix estime

### Ecran Formations

- Modules coiffure et maquillage
- Informations sur le diplome
- Pas de prix ni de duree — redirection vers l'infoline

## Endpoints API a consommer

### Consultation (GET publics)

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/services` | Liste des services |
| `GET /api/v1/services/{slug}` | Detail d'un service |
| `GET /api/v1/categories` | Categories de services |
| `GET /api/v1/team` | Liste des coiffeuses |
| `GET /api/v1/team/{id}` | Detail d'une coiffeuse |
| `GET /api/v1/bookings/available-slots?service_id=&team_member_id=&date=` | Creneaux disponibles |
| `GET /api/v1/gallery` | Galerie photos |
| `GET /api/v1/articles?page=` | Articles (pagines) |
| `GET /api/v1/articles/{slug}` | Detail d'un article |
| `GET /api/v1/videos` | Videos |
| `GET /api/v1/reviews` | Avis approuves |

### Actions (POST publics)

| Endpoint | Usage |
|----------|-------|
| `POST /api/v1/bookings` | Creer une reservation |
| `POST /api/v1/reviews` | Soumettre un avis |
| `POST /api/v1/contact` | Envoyer un message |
| `POST /api/v1/quotes` | Envoyer une demande de devis (multipart — photo) |

### Paiement (GeniusPay)

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/payments/config` | Configuration paiement |
| `POST /api/v1/payments/init` | Initier un paiement |
| `GET /api/v1/payments/status/{ref}` | Statut du paiement |
| `POST /api/v1/payments/retry/{ref}` | Reessayer avec autre operateur |
| `POST /api/v1/payments/cancel/{ref}` | Annuler |

## Integration paiement GeniusPay

### Flux

1. Reservation creee avec `deposit_status: pending`
2. Client choisit operateur (Wave, Orange Money, MTN)
3. `POST /payments/init` -> retourne `checkout_url`
4. **Wave** : Ouvrir lien dans navigateur externe
5. **Orange/MTN** : Notification USSD push -> ecran d'attente avec compte a rebours (180 secondes)
6. Poll `GET /payments/status/{ref}` toutes les 3-4 secondes
7. Succes -> confirmation | Echec -> option reessai autre operateur (max 10 tentatives par reservation)

### Validation telephone

- **Orange** : Prefixe `07`
- **MTN** : Prefixe `05`
- Format international `+225XXXXXXXXXX`

### Montant

- **50% du prix du service** — depot obligatoire pour la reservation en ligne
- Reservation sans paiement expiree apres 30 minutes (creneaux liberes)

## Notifications

### WhatsApp (remplacement de l'email)

- **Confirmation de reservation** : Message pre-rempli avec details (service, coiffeuse, date, heure, montant paye)
- **Confirmation de devis** : Recapitulatif de la demande
- **Contact rapide** : Bouton WhatsApp flottant dans l'app
- URL : `https://wa.me/2250545079850?text=...`

### Push Notifications (Firebase Cloud Messaging)

- Rappel de rendez-vous (1h et 24h avant)
- Confirmation de paiement
- Reponse a une demande de devis
- Nouveaux articles et promotions

## Regles metier

- **Pas de compte utilisateur** — reservations par nom/telephone/email
- **Depot 50%** obligatoire pour les reservations en ligne
- **3 types de prix** : fixe, fourchette (min-max), "a partir de"
- **Avis moderes** : Validation admin avant publication
- **Creneaux de reservation** : Calcules selon duree du service + disponibilite coiffeuse + horaires salon
- **Avant/apres** : Slider interactif (clip-path) pour les photos de galerie
- **Devis photo** : Le client uploade une photo de la coiffure souhaitee, le salon repond avec un prix

## Conventions de code

- **Langage** : Dart / Flutter
- **State management** : Riverpod
- **Navigation** : GoRouter
- **Client HTTP** : Dio
- **Architecture** : Feature-first
- **Nommage** : snake_case fichiers, PascalCase classes, camelCase variables
- **Formatage des prix** : FCFA, entiers, separateur de milliers espace (`15 000 FCFA`)
- **Gestion d'erreurs** : Loading / Error / Empty
- **Upload photos** : Utiliser `image_picker` pour la camera/galerie, `dio` multipart pour l'envoi

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
  image_picker: ^1.0.0
  intl: ^0.19.0

dev_dependencies:
  flutter_lints: ^4.0.0
```

## Structure de navigation

```
BottomNavigationBar
  |-- Accueil (HomeScreen)
  |-- Services (ServicesScreen)
  |     |-- ServiceDetailScreen
  |-- Reservation (BookingScreen - 4 etapes)
  |     |-- CalendarScreen
  |     |-- PaymentMethodPicker
  |     |-- PaymentWaitScreen
  |     |-- PaymentResultScreen
  |-- Galerie (GalleryScreen)
  |     |-- LightboxModal
  |     |-- BeforeAfterSlider
  |-- Plus (MoreScreen)
        |-- TeamScreen
        |-- ArticlesScreen -> ArticleDetailScreen
        |-- VideosScreen
        |-- ReviewsScreen (consultation + soumission)
        |-- QuoteScreen (devis photo)
        |-- TrainingScreen
        |-- ContactScreen
```
