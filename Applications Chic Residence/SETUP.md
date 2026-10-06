# Configuration des services externes — 3 apps mobiles Chic Residence

Guide complet des actions a mener avant la premiere distribution des APK.
Aucune etape ne touche au code : tout se fait dans les consoles des
prestataires et dans les variables d'environnement du backend.

Documentation detaillee existante (dossier backend `residences-meublees/docs/`) :

- `docs/FIREBASE.md` — SHA, google-services.json, FCM, Play Store
- `docs/PAIEMENT.md` — GeniusPay, flux de paiement, routage operateurs
- `docs/WHATSAPP.md` — API Cloud Meta, templates, webhook

---

## 1. Applications et packages Android

| App | Package (`applicationId`) | Role |
|---|---|---|
| Application client Mobile | `com.chicresidence.chic_residence_mobile` | Play Store — voyageurs |
| Application gestionnaire Mobile | `com.chicresidence.chic_residence_gestionnaire` | APK — personnel terrain |
| Application Backoffice Mobile | `com.chicresidence.chic_residence_backoffice` | APK — admin |

Ces trois noms de package sont **definitifs** : le Play Store interdit tout
changement apres le premier upload, et Firebase lie ses parametres au package.

---

## 2. Firebase — FCM uniquement (PAS d'OTP)

### 2.1 Ce qu'il faut activer

| Service Firebase | Activer ? | Raison |
|---|---|---|
| Cloud Messaging (FCM) | **OUI** | Push notifications (confirmation paiement, rappel check-in, nouvelles residences) |
| Authentication | **NON** | L'app client n'a pas de compte utilisateur. Les apps gestionnaire/backoffice utilisent JWT via l'API backend, pas Firebase Auth |
| Phone Auth / OTP | **NON** | Explicitement exclu. L'authentification staff se fait par telephone + PIN via le backend |
| Analytics | Optionnel | Recommande pour le suivi d'usage, pas obligatoire |
| Crashlytics | Optionnel | Recommande pour le suivi des crashs |

### 2.2 Etapes dans Firebase Console

1. Ouvrir https://console.firebase.google.com/ avec `sakamemmanuel@gmail.com`
2. Le projet **`chic-residence-meuble`** existe deja (project_id: `chic-residence-meuble`)
3. Les 3 apps Android sont deja enregistrees dans le projet
4. Verifier que **Cloud Messaging** est active :
   - Parametres du projet → Cloud Messaging → l'API doit etre activee
   - Si « Cloud Messaging API (V1) » est desactive, cliquer sur le lien
     vers Google Cloud Console et l'activer

### 2.3 google-services.json

Les 3 fichiers sont deja en place :

```
Application client Mobile/android/app/google-services.json
Application gestionnaire Mobile/android/app/google-services.json
Application Backoffice Mobile(Gestionnaire visualisation)/android/app/google-services.json
```

Le fichier actuel contient les 3 apps dans un seul fichier (le SDK Flutter
selectionne automatiquement l'entree correspondant au package de l'app).

Si vous regenerez les fichiers depuis Firebase Console (Parametres → Vos
applications → Telecharger google-services.json), placez chaque fichier dans
le dossier `android/app/` de l'app correspondante.

### 2.4 Services a NE PAS activer

- **Firebase Authentication** — les apps n'utilisent pas Firebase Auth.
  L'app client fonctionne en session anonyme (UUID local). Les apps
  gestionnaire et backoffice s'authentifient par JWT via le backend FastAPI.
- **Phone Authentication / OTP** — interdit. Pas de verification par SMS.
- **Firestore / Realtime Database** — les donnees viennent de l'API PostgreSQL.
- **Firebase Storage** — les images sont servies par le backend.

---

## 3. Empreintes SHA (fingerprints)

### 3.1 Debug (partagees par les 3 apps, specifiques a cette machine)

```
SHA-1   : 7D:9E:C4:3C:20:1E:F3:77:98:7D:18:1B:9D:B2:14:AE:95:71:DF:54
SHA-256 : F6:CA:32:85:A2:7A:AF:B1:EC:84:19:10:2E:E5:27:E8:E1:39:B3:B9:95:93:AC:BA:4B:DB:E1:B3:AF:6F:11:B8
```

A ajouter dans Firebase Console → Parametres du projet → chaque app Android
→ Ajouter une empreinte.

Pour retrouver les empreintes sur une autre machine :

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep -E "SHA"
```

### 3.2 Release

Keystore de release genere le 2026-09-19 :

- **Fichier** : `E:/applications aine williams/chic-residence-release.jks`
- **Alias** : `sakamemmanuel`

```
SHA-1   : 4E:4A:78:AA:40:C4:B8:B6:29:6F:46:CE:36:4F:8C:49:FD:A7:20:27
SHA-256 : B2:DF:BB:32:83:11:8B:53:4B:D5:FA:5D:A3:D0:51:81:79:17:95:6C:09:4D:A6:0E:AC:3B:DF:90:EC:17:BD:0D
```

Ajouter le SHA-1 release sur l'app cliente dans Firebase Console.

### 3.3 App Signing by Google Play (apres premier upload)

Apres le premier upload sur Play Console :
1. Play Console → Integrite de l'application → Signature d'application Play
2. Copier le SHA-1 et SHA-256 du « App signing key certificate »
3. Les ajouter dans Firebase Console sur l'app cliente

---

## 4. GeniusPay — paiement Mobile Money

Passerelle de paiement pour l'acompte 50% (Wave, Orange Money, MTN Mobile Money).

### 4.1 Creer un compte marchand

1. S'inscrire sur https://geniuspay.ci (si pas encore fait)
2. Faire verifier le compte marchand (KYC)
3. **Renommer le compte** : Portail → Parametres → Informations de
   l'entreprise → mettre **« CHIC RESIDENCE »** (actuellement
   « RUAH-STATISTICS » — c'est ce nom que le client voit en payant)

### 4.2 Recuperer les cles API

Dans le portail GeniusPay → API / Developpeurs :

| Valeur | Format | Ou la trouver |
|---|---|---|
| Cle publique (API Key) | `pk_sandbox_...` ou `pk_live_...` | Portail → API → API Key |
| Cle secrete (Secret Key) | `sk_sandbox_...` ou `sk_live_...` | Portail → API → Secret Key |
| Secret du webhook | `whsec_...` | Portail → Webhooks → Signing secret |

Les cles secretes ne s'affichent souvent **qu'une seule fois** a la creation.

### 4.3 Configurer le webhook GeniusPay

Dans le portail GeniusPay → Webhooks, declarer :

```
https://api-production-4e71.up.railway.app/api/v1/payments/webhook/geniuspay
```

Evenements a cocher : `payment.completed`, `payment.failed`, `payment.cancelled`
(ou « tous les evenements »).

### 4.4 Variables d'environnement Railway

Service **api** → Variables :

```env
GENIUSPAY_API_KEY=pk_sandbox_...
GENIUSPAY_SECRET_KEY=sk_sandbox_...
GENIUSPAY_WEBHOOK_SECRET=whsec_...

DEPOSIT_PERCENT=50
PUBLIC_SITE_URL=https://chicresidence.ci
PUBLIC_API_URL=https://api-production-4e71.up.railway.app
```

Commencer avec les cles **sandbox** pour tester sans argent reel.
Passer en cles **live** (`pk_live_`/`sk_live_`) pour la mise en production.

### 4.5 Routage des operateurs

Les valeurs par defaut du code sont deja correctes pour ce compte :

| Canal | `payment_method` | `mmo_provider` |
|---|---|---|
| Wave | `wave` (route directe) | — |
| Orange Money | `pawapay` | `ORANGE_CIV` |
| MTN Mobile Money | `pawapay` | `MTN_MOMO_CIV` |

Si GeniusPay indique d'autres identifiants, surcharger via variables :

```env
GENIUSPAY_METHOD_ORANGE_MONEY=pawapay
GENIUSPAY_MMO_ORANGE_MONEY=ORANGE_CIV
GENIUSPAY_METHOD_MTN_MONEY=pawapay
GENIUSPAY_MMO_MTN_MONEY=MTN_MOMO_CIV
```

### 4.6 Validation du telephone par canal

| Canal | Prefixe attendu | Variable |
|---|---|---|
| Orange Money | `07` | `PHONE_PREFIXES_ORANGE_MONEY` |
| MTN Mobile Money | `05` | `PHONE_PREFIXES_MTN_MONEY` |
| Wave | aucun | Wave accepte tout numero |

### 4.7 Verifier la configuration

```bash
curl https://api-production-4e71.up.railway.app/api/v1/payments/config
```

Reponse attendue : `"enabled": true, "mode": "sandbox"` (ou `"live"`).
Sans cle : `"enabled": false` — l'etape de paiement disparait du tunnel,
la reservation part en « en attente ».

### 4.8 Controle de mise en production

```bash
curl -H "Authorization: Bearer <JWT_ADMIN>" \
  https://api-production-4e71.up.railway.app/api/v1/payments/preflight
```

Tant que `"ready": true` n'apparait pas avec zero point bloquant,
ne pas passer en production.

---

## 5. Meta WhatsApp Business API — notifications transactionnelles

Les confirmations de reservation et les recus d'acompte partent par WhatsApp
(pas par email — le taux d'ouverture en Cote d'Ivoire est insuffisant).

### 5.1 Prerequis

- Compte Meta for Developers : https://developers.facebook.com
- Compte Meta Business relie : https://business.facebook.com
- Un numero de telephone dedie (puce dediee, jamais utilisee dans WhatsApp
  personnel). Meta autorise le numero de test gratuit pour demarrer.

### 5.2 Creer l'application Meta

1. https://developers.facebook.com/apps/ → Create App → Business
2. Nom : `chic-residence-notifications`
3. Add products → WhatsApp → Set up
4. Noter le **App Secret** (App Settings → Basic → Show) →
   sera `WHATSAPP_APP_SECRET`

### 5.3 Configurer le numero d'envoi

Onglet WhatsApp → API Setup :

- Pour tester : utiliser le numero de test gratuit Meta (envoie uniquement
  aux destinataires de la liste blanche)
- Pour la production : cliquer « Add phone number », ajouter le numero
  dedie de CHIC RESIDENCE (+225 05 45 07 98 50), verifier par SMS ou appel

Noter :

```
WHATSAPP_PHONE_NUMBER_ID     = <colonne « From », c'est un ID numerique, pas le numero>
WHATSAPP_BUSINESS_ACCOUNT_ID = <WABA ID>
```

### 5.4 Generer le token d'acces permanent

Le token affiche par defaut **expire en 24h** — inutilisable en production.

1. https://business.facebook.com → Parametres de l'entreprise
2. Utilisateurs → Utilisateurs systeme → Ajouter
3. Nom : `chic-residence-api`, role **Admin**
4. Sur l'utilisateur → Ajouter des actifs → selectionner l'app ET le WABA,
   controle **Total**
5. Generer un jeton → selectionner l'app → cocher :
   - `whatsapp_business_messaging`
   - `whatsapp_business_management`
6. Expiration : **Jamais** → Generer
7. Copier immediatement → sera `WHATSAPP_ACCESS_TOKEN`

### 5.5 Configurer le webhook

1. Choisir une chaine aleatoire → sera `WHATSAPP_WEBHOOK_VERIFY_TOKEN`
2. Dans le portail Meta : WhatsApp → Configuration → Webhook → Edit :
   - Callback URL : `https://api-production-4e71.up.railway.app/whatsapp/webhook`
   - Verify token : la chaine choisie
   - Verify and save
3. S'abonner au champ `messages`

### 5.6 Soumettre les templates

Dans WhatsApp Manager → Message Templates :

**Template 1 : `paiement_recu`** (Utility, fr)
- Header : Media → Document (joindre un PDF exemple)
- Body :
```
Bonjour {{1}},

Votre recu d'acompte est en piece jointe (PDF).
Reference : {{2}}
Sejour du {{3}} au {{4}}.

Solde a regler a l'arrivee : {{5}}.

Conservez ce message : le PDF vaut preuve de paiement.
```
- Exemples : {{1}}=Aicha Kone, {{2}}=CR-20260910-0001, {{3}}=15/10/2026,
  {{4}}=20/10/2026, {{5}}=50 000 F CFA

**Template 2 : `reservation_confirmee`** (Utility, fr)
```
Bonjour {{1}},

Votre reservation {{2}} est enregistree.

Logement : {{3}}
Arrivee : {{4}}
Depart : {{5}}
Occupants : {{6}}

Pour toute question, ce numero reste a votre disposition.
```

**Template 3 : `reservation_rappel`** (Utility, fr) — optionnel
```
Bonjour {{1}},

Rappel : votre sejour au {{2}} commence demain, {{3}}.
Nous vous attendons a partir de 14 h.

Solde a regler a l'arrivee : {{4}}.
```

L'approbation prend de quelques minutes a 24 heures.

### 5.7 Variables d'environnement Railway

```env
WHATSAPP_ACCESS_TOKEN=EAAG...
WHATSAPP_PHONE_NUMBER_ID=123456789012345
WHATSAPP_BUSINESS_ACCOUNT_ID=123456789012345
WHATSAPP_APP_SECRET=xxxxxxxxxxxxxxxxxxxx
WHATSAPP_WEBHOOK_VERIFY_TOKEN=une_chaine_aleatoire
WHATSAPP_LANGUAGE=fr
WHATSAPP_TEMPLATE_RECU_ACOMPTE=paiement_recu
WHATSAPP_TEMPLATE_RESERVATION=reservation_confirmee
WHATSAPP_TEMPLATE_RAPPEL=reservation_rappel
```

### 5.8 Cout previsionnel

- ~0,003 USD par conversation Utility (zone Afrique hors Afrique du Sud)
- 1 000 conversations Utility/mois gratuites
- Estimation : 5-10 USD/mois maximum

---

## 6. Backend API — variables Railway

Toutes les variables a renseigner sur le service API Railway
(`api-production-4e71.up.railway.app`) :

### Obligatoires

| Variable | Valeur | Description |
|---|---|---|
| `DATABASE_URL` | `postgresql://...` | URL PostgreSQL Railway |
| `REDIS_URL` | `redis://...` | URL Redis Railway |
| `SECRET_KEY` | (generer 64 caracteres) | Signature JWT |
| `ADMIN_EMAIL` | `admin@chicresidence.ci` | Compte admin initial |
| `ADMIN_PASSWORD` | (mot de passe fort) | Mot de passe admin |
| `CORS_ORIGINS` | `["https://chicresidence.ci","https://admin.chicresidence.ci"]` | Origines autorisees |

### GeniusPay (facultatif — sans cle, pas de paiement en ligne)

| Variable | Description |
|---|---|
| `GENIUSPAY_API_KEY` | Cle publique (`pk_sandbox_...` ou `pk_live_...`) |
| `GENIUSPAY_SECRET_KEY` | Cle secrete (`sk_sandbox_...` ou `sk_live_...`) |
| `GENIUSPAY_WEBHOOK_SECRET` | Secret de signature du webhook |
| `PUBLIC_SITE_URL` | URL du site public (pas localhost) |
| `PUBLIC_API_URL` | URL de l'API publique (pas localhost) |

### WhatsApp (facultatif — sans token, pas de notification)

| Variable | Description |
|---|---|
| `WHATSAPP_ACCESS_TOKEN` | System User Token permanent |
| `WHATSAPP_PHONE_NUMBER_ID` | ID du numero d'envoi |
| `WHATSAPP_BUSINESS_ACCOUNT_ID` | ID du WABA |
| `WHATSAPP_APP_SECRET` | Secret de l'app Meta |
| `WHATSAPP_WEBHOOK_VERIFY_TOKEN` | Chaine de verification du webhook |

---

## 7. Icones de notification

Les icones de notification transparentes sont deja en place pour les 3 apps
dans `android/app/src/main/res/drawable-*dpi/ic_notification.png` :

| Densite | Taille |
|---|---|
| mdpi | 24x24 |
| hdpi | 36x36 |
| xhdpi | 48x48 |
| xxhdpi | 72x72 |
| xxxhdpi | 96x96 |

Regle Android : l'icone doit etre **blanche pure sur fond transparent**.
Toute autre couleur est aplatie en blanc par le systeme (Android 5.0+).

La couleur de teinte est definie dans `res/values/colors.xml` :
```xml
<color name="notification_color">#DC2626</color>
```

Le `AndroidManifest.xml` de chaque app reference deja ces ressources via
les meta-data `com.google.firebase.messaging.default_notification_icon`
et `default_notification_color`.

---

## 8. Endpoints backend a ajouter (gestionnaire et backoffice)

Les endpoints staff n'existent pas encore dans le backend :

| Endpoint | Usage | Statut |
|---|---|---|
| `POST /api/v1/staff/login` | Authentification telephone + PIN | A creer |
| `GET /api/v1/cleaning-tasks` | Liste des taches de nettoyage | A creer |
| `PUT /api/v1/cleaning-tasks/{id}/status` | Changer le statut d'une tache | A creer |
| `POST /api/v1/cleaning-tasks/{id}/photos` | Upload photo avant/apres | A creer |
| `GET /api/v1/staff/stats` | Statistiques du personnel | A creer |
| `PUT /api/v1/staff/me/fcm-token` | Enregistrer le jeton FCM staff | A creer |
| `GET /api/v1/admin/dashboard` | KPIs admin | A creer |
| `GET /api/v1/admin/staff` | Liste du personnel | A creer |

Les apps gestionnaire et backoffice sont construites et installables, mais
fonctionneront pleinement une fois ces endpoints ajoutes au backend FastAPI.

---

## 9. Compilation des APK

### Contrainte de chemin (Windows)

Le chemin du projet contient le caractere accentue « aine » qui fait echouer
le compilateur Kotlin et le shader compiler Flutter. Copier le projet dans
un chemin ASCII avant de compiler :

```powershell
robocopy "Application client Mobile" "C:\CR-build\client" /MIR /NFL /NDL /NJH /NJS
cd C:\CR-build\client
flutter pub get
flutter build apk --debug
```

### Installer sur telephone

```bash
adb install -r build\app\outputs\flutter-apk\app-debug.apk
```

### Build release (app cliente pour Play Store)

```bash
flutter build appbundle --release
```

Le fichier genere : `build/app/outputs/bundle/release/app-release.aab`.
Necessite un `android/key.properties` configurant le keystore de release.

---

## 10. Checklist avant distribution

### Firebase

- [ ] Projet Firebase `chic-residence-meuble` verifie
- [ ] Cloud Messaging (FCM) active
- [ ] Firebase Authentication **NON active** (pas d'OTP)
- [ ] 3 apps Android enregistrees avec les bons packages
- [ ] SHA-1 debug ajoute sur les 3 apps
- [ ] SHA-1 release ajoute sur l'app cliente
- [ ] 3 google-services.json en place dans `android/app/`
- [ ] Notification de test recue depuis Firebase Console → Messaging
- [ ] Icone de notification affichee blanche (pas un carre uniforme)

### GeniusPay

- [ ] Compte marchand GeniusPay renomme « CHIC RESIDENCE »
- [ ] Cles sandbox recuperees et testees
- [ ] Webhook declare dans le portail GeniusPay
- [ ] Variables posees sur Railway
- [ ] `GET /payments/config` renvoie `"enabled": true`
- [ ] Parcours de test complet en sandbox (reservation → paiement → confirmation)
- [ ] Cles live installees pour la mise en production
- [ ] `GET /payments/preflight` renvoie `"ready": true` avec zero bloquant

### WhatsApp

- [ ] App Meta creee (`chic-residence-notifications`)
- [ ] Numero d'envoi ajoute et verifie
- [ ] System User Token genere (expiration : jamais)
- [ ] Template `paiement_recu` soumis et approuve
- [ ] Template `reservation_confirmee` soumis et approuve
- [ ] Webhook configure et verifie
- [ ] Variables posees sur Railway
- [ ] Notification de test recue sur un numero WhatsApp

### Play Store (app cliente uniquement)

- [ ] Compte developpeur Google Play cree (25 $)
- [ ] AAB release uploade en test interne
- [ ] SHA-1/SHA-256 de la cle Play copiees dans Firebase Console
- [ ] Fiche complete : icone 512x512, captures, description, politique de confidentialite
- [ ] Keystore upload sauvegarde HORS de la machine (cle USB + cloud)

### Backend

- [ ] Endpoints staff crees (pour gestionnaire et backoffice)
- [ ] Variables de production posees sur Railway
- [ ] `.env` de production NON versionne
