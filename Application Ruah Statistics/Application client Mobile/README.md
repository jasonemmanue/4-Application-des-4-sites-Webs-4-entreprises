# Ruah Statistics Mobile

Application mobile Flutter pour **RUAH-STATISTICS**, cabinet d'etudes et de conseil de reference en Afrique, base a Abidjan (Cote d'Ivoire).

## Apercu

Application compagnon du site web du cabinet, permettant aux clients et prospects de :
- Decouvrir les domaines d'expertise et services du cabinet
- Explorer le portfolio de realisations (filtrable par secteur, pays, annee)
- Lire les publications (articles et livres blancs)
- Regarder les videos (conferences, interviews, webinaires)
- Consulter les profils des consultants
- Soumettre des demandes de devis (formulaire 4 etapes)
- Envoyer des messages via le formulaire de contact
- Deposer des temoignages

## Stack technique

| Couche | Technologie |
|--------|-------------|
| Mobile | Flutter (Dart) |
| State | Riverpod |
| Navigation | GoRouter |
| HTTP | Dio |
| Push | Firebase Cloud Messaging |
| Backend | API FastAPI existante (partagee avec le site web) |
| BDD | PostgreSQL 16 (via le backend) |

## Lien avec le site web

L'application consomme la meme API REST (`/api/v1`) que le site web Next.js.
L'administration (gestion des services, realisations, publications, temoignages, leads) se fait exclusivement via le **back-office web** (admin Next.js).

## Design

- **Palette** : Cyan (`#00BCD4`) / Charcoal (`#1A1A2E`) / Ambre accent
- **Typographie** : Playfair Display (titres) + Inter (corps)
- **Style** : Premium, professionnel, mode sombre par defaut
- **Inspiration** : Site web existant adapte pour mobile

## Fonctionnalites cles

- **Chiffres cles animes** : Compteurs avec animation au scroll
- **Portfolio filtrable** : Par secteur, pays et annee
- **Livres blancs** : Telechargement avec capture d'email (lead magnet)
- **Devis multi-etapes** : 4 etapes (mission, projet, contact, recapitulatif)
- **Temoignages** : Consultation et soumission (moderes par l'admin)
- **Notifications WhatsApp** : Confirmations de devis et contact via WhatsApp (remplace l'email)
- **Push notifications** : Nouvelles publications, reponses aux devis

## Demarrage

```bash
flutter create --org com.ruahstatistics ruah_statistics_mobile
cd ruah_statistics_mobile
flutter pub get
flutter run
```

## Configuration

Creer un fichier `lib/config/api_config.dart` :

```dart
class ApiConfig {
  static const String baseUrl = 'https://api.ruah-statistics.com/api/v1';
  // En dev : 'http://localhost:8001/api/v1'
}
```

## Contact

- **Site web** : ruah-statistics.com
- **Email** : contact@ruah-statistics.com
- **Telephone** : +225 05 45 07 98 50
- **Adresse** : 123 Avenue de l'Independance, Abidjan, Cote d'Ivoire
