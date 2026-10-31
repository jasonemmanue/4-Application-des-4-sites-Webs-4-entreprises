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
      theme.dart               # Theme bordeaux / rose / or
      routes.dart
    models/
      service.dart
      category.dart
      team_member.dart
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
      appointments/            # Mes rendez-vous (a venir, historique)
      favorites/               # Favoris locaux
      home/
      services/                # Catalogue avec filtres par categorie + tarifs
      booking/                 # Reservation en 3 etapes
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
      flora_ui.dart            # Briques visuelles communes
      payment_sheet.dart       # Choix du moyen, relance
      team_card.dart
      article_card.dart
      gallery_grid.dart
      before_after_slider.dart
      review_card.dart
      review_form.dart
      booking_form.dart
      operator_grid.dart
      payment_countdown.dart
      section_heading.dart
      page_hero.dart
      loading_state.dart
      error_state.dart
      empty_state.dart
```

## Design System

Refonte du 2026-10-31 (v1.1.0+2) : voir `docs/REFONTE_UI_2026-10.md`.

| Token (`FloraColors`) | Hex | Usage |
|-------|-----|-------|
| burgundy (alias `lime`) | `#6B1F3A` | Couleur primaire |
| blush / blushLight | `#F4C9CE` / `#FBE8E6` | Rose poudre, surfaces |
| gold | `#D9A441` | Accent, mot « beaute. » |
| cocoa | `#3E2723` | Brun |
| background | `#FFF7F1` | Fond creme rose |

- **Logo** : celui du salon, dore (`assets/branding/logo_mark.png`), en haut a gauche de l'accueil.
- **Typographie** : DM Sans ; Allura pour « beaute. » ; Playfair Display pour le nom du salon.
- **Mode** : clair uniquement (`ThemeMode.light`).
- **Coins arrondis** : 14-18 px, boutons en pilule, ombre douce teintee bordeaux.
- **Briques communes** : `lib/widgets/flora_ui.dart`.

## Ecrans et navigation

### Bottom Navigation Bar (5 onglets)

1. **Accueil** — Logo, accroche, recherche, categories, tendances, prestations, inspirations, equipe, conseils
2. **Prestations** — Catalogue filtrable, cartes avec bouton « Choisir »
3. **Reserver** — Tunnel en 3 etapes
4. **Favoris** — Prestations et inspirations, conservees sur l'appareil
5. **Profil** (« Mon espace ») — Prochain rendez-vous, acces rapides, salon, rubriques (Galerie, Devis, Equipe, Articles, Videos, Avis, Formations)

### Profil et pastille « acompte 50 % »

Voir `docs/PROFIL_ET_PASTILLE.md` pour la pastille de l'accueil, toujours en place.
La carte d'identite et les cartes photo de ce document ont ete remplacees par « Mon espace ».

### Flux de reservation (3 etapes)

1. **Prestation** : prestation et expert·e
2. **Creneau** : date, creneau, note, total estime
3. **Confirmation** : recapitulatif, informations client, moyen de paiement (acompte 50 %)

### Mes rendez-vous

Liste locale a l'appareil (`services/appointments.dart`), sans compte. L'etat vient du back-office
via `GET /bookings/{id}/status`. Actions : payer l'acompte, annuler.

### Selection de la date

- Bandeau horizontal de 60 jours, dimanche grise et non cliquable
- Creneaux calcules par l'API selon la duree de la prestation et les reservations de l'expert·e
- Aujourd'hui, les heures passees sont retirees cote application

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
| `GET /api/v1/bookings/{id}/status` | Etat decide par le salon (sans donnee personnelle) |
| `GET /api/v1/gallery` | Galerie photos |
| `GET /api/v1/articles?page=` | Articles (pagines) |
| `GET /api/v1/articles/{slug}` | Detail d'un article |
| `GET /api/v1/videos` | Videos |
| `GET /api/v1/reviews` | Avis approuves |

### Actions (POST publics)

| Endpoint | Usage |
|----------|-------|
| `POST /api/v1/bookings` | Creer une reservation |
| `POST /api/v1/bookings/{id}/cancel` | Annuler (si acompte non paye) |
| `POST /api/v1/reviews` | Soumettre un avis |
| `POST /api/v1/contact` | Envoyer un message |
| `POST /api/v1/quotes` | Envoyer une demande de devis (multipart — photo) |

### Paiement (GeniusPay)

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/payments/config` | Configuration paiement |
| `POST /api/v1/payments/init` | Initier un paiement |
| `GET /api/v1/payments/{ref}` | Statut du paiement |
| `POST /api/v1/payments/{ref}/retry` | Reessayer avec autre operateur |
| `POST /api/v1/payments/{ref}/cancel` | Annuler |
| `POST /api/v1/payments/{ref}/push` | Renvoyer la demande Mobile Money |

## Integration paiement GeniusPay

### Flux

1. `POST /bookings` avec `payment_method: "Payement electronique"` (c'est ce qui fait expirer une demande non payee)
2. La cliente choisit un moyen parmi ceux de `GET /payments/config`
3. `POST /payments/init` renvoie `payment_url`
4. **Wave et carte** : ouvrir `payment_url` dans le navigateur externe (exigence de Wave : jamais de webview)
5. **Orange et MTN** : demande de validation poussee par le serveur, ecran d'attente
6. Poll `GET /payments/{ref}` toutes les 3 s. Succes = statut `succeeded`
7. L'ecran de resultat relit l'etat reel. Echec : relance, avec changement de moyen possible

### Validation telephone

- Dix chiffres, comme `phone_error` du backend
- **Pas de controle de prefixe** : la portabilite existe en Cote d'Ivoire
- Format envoye : `+225XXXXXXXXXX`

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

- **Pas de compte utilisateur** — reservations par nom/telephone/email ; favoris et rendez-vous conserves sur l'appareil
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
  |-- Prestations (ServicesScreen)
  |-- Reserver (BookingScreen - 3 etapes)
  |-- Favoris (FavoritesScreen)
  |-- Profil (MoreScreen)
Hors onglets
  |-- ServiceDetailScreen, GalleryScreen, AppointmentsScreen
  |-- PaymentWaitScreen, PaymentResultScreen
  |-- TeamScreen, ArticlesScreen, ArticleDetailScreen, VideosScreen
  |-- ReviewsScreen, QuoteScreen, TrainingScreen, ContactScreen
```

## Sortie d'une version

1. `version:` dans `pubspec.yaml` et `ApiConfig.appSource` alignes (un test le verifie)
2. `flutter test`
3. Construire depuis `C:\FH-build\client` : le « é » de « ainé » dans le chemin du projet fait echouer
   `gen_snapshot` et `impellerc`. Synchroniser par `robocopy <projet> C:\FH-build\client /MIR /XD build .dart_tool .gradle .kotlin /XF app-release.apk *.iml`,
   puis `flutter build apk --release` dans cette copie
4. Verifier la version de l'APK (`aapt dump badging`), puis le copier vers `flora_hair_mobile/app-release.apk` et `Application Flora Hair/FloraHair-release.apk` (ignores par git)
