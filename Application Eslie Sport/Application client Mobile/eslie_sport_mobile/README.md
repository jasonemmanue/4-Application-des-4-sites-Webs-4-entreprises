# Eslie Sport Mobile

Application Flutter compagnon du site web **ESLIE SPORT** (salle de sport, Blaukauss/Abidjan).

> _"Parce que le corps a besoin de sport."_

## Fonctionnalites

- Bottom navigation 5 onglets : Accueil, Activites, Planning, Abonnements, Plus
- Catalogue d'activites filtrable (categorie / niveau)
- Planning hebdomadaire interactif avec badges de capacite (vert/orange/rouge)
- Inscription 3 etapes (Infos -> Seance -> Paiement 50%)
- Souscription d'abonnements (Wave / Orange Money / MTN Mobile Money via GeniusPay)
- Coachs, equipements, articles, videos, transformations avant/apres
- Calculateur IMC
- Depot d'avis (modere cote admin)
- Contact + WhatsApp direct

## Stack

| Couche | Technologie |
|--------|-------------|
| Framework | Flutter 3.19+ |
| State | flutter_riverpod ^2.5 |
| Navigation | go_router ^14 |
| HTTP | dio ^5.4 |
| Push | firebase_messaging ^15 |
| Typo | Inter via google_fonts |

## Configuration API

L'app consomme l'API FastAPI du site `salle-de-sport` — **la meme instance**
que celle utilisee par le site public et l'admin (Postgres partagee).

Trois environnements sont selectionnables au build :

```bash
# Production Railway (defaut)
flutter run

# Docker local (voir salle-de-sport/docker-compose.yml : port 8010)
flutter run --dart-define=API_ENV=local

# URL personnalisee (ngrok, staging dedie)
flutter run --dart-define=API_BASE_URL=https://ma-preview.up.railway.app
```

URLs par environnement (fichier [`lib/config/api_config.dart`](lib/config/api_config.dart)) :

| ENV | Base URL |
|-----|----------|
| `production` | `https://api-production-fc58.up.railway.app` |
| `local` | `http://10.0.2.2:8010` |

## Endpoints consommes

Voir [`docs/INTEGRATION-API.md`](docs/INTEGRATION-API.md) pour la matrice complete.
Resume : toutes les routes sous `/api/v1` — activites, planning, abonnements,
coachs, equipements, articles, videos, transformations, avis, contact,
inscriptions, paiement GeniusPay (Wave / Orange Money / MTN).

## Design system

Palette or/navy (voir `lib/config/theme.dart`) :

| Token | Hex |
|-------|-----|
| primary (or) | `#FFD600` |
| dark (navy) | `#0F1724` |
| dark-card | `#1A2332` |
| success | `#22C55E` |
| warning | `#F59E0B` |
| error | `#EF4444` |

## Demarrage

```bash
flutter create --org com.esliesport . --project-name eslie_sport_mobile
flutter pub get
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

> Remarque : `flutter create` restaure les dossiers natifs (`android/`, `ios/`) sans ecraser `lib/`.

### Firebase (push notifications)

1. Creer un projet Firebase pour Android.
2. Ajouter l'app avec le package `com.esliesport.eslie_sport_mobile`.
3. Placer `google-services.json` dans `android/app/`.
4. Ajouter le plugin gradle Google Services.
5. Decommenter / completer `PushNotificationService.initialize()`.

## Architecture

```
lib/
  main.dart
  app.dart
  config/         # api_config, theme, routes
  models/         # activity, coach, subscription, ...
  services/       # api_client, payment, whatsapp, push, providers
  screens/        # une sous-feature par dossier
  widgets/        # cartes, badges, sliders, boutons
  utils/          # formatters
```

## Regles metier

- Devise : FCFA, entiers, separateur ` ` (espace)
- Depot 50% obligatoire pour chaque reservation / abonnement en ligne
- MTN prefixe `05`, Orange prefixe `07`, Wave libre (lien direct)
- Confirmations envoyees par WhatsApp (pas d'email obligatoire)
- Avis moderes cote admin

## Contact

- Telephone : +225 05 45 07 98 50
- WhatsApp : https://wa.me/2250545079850
- Adresse : Blaukauss, Abidjan, Cote d'Ivoire
