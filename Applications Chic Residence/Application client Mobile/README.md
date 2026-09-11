# Chic Residence Mobile — Application Client

Application mobile Flutter pour **CHIC RESIDENCE**, residences meublees a Abidjan (Cote d'Ivoire).
*"Votre chez-vous, ailleurs"*

## Apercu

Application de reservation de residences meublees **inspiree d'Airbnb**, permettant aux voyageurs de :
- Rechercher des residences avec autocomplete intelligent (fuzzy matching)
- Filtrer par type, capacite, prix, equipements
- Consulter les disponibilites sur un calendrier interactif
- Calculer le prix en temps reel (tarification saisonniere)
- Reserver et payer un depot 50% via Mobile Money
- Sauvegarder des favoris
- Comparer jusqu'a 3 residences cote a cote
- Lire des articles lifestyle et regarder des videos
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
L'administration se fait via le **back-office web** et l'**application backoffice mobile**.

## Ecosysteme Chic Residence (3 apps mobiles)

| Application | Role |
|-------------|------|
| **Client Mobile** (cette app) | Recherche, reservation, paiement pour les voyageurs |
| **Gestionnaire Mobile** | Validation nettoyage et controle pour le personnel |
| **Backoffice Mobile** | Administration complete + suivi des gestionnaires |

## Design

- **Inspiration** : Airbnb
- **Palette** : Rouge (`#EF4444`) / Orange accent (`#F97316`) / Sable (`#D4A05A`)
- **Typographie** : Playfair Display (titres) + Inter (corps)
- **Style** : Premium, moderne, cards avec grandes photos
- **Mode sombre et clair** supportes

## Fonctionnalites cles

- **Recherche Airbnb-like** : Barre de recherche + chips categories + filtres avances
- **Autocomplete fuzzy** : Suggestions en temps reel avec matching Levenshtein
- **Calendrier de disponibilite** : Vert = libre, Rouge = occupe
- **Calculateur de prix** : Tarification saisonniere en temps reel
- **Comparateur** : Jusqu'a 3 residences cote a cote
- **Favoris anonymes** : Coeur toggle, persistance par session UUID
- **Reservation 4 etapes** : Dates -> Infos -> Confirmation -> Paiement 50%
- **Paiement Mobile Money** : Wave, Orange Money, MTN via GeniusPay
- **Notifications WhatsApp** : Confirmations de reservation (remplace l'email)
- **Push notifications** : Rappels check-in/check-out, promotions

## Portfolio

- 21 logements meubles (Studios, Appartements, Villas, Duplex, Chambres)
- 42 personnes de capacite totale
- Equipements : WiFi, piscine, parking, clim, cuisine, TV, lave-linge, gym, jardin, securite, ascenseur, balcon, groupe electrogene

## Demarrage

```bash
flutter create --org com.chicresidence chic_residence_mobile
cd chic_residence_mobile
flutter pub get
flutter run
```

## Contact

- **Email** : chicresidencemeublee@gmail.com
- **Telephone** : +225 05 45 07 98 50
- **Adresse** : Dans le dos de l'Ivoire Trade Center (ITC), Abidjan
