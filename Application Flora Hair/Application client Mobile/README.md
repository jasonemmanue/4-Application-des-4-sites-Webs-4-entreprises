# Flora Hair Mobile

Application mobile Flutter pour **FLORA HAIR**, salon de coiffure et beaute a Abidjan (Cote d'Ivoire).

## Apercu

Application compagnon du site web du salon de coiffure, permettant aux clientes de :
- Decouvrir les services et tarifs (coiffure, maquillage, soins)
- Reserver un rendez-vous en ligne (choix service, coiffeuse, date/heure)
- Payer un depot 50% via Mobile Money (Wave, Orange, MTN)
- Parcourir la galerie photos avec comparaisons avant/apres
- Decouvrir l'equipe et ses specialites
- Lire des articles beaute et regarder des tutoriels video
- Demander un devis personnalise en envoyant une photo
- Consulter les formations coiffure et maquillage
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
L'administration (services, reservations, galerie, avis, devis) se fait exclusivement via le **back-office web** (admin Next.js).

## Design

- **Palette** : Or (`#C5A55A`) / Chocolat sombre (`#1A1510`) / Creme (`#F5F0E1`)
- **Typographie** : Playfair Display (titres) + Inter (corps)
- **Style** : Elegant, feminin, luxe accessible, mode sombre par defaut
- **Glassmorphism** et gradients dores

## Fonctionnalites cles

- **Reservation 4 etapes** : Service -> Coiffeuse -> Date/Heure -> Infos + Paiement
- **Calendrier intelligent** : Creneaux calcules selon duree service + dispo coiffeuse
- **Paiement Mobile Money** : Depot 50% via GeniusPay
- **Galerie avant/apres** : Slider interactif pour comparer les transformations
- **Devis photo** : Envoyer une photo de la coiffure souhaitee pour obtenir un prix
- **Notifications WhatsApp** : Confirmations de RDV (remplace l'email)
- **Push notifications** : Rappels de RDV, reponses devis

## Horaires

| Jour | Horaires |
|------|----------|
| Lundi - Mercredi | 09:00 - 19:00 |
| Jeudi - Vendredi | 09:00 - 20:00 |
| Samedi | 08:00 - 18:00 |
| Dimanche | Ferme |

## Demarrage

```bash
flutter create --org com.florahair flora_hair_mobile
cd flora_hair_mobile
flutter pub get
flutter run
```

## Contact

- **Email** : contact@florahair.com
- **Telephone** : +225 05 45 07 98 50
- **Infoline** : +225 05 45 19 67 65
- **WhatsApp** : wa.me/2250545079850
- **Reseaux** : @florahair.ci
