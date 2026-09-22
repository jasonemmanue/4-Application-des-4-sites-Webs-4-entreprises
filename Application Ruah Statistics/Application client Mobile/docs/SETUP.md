# Guide de mise en service — Ruah Statistics Mobile

Ce document liste **toutes les actions à mener** hors code : Firebase, clés
signature, GeniusPay, configuration réseau, déploiement, paramétrage
Meta / Google Play.

> Le code de l'application est déjà scaffoldé et pointe vers l'API FastAPI
> de `cabinet-etudes` — cf. [README.md](../README.md).

---

## 1. Identifiants du projet

| Élément | Valeur |
|---|---|
| **Application ID Android** | `com.ruahstatistics.ruah_statistics_mobile` |
| **Bundle ID iOS** | `com.ruahstatistics.ruahStatisticsMobile` (identique après conversion Xcode) |
| **Nom affiché** | Ruah Statistics |
| **API prod (Railway)** | `https://api-production-bc863.up.railway.app/api/v1` — **valeur par défaut** de `ApiConfig.baseUrl` |
| **API prod (domaine perso, quand disponible)** | `https://api.ruah-statistics.com/api/v1` |
| **API locale (dev, émulateur Android)** | `http://10.0.2.2:8001/api/v1` |
| **API locale (dev, téléphone physique)** | `http://localhost:8001/api/v1` **après** `adb reverse tcp:8001 tcp:8001` |
| **WhatsApp cabinet** | `+225 05 45 07 98 50` (encodé `2250545079850` dans `wa.me`) |

Le défaut cible **Railway en production** — aucun paramètre à passer pour un
build « il marche direct sur téléphone ». Redéfinir uniquement en dev local :

```bash
# Emulateur Android → Docker local sur l'hôte
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8001/api/v1

# Téléphone physique en USB debug (avec adb reverse tcp:8001 tcp:8001 d'abord)
flutter run --dart-define=API_BASE_URL=http://localhost:8001/api/v1
```

---

## 2. Clés SHA du certificat de signature

Nécessaires pour :
- Firebase Authentication (Google, Facebook, Apple — SI activées)
- Firebase App Check / Play Integrity
- Google Sign-In / Google Play Services

### 2.1 Debug (généré automatiquement par Flutter/Android Studio)

Empreintes du keystore de debug local (celui utilisé par les builds
`flutter run` / `flutter build --debug`) :

```
SHA-1   : 7D:9E:C4:3C:20:1E:F3:77:98:7D:18:1B:9D:B2:14:AE:95:71:DF:54
SHA-256 : F6:CA:32:85:A2:7A:AF:B1:EC:84:19:10:2E:E5:27:E8:E1:39:B3:B9:95:93:AC:BA:4B:DB:E1:B3:AF:6F:11:B8
Alias   : androiddebugkey
Keystore: ~/.android/debug.keystore  (mot de passe : android)
```

Pour les retrouver plus tard :

```bash
keytool -list -v -alias androiddebugkey \
  -keystore ~/.android/debug.keystore -storepass android | grep -E "SHA1|SHA256"
```

### 2.2 Release (à générer avant la première publication Play Store)

```bash
keytool -genkey -v -keystore ~/.android/ruah_release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias ruah_release
```

- Sauvegarder `ruah_release.jks` **hors du dépôt Git** (coffre-fort, 1Password, gestionnaire de secrets)
- Créer `android/key.properties` (déjà dans `.gitignore`) :
  ```
  storePassword=...
  keyPassword=...
  keyAlias=ruah_release
  storeFile=/chemin/absolu/vers/ruah_release.jks
  ```
- Récupérer SHA-1 / SHA-256 :
  ```bash
  keytool -list -v -alias ruah_release -keystore ~/.android/ruah_release.jks
  ```
- Ajouter ces empreintes dans Firebase Console avant la mise en prod.

### 2.3 Google Play App Signing

Si vous activez **Play App Signing** (recommandé), Google génère une clé
d'upload distincte. Récupérer alors le SHA-1 / SHA-256 depuis :
`Play Console → Setup → App signing → App signing key certificate`. Ajouter ces
empreintes **aussi** dans Firebase.

---

## 3. Firebase — actions à mener

### 3.1 Créer le projet

1. https://console.firebase.google.com → **Add project** → "Ruah Statistics"
2. Désactiver Google Analytics à moins qu'il ne soit demandé
3. Blaze plan requis **uniquement** si vous utilisez Cloud Functions ou une
   consommation FCM supérieure à Spark (rare pour cet usage)

### 3.2 Ajouter l'application Android

1. Icône Android → package name : `com.ruahstatistics.ruah_statistics_mobile`
2. App nickname : "Ruah Mobile"
3. **SHA-1 debug** : coller la valeur du §2.1
4. **SHA-1 release** : à ajouter après §2.2 (avant première release)
5. Télécharger `google-services.json`
6. Placer dans `android/app/google-services.json`
   - **Le fichier est déjà `.gitignore`** — ne pas le commit
7. Activer le plugin Gradle : éditer `android/settings.gradle.kts` :
   ```kotlin
   plugins {
       id("com.google.gms.google-services") version "4.4.2" apply false
       // ... plugins existants
   }
   ```
   Puis `android/app/build.gradle.kts` (fin du fichier) :
   ```kotlin
   plugins {
       id("com.google.gms.google-services")
   }
   ```

### 3.3 Ajouter l'application iOS (facultatif si iOS livré plus tard)

1. Bundle ID : `com.ruahstatistics.ruahStatisticsMobile`
2. Télécharger `GoogleService-Info.plist`
3. Placer dans `ios/Runner/GoogleService-Info.plist`
4. Ouvrir Xcode → glisser le fichier dans le projet Runner (target Runner coché)

### 3.4 Initialisation Firebase dans l'app

Ajouter à `lib/main.dart` (bloc `main()`) :

```dart
import 'package:firebase_core/firebase_core.dart';
// ...

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  // ...
  runApp(const ProviderScope(child: RuahStatisticsApp()));
}
```

L'app peut se lancer **sans** `google-services.json` si `Firebase.initializeApp()`
n'est pas appelé. Ce n'est activé qu'une fois le fichier ajouté.

### 3.5 Services Firebase à **activer** (Console)

| Service | Activer ? | Raison |
|---|---|---|
| **Cloud Messaging (FCM)** | ✅ **oui** | Push notifications (rappels devis, nouvelles publications) |
| **Crashlytics** | ✅ recommandé | Suivi des crashes en prod |
| **Analytics** | ⚪ optionnel | Métriques d'usage |
| **Remote Config** | ⚪ optionnel | Feature-flags sans rebuild |
| **App Check** | ✅ recommandé | Bloquer les appels API depuis des clients non-officiels |
| Authentication | ❌ **non** | Pas de compte utilisateur dans cette app |
| Firestore / Realtime DB | ❌ non | Données servies par FastAPI + PostgreSQL |
| Cloud Storage | ❌ non | Uploads gérés par backend FastAPI |
| **Phone Auth (OTP SMS)** | ❌ **non — expressément refusé** | — |
| Hosting | ❌ non | Sites déjà hébergés sur Railway/Vercel |

### 3.6 Configuration FCM détaillée

Une fois FCM activé, dans **Console → Project settings → Cloud Messaging** :

1. Vérifier que **Firebase Cloud Messaging API (V1)** est activée
   (peut nécessiter de désactiver la Legacy API)
2. Récupérer le fichier `service-account.json` si votre backend doit envoyer
   des pushs (via `firebase-admin` Python) — à ranger côté backend, pas
   dans l'app mobile
3. Côté Android l'icône et la couleur des notifications sont **déjà
   configurées** dans le manifeste :
   ```xml
   <meta-data android:name="com.google.firebase.messaging.default_notification_icon"
              android:resource="@mipmap/ic_notification"/>
   <meta-data android:name="com.google.firebase.messaging.default_notification_color"
              android:resource="@color/notification_color"/>
   ```
4. iOS : configurer les APNs (Apple Push Notification service) dans
   Console Firebase → Cloud Messaging → Apple app configuration → uploader
   la clé APNs `.p8` du compte Apple Developer

### 3.7 Push notifications côté backend

Si le backend `cabinet-etudes` doit envoyer des pushs (rappel de devis, nouvelle
publication) :
- Ajouter `firebase-admin` aux `requirements.txt`
- Stocker le `service-account.json` dans un secret Docker/Railway (jamais dans le repo)
- Nouveaux endpoints à créer côté backend :
  - `POST /api/v1/notifications/register` (l'app envoie son token FCM)
  - Hook interne quand un devis change de statut → envoyer un push

Non fait dans ce scaffolding (extension backend nécessaire).

---

## 4. GeniusPay

**Non applicable pour cette application.**

Le cabinet Ruah Statistics est un site vitrine / génération de leads.
Aucun paiement en ligne n'est prévu ni côté web ni côté mobile (cf. CLAUDE.md :
« Pas de paiement en ligne — le cabinet est un site vitrine »).

GeniusPay reste utilisé dans les 3 autres applications du groupe :
- Chic Résidence (Airbnb-like : dépôt 50 %)
- Eslie Sport (inscription cours : dépôt 50 %)
- Flora Hair (RDV coiffure : dépôt 50 %)

Si vous décidez plus tard d'ajouter du paiement (formations payantes, etc.) :

1. Créer un compte marchand sur https://geniuspay.ci
2. Récupérer `GENIUS_MERCHANT_ID`, `GENIUS_API_KEY`, `GENIUS_SECRET`
3. Backend (nouveau module `payments/` dans `cabinet-etudes/backend`) :
   - `POST /api/v1/payments/initiate` → renvoie une URL de paiement
   - `POST /api/v1/payments/webhook` → GeniusPay notifie du succès
4. App Flutter : `url_launcher` sur l'URL de paiement, écran `payment_return`
5. Moyens de paiement à activer côté GeniusPay :
   - Wave
   - Orange Money CI
   - MTN Mobile Money CI
   - Moov Money CI (optionnel)

---

## 5. Configuration Meta (Facebook / Instagram)

**Non requise pour cette application** — pas de social login, pas de Facebook SDK.

Si un jour vous ajoutez le partage vers Facebook / Instagram Stories :
- Utiliser `share_plus` (déjà dans `pubspec.yaml`) — pas de compte Meta
  Developer requis pour du partage système
- Uniquement si vous voulez faire du **login Facebook** ou du **partage
  natif ciblé Feed/Stories** : créer une app sur https://developers.facebook.com
  et configurer les identifiants dans `AndroidManifest.xml`

---

## 6. Réseau — accès à l'API depuis le téléphone en dev

### 6.1 App → API sur le PC (émulateur)

- Émulateur Android Studio : `http://10.0.2.2:8001/api/v1`
- Émulateur iOS : `http://127.0.0.1:8001/api/v1`

### 6.2 App → API sur le PC (téléphone physique via Wi-Fi)

1. Vérifier que téléphone et PC sont sur le même Wi-Fi
2. Récupérer l'IP LAN du PC : `ipconfig` (Windows) → chercher `IPv4`
3. Ouvrir le port 8001 dans le pare-feu Windows :
   ```powershell
   New-NetFirewallRule -DisplayName "cabinet-etudes API dev" `
     -Direction Inbound -LocalPort 8001 -Protocol TCP -Action Allow
   ```
4. Rebuild avec l'IP LAN :
   ```bash
   flutter build apk --debug --dart-define=API_BASE_URL=http://<IP_LAN>:8001/api/v1
   ```

### 6.3 Cleartext HTTP autorisé — debug uniquement

Android 9+ bloque HTTP en clair. Le fichier
`android/app/src/debug/res/xml/network_security_config.xml` **est déjà
présent** et référencé par `android/app/src/debug/AndroidManifest.xml`.
Il autorise le HTTP en clair vers `10.0.2.2`, `localhost` et `127.0.0.1` —
scope debug seulement, donc **release reste HTTPS-only par défaut**.

En release, aucun HTTP en clair possible : l'app ne parle qu'à Railway en HTTPS.

---

## 7. Base de données — actions déjà exécutées

Sur le container `cabinet-etudes-api-1` :

```bash
docker exec cabinet-etudes-api-1 alembic upgrade head   # 3 migrations
docker exec cabinet-etudes-api-1 python seed.py         # jeu de test
```

Contenu seedé :
- 5 services (Études faisabilité, Sondages, Conseil strat., Formation, Audit)
- 3 projets (dont Étude centrale solaire)
- 4 consultants
- 3 témoignages
- 6 partenaires
- 3 articles + livres blancs
- 2 vidéos
- 4 chiffres clés

Compte admin : `admin@cabinet.com` / mot de passe = `ADMIN_PASSWORD`
défini dans `.env` (défaut `changeme`).

---

## 8. Docker — override local

Un fichier `docker-compose.override.yml` a été créé dans
`cabinet-etudes/` pour désactiver `uvicorn --reload` qui crashait sous
WSL2 (bug `watchfiles: Cannot allocate memory`). Ne pas commit — c'est
un patch local pour le poste de dev.

```yaml
services:
  api:
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Ports exposés (aucun n'a été touché sur d'autres projets) :
- `8001 → api` (FastAPI)
- `5601 → db` (Postgres)
- `6379 → redis`

---

## 9. Build de release Android

```bash
# 1. Créer android/key.properties (cf. §2.2)
# 2. Éditer android/app/build.gradle.kts pour utiliser signingConfigs.release
# 3. Build
cd /x/  # ou le chemin de projet ASCII via subst
flutter build appbundle --release --dart-define=API_BASE_URL=https://api.ruah-statistics.com/api/v1
# → build/app/outputs/bundle/release/app-release.aab (à uploader sur Play Console)
```

**Contournement chemin non-ASCII** : le chemin actuel contient `ainé`
(non-ASCII) → utiliser un lecteur virtuel :

```powershell
subst X: "C:\Users\hp\StudioProjects\4 applications mobiles des 4 sites Webs ainé Williams\Application Ruah Statistics\Application client Mobile"
```

Ensuite `cd /x/` et build. **Nécessaire à chaque redémarrage du PC**
tant que le projet reste dans un chemin non-ASCII.

---

## 10. Publication Google Play Store

1. Créer un compte développeur Google Play (25 USD, une seule fois)
2. Créer la fiche de l'app
   - Titre : Ruah Statistics
   - Description courte : Cabinet d'études et de conseil de référence en Afrique
   - Description longue : cf. `README.md`
   - Icône 512x512 : source `assets/images/logo.png` (déjà cyan sur fond transparent)
   - Feature graphic 1024x500 : à créer (design cyan/charcoal)
3. Contenu — classification IARC : « Contenu réservé aux professionnels »
4. Politique de confidentialité : URL obligatoire — publier une page
   `ruah-statistics.com/privacy` avant soumission
5. Data safety :
   - Collecte : oui (nom, WhatsApp lors des formulaires devis / contact)
   - Partage tiers : non (données envoyées uniquement au backend Ruah)
   - Chiffrement en transit : oui (HTTPS)
6. Upload du `.aab` signé (cf. §9)
7. Play App Signing : accepter (Google gère la clé de signature finale)
8. Soumettre en Internal testing → Closed testing → Production

---

## 11. Récapitulatif des fichiers à ajouter manuellement

| Fichier | Emplacement | Source |
|---|---|---|
| `google-services.json` | `android/app/` | Firebase Console (§3.2) |
| `GoogleService-Info.plist` | `ios/Runner/` | Firebase Console (§3.3) |
| `ruah_release.jks` | Coffre-fort, jamais dans le repo | `keytool -genkey` (§2.2) |
| `key.properties` | `android/` | Édition manuelle (§2.2) |
| `network_security_config.xml` | `android/app/src/debug/res/xml/` (déjà présent) | §6.3 |
| `.env` cabinet-etudes | `cabinet-etudes/` | Copier depuis `.env.example` |

**Tous ces fichiers sont dans `.gitignore`** — ils ne doivent jamais être commit.

---

## 12. Checklist avant première release

- [ ] Générer keystore release et sauvegarder hors dépôt
- [ ] Ajouter SHA-1 debug + release dans Firebase Console
- [ ] Télécharger `google-services.json` et le placer dans `android/app/`
- [ ] Configurer plugin `com.google.gms.google-services` dans Gradle
- [ ] Ajouter `Firebase.initializeApp()` dans `main.dart`
- [ ] Activer FCM, Crashlytics, App Check dans Console Firebase
- [ ] Configurer clé APNs pour iOS (si iOS livré)
- [ ] Publier URL de politique de confidentialité
- [ ] Créer fiche Play Store + feature graphic
- [ ] Build release — URL par défaut = Railway (`https://api-production-bc863.up.railway.app/api/v1`), à surcharger si domaine perso disponible
- [ ] Tester install sur téléphone physique (release APK)
- [ ] Soumettre en Internal testing
