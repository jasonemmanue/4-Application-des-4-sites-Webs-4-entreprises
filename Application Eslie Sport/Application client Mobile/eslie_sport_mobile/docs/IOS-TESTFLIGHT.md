# Eslie Sport — iOS via Codemagic et TestFlight

Calqué sur Prepaxia (`Prepaxia Project/PROCEDURE_BUILD_TESTFLIGHT.md`), qui passe
TestFlight. Rien ne se compile sur le PC Windows : Codemagic construit l'IPA sur un
Mac et l'envoie dans App Store Connect.

| Élément | Valeur |
|---|---|
| Dépôt GitHub | `jasonemmanue/4-Application-des-4-sites-Webs-4-entreprises` |
| Fichier Codemagic | `codemagic.yaml` à la **racine** du dépôt |
| Dossier de l'app | `Application Eslie Sport/Application client Mobile/eslie_sport_mobile` |
| Bundle ID iOS | `com.esliesport.eslieSportMobile` (Android garde `com.esliesport.eslie_sport_mobile` : iOS refuse le `_`) |
| Appareils | iPhone uniquement, portrait, iOS 15 minimum |
| Workflows | `eslie-ios-build-check` (branche `eslie/ios-build-check`), `eslie-ios-testflight` (branche `eslie/ios-testflight`) |
| Clé App Store Connect | `Prepaxia ASC`, celle déjà déclarée dans Codemagic |
| Firebase | projet `eslie-sport-application` |

Le compte Apple Developer est supposé être **le même que Prepaxia** (équipe
`LD4W7KA5YG`) : la clé `Prepaxia ASC` et le certificat Apple Distribution déjà dans
Codemagic servent alors tels quels. Si Eslie Sport doit être publiée sous le compte
Apple de la salle, voir « Autre compte Apple » en bas.

---

## Étape 1 — App ID (developer.apple.com, 3 min)

1. https://developer.apple.com/account/resources/identifiers/list → **+** →
   **App IDs** → **App** → **Continue**.
2. **Description** : `Eslie Sport` ; **Bundle ID** : *Explicit*,
   `com.esliesport.eslieSportMobile`.
3. **Capabilities** : cocher **Push Notifications**. Rien d'autre.
4. **Continue** → **Register**.

⚠️ La case Push doit être cochée **avant** l'étape 2 : l'app déclare
`aps-environment` (`ios/Runner/RunnerRelease.entitlements`) et un profil créé sans
cette capacité fait échouer la signature.

## Étape 2 — Profil App Store (3 min)

1. https://developer.apple.com/account/resources/profiles/add → **Distribution** →
   **App Store Connect** → **Continue**.
2. **App ID** : `com.esliesport.eslieSportMobile` → **Continue**.
3. Cocher le certificat **Apple Distribution** utilisé par Codemagic pour Prepaxia
   (le plus récent) → **Continue**.
4. **Provisioning Profile Name** : `eslie_sport_app_store` → **Generate**. Pas
   besoin de le télécharger.

## Étape 3 — App dans App Store Connect (3 min)

1. https://appstoreconnect.apple.com/apps → **+** → **Nouvelle app**.
2. **Plateforme** : iOS ; **Nom** : `Eslie Sport` (s'il est pris : `Eslie Sport
   Abidjan`) ; **Langue principale** : Français ; **Bundle ID** :
   `com.esliesport.eslieSportMobile` ; **SKU** : `eslie-sport-ios` ; **Accès** :
   Accès complet → **Créer**.

Le workflow retrouve tout seul l'Apple ID de l'app à partir du bundle ID. S'il
n'y arrive pas, ajouter dans Codemagic la variable `APP_STORE_APPLE_ID` = le numéro
affiché dans App Store Connect › Informations sur l'app › Identifiant Apple.

## Étape 4 — Codemagic (5 min)

1. **Accès au dépôt** : GitHub → Settings → Applications → Installed GitHub Apps →
   **Codemagic** → **Configure** → *Only select repositories* → ajouter
   `4-Application-des-4-sites-Webs-4-entreprises` → **Save**.
2. https://codemagic.io/apps → **Add application** → GitHub → ce dépôt →
   **Flutter App (via codemagic.yaml)** → **Finish**. Codemagic lit le
   `codemagic.yaml` de la racine.
3. Dans la **même équipe** Codemagic que Prepaxia : **Code signing identities** →
   onglet **iOS provisioning profiles** → **Fetch profiles** (clé `Prepaxia ASC`) →
   cocher `eslie_sport_app_store` (bundle `com.esliesport.eslieSportMobile`, type
   App Store) → **Download selected**. Le profil doit afficher son certificat avec
   une coche verte.

## Étape 5 — Premier build, sans Apple (contrôle de compilation)

Depuis la racine du dépôt :

```bash
git push origin main:eslie/ios-build-check
```

Ou Codemagic → l'app → **Start new build** → branche `eslie/ios-build-check` →
workflow **Eslie Sport · iOS build check**. Environ 15 à 25 min. Il valide
dépendances, analyse, tests, CocoaPods et compilation iOS. Ne passer à l'étape 6
qu'une fois ce build vert.

## Étape 6 — Build TestFlight

```bash
git push origin main:eslie/ios-testflight
```

Ou **Start new build** → branche `eslie/ios-testflight` → **Eslie Sport · iOS
TestFlight**. Environ 25 à 40 min. Le numéro de build est le dernier de TestFlight
+ 1, la version vient de `pubspec.yaml` (`1.2.0`).

## Étape 7 — Tester sur l'iPhone

1. App Store Connect → l'app → **TestFlight** : le build passe de *Processing*
   (10 à 30 min) à *Ready to Test*. « Missing Compliance » n'apparaît pas : le
   chiffrement est déclaré dans `Info.plist`.
2. **Internal Testing** → créer un groupe `Équipe` → ajouter ton adresse Apple →
   **+** à côté de Builds → cocher le build. Pas de revue Apple pour les testeurs
   internes.
3. Sur l'iPhone : app **TestFlight** → **Eslie Sport** → **Installer**.
4. À vérifier : accueil et logo, planning et places restantes, réservation
   jusqu'au choix du paiement, ouverture de Wave / carte dans Safari, WhatsApp,
   bandeau hors connexion (mode avion).

---

## Push iOS (facultatif, après le premier TestFlight)

Sans cette partie, l'app iOS marche normalement, sans notifications.

1. **Clé APNs** : https://developer.apple.com/account/resources/authkeys/list →
   **+** → nom `Eslie APNs`, cocher **Apple Push Notifications service (APNs)** →
   **Continue** → **Register** → **Download** (`.p8`, une seule fois) ; noter le
   **Key ID**. Si la clé APNs de Prepaxia existe déjà, elle vaut pour toute
   l'équipe : la réutiliser.
2. **Firebase** → projet `eslie-sport-application` → Paramètres → **Ajouter une
   app** → iOS → bundle `com.esliesport.eslieSportMobile` → télécharger
   `GoogleService-Info.plist` (ne pas le commiter).
3. Firebase → Paramètres → **Cloud Messaging** → app iOS → **Clé
   d'authentification APNs** → téléverser le `.p8`, Key ID, Team ID `LD4W7KA5YG`.
4. Codemagic → l'app → **Environment variables** → groupe `eslie_firebase` :
   - `FIREBASE_IOS_API_KEY` = valeur `API_KEY` du plist ;
   - `FIREBASE_IOS_APP_ID` = valeur `GOOGLE_APP_ID` du plist.
5. Dans `codemagic.yaml`, retirer les `#` devant `groups:` et `- eslie_firebase`
   (workflow `eslie-ios-testflight`), pousser, relancer l'étape 6.

L'app lit ces valeurs au build (`lib/config/firebase_ios_options.dart`) : aucun
fichier Firebase n'est nécessaire dans le dépôt.

## Autre compte Apple

Si l'app doit être publiée sous le compte Apple de la salle (et non celui de
Prepaxia) :

1. Dans ce compte, App Store Connect → Utilisateurs et accès → **Intégrations** →
   **+** → nom `Codemagic`, accès **App Manager** → télécharger le `.p8`, noter Issuer
   ID et Key ID.
2. Codemagic → Teams → Integrations → Developer Portal → **Add key** → nom
   `Eslie ASC`.
3. Code signing identities → **Generate certificate** (Apple Distribution, clé
   `Eslie ASC`), puis les étapes 1 à 4 dans ce compte.
4. `codemagic.yaml` : remplacer `app_store_connect: Prepaxia ASC` par
   `app_store_connect: Eslie ASC`.

## Si le build échoue

| Étape en rouge | Cause | Que faire |
|---|---|---|
| Aucun workflow proposé | branche sans `codemagic.yaml` | choisir `eslie/ios-build-check` ou `eslie/ios-testflight` |
| `Integration "Prepaxia ASC" not found` | app ajoutée dans une autre équipe Codemagic | l'ajouter dans l'équipe qui porte la clé |
| `No matching profiles found for bundle identifier` | profil absent ou pas récupéré | étapes 2 et 4.3 |
| Signature : profil sans `aps-environment` | Push non coché sur l'App ID | étape 1.3, puis **Edit** → **Save** du profil, puis 4.3 |
| « Aucune app App Store Connect pour … » | app pas créée, ou recherche impossible | étape 3, ou variable `APP_STORE_APPLE_ID` |
| CocoaPods | dépôt de pods momentanément indisponible | relancer |
| `build number already used` | deux builds trop rapprochés | relancer |

Journaux complets : build Codemagic → **Artifacts** → `xcodebuild_logs`.

## Avant la revue App Store

- Captures iPhone 6,7 pouces (et 6,5) ; icône 1024 déjà sans transparence.
- Politique de confidentialité (URL) et « Confidentialité de l'app » : nom et
  numéro WhatsApp collectés pour la réservation.
- Paiement : il règle des séances en salle, donc des **services physiques**.
  Apple autorise alors un paiement hors achats intégrés (règle 3.1.3(e)). Le
  préciser dans les notes pour le relecteur.
