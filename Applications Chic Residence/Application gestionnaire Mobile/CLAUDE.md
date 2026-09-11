# CLAUDE.md — Application Mobile Gestionnaire Chic Residence

## Identite du projet

**Nom** : Chic Residence Gestionnaire
**Type** : Application gestionnaire Flutter (Android) — gestion terrain (nettoyage + controle)
**Entreprise** : CHIC RESIDENCE — Residences meublees
**Localisation** : Abidjan, Cote d'Ivoire
**Devise** : FCFA (XOF)
**Langue** : Francais (fr)

## Role de cette application

Cette application est destinee au **personnel de terrain** de Chic Residence. Elle gere le workflow de nettoyage et controle qualite des residences entre deux sejours.

### Deux roles dans la meme application

| Role | Responsabilite |
|------|---------------|
| **Agent de nettoyage** | Recoit les taches de nettoyage, les execute, et valide quand le nettoyage est termine (photos avant/apres) |
| **Controleur** | Recoit les notifications de nettoyage termine, inspecte la residence, et valide que le controle qualite est passe |

### Workflow de preparation d'une residence

```
Check-out du client
      |
      v
[Tache de nettoyage creee automatiquement]
      |
      v
Agent de nettoyage assigne
      |
      v
Agent commence le nettoyage (statut: en_cours)
      |
      v
Agent termine et valide (photos avant/apres, statut: nettoye)
      |
      v
[Notification push au controleur]
      |
      v
Controleur inspecte la residence
      |
      v
  /         \
OK           NON OK
|              |
v              v
Valide       Rejete (commentaire obligatoire)
(statut:     (retour a l'agent de nettoyage)
 controle)
      |
      v
Residence prete pour le prochain client
```

## Relation avec le backend

Cette application necessite une **extension du backend existant** (FastAPI) pour supporter les endpoints de gestion terrain. Ces endpoints n'existent pas encore dans le backend du site web et doivent etre crees.

**Nouveaux endpoints a creer dans le backend :**

### Authentification gestionnaire

| Endpoint | Usage |
|----------|-------|
| `POST /api/v1/staff/login` | Connexion (telephone + code PIN) |
| `GET /api/v1/staff/me` | Profil du gestionnaire connecte |
| `PUT /api/v1/staff/me/fcm-token` | Enregistrer le token FCM pour les push |

### Taches de nettoyage

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/cleaning-tasks?status=&assigned_to=` | Liste des taches (filtrables) |
| `GET /api/v1/cleaning-tasks/{id}` | Detail d'une tache |
| `PUT /api/v1/cleaning-tasks/{id}/start` | Demarrer le nettoyage |
| `PUT /api/v1/cleaning-tasks/{id}/complete` | Terminer (avec photos) |
| `PUT /api/v1/cleaning-tasks/{id}/validate` | Controleur valide |
| `PUT /api/v1/cleaning-tasks/{id}/reject` | Controleur rejette (commentaire obligatoire) |

### Photos de taches

| Endpoint | Usage |
|----------|-------|
| `POST /api/v1/cleaning-tasks/{id}/photos` | Upload photos (avant/apres) |
| `GET /api/v1/cleaning-tasks/{id}/photos` | Voir les photos |

### Statistiques gestionnaire

| Endpoint | Usage |
|----------|-------|
| `GET /api/v1/staff/stats` | Stats personnelles (taches terminees, temps moyen, taux de validation) |

## Architecture technique

```
chic_residence_gestionnaire/
  lib/
    main.dart
    app.dart
    config/
      api_config.dart
      theme.dart
      routes.dart
    models/
      staff_user.dart          # Agent ou controleur
      cleaning_task.dart       # Tache de nettoyage
      task_photo.dart          # Photo avant/apres
      residence_summary.dart   # Info minimale de la residence
    services/
      api_client.dart
      auth_service.dart        # Login telephone + PIN
      push_notification_service.dart
    screens/
      login/                   # Connexion telephone + PIN
      home/                    # Dashboard avec taches du jour
      tasks/                   # Liste des taches
      task_detail/             # Detail + actions
      photo_capture/           # Prise de photos avant/apres
      validation/              # Ecran de controle (controleur)
      stats/                   # Statistiques personnelles
      profile/                 # Profil + deconnexion
    widgets/
      task_card.dart
      status_badge.dart
      photo_grid.dart
      photo_capture_button.dart
      validation_form.dart
      rejection_form.dart
      stat_card.dart
      timer_widget.dart
      residence_mini_card.dart
```

## Design System

### Palette de couleurs

L'application utilise une palette fonctionnelle adaptee au travail de terrain :

| Token | Hex | Usage |
|-------|-----|-------|
| primary | `#DC2626` | Rouge Chic Residence (coherence marque) |
| primary-light | `#EF4444` | Variante claire |
| surface | `#F9FAFB` | Fond principal (mode clair par defaut) |
| card | `#FFFFFF` | Cartes |
| border | `#E5E7EB` | Bordures |
| text | `#1F2937` | Texte principal |
| text-muted | `#6B7280` | Texte secondaire |
| status-pending | `#F59E0B` | Ambre — en attente |
| status-in-progress | `#3B82F6` | Bleu — en cours |
| status-completed | `#22C55E` | Vert — termine/valide |
| status-rejected | `#EF4444` | Rouge — rejete |

### Typographie

- **Police unique** : Inter (sans-serif) — lisibilite terrain prioritaire

### Principes UI

- **Mode clair par defaut** — utilisation en exterieur/interieur lumineux
- **UI fonctionnelle** — pas de fioritures, efficacite d'abord
- **Gros boutons d'action** — utilisation avec des gants potentiellement
- **Cards avec statut colore** — identification visuelle rapide
- **Contraste eleve** — lisibilite en plein soleil
- **Navigation simple** — maximum 3 niveaux de profondeur

## Ecrans et navigation

### Bottom Navigation Bar (4 onglets)

1. **Accueil** — Dashboard : taches du jour, compteurs par statut, prochaine tache
2. **Taches** — Liste complete avec filtres (en attente, en cours, termine, rejete)
3. **Statistiques** — Performance personnelle (taches terminees, temps moyen, taux validation)
4. **Profil** — Infos personnelles, role, deconnexion

### Ecran Accueil (Dashboard)

- Salutation avec prenom
- Compteurs du jour : taches en attente, en cours, terminees
- Prochaine tache avec bouton d'action rapide
- Timeline des actions recentes

### Ecran Liste des taches

**Vue Agent de nettoyage :**
- Taches assignees avec statut (en attente, en cours, termine, rejete)
- Filtre par statut
- Tri par urgence (check-in prochain en premier)
- Card : nom residence, date check-in prochain, statut, temps estime

**Vue Controleur :**
- Taches en attente de controle (statut "nettoye")
- Historique des controles effectues
- Card : nom residence, agent qui a nettoye, heure de fin nettoyage

### Ecran Detail de tache

**Agent de nettoyage :**
- Informations de la residence (nom, adresse, type, capacite)
- Checklist de nettoyage (pieces, elements a verifier)
- Bouton "Commencer" -> chronometre demarre
- Section photos : prendre des photos avant/apres
- Bouton "Terminer le nettoyage" (necessite au moins 1 photo apres)

**Controleur :**
- Memes informations + photos de l'agent
- Bouton "Valider le controle" (tout est OK)
- Bouton "Rejeter" -> formulaire avec commentaire obligatoire + option photo

### Ecran Capture photos

- Camera avec bouton de capture
- Galerie des photos prises
- Labels : "Avant" / "Apres"
- Upload progressif (barre de progression)

## Authentification

- **Connexion** : Numero de telephone + code PIN (4-6 chiffres)
- **Pas d'inscription publique** — les comptes sont crees par l'admin
- **Token JWT** stocke dans SecureStorage
- **Auto-deconnexion** apres 24h d'inactivite
- **Token FCM** envoye au backend a chaque connexion pour les push notifications

## Notifications push (Firebase Cloud Messaging)

### Pour l'agent de nettoyage
- Nouvelle tache assignee
- Tache rejetee par le controleur (avec commentaire)

### Pour le controleur
- Nettoyage termine — en attente de controle
- Rappel : controle en attente depuis plus de 2h

## Regles metier

- Un agent ne peut travailler que sur **une seule tache a la fois**
- Le controleur **ne peut pas etre la meme personne** que l'agent de nettoyage sur une tache donnee
- Le rejet necessite un **commentaire obligatoire** expliquant ce qui doit etre refait
- Les photos sont **obligatoires** pour terminer un nettoyage (au moins 1 photo "apres")
- Le temps de nettoyage est **chronometre** (pour les statistiques)
- Les taches sont triees par **urgence** : prochain check-in en premier

## Conventions de code

- **Langage** : Dart / Flutter
- **State management** : Riverpod
- **Navigation** : GoRouter
- **Client HTTP** : Dio
- **Architecture** : Feature-first
- **Stockage securise** : flutter_secure_storage pour le JWT
- **Camera** : image_picker pour les photos, dio multipart pour l'upload
- **Notifications** : firebase_messaging

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
  image_picker: ^1.0.0
  flutter_secure_storage: ^9.0.0
  intl: ^0.19.0
  shimmer: ^3.0.0

dev_dependencies:
  flutter_lints: ^4.0.0
```

## Structure de navigation

```
BottomNavigationBar
  |-- Accueil (DashboardScreen)
  |     |-- TaskQuickAction
  |-- Taches (TasksListScreen)
  |     |-- TaskDetailScreen
  |           |-- PhotoCaptureScreen
  |           |-- ValidationScreen (controleur)
  |           |-- RejectionFormScreen (controleur)
  |-- Statistiques (StatsScreen)
  |-- Profil (ProfileScreen)

LoginScreen (hors navigation principale)
```
