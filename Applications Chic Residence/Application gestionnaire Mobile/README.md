# Chic Residence Gestionnaire

Application mobile Flutter pour le **personnel de terrain** de CHIC RESIDENCE (Abidjan, Cote d'Ivoire).

## Apercu

Application de gestion du nettoyage et du controle qualite des residences meublees entre les sejours des clients. Deux roles coexistent dans la meme application :

- **Agent de nettoyage** : Recoit les taches, effectue le menage, prend des photos avant/apres, valide la fin du nettoyage
- **Controleur** : Inspecte les residences nettoyees, valide ou rejette avec commentaire

## Workflow

```
Check-out -> Tache creee -> Agent nettoie -> Photos avant/apres -> Controleur inspecte -> Valide/Rejete
```

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter (Dart) |
| State | Riverpod |
| Navigation | GoRouter |
| HTTP | Dio |
| Auth | JWT (telephone + PIN) |
| Push | Firebase Cloud Messaging |
| Camera | image_picker |
| Backend | Extension de l'API FastAPI existante |

## Ecosysteme Chic Residence (3 apps mobiles)

| Application | Role |
|-------------|------|
| **Client Mobile** | Recherche, reservation, paiement pour les voyageurs |
| **Gestionnaire Mobile** (cette app) | Validation nettoyage et controle pour le personnel |
| **Backoffice Mobile** | Administration complete + suivi des gestionnaires |

## Design

- **Palette** : Rouge Chic Residence (`#DC2626`) + statuts colores (ambre/bleu/vert/rouge)
- **Typographie** : Inter
- **Style** : Fonctionnel, contraste eleve, gros boutons — optimise pour le terrain
- **Mode clair** par defaut (utilisation exterieur)

## Fonctionnalites cles

- **Dashboard** : Taches du jour avec compteurs par statut
- **Liste des taches** : Filtrables par statut, triees par urgence
- **Detail de tache** : Infos residence, checklist, chronometre, photos
- **Capture photos** : Avant/apres avec upload progressif
- **Validation/Rejet** : Le controleur valide ou rejette avec commentaire obligatoire
- **Statistiques** : Performance personnelle (taches, temps moyen, taux validation)
- **Push notifications** : Nouvelle tache, nettoyage termine, tache rejetee

## Demarrage

```bash
flutter create --org com.chicresidence chic_residence_gestionnaire
cd chic_residence_gestionnaire
flutter pub get
flutter run
```

## Note importante

Cette application necessite une **extension du backend FastAPI** existant avec de nouveaux endpoints pour la gestion des taches de nettoyage, l'authentification du personnel, et les photos de taches. Ces endpoints sont specifies dans le CLAUDE.md.
