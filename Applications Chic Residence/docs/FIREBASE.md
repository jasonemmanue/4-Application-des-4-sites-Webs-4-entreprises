# Firebase / FCM — Guide de configuration des 3 apps mobiles

Ce guide couvre tout ce qui doit être fait côté Firebase Console, côté code,
et côté keystores pour que les notifications push et la publication Play
Store fonctionnent.

**Rappel** — seule l'**application client Mobile** est destinée au Play
Store. Les 2 autres apps (gestionnaire, backoffice) sont installées
manuellement en APK release ou debug.

---

## 1. Noms de package (applicationId)

| App | Package Android | Rôle |
|---|---|---|
| Application client Mobile | `com.chicresidence.chic_residence_mobile` | Play Store — voyageurs |
| Application gestionnaire Mobile | `com.chicresidence.chic_residence_gestionnaire` | APK — personnel terrain |
| Application Backoffice Mobile | `com.chicresidence.chic_residence_backoffice` | APK — admin |

Ces trois packages sont **déjà configurés** dans les `build.gradle.kts` et
`AndroidManifest.xml` respectifs. Ne pas les modifier après la première
publication : le Play Store bloque tout changement, et un projet Firebase
lie ses paramètres au package name.

---

## 2. Empreintes SHA (fingerprints)

### 2.1 Debug — partagé par les 3 apps

Le keystore de debug Android est unique par machine (`~/.android/debug.keystore`).
Toutes les apps compilées en `flutter run` (sans `--release`) le partagent.

```
SHA-1   : 7D:9E:C4:3C:20:1E:F3:77:98:7D:18:1B:9D:B2:14:AE:95:71:DF:54
SHA-256 : F6:CA:32:85:A2:7A:AF:B1:EC:84:19:10:2E:E5:27:E8:E1:39:B3:B9:95:93:AC:BA:4B:DB:E1:B3:AF:6F:11:B8
```

À ajouter dans Firebase Console → Paramètres du projet → onglet **Général**
→ sur chaque appli Android → **Ajouter une empreinte**.

⚠️ **Chaque machine de dev a son propre debug keystore.** Si tu compiles
depuis un autre PC, il faudra y régénérer les empreintes et les ajouter.

Pour retrouver ces empreintes plus tard :

```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android | grep -E "SHA"
```

### 2.2 Release — keystore unique pour les 3 apps

Keystore de signature *release* utilisé par les 3 apps (le même fichier
signe les 3 packages différents). Généré le 2026-09-19 :

- **Fichier** : `E:/applications ainé williams/chic-residence-release.jks`
- **Alias** : `sakamemmanuel`
- **Store password / Key password** : `Argentemmanu`
- **DN** : `CN=sakamemmanuel, EMAILADDRESS=sakamemmanuel@gmail.com, O=Chic Residence, L=Abidjan, ST=Abidjan, C=CI`
- **Validité** : 10 000 jours (jusqu'au 2054-02-04)
- **Doc de sauvegarde** : `E:/applications ainé williams/chic-residence-release-INFOS.md`

```
SHA-1   : 4E:4A:78:AA:40:C4:B8:B6:29:6F:46:CE:36:4F:8C:49:FD:A7:20:27
SHA-256 : B2:DF:BB:32:83:11:8B:53:4B:D5:FA:5D:A3:D0:51:81:79:17:95:6C:09:4D:A6:0E:AC:3B:DF:90:EC:17:BD:0D
```

⚠️ **SAUVEGARDER LE FICHIER `.jks` HORS DE LA MACHINE.** Perdre ce keystore
signifie qu'aucune nouvelle version ne pourra plus jamais mettre à jour
l'app existante sur Play Store.

Recommandations :
- Copie du `.jks` sur clé USB chiffrée + Google Drive privé
- Mots de passe conservés dans un gestionnaire (Bitwarden, 1Password)
- Le document `chic-residence-release-INFOS.md` accompagne le `.jks`

### 2.3 App Signing by Google Play — la clé finale

Le Play Store signe *lui-même* l'APK distribué aux utilisateurs, avec sa
propre clé. Ton keystore ci-dessus n'est que la clé *upload* : elle prouve
que c'est bien toi qui téléverses.

**Après le premier upload** dans la Play Console → App signing, Google
affiche un « **App signing key certificate** » avec ses propres SHA-1 /
SHA-256. **Ajouter ces deux empreintes-là aussi** dans Firebase Console —
sans elles, les APK distribués par Google ne pourront pas utiliser FCM /
Auth Firebase.

---

## 3. Firebase Console — étapes exactes

Ouvrir https://console.firebase.google.com/ avec le compte
`sakamemmanuel@gmail.com` (ou un compte Google dédié à l'entreprise).

### 3.1 Créer le projet

1. **Ajouter un projet** → nom : `Chic Residence`
2. Analytics : au choix (recommandé oui)
3. Compte Analytics : par défaut

### 3.2 Ajouter les 3 apps Android

Pour **chacun des 3 packages** listés au § 1, cliquer sur l'icône Android
et suivre l'assistant :

1. **Nom du package Android** → un des 3 (voir tableau § 1)
2. **Surnom** (facultatif) → `Client`, `Gestionnaire`, `Backoffice`
3. **SHA-1 du certificat** → colle celui du debug (§ 2.1)
4. **Enregistrer**
5. **Télécharger `google-services.json`** — un fichier différent par app
6. **Passer les étapes 3 et 4** (« Ajouter le SDK ») — tout est déjà dans
   `pubspec.yaml` et `build.gradle.kts`

### 3.3 Placer les fichiers

Chaque `google-services.json` téléchargé va dans le dossier `android/app/`
de son app :

```
Application client Mobile/android/app/google-services.json
Application gestionnaire Mobile/android/app/google-services.json
Application Backoffice Mobile(Gestionnaire visualisation)/android/app/google-services.json
```

Les 3 fichiers sont ignorés par git (voir `.gitignore` mis à jour le
2026-09-19).

### 3.4 Ajouter les SHA release après le 1er build

- App cliente : ajouter le SHA-1 upload (§ 2.2) sur l'app cliente Firebase.
- Après premier upload Play Store : ajouter les SHA-1 et SHA-256 de la
  *App signing key* Google (§ 2.3).
- Apps gestionnaire et backoffice : elles ne passent pas par Play Store,
  donc leur SHA release doit être celui du keystore local qui les signera.
  Génère-en un ou utilise le même que le client (moins recommandé).

---

## 4. Icônes de notification transparentes

**Bonne nouvelle** — les fichiers `ic_notification.png` sont **déjà en
place** dans les 5 densités pour chacune des 3 apps, sous
`android/app/src/main/res/drawable-*dpi/ic_notification.png`, et déjà
référencés dans les `AndroidManifest.xml` via :

```xml
<meta-data
    android:name="com.google.firebase.messaging.default_notification_icon"
    android:resource="@drawable/ic_notification" />
<meta-data
    android:name="com.google.firebase.messaging.default_notification_color"
    android:resource="@color/notification_color" />
```

### 4.1 Contraintes Android à respecter

Depuis Android 5.0 (Lollipop, API 21), l'icône de notification affichée
dans la status bar **doit être blanche pure sur fond transparent** — toute
autre couleur est aplatie en blanc par le système. Si les icônes actuelles
ne le respectent pas, elles apparaissent en carré blanc uniforme.

Tailles attendues (déjà générées, à vérifier si régénération) :

| Densité | Taille (px) |
|---|---|
| mdpi | 24×24 |
| hdpi | 36×36 |
| xhdpi | 48×48 |
| xxhdpi | 72×72 |
| xxxhdpi | 96×96 |

### 4.2 Régénérer les icônes

Deux options :

**A) Android Studio (le plus simple)**
`File → New → Image Asset → Icon Type: Notification Icons`,
choisir un SVG monochrome, Android Studio génère les 5 densités.

**B) Générateur en ligne**
https://romannurik.github.io/AndroidAssetStudio/icons-notification.html —
uploader un SVG, télécharger le ZIP `res/drawable-*` prêt à décompresser.

Le fichier `res/values/colors.xml` contient déjà :

```xml
<color name="notification_color">#DC2626</color>
```

C'est la couleur de teinte appliquée par le système à l'icône blanche
(rouge Chic Residence). Modifiable ici si besoin.

---

## 5. Code Flutter — initialisation FCM

### 5.1 Où — `lib/main.dart`

Ajouter en haut du fichier :

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// Handler qui reçoit les push quand l'app est complètement fermée.
// DOIT être une fonction top-level annotée @pragma('vm:entry-point').
@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Rien de plus — le système d'exploitation affiche la notification
  // à partir du bloc `notification` du payload FCM.
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

  // Permission notifications (Android 13+ / iOS)
  await FirebaseMessaging.instance.requestPermission();

  runApp(const MyApp());
}
```

### 5.2 Récupérer et envoyer le jeton (apps gestionnaire + backoffice)

Après la connexion staff, envoyer le jeton FCM au backend :

```dart
final token = await FirebaseMessaging.instance.getToken();
if (token != null) {
  await dio.put('/staff/me/fcm-token', data: {'fcm_token': token});
}

// Rotation du jeton (arrive parfois — Google peut le régénérer).
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  dio.put('/staff/me/fcm-token', data: {'fcm_token': newToken});
});
```

L'endpoint `PUT /api/v1/staff/me/fcm-token` est déjà déployé sur
`api-production-4e71.up.railway.app` (voir docs/MOBILE_API.md § 5).

### 5.3 Réagir à un tap sur une notification

```dart
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  // Ex: message.data['task_id'] → naviguer vers l'écran détail
  final taskId = message.data['task_id'];
  if (taskId != null) {
    context.go('/tasks/$taskId');
  }
});
```

---

## 6. Play Store — publication de l'app cliente

### 6.1 Créer un compte développeur

Play Console → https://play.google.com/console (25 $ à vie, unique achat).

### 6.2 Construire l'App Bundle release

```bash
cd "Application client Mobile"
flutter build appbundle --release
```

Le fichier généré : `build/app/outputs/bundle/release/app-release.aab`.
Il est signé avec le keystore upload configuré dans
`android/key.properties` (§ 2.2).

### 6.3 Upload dans la Play Console

1. Créer l'application → nom : `Chic Residence`
2. **Configuration → Intégrité de l'application → Signature d'application
   Play** → accepter que Google gère la clé finale (obligatoire pour les
   nouvelles apps depuis 2021)
3. **Test interne** → uploader l'AAB, ajouter des testeurs
4. Après premier upload, aller dans **Signature d'application** et copier
   le SHA-1 et SHA-256 du **App signing key certificate** → les ajouter
   dans Firebase Console sur l'app cliente

### 6.4 Fiche Play Store — éléments requis

- Icône 512×512 PNG
- Bandeau feature graphic 1024×500 PNG
- 2 captures d'écran minimum, format téléphone
- Description courte (80 caractères max) et longue
- Politique de confidentialité (URL — obligatoire)
- Coordonnées de contact
- Classification du contenu (questionnaire)

---

## 7. APK release pour gestionnaire et backoffice

Pas de Play Store — installation directe. Pour signer proprement :

```bash
cd "Application gestionnaire Mobile"
flutter build apk --release
```

Le keystore de release peut être :
- Le même que le client (§ 2.2), pratique mais couple les 3 apps
- Un keystore dédié — plus propre, généré à part

Pour générer un keystore dédié à une app :

```bash
keytool -genkey -v \
  -keystore C:/Users/hp/keystores/chic-residence-gestionnaire.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias chic-residence-gestionnaire \
  -dname "CN=CHIC RESIDENCE Gestionnaire, O=Chic Residence, C=CI"
```

Puis créer un `android/key.properties` dans cette app (comme celui du
client), et configurer `signingConfigs.release` dans son
`build.gradle.kts`.

APK signé : `build/app/outputs/flutter-apk/app-release.apk`. À distribuer
via un lien direct, Google Drive, ou une plateforme MDM.

---

## 8. Envoi de test depuis Firebase Console

1. Firebase Console → **Messaging** → **Nouvelle campagne** → **Notifications**
2. Titre : « Test push »
3. Corps : « Ça marche 🎉 »
4. **Envoyer un message de test** → coller le jeton FCM de l'appareil
5. L'appareil doit afficher la notification en quelques secondes

Le jeton FCM peut être récupéré via `print(await FirebaseMessaging.instance.getToken())`
au premier lancement.

---

## 9. Backend — envoi de push (à ajouter)

Non déployé pour l'instant. Le champ `fcm_token` de la table
`staff_users` est déjà rempli à chaque connexion staff. Pour envoyer :

1. Ajouter au backend `firebase-admin` (Python) : `pip install firebase-admin`
2. Placer une clé de service Firebase (`service-account.json`) dans un
   secret Railway
3. Écrire un `services/fcm_service.py` qui charge `firebase_admin.credentials`
   et envoie via `messaging.send()`
4. Appeler ce service aux transitions de tâche
   (`cleaning_task_service.py`) — après création, après passage en
   `cleaned` (pour le contrôleur), après rejet (pour l'agent)

Un chantier séparé — priorité basse, l'app fonctionne sans push.

---

## 10. Checklist finale

Avant première distribution :

- [ ] Projet Firebase créé
- [ ] 3 apps Android enregistrées avec les bons packages
- [ ] SHA-1 debug ajouté sur les 3 apps
- [ ] SHA-1 release ajouté sur l'app cliente
- [ ] 3 `google-services.json` téléchargés et placés dans `android/app/`
- [ ] `flutter clean && flutter build apk --debug` réussit sur les 3 apps
- [ ] Le jeton FCM est reçu et loggé au premier lancement
- [ ] Notification de test reçue depuis Firebase Console
- [ ] Icône de notification affichée blanche (pas un carré uniforme)
- [ ] Keystore upload de l'app cliente sauvegardé HORS de la machine
- [ ] `key.properties` NON versionné (vérifié via `git status`)
- [ ] Sur Play Store : AAB signé uploadé, App signing key activé, SHA
      de la clé Play copiés dans Firebase
