// Copie assets/branding/notification_icon.png dans les differents
// dossiers drawable-* en le redimensionnant a la bonne taille pour
// chaque densite Android.
//
// Nom de sortie : ic_stat_notification.png
// A referencer dans AndroidManifest.xml :
//   <meta-data
//     android:name="com.google.firebase.messaging.default_notification_icon"
//     android:resource="@drawable/ic_stat_notification" />
//
// Usage : dart run tool/install_notification_icon.dart
import 'dart:io';
import 'package:image/image.dart' as img;

const String src = 'assets/branding/notification_icon.png';
const Map<String, int> densities = <String, int>{
  'drawable-mdpi': 24,
  'drawable-hdpi': 36,
  'drawable-xhdpi': 48,
  'drawable-xxhdpi': 72,
  'drawable-xxxhdpi': 96,
};

void main() {
  final base = img.decodePng(File(src).readAsBytesSync());
  if (base == null) {
    stderr.writeln('Impossible de decoder $src');
    exit(1);
  }
  const androidRes = 'android/app/src/main/res';
  densities.forEach((folder, size) {
    final dir = Directory('$androidRes/$folder');
    dir.createSync(recursive: true);
    final resized = img.copyResize(base, width: size, height: size);
    final outPath = '${dir.path}/ic_stat_notification.png';
    File(outPath).writeAsBytesSync(img.encodePng(resized));
    stdout.writeln('OK $outPath (${size}px)');
  });
}
