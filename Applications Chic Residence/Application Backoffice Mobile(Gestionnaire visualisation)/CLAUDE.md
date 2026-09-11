# CLAUDE.md — Application Mobile Backoffice Chic Residence

## Identite du projet

**Nom** : Chic Residence Backoffice
**Type** : Application backoffice/admin Flutter (Android)
**Entreprise** : CHIC RESIDENCE — Residences meublees
**Localisation** : Abidjan, Cote d'Ivoire
**Devise** : FCFA (XOF)
**Langue** : Francais (fr)

## Role de cette application

Cette application est destinee aux **administrateurs et proprietaires** de Chic Residence. Elle offre :
1. **Tout ce que l'admin web voit** — version mobile du back-office Next.js
2. **Vue sur le travail des gestionnaires** — suivi en temps reel du nettoyage et du controle qualite

C'est le cockpit de gestion complet de l'entreprise, accessible depuis un smartphone.

## Relation avec l'ecosysteme

| Application | Role | Public |
|-------------|------|--------|
| Site web client (Next.js) | Recherche et reservation en ligne | Voyageurs |
| Admin web (Next.js) | Back-office complet | Administrateurs |
| App client mobile (Flutter) | Reservation style Airbnb | Voyageurs |
| App gestionnaire mobile (Flutter) | Nettoyage et controle terrain | Personnel |
| **App backoffice mobile (Flutter)** | **Admin complet + suivi terrain** | **Administrateurs** |

L'app backoffice mobile consomme la **meme API FastAPI** que le site web + les **endpoints de gestion terrain** (crees pour l'app gestionnaire).

## Architecture technique

```
chic_residence_backoffice/
  lib/
    main.dart
    app.dart
    config/
      api_config.dart
      theme.dart
      routes.dart
    models/
      # Modeles admin (memes que l'admin web)
      residence.dart
      seasonal_price.dart
      availability.dart
      booking.dart
      payment.dart
      article.dart
      video.dart
      review.dart
      faq_item.dart
      contact_message.dart
      stats.dart
      settings.dart
      # Modeles gestionnaire
      staff_user.dart
      cleaning_task.dart
      task_photo.dart
    services/
      api_client.dart          # Client authentifie (JWT admin)
      auth_service.dart
      push_notification_service.dart
    screens/
      login/
      # --- Section Admin (memes fonctions que l'admin web) ---
      dashboard/               # Tableau de bord avec stats
      residences/              # Liste + creation + edition
      calendar/                # Calendrier de disponibilite
      bookings/                # Reservations + gestion statuts
      payments/                # Journal des paiements
      pricing/                 # Tarifs saisonniers
      articles/                # CRUD articles
      videos/                  # CRUD videos
      reviews/                 # Moderation des avis
      faq/                     # CRUD FAQ
      contacts/                # Messages recus
      export/                  # Export Excel/JSON
      settings/                # Parametres entreprise
      # --- Section Suivi Gestionnaires (nouveau) ---
      staff/                   # Gestion du personnel
      cleaning_overview/       # Vue d'ensemble nettoyage/controle
      cleaning_detail/         # Detail d'une tache avec photos
      staff_performance/       # Performance des agents et controleurs
    widgets/
      # Widgets admin
      stat_card.dart
      data_table.dart
      status_badge.dart
      booking_card.dart
      payment_card.dart
      residence_form.dart
      photo_uploader.dart
      availability_editor.dart
      review_card.dart
      chart_widget.dart
      export_button.dart
      # Widgets gestionnaire
      staff_card.dart
      cleaning_task_card.dart
      cleaning_timeline.dart
      performance_chart.dart
      photo_comparison.dart
      progress_indicator.dart
```

## Design System

### Palette de couleurs

Coherente avec l'admin web, adaptee au mobile :

| Token | Hex | Usage |
|-------|-----|-------|
| primary | `#DC2626` | Rouge Chic Residence |
| primary-dark | `#991B1B` | AppBar, elements sombres |
| primary-light | `#FEE2E2` | Fonds legers |
| accent | `#F97316` | Orange accent |
| surface | `#F9FAFB` | Fond principal |
| card | `#FFFFFF` | Cartes |
| sidebar | `#1F2937` | Drawer de navigation (sombre) |
| text | `#1F2937` | Texte principal |
| text-muted | `#6B7280` | Texte secondaire |
| success | `#22C55E` | Valide, confirme |
| warning | `#F59E0B` | En attente |
| info | `#3B82F6` | En cours |
| error | `#EF4444` | Rejete, echoue |

### Typographie

- **Police** : Inter — uniforme, professionnelle
- **Titres** : Inter Bold/SemiBold
- **Corps** : Inter Regular

### Principes UI

- **Navigation par Drawer** (menu lateral coulissant) — trop d'ecrans pour un bottom bar
- **Mode clair** par defaut — usage bureau/interieur
- **Tableaux responsifs** : Cards sur mobile, tableaux sur tablette
- **Graphiques** : Diagrammes simples (barres, lignes) pour le dashboard
- **Actions rapides** : FAB (Floating Action Button) pour les creations
- **Pull-to-refresh** sur les listes
- **Recherche** dans les listes longues (residences, reservations)

## Ecrans et navigation

### Navigation par Drawer (menu lateral)

```
Drawer Navigation
  |
  |-- [Section Administration]
  |     |-- Dashboard
  |     |-- Residences
  |     |-- Calendrier
  |     |-- Reservations
  |     |-- Paiements
  |     |-- Tarifs saisonniers
  |     |-- Articles
  |     |-- Videos
  |     |-- Avis
  |     |-- FAQ
  |     |-- Contacts
  |     |-- Export
  |     |-- Parametres
  |
  |-- [Section Suivi Terrain]  <-- NOUVEAU
  |     |-- Personnel
  |     |-- Nettoyage & Controle
  |     |-- Performance
  |
  |-- Deconnexion
```

### Dashboard (ecran principal)

Reprend les stats de l'admin web + ajoute la vue terrain :

**Stats existantes (admin web) :**
- Nombre de residences
- Reservations du mois
- Taux d'occupation
- Revenus du mois
- Reservations recentes
- Avis recents en attente de moderation

**Stats nouvelles (suivi terrain) :**
- Residences en cours de preparation
- Taches de nettoyage du jour (en attente / en cours / terminees)
- Controles en attente
- Taux de validation au premier passage
- Temps moyen de preparation
- Alertes : taches en retard, controles bloques

### Ecrans Administration (identiques a l'admin web)

Chaque ecran de l'admin web Next.js a son equivalent mobile :

| Ecran | Fonctionnalites |
|-------|----------------|
| **Residences** | Liste, creation multi-etapes (infos, photos, equipements, prix), edition, statut |
| **Calendrier** | Vue mensuelle/annuelle, bloquer/debloquer des dates |
| **Reservations** | Liste filtrable, changement de statut (pending/confirmed/cancelled/completed), export Excel |
| **Paiements** | Journal de tous les paiements et tentatives |
| **Tarifs** | Gestion des prix saisonniers par residence |
| **Articles** | CRUD articles de blog |
| **Videos** | CRUD videos |
| **Avis** | Moderation (approuver/rejeter) |
| **FAQ** | CRUD par categorie |
| **Contacts** | Messages recus, marquer comme lu |
| **Export** | Export Excel (12 feuilles), JSON, par table |
| **Parametres** | Infos entreprise, conditions de reservation, reseaux sociaux |

### Ecrans Suivi Terrain (NOUVEAU — exclusif a cette app)

#### Ecran Personnel

- Liste des agents de nettoyage et controleurs
- Statut (actif/inactif)
- Creation/modification de comptes (telephone + PIN)
- Attribution de role (agent / controleur)
- Historique d'activite par personne

#### Ecran Nettoyage & Controle (Vue d'ensemble)

- **Vue Kanban** des taches par statut :
  - Colonne "A faire" (taches assignees, pas commencees)
  - Colonne "En cours" (nettoyage en cours)
  - Colonne "A controler" (nettoyage termine, attente controle)
  - Colonne "Termine" (controle valide)
  - Colonne "Rejete" (a refaire)
- Filtre par residence, par agent, par date
- Vue chronologique (timeline) des actions du jour
- Indicateur de progression global (% des residences pretes)

#### Ecran Detail de tache (admin)

- Toutes les infos de la tache
- Photos avant/apres de l'agent
- Photos du controleur (si rejet)
- Timeline complete : creation, debut nettoyage, fin, controle, validation/rejet
- Agent assigne et controleur
- Duree du nettoyage
- Commentaire de rejet (si applicable)
- Actions admin : reassigner, forcer la validation, supprimer

#### Ecran Performance

- **Par agent** : Nombre de taches terminees, temps moyen, taux de validation au premier passage
- **Par controleur** : Nombre de controles, taux de rejet, temps moyen d'inspection
- **Global** : Temps moyen de preparation d'une residence, taux de conformite, residences les plus problematiques
- **Graphiques** : Evolution sur 7j / 30j / 90j
- **Classement** : Top agents, agents a accompagner

## Endpoints API a consommer

### Endpoints admin existants (du site web)

Tous les endpoints authentifies du backend existant :

| Domaine | Endpoints |
|---------|-----------|
| Auth | `POST /auth/login`, `POST /auth/refresh`, `GET /auth/me` |
| Residences | CRUD + statut + facets |
| Disponibilite | Calendrier + bloquer/debloquer |
| Tarifs | CRUD prix saisonniers |
| Reservations | Liste + statut + export |
| Paiements | Liste + detail |
| Articles | CRUD |
| Videos | CRUD |
| Avis | Liste + moderation |
| FAQ | CRUD |
| Contacts | Liste + marquer lu |
| Upload | Upload fichiers |
| Settings | Get/Set |
| Stats | Dashboard |
| Export | Excel / JSON / par table |

### Nouveaux endpoints (suivi terrain)

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/staff` | Liste du personnel |
| `POST /api/v1/staff` | Creer un agent/controleur |
| `PUT /api/v1/staff/{id}` | Modifier |
| `DELETE /api/v1/staff/{id}` | Desactiver |
| `GET /api/v1/cleaning-tasks?status=&assigned_to=&residence_id=&date=` | Taches filtrables |
| `GET /api/v1/cleaning-tasks/{id}` | Detail avec timeline |
| `POST /api/v1/cleaning-tasks` | Creer manuellement une tache |
| `PUT /api/v1/cleaning-tasks/{id}/assign` | Reassigner |
| `PUT /api/v1/cleaning-tasks/{id}/force-validate` | Forcer la validation (admin) |
| `DELETE /api/v1/cleaning-tasks/{id}` | Supprimer |
| `GET /api/v1/cleaning-tasks/{id}/photos` | Photos de la tache |
| `GET /api/v1/staff/stats/overview` | Stats globales |
| `GET /api/v1/staff/stats/{id}` | Stats individuelles |
| `GET /api/v1/staff/stats/performance?period=7d|30d|90d` | Evolution dans le temps |

## Authentification

- **Meme systeme JWT** que l'admin web (email + mot de passe)
- Token stocke dans SecureStorage
- Auto-refresh avant expiration
- Role requis : `admin` (pas `staff` — le staff utilise l'app gestionnaire)
- Auto-deconnexion apres 7 jours d'inactivite

## Notifications push (Firebase Cloud Messaging)

- Nouvelle reservation
- Paiement recu
- Nouvel avis a moderer
- Nouveau message de contact
- Tache de nettoyage en retard
- Controle en attente depuis longtemps
- Alerte : residence non prete avant le prochain check-in

## Regles metier

- **Acces admin uniquement** — pas le personnel de terrain
- **Voit tout ce que l'admin web voit** + le suivi des gestionnaires
- **Peut forcer la validation** d'une tache (passer outre le controleur)
- **Peut reassigner** une tache a un autre agent
- **Peut creer manuellement** une tache de nettoyage
- **Export Excel** : Meme format 12 feuilles que l'admin web
- **Tarification saisonniere** : Gerer les prix par periode par residence
- **Moderation des avis** : Approuver ou rejeter avant publication

## Conventions de code

- **Langage** : Dart / Flutter
- **State management** : Riverpod
- **Navigation** : GoRouter
- **Client HTTP** : Dio avec intercepteur JWT
- **Architecture** : Feature-first
- **Stockage securise** : flutter_secure_storage
- **Graphiques** : fl_chart
- **Tableaux** : DataTable Flutter adaptatif (cards sur petit ecran)
- **Formulaires** : Validation cote client + erreurs API

## Dependances Flutter recommandees

```yaml
dependencies:
  flutter_riverpod: ^2.0.0
  go_router: ^14.0.0
  dio: ^5.0.0
  cached_network_image: ^3.0.0
  firebase_messaging: ^15.0.0
  firebase_core: ^3.0.0
  google_fonts: ^6.0.0
  flutter_secure_storage: ^9.0.0
  fl_chart: ^0.68.0
  intl: ^0.19.0
  shimmer: ^3.0.0
  share_plus: ^9.0.0
  image_picker: ^1.0.0
  table_calendar: ^3.0.0
  path_provider: ^2.0.0

dev_dependencies:
  flutter_lints: ^4.0.0
```

## Structure de navigation

```
Drawer Navigation
  |
  |-- Dashboard (DashboardScreen)
  |
  |-- [Administration]
  |     |-- ResidencesScreen -> ResidenceFormScreen
  |     |-- CalendarScreen
  |     |-- BookingsScreen -> BookingDetailScreen
  |     |-- PaymentsScreen
  |     |-- PricingScreen -> PricingFormScreen
  |     |-- ArticlesScreen -> ArticleFormScreen
  |     |-- VideosScreen -> VideoFormScreen
  |     |-- ReviewsScreen
  |     |-- FAQScreen -> FAQFormScreen
  |     |-- ContactsScreen
  |     |-- ExportScreen
  |     |-- SettingsScreen
  |
  |-- [Suivi Terrain]
  |     |-- StaffScreen -> StaffFormScreen
  |     |-- CleaningOverviewScreen (Kanban)
  |     |     |-- CleaningDetailScreen
  |     |-- PerformanceScreen
  |
  |-- ProfileScreen
  |-- LogoutAction

LoginScreen (hors navigation)
```
