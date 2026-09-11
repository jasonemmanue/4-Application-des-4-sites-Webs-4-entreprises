# Chic Residence Backoffice Mobile

Application mobile Flutter d'administration pour **CHIC RESIDENCE**, residences meublees a Abidjan (Cote d'Ivoire).

## Apercu

Application de gestion complete destinee aux administrateurs et proprietaires. Elle combine :
- **Toutes les fonctions de l'admin web** en version mobile
- **Le suivi du travail des gestionnaires** (nettoyage et controle qualite)

C'est le cockpit complet de l'entreprise, accessible depuis un smartphone.

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter (Dart) |
| State | Riverpod |
| Navigation | GoRouter (Drawer) |
| HTTP | Dio + JWT |
| Graphiques | fl_chart |
| Push | Firebase Cloud Messaging |
| Backend | API FastAPI existante + extension terrain |

## Ecosysteme Chic Residence (3 apps mobiles)

| Application | Role |
|-------------|------|
| **Client Mobile** | Recherche, reservation, paiement pour les voyageurs |
| **Gestionnaire Mobile** | Validation nettoyage et controle pour le personnel |
| **Backoffice Mobile** (cette app) | Administration complete + suivi des gestionnaires |

## Design

- **Palette** : Rouge Chic Residence (`#DC2626`) + Orange accent + Statuts colores
- **Typographie** : Inter
- **Style** : Professionnel, tableaux adaptatifs, graphiques
- **Navigation** : Drawer lateral (trop d'ecrans pour un bottom bar)
- **Mode clair** par defaut

## Fonctionnalites — Section Administration

| Module | Fonctionnalite |
|--------|---------------|
| Dashboard | Stats (residences, reservations, occupation, revenus) + alertes |
| Residences | CRUD multi-etapes (infos, photos, equipements, prix) |
| Calendrier | Disponibilite mensuelle, bloquer/debloquer dates |
| Reservations | Liste filtrable, gestion statuts, export Excel |
| Paiements | Journal de tous les paiements et tentatives |
| Tarifs | Prix saisonniers par residence |
| Articles | CRUD blog |
| Videos | CRUD videos |
| Avis | Moderation (approuver/rejeter) |
| FAQ | CRUD par categorie |
| Contacts | Messages recus |
| Export | Excel 12 feuilles, JSON, par table |
| Parametres | Infos entreprise, conditions, reseaux sociaux |

## Fonctionnalites — Section Suivi Terrain (exclusif)

| Module | Fonctionnalite |
|--------|---------------|
| Personnel | CRUD agents et controleurs |
| Nettoyage & Controle | Vue Kanban des taches par statut, timeline du jour |
| Detail tache | Photos avant/apres, timeline, actions admin (reassigner, forcer) |
| Performance | Stats individuelles et globales, graphiques d'evolution |

## Demarrage

```bash
flutter create --org com.chicresidence chic_residence_backoffice
cd chic_residence_backoffice
flutter pub get
flutter run
```

## Note importante

Cette application necessite les memes extensions backend que l'app gestionnaire (endpoints de gestion terrain, authentification personnel, taches de nettoyage). Voir le CLAUDE.md pour la specification complete des endpoints.
