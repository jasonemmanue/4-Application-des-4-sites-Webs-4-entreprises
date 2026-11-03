# Ruah Statistics sur iPhone : build TestFlight par Codemagic

Le build iOS est fait **par Codemagic** (Mac dans le cloud) puis envoyé
**automatiquement** dans App Store Connect → TestFlight. Rien ne se compile sur
le PC Windows. Configuration calquée sur Prepaxia (`Prepaxia Project/
PROCEDURE_BUILD_TESTFLIGHT.md`), qui passe TestFlight.

| Élément | Valeur |
|---|---|
| Dépôt GitHub | `jasonemmanue/4-Application-des-4-sites-Webs-4-entreprises` |
| Fichier Codemagic | `codemagic.yaml` **à la racine du dépôt** (partagé avec les autres apps) |
| Dossier de l'app | `Application Ruah Statistics/Application client Mobile` |
| Bundle iOS | `com.ruahstatistics.ruahStatisticsMobile` |
| Compte Apple | le même que Prepaxia, équipe `LD4W7KA5YG` |
| Clé App Store Connect dans Codemagic | `Prepaxia ASC` (déjà en place, couvre toute l'équipe) |
| Firebase | projet `ruah-statistics-mobile`, app iOS `1:1037340562498:ios:1376fc04c856278858c9db` |
| Flutter | 3.38.4, identique au PC |

| Branche | Workflow | Compte Apple ? | Résultat |
|---|---|---|---|
| `ruah/ios-build-check` | `ruah-ios-build-check` | non | compile ? |
| `ruah/ios-simulateur` | `ruah-ios-simulateur` | non | app lancée dans un iPhone simulé + 2 captures |
| `ruah/ios-testflight` | `ruah-ios-testflight` | **oui** | IPA signée envoyée à TestFlight |

## Ce qui est déjà fait dans le code (2026-11-03)

| Fichier | Rôle |
|---|---|
| `ios/Podfile` | iOS 15.0, plancher des SDK Firebase 11 ; pods alignés |
| `ios/Runner/GoogleService-Info.plist` | Firebase iOS (app créée dans la console), **hors Git** : transmis à Codemagic par le groupe `ruah_firebase` |
| `ios/Runner/AppDelegate.swift` | `FirebaseApp.configure()` avant Flutter, notifications app ouverte |
| `ios/Runner/Info.plist` | Nom « Ruah Statistics », portrait, iPad plein écran, push en arrière-plan, schémas WhatsApp/tél/mail, chiffrement déclaré (pas de « Missing Compliance ») |
| `ios/Runner/Runner.entitlements` / `RunnerRelease.entitlements` | APNs `development` (Debug/Profile) / `production` (Release) |
| `ios/Runner/PrivacyInfo.xcprivacy` | Manifeste de confidentialité : nom, numéro WhatsApp et message envoyés par les formulaires, sans suivi |
| `ios/Runner.xcodeproj/project.pbxproj` | iOS 15.0, entitlements par configuration, plist Firebase et manifeste embarqués |
| `lib/services/push.dart` | Sur iOS, attend le jeton APNs avant l'abonnement au sujet `actualites` |

## À faire une fois (20 à 30 min)

### 1. Codemagic : ajouter le dépôt

1. GitHub → Settings → Applications → Installed GitHub Apps → **Codemagic** →
   Configure → **Repository access** : ajouter
   `4-Application-des-4-sites-Webs-4-entreprises` → Save.
2. https://codemagic.io/apps → **Add application** → GitHub → ce dépôt → type
   **Flutter App (via codemagic.yaml)** → Finish. (Déjà fait si Eslie Sport ou
   une autre app du dépôt est déjà dans Codemagic : rien à refaire.)

### 2. Apple Developer : l'App ID

[Identifiers](https://developer.apple.com/account/resources/identifiers/list) →
**+** → App IDs → App → Description `Ruah Statistics`, Bundle ID **Explicit**
`com.ruahstatistics.ruahStatisticsMobile` → cocher **Push Notifications** →
Continue → Register.

### 3. App Store Connect : l'app

[Apps](https://appstoreconnect.apple.com/apps) → **+** → New App → iOS, nom
`Ruah Statistics`, langue Français, bundle
`com.ruahstatistics.ruahStatisticsMobile`, SKU `ruah-statistics-ios`, accès
complet → Create. Le workflow retrouve l'app par son bundle : aucun Apple ID à
recopier dans `codemagic.yaml`.

### 4. Profil App Store

1. [Créer un profil](https://developer.apple.com/account/resources/profiles/add)
   → **App Store Connect** → App ID `com.ruahstatistics.ruahStatisticsMobile` →
   cocher le certificat **Apple Distribution** utilisé par Prepaxia dans
   Codemagic → nom `ruah_app_store` → Generate.
2. Codemagic → Teams → **codemagic.yaml settings** → Code signing identities →
   **iOS provisioning profiles** → **Fetch profiles** (clé `Prepaxia ASC`) →
   cocher `ruah_app_store` → Download selected. Le certificat doit avoir une
   **coche verte** ; une croix rouge = le profil n'a pas le bon certificat :
   refaire 4.1.

### 5. Notifications iOS : clé APNs dans Firebase

[Firebase](https://console.firebase.google.com/project/ruah-statistics-mobile/settings/cloudmessaging)
→ Cloud Messaging → app iOS → **APNs Authentication Key** → Upload : la même
clé `.p8` APNs que Prepaxia convient (une clé APNs vaut pour toute l'équipe
Apple), avec son Key ID et le Team ID `LD4W7KA5YG`. Sans elle, l'app tourne
normalement mais **aucune notification n'arrive sur iPhone**.

### 6. Codemagic : le fichier Firebase iOS

`ios/Runner/GoogleService-Info.plist` est **hors Git** (`.gitignore` de l'app,
comme `google-services.json`). Codemagic le reçoit par un groupe de variables
et le recrée avant chaque build ; sans ce groupe, les trois workflows Ruah
s'arrêtent dès la première étape avec un message clair.

1. Sur le PC, copier le contenu du fichier encodé en base64 (PowerShell) :

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("C:\Users\hp\StudioProjects\4 applications mobiles des 4 sites Webs ainé Williams\Application Ruah Statistics\Application client Mobile\ios\Runner\GoogleService-Info.plist")) | Set-Clipboard
   ```

   Fichier perdu : `firebase apps:sdkconfig IOS 1:1037340562498:ios:1376fc04c856278858c9db --project ruah-statistics-mobile --out ios/Runner/GoogleService-Info.plist`
   depuis le dossier de l'app.
2. Codemagic → l'application du dépôt → **Environment variables** → **Add** :
   nom `RUAH_GOOGLE_SERVICE_INFO_PLIST`, valeur = coller, groupe
   **`ruah_firebase`** (le créer), cocher **Secure** → Add.

## Lancer un build

Depuis la racine du dépôt, `main` à jour :

```bash
git push origin main:ruah/ios-build-check
```

```bash
git push origin main:ruah/ios-testflight
```

Commencer par `ruah/ios-build-check` : il ne demande rien à Apple et valide
CocoaPods et la compilation (15 à 25 min). Ensuite `ruah/ios-testflight`
(25 à 40 min). Ou dans Codemagic : **Start new build** → branche → workflow.

- Version : `pubspec.yaml` (partie avant le `+`). Le numéro de build est
  calculé : dernier build TestFlight + 1.
- Le build arrive dans TestFlight **sans revue bêta** (test interne,
  `submit_to_testflight: false`).

## Dans App Store Connect puis sur l'iPhone

1. App → TestFlight : le build passe **Processing** (10 à 30 min) puis **Ready to Test**.
2. Internal Testing → groupe de testeurs → **+** → cocher le build.
3. iPhone : app **TestFlight**, même identifiant Apple → Ruah Statistics → Installer.
4. À vérifier : accueil et images, Services, Projets, envoi d'un devis
   (onglet Contact), ouverture de WhatsApp, Publications, Profil > mode
   sombre, notification envoyée depuis la console Firebase (sujet `actualites`).

## Si le build échoue

| Message | Cause | Que faire |
|---|---|---|
| Aucun workflow proposé | branche sans `codemagic.yaml` | pousser `main` sur la branche `ruah/...` |
| `Groupe ruah_firebase absent ou vide` | étape 6 non faite | ajouter la variable |
| `Aucune app App Store Connect pour ...` | étape 3 non faite | créer l'app |
| `No matching profiles found for bundle identifier` | profil absent ou sans le certificat | refaire l'étape 4 |
| `Integration "Prepaxia ASC" not found` | dépôt ajouté sous une autre équipe Codemagic | ajouter l'app dans l'équipe qui a la clé |
| CocoaPods | dépôt de pods momentanément indisponible | relancer |
| « build number already used » | build relancé trop vite | relancer |

Journaux complets : build Codemagic → Artifacts → `xcodebuild_logs`.

## Paiement et revue Apple

L'écran Paiement règle des **prestations de conseil réalisées hors de l'app**
(CinetPay) : c'est un service physique, autorisé hors achat intégré
(règle 3.1.3(e)). Rien de numérique n'est vendu dans l'app. À rappeler dans les
notes de revue lors d'une soumission App Store.
