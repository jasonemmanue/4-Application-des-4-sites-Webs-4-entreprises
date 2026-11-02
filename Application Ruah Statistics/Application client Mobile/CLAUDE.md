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
      push.dart                # FCM, sujet `actualites`
      notification_inbox.dart  # Boite locale des push recus
      network.dart             # Hors connexion et reprise
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

Refonte 1.1 : voir `docs/REFONTE_UI_1.1.md`.

| Token | Hex | Usage |
|-------|-----|-------|
| brand-500 | `#0E8784` | Couleur primaire (sarcelle) |
| brand-400 | `#12908C` | Variante claire |
| brand-600 | `#0B7A77` | Variante foncee, onglet actif |
| brand-700 | `#096B69` | Boutons presses |
| brand-800 | `#07595A` | Gradients |
| brandTint | `#DDF0EE` | Pastilles d'icones |
| charcoal-900 | `#0B2340` | Titres, fond principal (mode sombre) |
| charcoal-800 | `#12304F` | Fond cartes (mode sombre) |
| charcoal-700 | `#1D3E60` | Fond eleve (mode sombre) |
| lightBg | `#FBF6EC` | Fond creme (mode clair) |
| accent-500 | `#F39C1F` | Accent ambre (usage modere) |

### Gradients

- **Hero** : `#0B2340 -> #12304F -> #1D3E60 -> #07595A` (diagonal 135deg)
- **CTA** : `#07595A -> #0E8784 -> #12908C` (diagonal 135deg)

### Typographie

- **Titres et corps** : Plus Jakarta Sans

### Principes UI

- **Style** : Premium, professionnel, sobre — adapte a un cabinet de conseil
- **Mode clair par defaut** avec option mode sombre dans Profil
- **Glassmorphism** pour les cartes sur fonds sombres
- **Animations** : Transitions fluides, compteurs animes au scroll, apparitions progressives
- **Coins arrondis** : 12-16px pour les cartes
- **Ombres** : Subtiles, elevation douce

## Ecrans et navigation

### Bottom Navigation Bar (4 onglets)

1. **Accueil** — Logo en haut a gauche, recherche, filtres, expertises, projet a la une, chiffres cles, Explorer (Publications, Temoignages, Equipe, Videos)
2. **Services** — Catalogue des domaines d'expertise avec fiches detaillees
3. **Projets** — Portfolio de projets filtrable (secteur, pays, annee)
4. **Contact** — Demande de devis sur une page (`POST /leads/quote-request`), WhatsApp

**Profil** s'ouvre depuis l'en-tete de l'accueil — carte d'identite (nom + entreprise de la derniere demande de devis, « Visiteur » sinon), cartes Demander un devis / Nos realisations, carte large Parler a un consultant (WhatsApp), puis Equipe, A propos, Videos, Temoignages, Contact

### Profil et pastille « Devis sans engagement » (2026-10-06)

Voir `docs/PROFIL_ET_PASTILLE.md`. La pastille a ete retiree par la refonte 1.1 : l'onglet Contact joue ce role. Ne pas reintroduire « Consultation gratuite », que le site ne promet nulle part.

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
| `GET /api/v1/articles?page=&type=` | Articles et livres blancs (`type`, pas `article_type`) |
| `GET /api/v1/articles/{slug}` | Detail d'un article |
| `POST /api/v1/articles/{id}/download` | Telechargement livre blanc (email requis) |
| `GET /api/v1/videos` | Videos |
| `GET /api/v1/testimonials` | Temoignages approuves |
| `POST /api/v1/testimonials/submit` | Soumettre un temoignage (modere) |
| `GET /api/v1/partners` | Partenaires |
| `GET /api/v1/key-figures` | Chiffres cles |
| `POST /api/v1/leads/quote-request` | Envoi de demande de devis |
| `POST /api/v1/contact` | Envoi de message de contact |

## Notifications

### WhatsApp (remplacement de l'email)

- **Confirmation de devis** : Apres soumission d'une demande de devis, proposer d'ouvrir WhatsApp avec un message pre-rempli au numero du cabinet (+225 05 45 07 98 50) contenant le recapitulatif
- **Confirmation de contact** : Idem apres envoi du formulaire de contact
- Utiliser `url_launcher` pour ouvrir `https://wa.me/2250545079850?text=...`

### Push Notifications (Firebase Cloud Messaging)

Voir `docs/V1_2_RESEAU_NOTIFICATIONS.md`. Chaque telephone s'abonne au sujet FCM `actualites` ; le cabinet envoie depuis la console Firebase. Les push recus sont ranges dans une boite locale (cloche de l'accueil, Profil > Notifications).

- Notification quand un devis recoit une reponse : necessite d'enregistrer les appareils cote API (non fait)

### Reseau

`lib/services/network.dart` : bandeau hors connexion, lectures GET retentees 2 min, envois jamais rejoues, rechargement au retour du reseau.

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
Barre basse (MainScaffold)
  |-- Accueil (HomeScreen)
  |     |-- PublicationsScreen -> ArticleDetailScreen, DownloadModal
  |     |-- TestimonialsScreen, TeamScreen -> ConsultantDetailScreen, VideosScreen
  |     |-- Profil (MoreScreen)
  |           |-- AboutScreen, PaymentScreen
  |           |-- QuoteFlowScreen (4 etapes) -> QuoteConfirmationScreen
  |           |-- ContactScreen (message simple)
  |-- Services (ServicesListScreen)
  |     |-- ServiceDetailScreen
  |-- Projets (ProjectsListScreen)
  |     |-- ProjectDetailScreen
  |-- Contact (ContactHubScreen)
        |-- QuoteConfirmationScreen, ContactScreen
```
