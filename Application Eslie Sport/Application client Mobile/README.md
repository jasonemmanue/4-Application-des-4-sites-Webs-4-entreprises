# Eslie Sport Mobile

Application mobile Flutter pour **ESLIE SPORT**, salle de sport a Abidjan (Cote d'Ivoire).
*"Parce que le corps a besoin de sport"*

## Apercu

Application compagnon du site web de la salle de sport, permettant aux sportifs de :
- Decouvrir les activites (force, cardio, souplesse, arts martiaux, danse)
- Consulter le planning hebdomadaire en temps reel avec places disponibles
- S'inscrire a des cours avec depot 50% via Mobile Money (Wave, Orange, MTN)
- Comparer les formules d'abonnement et souscrire en ligne
- Decouvrir les coachs et leurs specialites
- Explorer les equipements par zone
- Lire des articles fitness et regarder des videos d'entrainement
- Voir les transformations avant/apres
- Calculer son IMC
- Deposer des avis

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter (Dart) |
| State | Riverpod |
| Navigation | GoRouter |
| HTTP | Dio |
| Paiement | GeniusPay (Wave, Orange Money, MTN) |
| Push | Firebase Cloud Messaging |
| Backend | API FastAPI existante (partagee avec le site web) |
| BDD | PostgreSQL 16 (via le backend) |

## Lien avec le site web

L'application consomme la meme API REST (`/api/v1`) que le site web Next.js.
L'administration (gestion des activites, planning, coachs, reservations) se fait exclusivement via le **back-office web** (admin Next.js).

## Design

- **Palette** : Or (`#FFD600`) / Navy (`#0F1724`) / Gris-bleu secondaire
- **Typographie** : Inter (variable weight)
- **Style** : Sportif, energique, mode sombre par defaut
- **Glassmorphism** et gradients dores

## Fonctionnalites cles

- **Planning interactif** : Grille 7j x 15h avec badges de capacite (vert/orange/rouge)
- **Inscription 3 etapes** : Infos -> Seance -> Paiement 50%
- **Paiement Mobile Money** : Wave (lien direct), Orange/MTN (USSD push) via GeniusPay
- **Calculateur IMC** : Outil interactif
- **Transformations** : Slider avant/apres
- **Notifications WhatsApp** : Confirmations d'inscription (remplace l'email)
- **Push notifications** : Rappels de seances, nouveaux contenus

## Demarrage

```bash
flutter create --org com.esliesport eslie_sport_mobile
cd eslie_sport_mobile
flutter pub get
flutter run
```

## Contact

- **Telephone** : +225 05 45 07 98 50
- **Localisation** : Blaukauss, Abidjan, Cote d'Ivoire
