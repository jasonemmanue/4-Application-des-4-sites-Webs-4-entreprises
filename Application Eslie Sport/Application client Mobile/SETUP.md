# Eslie Sport Mobile — Guide de configuration et deploiement

## 1. Firebase Console

### Creer le projet Firebase

1. Aller sur https://console.firebase.google.com
2. Cliquer **Ajouter un projet** → nommer `eslie-sport` (ou reutiliser un projet existant)
3. Desactiver Google Analytics si non necessaire → **Creer le projet**

### Ajouter l'application Android

1. Dans le projet Firebase, cliquer l'icone Android (ajouter une appli)
2. Renseigner :
   - **Nom du package** : `com.esliesport.eslie_sport_mobile`
   - **Nom de l'appli** : `Eslie Sport`
   - **Certificat SHA-1** : voir section suivante
3. Telecharger le fichier `google-services.json`
4. Placer le fichier dans :
   ```
   eslie_sport_mobile/android/app/google-services.json
   ```

### Obtenir les cles SHA

Sur la machine de dev, ouvrir un terminal dans le dossier `android/` du projet Flutter :

```bash
cd eslie_sport_mobile/android
./gradlew signingReport
```

Ou avec keytool (debug key par defaut) :

```bash
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

Copier les empreintes **SHA-1** et **SHA-256** affichees.

Dans Firebase Console → Parametres du projet → Vos applis → section Android :
- Ajouter les deux empreintes SHA

> Pour la cle de production (release), utiliser votre keystore de signature
> et ajouter egalement ses SHA dans Firebase.

### Services Firebase a activer

| Service | Activer ? | Pourquoi |
|---------|-----------|----------|
| Cloud Messaging (FCM) | OUI | Notifications push (rappels, confirmations) |
| Authentication | NON | Pas d'OTP Firebase, pas de login Firebase |
| Firestore | NON | L'app utilise l'API FastAPI/PostgreSQL |
| Storage | NON | Medias servis par l'API backend |
| Analytics | OPTIONNEL | Statistiques d'usage |
| Crashlytics | OPTIONNEL | Rapports de crash |

**Important** : L'utilisateur ne veut PAS l'OTP Firebase. Aucun service d'authentification Firebase n'est necessaire.

### Activer Cloud Messaging

1. Dans Firebase Console → Cloud Messaging
2. S'assurer que l'API Cloud Messaging v1 est activee
3. Aucune configuration serveur supplementaire n'est requise pour l'instant (les notifications seront envoyees depuis le backend FastAPI plus tard)

---

## 2. Configuration Android deja en place

Ces elements sont deja configures dans le code source :

| Fichier | Configuration |
|---------|---------------|
| `AndroidManifest.xml` | Icone FCM (`@drawable/ic_notification`) et couleur (`@color/notification_color` = #FFD600) |
| `AndroidManifest.xml` | Permission `POST_NOTIFICATIONS` pour Android 13+ |
| `AndroidManifest.xml` | Queries pour `https://`, `tel:`, `mailto:`, `com.whatsapp` |
| `android/app/build.gradle.kts` | `applicationId = "com.esliesport.eslie_sport_mobile"` |
| `android/app/src/main/res/values/colors.xml` | `notification_color` = #FFD600, `ic_launcher_background` = #0F1724 |
| `android/app/src/main/res/drawable-*/ic_notification.png` | Icone notification blanche sur transparent (toutes densites) |
| Icones launcher | Generees avec flutter_launcher_icons (adaptif, fond navy) |

---

## 3. GeniusPay (Paiement Mobile Money)

### Configuration backend

Les cles API GeniusPay sont gerees cote backend FastAPI (pas dans l'app mobile).

Variables d'environnement backend a configurer :

```
GENIUSPAY_API_KEY=<votre_cle_api>
GENIUSPAY_API_SECRET=<votre_secret>
GENIUSPAY_MODE=production       # ou "sandbox" pour les tests
GENIUSPAY_WEBHOOK_URL=https://api-production-fc58.up.railway.app/api/v1/payments/webhook
```

### Operateurs supportes

| Operateur | Code API | Prefixe telephone | Mode |
|-----------|----------|-------------------|------|
| Wave | `wave` | Tous numeros | Lien direct (navigateur) |
| Orange Money | `orange_money` | `07` | USSD push (notification mobile) |
| MTN Mobile Money | `mtn_mobile_money` | `05` | USSD push (notification mobile) |

### Flux de paiement (cote mobile)

1. L'utilisateur choisit un operateur et entre son numero
2. L'app appelle `POST /api/v1/payments/init`
3. **Wave** : L'app ouvre le `payment_url` dans le navigateur externe
4. **Orange/MTN** : L'app affiche un ecran d'attente pendant que l'utilisateur recoit un push USSD
5. L'app poll `GET /api/v1/payments/{reference}` toutes les 3-4 secondes (max 60s)
6. Resultat : `completed` → ecran de succes | `failed`/`expired` → option de reessai

### Webhook GeniusPay

Configurer le webhook dans le dashboard GeniusPay :
- **URL** : `https://<votre-api-domain>/api/v1/payments/webhook`
- **Evenements** : `payment.completed`, `payment.failed`, `payment.expired`

---

## 4. API Backend (Railway)

### URL de production

```
https://api-production-fc58.up.railway.app
```

### Migration Alembic (correctif deploiement)

La migration `e5f8a12c3b90` (email → whatsapp) a ete corrigee pour etre **idempotente**.
Elle verifie maintenant si les colonnes existent avant de les ajouter ou supprimer.

**Apres avoir push le code corrige**, Railway devrait deployer automatiquement et la migration passera sans erreur.

Si le probleme persiste, connectez-vous au container Railway et stampez manuellement :

```bash
alembic stamp e5f8a12c3b90
```

Cela indique a Alembic que la migration est deja appliquee sans la re-executer.

### Variables d'environnement Railway

S'assurer que ces variables sont definies dans le service Railway :

| Variable | Valeur |
|----------|--------|
| `DATABASE_URL` | `postgresql://...` (fourni par Railway PostgreSQL) |
| `REDIS_URL` | `redis://...` (fourni par Railway Redis) |
| `SECRET_KEY` | Cle secrete pour JWT/sessions |
| `GENIUSPAY_API_KEY` | Cle API GeniusPay |
| `GENIUSPAY_API_SECRET` | Secret GeniusPay |
| `GENIUSPAY_MODE` | `production` ou `sandbox` |
| `CORS_ORIGINS` | `https://www.esliesport.com,https://esliesport.com` |

---

## 5. Compilation et deploiement mobile

### Build debug (telephone branche en USB)

Depuis le chemin junction (necessaire a cause des accents dans le chemin) :

```bash
cd C:\Users\hp\eslie_sport_mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8010
```

Pour tester contre l'API Railway en production :

```bash
cd C:\Users\hp\eslie_sport_mobile
flutter run
```

(Sans `--dart-define`, l'app pointe vers `https://api-production-fc58.up.railway.app` par defaut.)

### Build release APK

```bash
cd C:\Users\hp\eslie_sport_mobile
flutter build apk --release
```

L'APK sera dans `build/app/outputs/flutter-apk/app-release.apk`.

### Build App Bundle (Play Store)

```bash
cd C:\Users\hp\eslie_sport_mobile
flutter build appbundle --release
```

Le bundle sera dans `build/app/outputs/bundle/release/app-release.aab`.

> **Note** : Pour la publication Play Store, il faudra un keystore de signature
> et configurer `android/key.properties` + `android/app/build.gradle.kts` avec
> les parametres de signature.

### Junction Windows

Le projet reel est dans :
```
C:\Users\hp\StudioProjects\4 applications mobiles des 4 sites Webs ainé Williams\Application Eslie Sport\Application client Mobile\eslie_sport_mobile
```

La junction existe a :
```
C:\Users\hp\eslie_sport_mobile
```

Si la junction n'existe plus, la recreer (en admin) :
```cmd
mklink /J "C:\Users\hp\eslie_sport_mobile" "C:\Users\hp\StudioProjects\4 applications mobiles des 4 sites Webs ainé Williams\Application Eslie Sport\Application client Mobile\eslie_sport_mobile"
```

---

## 6. Checklist avant mise en production

- [ ] Creer le projet Firebase et ajouter l'app Android
- [ ] Telecharger `google-services.json` et le placer dans `android/app/`
- [ ] Ajouter les SHA-1 et SHA-256 dans Firebase Console
- [ ] Activer Cloud Messaging dans Firebase
- [ ] Configurer les cles GeniusPay dans les variables d'environnement Railway
- [ ] Configurer le webhook GeniusPay vers l'API
- [ ] Push le code backend corrige (migration idempotente) sur Railway
- [ ] Verifier que le deploiement Railway reussit
- [ ] Generer un keystore de signature pour le release
- [ ] Builder l'APK/AAB de production
- [ ] Tester le flux complet : inscription → paiement → confirmation

---

## 7. Recap des identifiants

| Element | Valeur |
|---------|--------|
| Package Android | `com.esliesport.eslie_sport_mobile` |
| Nom de l'app | Eslie Sport |
| API production | `https://api-production-fc58.up.railway.app` |
| API locale (Docker) | `http://localhost:8010` (host) / `http://10.0.2.2:8010` (emulateur) |
| Port Docker API | 8010 → 8000 |
| Port Docker PostgreSQL | 5600 → 5432 |
| Port Docker Redis | 6381 → 6379 |
| Port Docker Frontend | 3400 → 3000 |
| Port Docker Admin | 3403 → 3000 |
| Contact WhatsApp | +225 05 45 07 98 50 |
| Depot reservation | 50% du prix |
