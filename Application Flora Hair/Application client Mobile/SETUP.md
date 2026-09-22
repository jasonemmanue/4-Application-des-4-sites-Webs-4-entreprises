# Configuration externe — Flora Hair Mobile

> Ce document liste **toutes les actions manuelles** a effectuer en dehors du code
> pour que l'application fonctionne completement. Le code est deja ecrit et
> fonctionnel.

---

## 1. Firebase — Cloud Messaging (notifications push)

### 1.1 Etat actuel

| Element | Statut |
|---------|--------|
| Projet Firebase | **Cree** — `flora-hair-app` |
| `google-services.json` | **En place** — `android/app/google-services.json` |
| Package Android | `com.florahair.flora_hair_mobile` |
| Plugin Gradle `com.google.gms.google-services` | **Configure** |
| `firebase_core` + `firebase_messaging` | **Dans pubspec.yaml** |

### 1.2 Actions a mener dans la console Firebase

Aller sur **https://console.firebase.google.com** → projet `flora-hair-app`.

#### A. Ajouter les cles SHA (obligatoire pour FCM sur Android)

1. **SHA-1 debug** — executer dans le terminal :

   ```bash
   # Windows
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android

   # Linux/Mac
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   ```

2. **SHA-1 et SHA-256 release** — si vous avez un keystore de release :

   ```bash
   keytool -list -v -keystore chemin/vers/votre-keystore.jks -alias votre-alias
   ```

3. Dans la console Firebase :
   - **Parametres du projet** (roue dentee) → **Vos applications** → application Android
   - **Ajouter une empreinte** → coller le SHA-1 debug
   - **Ajouter une empreinte** → coller le SHA-1 release
   - **Ajouter une empreinte** → coller le SHA-256 release

4. **Re-telecharger `google-services.json`** apres ajout des SHA et le placer dans `android/app/`.

#### B. Activer Cloud Messaging

1. Console Firebase → **Cloud Messaging** (menu de gauche)
2. Verifier que l'API **Firebase Cloud Messaging API (V1)** est **activee**
   - Si elle est desactivee : cliquer sur les trois points → **Activer**
3. **Ne PAS activer** Firebase Authentication — l'app n'utilise pas d'OTP ni de connexion Firebase

#### C. Services a NE PAS activer

| Service | Raison |
|---------|--------|
| Firebase Authentication | Pas de comptes utilisateurs, pas d'OTP |
| Firestore / Realtime Database | L'app utilise l'API FastAPI existante |
| Firebase Analytics | Optionnel, pas necessaire |
| Firebase Crashlytics | Optionnel, pas configure dans le code |

### 1.3 Envoyer des notifications push (cote backend)

Pour envoyer des notifications push aux clientes (rappels RDV, confirmations), le
backend devra utiliser le **Firebase Admin SDK** (Python). Cela necessite :

1. Console Firebase → **Parametres du projet** → **Comptes de service**
2. **Generer une nouvelle cle privee** → telecharge un fichier JSON
3. Placer ce fichier sur le serveur backend (Railway) en variable d'environnement
   `FIREBASE_SERVICE_ACCOUNT` (contenu JSON encode)

> Cette etape est **pour plus tard** — l'app fonctionne sans, elle ne recevra
> simplement pas de notifications push tant que le backend n'envoie pas de
> messages FCM.

---

## 2. GeniusPay — Paiement mobile money

### 2.1 Ce qui est deja en place

L'integration complete est dans le **backend FastAPI** (`salon-coiffure/backend/`).
L'application mobile appelle les memes routes que le site web :

| Route mobile | Action |
|-------------|--------|
| `POST /api/v1/payments/init` | Initier un paiement (50% acompte) |
| `GET /api/v1/payments/{ref}` | Verifier le statut (polling 3s) |
| `POST /api/v1/payments/{ref}/retry` | Reessayer avec autre operateur |
| `POST /api/v1/payments/{ref}/cancel` | Annuler |

### 2.2 Actions a mener

Tout est documente en detail dans `salon-coiffure/docs/PAIEMENT-GENIUSPAY.md`.
En resume :

1. **Creer un compte marchand** sur https://pay.genius.ci
   - Piece d'identite du gerant
   - RCCM de l'entreprise
   - Coordonnees du compte de versement (mobile money ou bancaire)

2. **Recuperer les cles API** dans l'espace marchand :
   - `GENIUSPAY_API_KEY` (`pk_live_...`)
   - `GENIUSPAY_API_SECRET` (`sk_live_...`)
   - `GENIUSPAY_SANDBOX_API_KEY` (`pk_sandbox_...`) — pour les tests
   - `GENIUSPAY_SANDBOX_API_SECRET` (`sk_sandbox_...`)

3. **Configurer les variables d'environnement** du backend :

   ```bash
   # .env (developpement)
   GENIUSPAY_MODE=sandbox
   GENIUSPAY_SANDBOX_API_KEY=pk_sandbox_xxxxxxxxxxxx
   GENIUSPAY_SANDBOX_API_SECRET=sk_sandbox_xxxxxxxxxxxx

   # Railway (production)
   GENIUSPAY_MODE=production
   GENIUSPAY_API_KEY=pk_live_xxxxxxxxxxxx
   GENIUSPAY_API_SECRET=sk_live_xxxxxxxxxxxx
   ```

4. **Enregistrer le webhook** (une seule fois par environnement) :

   ```bash
   docker compose exec api python register_webhook.py
   ```

   Copier le secret affiche (`whsec_live_...`) dans `GENIUSPAY_WEBHOOK_SECRET`.

5. **Verifier** :

   ```bash
   curl -s https://api.florahair.online/api/v1/payments/config
   # Doit renvoyer : {"configured": true, "mode": "production", ...}
   ```

### 2.3 Operateurs supportes

| Operateur | Code | Prefixe telephone |
|-----------|------|-------------------|
| Wave | `wave` | Tous (portefeuille, pas de prefixe impose) |
| Orange Money | `orange_money` | `07` |
| MTN Mobile Money | `mtn_money` | `05` |

---

## 3. Signature de release (keystore Android)

Pour publier sur le Play Store ou distribuer un APK signe :

### 3.1 Generer le keystore (une seule fois)

```bash
keytool -genkey -v -keystore flora-hair-release.jks -keyalg RSA -keysize 2048 -validity 10000 -alias flora-hair
```

### 3.2 Creer `android/key.properties`

```properties
storePassword=votre_mot_de_passe
keyPassword=votre_mot_de_passe
keyAlias=flora-hair
storeFile=chemin/absolu/vers/flora-hair-release.jks
```

> **Ne jamais commiter ce fichier** — il est deja dans `.gitignore`.

### 3.3 Compiler en release

```bash
# APK release (distribution directe)
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

---

## 4. URL de l'API — configuration au build

### 4.1 Valeurs par defaut

| Contexte | URL | Configuration |
|----------|-----|---------------|
| Production (defaut) | `https://api.florahair.online` | Aucune, c'est la valeur par defaut |
| Docker local (emulateur) | `http://10.0.2.2:8000` | `--dart-define=API_BASE_URL=http://10.0.2.2:8000` |
| Docker local (appareil physique Wi-Fi) | `http://IP_DU_PC:8000` | `--dart-define=API_BASE_URL=http://192.168.x.x:8000` |

### 4.2 Exemples

```bash
# Dev avec Docker local sur emulateur
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000

# Dev avec Docker local sur telephone (meme Wi-Fi)
flutter run --dart-define=API_BASE_URL=http://192.168.1.42:8000

# Production (pas besoin de --dart-define, c'est le defaut)
flutter build apk --release
```

---

## 5. WhatsApp Business API (optionnel)

Les confirmations de reservation et recus de paiement sont envoyes par WhatsApp
(via Meta Business API). Configuration dans le backend :

| Variable | Valeur |
|----------|--------|
| `WHATSAPP_PHONE_NUMBER_ID` | ID du numero WhatsApp Business |
| `WHATSAPP_ACCESS_TOKEN` | Token d'acces permanent (Meta for Developers) |
| `WHATSAPP_BUSINESS_ACCOUNT_ID` | ID du compte WhatsApp Business |

Les modeles de message doivent etre **approuves par Meta** (24-48h) :

| Modele | Usage |
|--------|-------|
| `flora_reservation_confirmee` | Confirmation de reservation |
| `flora_acompte_recu` | Recu de paiement |
| `flora_recu_pdf` | Recu PDF en piece jointe |
| `flora_devis_reponse` | Reponse a une demande de devis |

> Sans WhatsApp configure, l'app fonctionne normalement. Le bouton WhatsApp
> dans l'app ouvre directement `wa.me/2250545079850` (lien universel).

---

## 6. SMTP (optionnel, recus email)

Si WhatsApp n'est pas configure, les recus partent par email. Variables :

```
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=contact@florahair.com
SMTP_PASSWORD=mot_de_passe_application
SMTP_FROM=contact@florahair.com
SMTP_STARTTLS=true
```

> Sans ni WhatsApp ni SMTP, tout fonctionne : le salon voit les demandes dans
> l'administration et rappelle manuellement.

---

## 7. Deploiement backend (Railway)

Le backend est deploye sur Railway. Variables d'environnement a configurer :

### Variables obligatoires

```
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
SECRET_KEY=cle-secrete-longue-et-aleatoire
ADMIN_EMAIL=admin@florahair.com
ADMIN_PASSWORD=mot_de_passe_fort
PUBLIC_SITE_URL=https://www.florahair.online
PUBLIC_API_URL=https://api.florahair.online
CORS_ORIGINS=https://www.florahair.online,https://admin.florahair.online
```

### Variables paiement (voir section 2)

```
GENIUSPAY_MODE=production
GENIUSPAY_API_KEY=pk_live_...
GENIUSPAY_API_SECRET=sk_live_...
GENIUSPAY_WEBHOOK_SECRET=whsec_live_...
```

---

## 8. Recapitulatif — checklist avant mise en production

- [ ] **Firebase** : SHA-1 debug + release ajoutees, `google-services.json` a jour
- [ ] **Firebase** : Cloud Messaging API (V1) activee
- [ ] **GeniusPay** : compte marchand actif, cles live configurees
- [ ] **GeniusPay** : webhook enregistre, secret configure
- [ ] **GeniusPay** : `payments/config` renvoie `configured: true, mode: production`
- [ ] **Keystore** : `key.properties` cree avec le keystore release
- [ ] **APK** : compile en release avec `flutter build apk --release`
- [ ] **Backend** : deploye sur Railway avec toutes les variables d'environnement
- [ ] **Domaine** : `api.florahair.online` pointe vers le backend Railway
- [ ] **WhatsApp** (optionnel) : modeles approuves par Meta, tokens configures
- [ ] **SMTP** (optionnel) : serveur configure pour les recus email
