# CLAUDE.md — Application Mobile Eslie Sport

## Identite du projet

**Nom** : Eslie Sport Mobile
**Type** : Application client Flutter (Android)
**Entreprise** : ESLIE SPORT — Salle de sport
**Slogan** : "Parce que le corps a besoin de sport"
**Localisation** : Blaukauss, Abidjan, Cote d'Ivoire
**Contact** : +225 05 45 07 98 50
**Devise** : FCFA (XOF) — entiers uniquement, jamais de decimales
**Langue** : Francais (fr)

## Relation avec le site web

L'application mobile est le compagnon du site web Next.js de la salle de sport ESLIE SPORT.
Elle consomme la **meme API FastAPI** (backend existant) que le site web.
L'**administration reste sur le site web** (admin Next.js sur port 3403) — il n'y a pas d'admin mobile.

**Backend existant** : FastAPI + PostgreSQL 16 + Redis 7
**API base** : `/api/v1`
**Paiement** : GeniusPay (Wave, Orange Money, MTN Mobile Money) — depot 50%

## Architecture technique

```
eslie_sport_mobile/
  lib/
    main.dart
    app.dart
    config/
      api_config.dart
      theme.dart               # Theme or/navy
      routes.dart
    models/
      activity.dart
      coach.dart
      schedule_slot.dart
      subscription.dart
      enrollment.dart
      payment.dart
      article.dart
      video.dart
      transformation.dart
      equipment.dart
      review.dart
    services/
      api_client.dart
      payment_service.dart     # Integration GeniusPay
      whatsapp_service.dart
      push_notification_service.dart
    screens/
      home/
      activities/              # Catalogue + detail
      schedule/                # Planning hebdomadaire interactif
      enrollment/              # Formulaire d'inscription 3 etapes
      subscriptions/           # Plans d'abonnement
      coaches/                 # Profils des coachs
      equipment/               # Equipements par zone
      articles/                # Blog fitness
      videos/                  # Videos d'entrainement
      transformations/         # Avant/apres
      reviews/                 # Avis clients
      contact/                 # Formulaire de contact
      payment/                 # Ecrans de paiement (attente, succes, echec)
      bmi/                     # Calculateur IMC
    widgets/
      activity_card.dart
      coach_card.dart
      schedule_grid.dart
      subscription_card.dart
      capacity_badge.dart
      transformation_slider.dart
      bmi_calculator.dart
      payment_method_picker.dart
      payment_overlay.dart
      countdown_timer.dart
      section_title.dart
      loading_state.dart
      error_state.dart
      empty_state.dart
```

## Design System

### Palette de couleurs (heritee du site web)

| Token | Hex | Usage |
|-------|-----|-------|
| primary (gold) | `#FFD600` | CTAs, accents, titres en emphase |
| primary-light | `#FFE44D` | Hover / etats clairs |
| secondary | `#A8B2C1` | Texte secondaire (gris-bleu) |
| dark (navy) | `#0F1724` | Fond principal |
| dark-card | `#1A2332` | Fond des cartes |
| dark-lighter | `#1E293B` | Fond eleve |
| dark-border | `#2D3A4A` | Bordures |
| dark-muted | `#8896A8` | Texte attenue |
| success | `#22C55E` | Places disponibles |
| warning | `#F59E0B` | Places limitees |
| error | `#EF4444` | Complet / erreurs |

### Mode clair (optionnel)

- Fond : `#F1F5F9`
- Cartes : `#FFFFFF`
- Primary adapte : `#B8960A` (contraste sur fond blanc)

### Typographie

- **Police unique** : Inter (variable weight) — pas de serif pour cette app sportive

### Principes UI

- **Style** : Sportif, energique, moderne — mode sombre par defaut
- **Glassmorphism** pour les cartes sur fonds sombres
- **Gradient primaire** : or -> or clair pour les CTAs
- **Animations** : Dynamiques, transitions rapides
- **Coins arrondis** : 12-16px pour les cartes
- **Icones** : Style outline (Lucide-compatible)

## Ecrans et navigation

### Bottom Navigation Bar (5 onglets)

1. **Accueil** — Hero, chiffres cles, activites vedettes, temoignages, CTA inscription
2. **Activites** — Catalogue filtrable (categorie: force/cardio/souplesse/arts martiaux/danse, niveau)
3. **Planning** — Grille horaire hebdomadaire interactive avec badges de capacite
4. **Abonnements** — Comparaison des formules avec prix en FCFA
5. **Profil** (ex-« Compte ») — carte d'identite (nom de la derniere inscription, « Visiteur » sinon), cartes photo Mes formules / Planning des cours, carte large Seance decouverte (WhatsApp), puis Coachs, Equipements, Transformations, Articles, Videos, Avis, IMC, Contact

### Profil et pastille « acompte 50 % » (2026-10-06)

Voir `docs/PROFIL_ET_PASTILLE.md`. Pastille flottante « Reservez avec 50 % d'acompte » sur l'accueil → pop-up (navigateur racine) « Payez 50 % maintenant, le reste se regle a la salle ». Ne jamais ecrire « depot inclus dans le prix » : c'etait faux.

### Ecrans detailles

- **Detail activite** : Description, niveau, duree, equipement, coach, horaires, bouton inscription
- **Profil coach** : Photo, specialites, certifications, cours associes
- **Detail article** : Contenu HTML sanitise (attention au rendu Flutter)
- **Calculateur IMC** : Saisie taille/poids, resultat avec interpretation visuelle

### Flux d'inscription a un cours (3 etapes)

1. **Informations personnelles** : Nom, email, telephone
2. **Details de la seance** : Activite selectionnee, creneau horaire, nombre de participants
3. **Confirmation + Paiement** : Recapitulatif, choix du mode de paiement, depot 50%

### Ecrans de paiement

- **Choix operateur** : Wave, Orange Money, MTN Mobile Money (pas Moov)
- **Attente** : Overlay avec compte a rebours (60 secondes)
- **Succes** : Confirmation avec details de la reservation
- **Echec** : Message d'erreur avec option de reessai

## Endpoints API a consommer

### Consultation (GET publics)

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/activities?page=&category=&level=` | Liste des activites |
| `GET /api/v1/activities/{slug}` | Detail d'une activite |
| `GET /api/v1/schedule` | Planning hebdomadaire |
| `GET /api/v1/subscriptions` | Plans d'abonnement |
| `GET /api/v1/coaches` | Liste des coachs |
| `GET /api/v1/equipment` | Equipements par zone |
| `GET /api/v1/articles?page=` | Articles (pagines) |
| `GET /api/v1/articles/{slug}` | Detail d'un article |
| `GET /api/v1/videos` | Videos |
| `GET /api/v1/transformations` | Avant/apres |
| `GET /api/v1/reviews` | Avis approuves |
| `GET /api/v1/settings/public` | Parametres publics de la salle |

### Actions (POST publics)

| Endpoint | Usage |
|----------|-------|
| `POST /api/v1/enrollments` | Creer une reservation |
| `GET /api/v1/enrollments/slots/{slot_id}/availability` | Verifier disponibilite |
| `POST /api/v1/reviews` | Soumettre un avis |
| `POST /api/v1/contact` | Envoyer un message |
| `POST /api/v1/subscriptions/orders` | Commander un abonnement |

### Paiement (GeniusPay)

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/payments/config` | Configuration paiement (mode, canaux actifs) |
| `POST /api/v1/payments/init` | Initier un paiement |
| `GET /api/v1/payments/{ref}` | Verifier le statut d'un paiement |
| `POST /api/v1/payments/{ref}/cancel` | Annuler un paiement |

## Integration paiement GeniusPay

### Flux de paiement

1. L'utilisateur choisit un operateur (Wave, Orange Money, MTN)
2. L'app appelle `POST /payments/init` avec : booking_id, operator, phone, amount
3. L'API retourne une `checkout_url`
4. **Wave** : Ouvrir le lien direct dans le navigateur externe (url_launcher)
5. **Orange/MTN** : L'utilisateur recoit une notification USSD push sur son telephone — afficher un ecran d'attente
6. L'app poll `GET /payments/{ref}` toutes les 3-4 secondes pendant 60 secondes max
7. Resultat : succes -> ecran de confirmation | echec -> option de reessai avec autre operateur

### Validation du telephone

- **MTN** : Prefixe `05` (format +225 05XXXXXXXX)
- **Orange** : Prefixe `07` (format +225 07XXXXXXXX)
- **Wave** : Pas de validation de prefixe (lien direct)
- Normaliser au format international `+225XXXXXXXXXX`

### Montant du depot

- **50% du prix** de la formule/seance
- Calculer cote client ET verifier cote serveur

## Notifications

### WhatsApp (remplacement de l'email)

- **Confirmation d'inscription** : Apres paiement reussi, proposer d'envoyer un recapitulatif par WhatsApp
- **Rappel de seance** : Lien WhatsApp avec message pre-rempli
- Utiliser `url_launcher` pour `https://wa.me/2250545079850?text=...`

### Push Notifications (Firebase Cloud Messaging)

- Rappel avant une seance reservee (1h avant)
- Notification de nouveau planning disponible
- Promotions et nouveaux articles
- Confirmation de paiement

## Regles metier

- **Pas de compte utilisateur** sur le site web — les inscriptions utilisent nom/email/telephone
- L'app mobile peut introduire un systeme de compte leger (telephone + OTP) pour retrouver ses reservations
- **Depot 50%** obligatoire pour les reservations en ligne
- **Capacite des cours** : Afficher les places restantes en temps reel (badge vert/orange/rouge)
- **Avis moderes** : Les soumissions ne sont visibles qu'apres validation admin
- **Planning** : Grille 7 jours x 15 heures, creneaux avec activite, coach, salle, capacite

## Tarification (FCFA)

| Formule | Prix |
|---------|------|
| Seance individuelle/groupe | 3 000 |
| Inscription mensuelle | 5 000 |
| Cotisation mensuelle | 30 000 |
| Kung-Fu Wushu — Inscription | 10 000 |
| Kung-Fu Wushu — Mensuel | 10 000 |
| Kung-Fu Wushu — Tenue | 20 000 |
| Boxe & Kick Boxing — Inscription | 10 000 |
| Boxe & Kick Boxing — Mensuel | 15 000 |
| Boxe & Kick Boxing — Tenue | 20 000 |

## Conventions de code

- **Langage** : Dart / Flutter
- **State management** : Riverpod
- **Navigation** : GoRouter
- **Client HTTP** : Dio
- **Architecture** : Feature-first
- **Nommage** : snake_case fichiers, PascalCase classes, camelCase variables
- **Formatage des prix** : Toujours en FCFA, entiers, separateur de milliers avec espace (`30 000 FCFA`)
- **Gestion d'erreurs** : Etats Loading / Error / Empty sur chaque ecran
- **Pas de commentaires inutiles**

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

dev_dependencies:
  flutter_lints: ^4.0.0
```

## Structure de navigation

```
BottomNavigationBar
  |-- Accueil (HomeScreen)
  |-- Activites (ActivitiesScreen)
  |     |-- ActivityDetailScreen
  |     |-- EnrollmentForm (3 etapes)
  |           |-- PaymentMethodPicker
  |           |-- PaymentWaitScreen
  |           |-- PaymentResultScreen
  |-- Planning (ScheduleScreen)
  |     |-- EnrollmentForm (acces direct)
  |-- Abonnements (SubscriptionsScreen)
  |     |-- SubscriptionOrderForm
  |-- Plus (MoreScreen)
        |-- CoachesScreen
        |-- EquipmentScreen
        |-- ArticlesScreen -> ArticleDetailScreen
        |-- VideosScreen
        |-- TransformationsScreen
        |-- ReviewsScreen
        |-- ContactScreen
        |-- BMICalculatorScreen
```
