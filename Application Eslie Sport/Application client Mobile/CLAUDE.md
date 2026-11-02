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
**Paiement** : GeniusPay (Wave, Orange Money, MTN Mobile Money, carte Visa / Mastercard) — depot 50%

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

Refonte 1.1.0 et reprise reseau / FAQ / noter-partager en 1.2.0 : voir `eslie_sport_mobile/docs/REFONTE-UI-1.1.0.md`.

### Palette de couleurs (`lib/config/theme.dart`)

| Token | Hex | Usage |
|-------|-----|-------|
| primary | `#0B4F36` | Vert : identite, navigation, icones actives |
| primarySoft | `#E2EFE8` | Fonds d'information, selection |
| accent | `#F2681C` | Orange : actions principales uniquement |
| yellow | `#FFC60B` | Soulignes, badge « Populaire » |
| bg | `#FBF8F1` | Fond creme |
| surface | `#FFFFFF` | Cartes |
| textPrimary | `#14231C` | Texte |
| textSecondary | `#55645C` | Texte secondaire |
| success / warning / error | `#16A34A` / `#D97706` / `#DC2626` | Places restantes, erreurs |

### Typographie

- **Police unique** : Poppins (google_fonts)

### Principes UI

- **Style** : clair, sportif, cartes blanches a ombre douce
- **Boutons principaux** : pilule orange
- **Logo** : `assets/images/logo.png`, en haut a gauche de l'accueil, ne pas le remplacer
- **Logos de paiement** : fichiers reels dans `assets/images/paiement/`, jamais d'icone generique

## Ecrans et navigation

### Bottom Navigation Bar (5 onglets)

1. **Accueil** — Logo, hero, acces rapides, prochain cours, tarifs, coachs, transformations
2. **Activites** — Catalogue filtrable (valeurs API : `force`, `cardio`, `martial_arts`, `flexibility`)
3. **Planning** — 7 prochains jours, places restantes en temps reel par date
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

1. **Informations personnelles** : Nom, WhatsApp
2. **Details de la seance** : Date (uniquement le jour du creneau), type, **formule (`payment_type`, obligatoire : sans elle pas d'acompte)**
3. **Confirmation + Paiement** : Recapitulatif, choix du mode de paiement, depot 50%

### Ecrans de paiement

- **Choix operateur** : liste lue dans `GET /payments/config` — Wave, Orange Money, MTN Mobile Money, carte (pas Moov)
- **Attente** : compte a rebours sur `expires_in` du serveur ; le renvoi USSD ouvre une NOUVELLE reference a suivre
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
6. L'app poll `GET /payments/{ref}` toutes les 3-5 secondes jusqu'a `expires_in` + 20 s
7. Resultat : succes -> ecran de confirmation | echec -> option de reessai avec autre operateur

### Validation du telephone

- **MTN** : Prefixes `05`, `06`, `04`
- **Orange** : Prefixes `07`, `08`, `09`
- **Wave** : Pas de validation de prefixe (lien direct)
- Memes plages que `PREFIXES_PAR_MOYEN` du backend
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
