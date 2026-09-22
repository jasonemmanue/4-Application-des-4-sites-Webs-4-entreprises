import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  for (final path in <String>[
    'assets/branding/app_icon_fg.png',
    'assets/branding/notification_icon.png',
  ]) {
    final im = img.decodePng(File(path).readAsBytesSync())!;
    int opaque = 0, transparent = 0, partial = 0;
    for (int y = 0; y < im.height; y++) {
      for (int x = 0; x < im.width; x++) {
        final a = im.getPixel(x, y).a.toInt();
        if (a == 0) {
          transparent++;
        } else if (a == 255) {
          opaque++;
        } else {
          partial++;
        }
      }
    }
    stdout.writeln('$path : opaque=$opaque transparent=$transparent partial=$partial');
  }
}
