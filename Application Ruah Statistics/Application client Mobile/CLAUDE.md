# CLAUDE.md — Application Mobile Ruah Statistics

## Identite du projet

**Nom** : Ruah Statistics Mobile
**Type** : Application client Flutter (Android)
**Entreprise** : RUAH-STATISTICS — Cabinet d'Etudes & Conseil
**Slogan** : "Cabinet d'etudes et de conseil de reference en Afrique"
**Localisation** : Abidjan, Cote d'Ivoire (siege) + Dakar, Senegal (bureau regional)
**Contact** : contact@ruah-statistics.com | +225 05 45 07 98 50
**Devise** : XOF (Franc CFA) — entiers uniquement, jamais de decimales
**Langue** : Francais (fr)

## Relation avec le site web

L'application mobile est le compagnon du site web Next.js du cabinet d'etudes RUAH-STATISTICS.
Elle consomme la **meme API FastAPI** (backend existant) que le site web.
L'**administration reste sur le site web** (admin Next.js sur port 3405) — il n'y a pas d'admin mobile.

**Backend existant** : FastAPI + PostgreSQL 16 + Redis 7
**API base** : `/api/v1`
**Pas de paiement en ligne** — le cabinet est un site vitrine / generation de leads.

## Architecture technique

```
ruah_statistics_mobile/
  lib/
    main.dart
    app.dart
    config/
      api_config.dart          # URL de l'API, timeouts
      theme.dart               # Theme cyan/charcoal
      routes.dart              # Routage nomme (GoRouter)
    models/                    # Classes Dart miroir des schemas API
      service.dart
      project.dart
      team_member.dart
      article.dart
      video.dart
      testimonial.dart
      partner.dart
      key_figure.dart
      lead.dart                # Pour le formulaire de devis
      contact_message.dart
    services/
      api_client.dart          # Client HTTP (dio ou http)
      whatsapp_service.dart    # Ouverture WhatsApp pour confirmations
      push_notification_service.dart
    screens/
      home/                    # Accueil
      services/                # Liste + detail des domaines
      projects/                # Portfolio realisations
      team/                    # Equipe / consultants
      publications/            # Articles + livres blancs
      videos/                  # Videos (conferences, interviews, webinaires)
      testimonials/            # Temoignages clients
      about/                   # A propos (timeline, mission, valeurs)
      quote/                   # Formulaire de devis multi-etapes
      contact/                 # Formulaire de contact
    widgets/                   # Composants reutilisables
      animated_counter.dart
      section_header.dart
      service_card.dart
      project_card.dart
      team_card.dart
      article_card.dart
      video_card.dart
      testimonial_card.dart
      partner_logo.dart
      download_modal.dart
      loading_state.dart
      error_state.dart
      empty_state.dart
```

## Design System

### Palette de couleurs (heritee du site web)

| Token | Hex | Usage |
|-------|-----|-------|
| brand-500 | `#00BCD4` | Couleur primaire (cyan) |
| brand-400 | `#26C6DA` | Variante claire |
| brand-600 | `#00ACC1` | Variante foncee |
| brand-700 | `#0097A7` | Boutons presses |
| brand-800 | `#00838F` | Gradients |
| charcoal-900 | `#0F0F1A` | Fond principal (mode sombre) |
| charcoal-800 | `#1A1A2E` | Fond cartes (mode sombre) |
| charcoal-700 | `#272B45` | Fond eleve (mode sombre) |
| accent-500 | `#FFB300` | Accent ambre (usage modere) |

### Gradients

- **Hero** : `#0A0A15 -> #1A1A2E -> #272B45 -> #00838F` (diagonal 135deg)
- **CTA** : `#00838F -> #00BCD4 -> #26C6DA` (diagonal 135deg)

### Typographie

- **Titres** : Playfair Display (serif, elegance professionnelle)
- **Corps** : Inter (sans-serif, lisibilite)

### Principes UI

- **Style** : Premium, professionnel, sobre — adapte a un cabinet de conseil
- **Mode sombre par defaut** avec option mode clair
- **Glassmorphism** pour les cartes sur fonds sombres
- **Animations** : Transitions fluides, compteurs animes au scroll, apparitions progressives
- **Coins arrondis** : 12-16px pour les cartes
- **Ombres** : Subtiles, elevation douce

## Ecrans et navigation

### Bottom Navigation Bar (5 onglets)

1. **Accueil** — Chiffres cles animes, services vedettes, realisations recentes, temoignages
2. **Services** — Catalogue des domaines d'expertise avec fiches detaillees
3. **Realisations** — Portfolio de projets filtrable (secteur, pays, annee)
4. **Publications** — Articles et livres blancs avec telechargement (capture email)
5. **Plus** — Equipe, A propos, Videos, Temoignages, Contact, Devis

### Ecrans detailles

- **Detail service** : Methodologie, secteurs, livrables
- **Detail realisation** : Contexte, solution, resultats, chiffres d'impact
- **Detail article** : Contenu complet, articles similaires
- **Detail video** : Lecteur integre (YouTube/externe)
- **Profil consultant** : Photo, poste, specialites, LinkedIn
- **Formulaire de devis** (4 etapes) :
  1. Type de mission (etude, conseil, formation, audit, autre)
  2. Details du projet (secteur, pays, budget en tranches FCFA, delais)
  3. Informations de contact (nom, email, telephone, entreprise, poste)
  4. Recapitulatif et envoi

### Ecran Contact

- Formulaire (nom, email, telephone, entreprise, objet, message)
- Informations de contact (telephone, email, adresse)
- Horaires d'ouverture
- Lien vers localisation (Google Maps)

## Endpoints API a consommer

Tous les endpoints GET publics du backend existant :

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/services` | Liste des services |
| `GET /api/v1/services/{slug}` | Detail d'un service |
| `GET /api/v1/projects?page=&sector=&country=&year=` | Realisations (paginees, filtrees) |
| `GET /api/v1/projects/{slug}` | Detail d'une realisation |
| `GET /api/v1/team` | Liste des consultants |
| `GET /api/v1/articles?page=&type=` | Articles et livres blancs |
| `GET /api/v1/articles/{slug}` | Detail d'un article |
| `POST /api/v1/articles/{id}/download` | Telechargement livre blanc (email requis) |
| `GET /api/v1/videos` | Videos |
| `GET /api/v1/testimonials` | Temoignages approuves |
| `POST /api/v1/testimonials/submit` | Soumettre un temoignage (modere) |
| `GET /api/v1/partners` | Partenaires |
| `GET /api/v1/key-figures` | Chiffres cles |
| `POST /api/v1/leads/quote-request` | Envoi de demande de devis |
| `POST /api/v1/contact` | Envoi de message de contact |
| `GET /api/v1/settings` | Parametres de l'entreprise |

## Notifications

### WhatsApp (remplacement de l'email)

- **Confirmation de devis** : Apres soumission d'une demande de devis, proposer d'ouvrir WhatsApp avec un message pre-rempli au numero du cabinet (+225 05 45 07 98 50) contenant le recapitulatif
- **Confirmation de contact** : Idem apres envoi du formulaire de contact
- Utiliser `url_launcher` pour ouvrir `https://wa.me/2250545079850?text=...`

### Push Notifications (Firebase Cloud Messaging)

- Notification quand un devis recoit une reponse (necessite extension backend)
- Notification quand un nouveau article/publication est publie (necesssite extension backend)
- Notifications promotionnelles

## Regles metier

- **Pas de paiement en ligne** — ce n'est pas un site e-commerce
- **Pas de compte utilisateur** — l'application est en consultation libre
- **Budgets indicatifs** dans le formulaire de devis : tranches en FCFA (< 5M, 5-15M, 15-30M, 30-65M, > 65M)
- **Temoignages moderes** — les soumissions publiques ne sont visibles qu'apres validation admin
- **Livres blancs** — telechargement conditionne a la saisie d'un email (lead magnet)

## Conventions de code

- **Langage** : Dart / Flutter
- **State management** : Riverpod (recommande) ou Provider
- **Navigation** : GoRouter
- **Client HTTP** : Dio avec intercepteurs pour logging et gestion d'erreurs
- **Architecture** : Feature-first (chaque ecran est un dossier avec ses widgets, controllers, et models locaux)
- **Nommage** : snake_case pour les fichiers, PascalCase pour les classes, camelCase pour les variables
- **Pas de commentaires inutiles** — le code doit etre auto-explicatif
- **Gestion d'erreurs** : Etats Loading / Error / Empty sur chaque ecran avec donnees API
- **Responsive** : Adapter les layouts pour tablettes (2-3 colonnes)
- **Internationalisation** : Pas necessaire (francais uniquement), mais les textes dans des constantes

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

dev_dependencies:
  flutter_lints: ^4.0.0
  build_runner: ^2.0.0
```

## Structure de navigation

```
BottomNavigationBar
  |-- Accueil (HomeScreen)
  |-- Services (ServicesListScreen)
  |     |-- ServiceDetailScreen
  |-- Realisations (ProjectsListScreen)
  |     |-- ProjectDetailScreen
  |-- Publications (PublicationsScreen)
  |     |-- ArticleDetailScreen
  |     |-- DownloadModal (livres blancs)
  |-- Plus (MoreScreen)
        |-- EquipeScreen
        |     |-- ConsultantDetailScreen
        |-- AProposScreen
        |-- VideosScreen
        |-- TemoignagesScreen
        |-- ContactScreen
        |-- DevisScreen (4 etapes)
              |-- DevisConfirmationScreen
```
