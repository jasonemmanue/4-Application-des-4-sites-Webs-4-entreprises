# flora_hair_mobile

Application Flutter compagnon du site web **Flora Hair** (Abidjan). Elle consomme la meme API FastAPI (`/api/v1`) et gere reservation en ligne, depot 50 % via GeniusPay (Wave, Orange, MTN), galerie avant/apres, devis photo, avis, articles, videos et formations.

## Demarrer

```bash
flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8000
```

En production :

```bash
flutter build apk --release --dart-define=API_BASE_URL=https://api.florahair.ci
```

## Structure

```
lib/
  main.dart            # point d'entree (Firebase + ProviderScope)
  app.dart             # MaterialApp.router + theme
  config/              # theme or/chocolat, GoRouter, API config
  models/              # Service, TeamMember, Booking, Payment, Article, ...
  services/            # ApiClient (Dio), PaymentService (GeniusPay), WhatsApp, FCM
  screens/             # home, services, booking (4 etapes), gallery, more, ...
  widgets/             # calendar, before_after_slider, operator_grid, ...
```

## Notes d'integration

- L'admin (services, reservations, devis) reste sur le back-office web Next.js.
- Les notifications WhatsApp remplacent l'email (confirmation reservation / devis).
- Le paiement passe par les endpoints `/payments/*` du backend (GeniusPay).
- Push notifications via Firebase Cloud Messaging (initialisation best-effort).
