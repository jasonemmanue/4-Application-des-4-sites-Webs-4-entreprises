# 4 Applications Mobiles des 4 Sites Webs

Applications mobiles Flutter (Android) pour les 4 entreprises de services basees a Abidjan, Cote d'Ivoire. Chaque application mobile est le compagnon de son site web respectif et consomme la meme API backend.

## Entreprises et applications

### 1. Ruah Statistics — Cabinet d'Etudes & Conseil

| Application | Dossier | Description |
|-------------|---------|-------------|
| Client Mobile | `Application Ruah Statistics/Application client Mobile/` | Consultation des services, portfolio, publications, demande de devis |

- **Site web** : cabinet-etudes (Next.js + FastAPI)
- **Palette** : Cyan / Charcoal
- **Pas de paiement en ligne** — site vitrine / generation de leads

### 2. Chic Residence — Residences Meublees

| Application | Dossier | Description |
|-------------|---------|-------------|
| Client Mobile | `Applications Chic Residence/Application client Mobile/` | Reservation style Airbnb, recherche, favoris, paiement |
| Gestionnaire Mobile | `Applications Chic Residence/Application gestionnaire Mobile/` | Validation nettoyage et controle qualite terrain |
| Backoffice Mobile | `Applications Chic Residence/Application Backoffice Mobile(Gestionnaire visualisation)/` | Admin complet + suivi des gestionnaires |

- **Site web** : residences-meublees (Next.js + FastAPI)
- **Palette** : Rouge / Orange / Sable
- **Paiement** : GeniusPay (Wave, Orange Money, MTN) — depot 50%
- **21 logements** meubles (Studios, Appartements, Villas, Duplex, Chambres)

### 3. Eslie Sport — Salle de Sport

| Application | Dossier | Description |
|-------------|---------|-------------|
| Client Mobile | `Application Eslie Sport/Application client Mobile/` | Activites, planning, inscription cours, abonnements |

- **Site web** : salle-de-sport (Next.js + FastAPI)
- **Palette** : Or / Navy
- **Paiement** : GeniusPay — depot 50% pour les inscriptions

### 4. Flora Hair — Salon de Coiffure & Beaute

| Application | Dossier | Description |
|-------------|---------|-------------|
| Client Mobile | `Application Flora Hair/Application client Mobile/` | Services, reservation RDV, galerie avant/apres, devis photo |

- **Site web** : salon-coiffure (Next.js + FastAPI)
- **Palette** : Or / Chocolat
- **Paiement** : GeniusPay — depot 50% pour les reservations

## Stack technique commune

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter (Dart) |
| State management | Riverpod |
| Navigation | GoRouter |
| Client HTTP | Dio |
| Notifications push | Firebase Cloud Messaging |
| Backend | API FastAPI existante (partagee avec chaque site web) |
| Base de donnees | PostgreSQL 16 (via backend) |
| Paiement | GeniusPay (Wave, Orange Money, MTN Mobile Money) |

## Principes communs

- **Notifications WhatsApp** : Les confirmations de paiement et reservations sont envoyees par WhatsApp (remplace l'email)
- **Push notifications** : Firebase Cloud Messaging pour les rappels et alertes
- **Meme API** : Chaque app consomme les endpoints de l'API FastAPI de son site web
- **Admin web inchange** : L'administration des sites reste sur les back-offices web Next.js
- **Design premium** : Applications professionnelles et elegantes, adaptees a chaque marque
- **Mode sombre/clair** : Support des deux themes

## Structure du projet

```
4 applications mobiles des 4 sites Webs aine Williams/
  |
  |-- Application Ruah Statistics/
  |     |-- Application client Mobile/
  |           |-- CLAUDE.md
  |           |-- README.md
  |
  |-- Applications Chic Residence/
  |     |-- Application client Mobile/
  |     |     |-- CLAUDE.md
  |     |     |-- README.md
  |     |-- Application gestionnaire Mobile/
  |     |     |-- CLAUDE.md
  |     |     |-- README.md
  |     |-- Application Backoffice Mobile(Gestionnaire visualisation)/
  |           |-- CLAUDE.md
  |           |-- README.md
  |
  |-- Application Eslie Sport/
  |     |-- Application client Mobile/
  |           |-- CLAUDE.md
  |           |-- README.md
  |
  |-- Application Flora Hair/
        |-- Application client Mobile/
              |-- CLAUDE.md
              |-- README.md
```

## Contact

- **Developpeur** : prepaxiasfe@gmail.com
- **GitHub** : github.com/jasonemmanue
