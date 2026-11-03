# Flora Hair sur iPhone : TestFlight par Codemagic

Le build iOS est construit **par Codemagic** (Mac dans le cloud) et envoyé tout seul dans
App Store Connect → TestFlight. Rien ne se compile sur le PC Windows. Modèle : la chaîne
Prepaxia (`Prepaxia Project/PROCEDURE_BUILD_TESTFLIGHT.md`), qui passe TestFlight depuis le
18/10/2026.

| Élément | Valeur |
|---|---|
| Dépôt GitHub | `jasonemmanue/4-Application-des-4-sites-Webs-4-entreprises` (monorepo) |
| Fichier Codemagic | `codemagic.yaml` à la **racine** du dépôt (partagé avec Eslie et Ruah) |
| Dossier de l'app | `Application Flora Hair/Application client Mobile/flora_hair_mobile` |
| Bundle ID | `com.florahair.floraHairMobile` |
| Équipe Apple | `LD4W7KA5YG` (celle de Prepaxia) |
| Clé App Store Connect dans Codemagic | `Prepaxia ASC` (clé d'équipe, sert à toutes les apps) |
| Firebase | projet `flora-hair-app`, app iOS `1:314498247667:ios:dbc6c790492af5b2e84086` |
| Flutter | 3.38.4 (identique au PC) |
| Version envoyée | celle de `pubspec.yaml` (1.3.0) ; numéro de build = dernier TestFlight + 1 |

## Ce qui est déjà fait (2026-11-03)

- App iOS déclarée dans Firebase (`flora-hair-app`) et `GoogleService-Info.plist` téléchargé
  (local seulement, jamais commité : règle « Secrets » du `.gitignore`).
- Projet Xcode : iOS 15, `Podfile`, notifications push (entitlements `development` en Debug,
  `production` en Release), `PrivacyInfo.xcprivacy`, autorisations appareil photo et photos
  (devis), `ITSAppUsesNonExemptEncryption = false`, nom affiché « Flora Hair », portrait.
- Code : jeton APNs attendu avant le jeton FCM, notifications visibles application ouverte.
- `codemagic.yaml` : workflows `flora-ios-build-check` et `flora-ios-testflight`.

## À faire par toi, une seule fois (30 à 45 min)

### 1. App ID (developer.apple.com)
1. https://developer.apple.com/account/resources/identifiers/list → **+** → **App IDs** → **App**.
2. Description `Flora Hair`, **Bundle ID explicite** : `com.florahair.floraHairMobile`.
3. Cocher **Push Notifications** → **Continue** → **Register**.

### 2. Fiche de l'app (App Store Connect)
1. https://appstoreconnect.apple.com/apps → **+** → **Nouvelle app**.
2. Plateforme **iOS**, nom `Flora Hair` (si Apple dit qu'il est pris : `Flora Hair Abidjan`),
   langue **Français**, bundle `com.florahair.floraHairMobile`, SKU `florahair-ios`,
   accès complet → **Créer**.
3. Rien d'autre à remplir pour TestFlight interne. Le workflow retrouve l'app par son bundle.

### 3. Profil App Store
1. https://developer.apple.com/account/resources/profiles/add → **App Store Connect** → **Continue**.
2. App ID `com.florahair.floraHairMobile` → **Continue**.
3. Cocher le certificat **Apple Distribution** déjà utilisé par Prepaxia (celui de Codemagic,
   le plus récent) → **Continue**.
4. Nom : `flora_hair_app_store` → **Generate**. Pas besoin de le télécharger.
5. Codemagic → **Teams** → **codemagic.yaml settings** → **Code signing identities** → onglet
   **iOS provisioning profiles** → **Fetch profiles** (clé `Prepaxia ASC`) → cocher
   `flora_hair_app_store` → **Download selected**. Le profil doit afficher son certificat avec
   une coche verte.

### 4. Codemagic : application et variable Firebase
1. GitHub : l'application Codemagic doit avoir accès au dépôt. https://github.com/settings/installations
   → **Codemagic** → **Configure** → ajouter `4-Application-des-4-sites-Webs-4-entreprises`.
2. https://codemagic.io/apps → **Add application** → GitHub → ce dépôt → **Flutter App (via
   codemagic.yaml)**. Une seule application Codemagic pour les trois apps du dépôt.
3. Copier le fichier Firebase iOS dans le presse-papiers (Git Bash, sur ce PC) :

   ```bash
   base64 -w0 "C:/Users/hp/StudioProjects/4 applications mobiles des 4 sites Webs ainé Williams/Application Flora Hair/Application client Mobile/flora_hair_mobile/ios/Runner/GoogleService-Info.plist" | clip
   ```

4. Codemagic → l'application → **Environment variables** → **Add** : nom
   `FLORA_GOOGLE_SERVICE_INFO_PLIST`, valeur = coller, **Group** `flora_firebase`, cocher
   **Secure** → **Add**.

### 5. Clé APNs dans Firebase (sans elle, aucune notification sur iPhone)
1. La clé APNs (`.p8`) de l'équipe `LD4W7KA5YG` est la même que celle de Prepaxia : une clé
   APNs sert à toutes les apps de l'équipe. Sinon : https://developer.apple.com/account/resources/authkeys/list
   → **+** → cocher **Apple Push Notifications service (APNs)** → télécharger (une seule fois).
2. https://console.firebase.google.com/project/flora-hair-app/settings/cloudmessaging → app iOS
   `com.florahair.floraHairMobile` → **APNs Authentication Key** → **Upload** : le `.p8`, son
   **Key ID** et le Team ID `LD4W7KA5YG`.

## Lancer les builds

Depuis la racine du dépôt mobile :

```bash
git push origin main:flora-hair/ios-build-check
```

Compile l'app iOS **sans** signature (étapes 4 seulement nécessaires). À faire d'abord.

```bash
git push origin main:flora-hair/testflight
```

Build signé, envoyé à TestFlight (étapes 1 à 5). Sans push : Codemagic → **Start new build** →
branche `flora-hair/testflight` → workflow **Flora Hair · iOS TestFlight**.

Durée : 25 à 40 min. Ensuite, dans App Store Connect → TestFlight : le build passe de
**Processing** à **Ready to Test** (10 à 30 min) → **Internal Testing** → ajouter le build au
groupe → application **TestFlight** sur l'iPhone.

## Si le build échoue

| Message | Cause | Que faire |
|---|---|---|
| `FLORA_GOOGLE_SERVICE_INFO_PLIST absente` | étape 4 non faite | faire 4.3 et 4.4 |
| `Aucune app App Store Connect pour com.florahair.floraHairMobile` | étape 2 non faite | créer la fiche |
| `No matching profiles found for bundle identifier` | profil absent ou sans le certificat | refaire l'étape 3 |
| `Integration "Prepaxia ASC" not found` | application Codemagic dans une autre équipe | l'ajouter dans l'équipe qui a la clé |
| Aucun workflow proposé | branche sans `codemagic.yaml` | pousser `main` sur la branche |
| CocoaPods | dépôt de pods momentanément indisponible | relancer |

Journaux complets : build Codemagic → **Artifacts** → `xcodebuild_logs`.

## À vérifier sur l'iPhone

- Accueil, catalogue, réservation jusqu'au choix du paiement.
- Paiement : Wave et la carte s'ouvrent dans Safari ; Orange et MTN restent dans l'app.
- Devis : l'appareil photo et la galerie demandent l'autorisation, avec le texte du salon.
- Notifications : réserver, fermer l'app, confirmer le rendez-vous dans l'administration.

## Avant la revue App Store (plus tard)

Captures d'écran, description, politique de confidentialité (le site en a une), questionnaire
« Confidentialité de l'app » cohérent avec `ios/Runner/PrivacyInfo.xcprivacy`, compte de démo
inutile (pas de connexion). Les paiements sont pour des services réalisés au salon : ils
n'entrent pas dans l'achat intégré d'Apple.
