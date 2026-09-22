import 'dart:io';

import 'package:image/image.dart' as img;

const Map<String, int> _densities = {
  'mipmap-mdpi': 24,
  'mipmap-hdpi': 36,
  'mipmap-xhdpi': 48,
  'mipmap-xxhdpi': 72,
  'mipmap-xxxhdpi': 96,
};

const String _sourceLogo = 'assets/images/logo.png';
const String _androidResDir = 'android/app/src/main/res';
const String _iconName = 'ic_notification';

Future<int> main(List<String> args) async {
  final File srcFile = File(_sourceLogo);
  if (!srcFile.existsSync()) {
    stderr.writeln('ERREUR: logo introuvable a $_sourceLogo');
    return 1;
  }

  final img.Image? source = img.decodePng(await srcFile.readAsBytes());
  if (source == null) {
    stderr.writeln('ERREUR: impossible de decoder $_sourceLogo');
    return 1;
  }

  final img.Image monochrome = _makeWhiteOnTransparent(source);
  final img.Image trimmed = _trimTransparent(monochrome);

  for (final entry in _densities.entries) {
    final Directory dir = Directory('$_androidResDir/${entry.key}');
    dir.createSync(recursive: true);

    final int canvas = entry.value;
    final int inner = (canvas * 0.72).round();

    final img.Image resized = img.copyResize(
      trimmed,
      width: inner,
      height: inner,
      interpolation: img.Interpolation.linear,
    );

    final img.Image out =
        img.Image(width: canvas, height: canvas, numChannels: 4);
    final int offsetX = ((canvas - inner) / 2).round();
    final int offsetY = ((canvas - inner) / 2).round();
    img.compositeImage(out, resized, dstX: offsetX, dstY: offsetY);

    final File file = File('${dir.path}/$_iconName.png');
    await file.writeAsBytes(img.encodePng(out));
    stdout.writeln('  ${entry.key}/$_iconName.png (${canvas}x${canvas})');
  }

  stdout.writeln(
      '\nOK — icones de notification generees dans $_androidResDir/mipmap-*');
  stdout.writeln(
      'Reference dans AndroidManifest.xml via com.google.firebase.messaging.default_notification_icon');
  return 0;
}

img.Image _makeWhiteOnTransparent(img.Image src) {
  final img.Image rgba = src.numChannels == 4 ? src.clone() : src.convert(numChannels: 4);
  for (final img.Pixel p in rgba) {
    final num alpha = p.a;
    if (alpha == 0) {
      p.setRgba(0, 0, 0, 0);
      continue;
    }
    final num luminance = 0.2126 * p.r + 0.7152 * p.g + 0.0722 * p.b;
    final int mask = luminance < 220 ? 255 : 0;
    if (mask == 0) {
      p.setRgba(0, 0, 0, 0);
    } else {
      p.setRgba(255, 255, 255, alpha.toInt());
    }
  }
  return rgba;
}

img.Image _trimTransparent(img.Image src) {
  int minX = src.width;
  int minY = src.height;
  int maxX = -1;
  int maxY = -1;

  for (int y = 0; y < src.height; y++) {
    for (int x = 0; x < src.width; x++) {
      if (src.getPixel(x, y).a > 0) {
        if (x < minX) minX = x;
        if (y < minY) minY = y;
        if (x > maxX) maxX = x;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX < 0) return src;
  return img.copyCrop(
    src,
    x: minX,
    y: minY,
    width: maxX - minX + 1,
    height: maxY - minY + 1,
  );
}
