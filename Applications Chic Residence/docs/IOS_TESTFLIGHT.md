# iOS : les 3 apps Chic Résidence sur TestFlight par Codemagic

Le build iOS se fait **chez Codemagic** (Mac dans le cloud) puis part tout seul
dans App Store Connect → TestFlight. Rien ne se compile sous Windows. Modèle :
Prepaxia (`Prepaxia Mobile/codemagic.yaml` et `PROCEDURE_BUILD_TESTFLIGHT.md`),
qui passe TestFlight.

| App | Bundle iOS | Nom sous l'icône | App Firebase iOS |
|---|---|---|---|
| Client | `com.chicresidence.chicResidenceMobile` | Chic Résidence | `1:1053030542423:ios:c81347b239be8376630712` |
| Gestionnaire | `com.chicresidence.chicResidenceGestionnaire` | Chic Gestion | `1:1053030542423:ios:242b924f6f2abd1f630712` |
| Backoffice | `com.chicresidence.chicResidenceBackoffice` | Chic Admin | `1:1053030542423:ios:fe96c22f09a50704630712` |

Équipe Apple : celle de Prepaxia (**LD4W7KA5YG**), dont la clé d'équipe
**`Prepaxia ASC`** est déjà déclarée dans Codemagic et sert aussi à Eslie, Ruah
et Flora. Si Chic Résidence doit être publiée sous **son propre** compte Apple,
déclarer sa clé dans Codemagic et remplacer `Prepaxia ASC` dans ses trois
workflows.

## Ce qui est déjà fait dans le code (2026-11-03)

- `codemagic.yaml` (racine du dépôt) : 4 workflows Chic, à la suite de ceux
  des autres apps.
- Les 3 projets iOS : `Podfile` (iOS 15, réglages Prepaxia), cible iOS 15.0,
  capacité push (`Runner.entitlements` en développement,
  `RunnerRelease.entitlements` en production), `ITSAppUsesNonExemptEncryption
  = false` (pas de « Missing Compliance »), `remote-notification`, textes
  d'autorisation caméra et photos (gestionnaire, backoffice), schéma
  `chicresidence://` pour revenir dans l'app après un paiement (client).
- Firebase : les 3 apps iOS sont **créées** dans le projet
  `chic-residence-meuble`. Leurs identifiants sont passés au build par
  `--dart-define` : aucun `GoogleService-Info.plist` dans le dépôt, comme pour
  `google-services.json`. Fichiers et valeurs rangés dans
  `E:\INFORMATIONS CONFIDENTIELLE CHIC RESIDENCE MEUBLEE\firebase ios\`.
- Paiement : la page de retour de l'API renvoie dans l'app aussi sur iPhone.
  Une réservation de logement se règle hors achat intégré : c'est un service
  consommé hors de l'application (règle App Store 3.1.3), contrairement aux
  contenus numériques de Prepaxia.

## Ce qu'il reste à faire, une seule fois (30 à 45 min)

### 1. App IDs (developer.apple.com)
https://developer.apple.com/account/resources/identifiers/list → **+** →
App IDs → App → pour chacun des 3 bundles ci-dessus : description
(« Chic Résidence Client »…), Bundle ID **Explicit**, cocher **Push
Notifications** → Register.

### 2. Apps dans App Store Connect
https://appstoreconnect.apple.com/apps → **+** → Nouvelle app, trois fois :
plateforme iOS, nom (« Chic Résidence », « Chic Résidence Gestion »,
« Chic Résidence Admin » : le nom doit être unique sur l'App Store), langue
Français, bundle de l'étape 1, SKU libre (`chic-client`, `chic-gestion`,
`chic-admin`), accès complet.

### 3. Profils App Store
https://developer.apple.com/account/resources/profiles/add → Distribution →
**App Store Connect** → App ID → le certificat **Apple Distribution** déjà
utilisé par Codemagic pour Prepaxia → nom `chic_client_app_store` (puis
`chic_gestion_app_store`, `chic_admin_app_store`) → Generate.
Puis Codemagic → Teams → codemagic.yaml settings → Code signing identities →
**iOS provisioning profiles** → **Fetch profiles** (clé `Prepaxia ASC`) →
cocher les 3 profils → Download selected. Coche verte = le profil contient
bien le certificat ; croix rouge = refaire avec le bon certificat.

### 4. Variables Firebase dans Codemagic
Codemagic → Teams → **Global variables and secrets** → groupe
**`chic_residence_firebase`** → ajouter les 4 variables du fichier
`codemagic_variables.txt` (dossier `firebase ios` sur `E:`), en **Secret** :
`FIREBASE_IOS_API_KEY`, `FIREBASE_IOS_APP_ID_CLIENT`,
`FIREBASE_IOS_APP_ID_GESTIONNAIRE`, `FIREBASE_IOS_APP_ID_BACKOFFICE`.
⚠️ Le groupe doit exister, même vide : un groupe absent fait échouer le build.

### 5. Clé APNs dans Firebase (notifications iOS)
https://developer.apple.com/account/resources/authkeys/list : la clé APNs
(.p8) de Prepaxia convient (une clé APNs sert toute l'équipe). Console
Firebase → projet `chic-residence-meuble` → Paramètres → **Cloud Messaging** →
chacune des 3 apps iOS → **Clé d'authentification APNs** → téléverser le .p8,
Key ID et Team ID `LD4W7KA5YG`. Sans elle, aucune notification n'arrive sur
iPhone (le reste de l'app fonctionne).

## Lancer les builds

Depuis la racine du dépôt :

```bash
git push origin main:chic/ios-build-check
```

compile les 3 apps **sans signature**, sans compte Apple : à faire d'abord.

```bash
git push origin main:chic-client/ios-testflight
git push origin main:chic-gestion/ios-testflight
git push origin main:chic-admin/ios-testflight
```

envoie chaque app sur TestFlight (25 à 40 min chacune). Sans push : Codemagic →
l'application → **Start new build** → choisir la branche et le workflow.

Numéro de build : dernier build TestFlight + 1 (lu chez Apple à chaque build).
Version : la ligne `version:` de chaque `pubspec.yaml`.

## Dans App Store Connect, puis sur l'iPhone

1. L'app → **TestFlight** : le build passe de *Processing* à *Ready to Test*
   (10 à 30 min).
2. **Internal Testing** → groupe de testeurs → ajouter le build. Pas de revue
   Apple pour les testeurs internes (`submit_to_testflight: false`).
3. Sur l'iPhone : app **TestFlight**, même identifiant Apple → Installer.

À vérifier : connexion (backoffice : email + mot de passe du web ;
gestionnaire : téléphone + PIN), notifications, appareil photo (fiche voyageur,
photos de tâche), paiement par carte et retour dans l'app.

## Si le build échoue

| Étape | Cause habituelle | Que faire |
|---|---|---|
| Démarrage : groupe introuvable | `chic_residence_firebase` absent | étape 4 |
| CocoaPods | dépôt de pods indisponible | relancer |
| Profils de signature : *No matching profiles* | profil absent ou sans le certificat | étape 3 |
| Build IPA : *Aucune app App Store Connect* | app non créée | étape 2 |
| Publication : *build number already used* | deux builds lancés trop vite | relancer |
| Push absent sur iPhone | clé APNs non téléversée | étape 5 |

Journaux complets : onglet Artifacts du build (`xcodebuild_logs`).
