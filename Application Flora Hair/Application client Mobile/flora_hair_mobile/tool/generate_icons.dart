// Script standalone : genere les PNG a partir de assets/branding/logo.jpg
//   - assets/branding/app_icon.png      : 1024x1024 opaque (launcher)
//   - assets/branding/app_icon_fg.png   : 1024x1024 foreground transparent
//                                         (fond creme retire, garde le dore)
//   - assets/branding/notification_icon.png : 512x512 silhouette blanche
//                                         sur fond transparent (Android FCM)
//
// Usage : dart run tool/generate_icons.dart
import 'dart:io';
import 'package:image/image.dart' as img;

const String src = 'assets/branding/logo.jpg';
const String outLauncher = 'assets/branding/app_icon.png';
const String outForeground = 'assets/branding/app_icon_fg.png';
const String outNotif = 'assets/branding/notification_icon.png';

void main() {
  final bytes = File(src).readAsBytesSync();
  final orig = img.decodeImage(bytes);
  if (orig == null) {
    stderr.writeln('Impossible de decoder $src');
    exit(1);
  }
  stdout.writeln('Logo source : ${orig.width}x${orig.height}');

  // 1. Launcher opaque 1024x1024 (recadre en carre au besoin, fond creme)
  final square = _cropCenterSquare(orig);
  final launcher = img.copyResize(square, width: 1024, height: 1024);
  File(outLauncher).writeAsBytesSync(img.encodePng(launcher));
  stdout.writeln('OK $outLauncher');

  // 2. Foreground transparent : retire fond creme (garde motif dore + texte)
  final fg = _extractGoldOnTransparent(square, size: 1024);
  File(outForeground).writeAsBytesSync(img.encodePng(fg));
  stdout.writeln('OK $outForeground');

  // 3. Icone notification : silhouette blanche opaque sur transparent
  final notif = _toWhiteSilhouette(square, size: 512);
  File(outNotif).writeAsBytesSync(img.encodePng(notif));
  stdout.writeln('OK $outNotif');
}

img.Image _cropCenterSquare(img.Image src) {
  final side = src.width < src.height ? src.width : src.height;
  final x = (src.width - side) ~/ 2;
  final y = (src.height - side) ~/ 2;
  return img.copyCrop(src, x: x, y: y, width: side, height: side);
}

// Seuils : pixels au-dessus = fond clair (transparent),
// pixels en dessous = motif (opaque).
const int _bgLuminance = 225;  // au-dessus -> transparent
const int _fgLuminance = 190;  // en dessous -> pleinement opaque

int _luma(int r, int g, int b) =>
    ((0.299 * r) + (0.587 * g) + (0.114 * b)).round();

/// Retire le fond creme (garde le motif dore visible).
img.Image _extractGoldOnTransparent(img.Image src, {required int size}) {
  final base = img.copyResize(src, width: size, height: size);
  final out = img.Image(width: size, height: size, numChannels: 4);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final p = base.getPixel(x, y);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final l = _luma(r, g, b);
      if (l >= _bgLuminance) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
      } else if (l <= _fgLuminance) {
        out.setPixelRgba(x, y, r, g, b, 255);
      } else {
        final t = (_bgLuminance - l) / (_bgLuminance - _fgLuminance);
        final a = (t * 255).round().clamp(0, 255);
        out.setPixelRgba(x, y, r, g, b, a);
      }
    }
  }
  return out;
}

/// Silhouette blanche opaque sur fond transparent (icone notif Android).
img.Image _toWhiteSilhouette(img.Image src, {required int size}) {
  final base = img.copyResize(src, width: size, height: size);
  final out = img.Image(width: size, height: size, numChannels: 4);
  for (int y = 0; y < size; y++) {
    for (int x = 0; x < size; x++) {
      final p = base.getPixel(x, y);
      final l = _luma(p.r.toInt(), p.g.toInt(), p.b.toInt());
      int alpha;
      if (l >= _bgLuminance) {
        alpha = 0;
      } else if (l <= _fgLuminance) {
        alpha = 255;
      } else {
        final t = (_bgLuminance - l) / (_bgLuminance - _fgLuminance);
        alpha = (t * 255).round().clamp(0, 255);
      }
      out.setPixelRgba(x, y, 255, 255, 255, alpha);
    }
  }
  return out;
}
