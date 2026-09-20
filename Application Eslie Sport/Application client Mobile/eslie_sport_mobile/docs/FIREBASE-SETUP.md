# Configuration Firebase — Eslie Sport Mobile

Ce document liste **tout ce qu'il reste a faire** pour activer Firebase Cloud
Messaging (notifications push) sur l'application. Le code Flutter et la
configuration Gradle sont **deja pretes** ; il ne manque que l'enregistrement
Firebase et le fichier `google-services.json`.

---

## 1. Identifiants a fournir a la console Firebase

| Champ | Valeur |
|-------|--------|
| **Package Android (applicationId)** | `com.esliesport.eslie_sport_mobile` |
| **Nom de l'app** (libre, affiche dans la console) | `Eslie Sport Mobile` |
| **SHA-1 du keystore de debug** | `7D:9E:C4:3C:20:1E:F3:77:98:7D:18:1B:9D:B2:14:AE:95:71:DF:54` |
| **SHA-256 du keystore de debug** | `F6:CA:32:85:A2:7A:AF:B1:EC:84:19:10:2E:E5:27:E8:E1:39:B3:B9:95:93:AC:BA:4B:DB:E1:B3:AF:6F:11:B8` |
| **SHA-1 du keystore de release** | _a generer lors de la creation du keystore de prod (voir §5)_ |

**Comment regenerer ces empreintes** (si tu changes de machine) :

```bash
# SHA-1 et SHA-256 du keystore debug (Windows Git Bash / macOS / Linux)
keytool -list -v -keystore "$HOME/.android/debug.keystore" \
        -alias androiddebugkey -storepass android -keypass android
```

Sous PowerShell pure :

```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" `
        -alias androiddebugkey -storepass android -keypass android
```

Les empreintes apparaissent sous la section `Empreintes du certificat` / `Certificate fingerprints`.

---

## 2. Etapes cote console Firebase

1. Va sur https://console.firebase.google.com/ et cree un projet
   (ou reutilise-en un existant) : **"Eslie Sport"**.
2. Dans le projet, clique **Add app** → icone Android.
3. Renseigne :
   - **Android package name** : `com.esliesport.eslie_sport_mobile`
   - **App nickname** : `Eslie Sport Mobile`
   - **Debug signing certificate SHA-1** : colle la SHA-1 ci-dessus.
4. Clique **Register app**.
5. **Telecharge `google-services.json`**.
6. Place le fichier dans :

   ```
   eslie_sport_mobile/android/app/google-services.json
   ```

   Ce chemin est **git-ignore** (voir `.gitignore`) : le fichier ne doit pas
   etre committe (il contient l'`api_key` Android specifique au projet).

7. Passe les etapes 4 et 5 du wizard Firebase (le code Gradle est deja en
   place — voir §4).
8. Dans **Project settings → Cloud Messaging**, active l'API Cloud Messaging
   si elle ne l'est pas encore.

---

## 3. Icone des notifications (transparente)

Android exige, depuis Lollipop (API 21), une icone de notification
**monochrome, blanche, sur fond transparent**. Les icones actuelles suivent
deja cette regle et sont deposees dans :

```
android/app/src/main/res/
  drawable-mdpi/ic_notification.png    24x24 px
  drawable-hdpi/ic_notification.png    36x36 px
  drawable-xhdpi/ic_notification.png   48x48 px
  drawable-xxhdpi/ic_notification.png  72x72 px
  drawable-xxxhdpi/ic_notification.png 96x96 px
```

La couleur d'accent (or #FFD600) est definie dans
`android/app/src/main/res/values/colors.xml` :

```xml
<color name="notification_color">#FFD600</color>
```

Et referencee dans `AndroidManifest.xml` :

```xml
<meta-data android:name="com.google.firebase.messaging.default_notification_icon"
           android:resource="@drawable/ic_notification"/>
<meta-data android:name="com.google.firebase.messaging.default_notification_color"
           android:resource="@color/notification_color"/>
```

**Regenerer les icones a partir d'une source PNG** :

Le plus simple est d'utiliser https://romannurik.github.io/AndroidAssetStudio/icons-notification.html :

1. Charge le logo (SVG ou PNG de bonne resolution, sans fond).
2. Coche `Trim` et laisse `Padding` a 0-4 %.
3. Le generateur exporte un ZIP avec les 5 densites nommees `ic_stat_*`.
4. Renomme-les en `ic_notification.png` et depose-les dans les dossiers
   `drawable-*dpi/` correspondants (ecrase les fichiers existants).

Alternative en ligne de commande avec **ImageMagick** (`magick`) depuis
un `logo.png` **deja blanc sur fond transparent** :

```bash
cd android/app/src/main/res
for pair in "mdpi:24" "hdpi:36" "xhdpi:48" "xxhdpi:72" "xxxhdpi:96"; do
  dpi=${pair%:*}
  size=${pair##*:}
  magick logo.png -resize ${size}x${size} drawable-$dpi/ic_notification.png
done
```

---

## 4. Ce qui est deja en place cote code

Ces modifications ont deja ete faites — tu n'as rien a toucher a moins de
vouloir changer le comportement :

### `android/settings.gradle.kts`
```kotlin
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.11.1" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.gms.google-services") version "4.4.2" apply false
}
```

### `android/app/build.gradle.kts`
Le plugin Google Services est applique **seulement si**
`google-services.json` est present :

```kotlin
if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}
```

Cela veut dire :
- Sans le fichier : l'app compile normalement, FCM ne s'initialise pas
  (`PushNotificationService.initialize()` echoue proprement, `_fcmToken` reste `null`).
- Avec le fichier : le plugin genere les ressources Firebase et FCM demarre.

### `pubspec.yaml`
```yaml
firebase_core: ^3.0.0
firebase_messaging: ^15.0.0
```

### `lib/services/push_notification_service.dart`
Init defensive :
- Appelle `Firebase.initializeApp()` sans arguments (lit `google-services.json`).
- Demande la permission notifications a l'utilisateur.
- Recupere le token FCM.
- Expose `onForegroundMessage()` pour les notifications recues app ouverte.

### `AndroidManifest.xml`
- Permission `POST_NOTIFICATIONS` deja declaree (obligatoire Android 13+).
- Icone et couleur par defaut deja pointees vers `ic_notification` et
  `notification_color`.

---

## 5. Keystore de release (a faire avant Play Store)

Le build debug utilise un keystore auto-genere. Pour publier sur le Play Store,
il faut un keystore signe :

```bash
# Depuis eslie_sport_mobile/android/
keytool -genkey -v -keystore ~/eslie-sport-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias eslie-sport
```

Recupere ensuite la SHA-1 et SHA-256 du keystore genere :

```bash
keytool -list -v -keystore ~/eslie-sport-release.jks -alias eslie-sport
```

**Ajoute les deux SHA (debug ET release) dans les parametres du projet Firebase**
(Project settings → General → Your apps → SHA certificate fingerprints).
Sinon la premiere authentification Google (si utilisee un jour) echouera en
release.

Cree ensuite `android/key.properties` (git-ignore) :

```
storePassword=<mot de passe>
keyPassword=<mot de passe>
keyAlias=eslie-sport
storeFile=C:/Users/<toi>/eslie-sport-release.jks
```

Et remplace dans `android/app/build.gradle.kts` le `signingConfig` par un
signingConfig qui lit ce fichier.

---

## 6. Envoi d'une notification de test

Une fois `google-services.json` en place et l'app lancee au moins une fois
sur ton telephone :

1. **Recupere le token FCM** dans les logs (`flutter run` en mode debug affiche
   `[Push] token=…`).
2. Dans la console Firebase → **Messaging** → **Nouvelle campagne** →
   **Notifications**.
3. Renseigne un titre + un message, puis dans **Cibler** choisis
   **Un seul appareil** et colle le token.
4. Envoie. Le telephone recoit la notification meme app fermee.

Test rapide via REST (`curl`) — necessite la cle serveur Firebase
(Project settings → Cloud Messaging → Server key) :

```bash
curl -X POST https://fcm.googleapis.com/fcm/send \
  -H "Authorization: key=<SERVER_KEY>" \
  -H "Content-Type: application/json" \
  -d '{
    "to": "<FCM_TOKEN>",
    "notification": {
      "title": "Bienvenue chez Eslie Sport",
      "body": "Ta reservation est confirmee !"
    }
  }'
```

---

## 7. Envoi depuis le backend FastAPI (futur)

Le backend n'expose pas encore d'endpoint pour :
- enregistrer un token FCM (`POST /devices` ou similaire)
- pousser une notification a un membre (`POST /notifications/{enrollment_id}`)

Quand ces endpoints seront ajoutes, l'app appellera `registerToken()` apres
recuperation du token FCM, et le backend enverra les rappels de seance via
`firebase-admin` cote Python.

---

## Recapitulatif — actions concretes a faire

- [ ] Creer le projet Firebase.
- [ ] Ajouter l'app Android avec le package `com.esliesport.eslie_sport_mobile`.
- [ ] Coller la SHA-1 debug (`7D:9E:C4:3C:20:1E:F3:77:98:7D:18:1B:9D:B2:14:AE:95:71:DF:54`).
- [ ] Telecharger `google-services.json` → le placer dans `android/app/`.
- [ ] `flutter clean && flutter run` pour verifier que Firebase s'initialise
      (le token FCM doit apparaitre dans les logs).
- [ ] Envoyer une notif de test depuis la console Firebase.
- [ ] Plus tard : creer le keystore release + ajouter sa SHA au projet Firebase.
