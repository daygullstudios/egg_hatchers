import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

const _sourceDirectory = 'assets/images/animal_themes/realistic';
const _outputDirectory = 'assets/images/animal_themes/retro_pixel';
const _workingSize = 64;
const _outputSize = 128;
const _transparent = 0x00000000;
const _outline = 0xFF171827;

const _preserveHandPolished = {
  'boba_bazooka',
  'crossword_beast',
  'the_hatched_egg',
};

const _palette = <int>[
  0xFF171827,
  0xFF2F3349,
  0xFF575D78,
  0xFF8F96B0,
  0xFFEFECE2,
  0xFFFFFFFF,
  0xFF5E3426,
  0xFF8D5634,
  0xFFC98243,
  0xFFF0BE59,
  0xFFFFE17B,
  0xFFE85C5C,
  0xFFF28CB1,
  0xFF6BCB6F,
  0xFF2F8D52,
  0xFF89D7F5,
  0xFF3489D6,
  0xFF1E4C9A,
  0xFF8163D9,
  0xFFC186F4,
  0xFF51E0D7,
  0xFF3E2B74,
  0xFFE8D1A2,
  0xFFB88A5C,
];

void main(List<String> args) {
  final sourceDir = Directory(_sourceDirectory);
  final outputDir = Directory(_outputDirectory)..createSync(recursive: true);
  if (!sourceDir.existsSync()) {
    stderr.writeln('Missing source directory: $_sourceDirectory');
    exitCode = 1;
    return;
  }

  final files =
      sourceDir
          .listSync()
          .whereType<File>()
          .where((file) => file.path.toLowerCase().endsWith('.png'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

  var generated = 0;
  for (final file in files) {
    final id = file.uri.pathSegments.last.replaceAll('.png', '');
    if (_preserveHandPolished.contains(id)) continue;

    final bytes = file.readAsBytesSync();
    final decoded = img.decodePng(bytes);
    if (decoded == null) {
      stderr.writeln('Could not decode ${file.path}');
      continue;
    }

    final sprite = _pixelate(decoded);
    final out = File('${outputDir.path}${Platform.pathSeparator}$id.png');
    out.writeAsBytesSync(img.encodePng(sprite, level: 9));
    generated++;
  }

  stdout.writeln('Generated $generated retro pixel animal assets.');
}

img.Image _pixelate(img.Image source) {
  final bounds = _visibleBounds(source);
  final trimmed = img.copyCrop(
    source,
    x: bounds.left,
    y: bounds.top,
    width: bounds.width,
    height: bounds.height,
  );

  final canvas = img.Image(width: 96, height: 96, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0, 0, 0, 0));

  final maxSide = math.max(trimmed.width, trimmed.height);
  final drawSize = math.max(1, (76 * math.min(1.0, 512 / maxSide)).round());
  final scaled = img.copyResize(
    trimmed,
    width: trimmed.width >= trimmed.height ? drawSize : null,
    height: trimmed.height > trimmed.width ? drawSize : null,
    interpolation: img.Interpolation.average,
  );
  final dx = ((canvas.width - scaled.width) / 2).round();
  final dy = ((canvas.height - scaled.height) / 2).round();
  img.compositeImage(canvas, scaled, dstX: dx, dstY: dy);

  final small = img.copyResize(
    canvas,
    width: _workingSize,
    height: _workingSize,
    interpolation: img.Interpolation.average,
  );

  _posterize(small);
  _addPixelOutline(small);
  _cleanAlpha(small);

  return img.copyResize(
    small,
    width: _outputSize,
    height: _outputSize,
    interpolation: img.Interpolation.nearest,
  );
}

({int left, int top, int width, int height}) _visibleBounds(img.Image image) {
  var minX = image.width;
  var minY = image.height;
  var maxX = -1;
  var maxY = -1;

  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (image.getPixel(x, y).a < 20) continue;
      minX = math.min(minX, x);
      minY = math.min(minY, y);
      maxX = math.max(maxX, x);
      maxY = math.max(maxY, y);
    }
  }

  if (maxX < minX || maxY < minY) {
    return (left: 0, top: 0, width: image.width, height: image.height);
  }

  final pad = 14;
  final left = math.max(0, minX - pad);
  final top = math.max(0, minY - pad);
  final right = math.min(image.width - 1, maxX + pad);
  final bottom = math.min(image.height - 1, maxY + pad);
  return (
    left: left,
    top: top,
    width: right - left + 1,
    height: bottom - top + 1,
  );
}

void _posterize(img.Image image) {
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.a < 34) {
        image.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      final snapped = _nearestPaletteColor(
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
      );
      final alpha = pixel.a > 190 ? 255 : 220;
      image.setPixelRgba(
        x,
        y,
        (snapped >> 16) & 0xFF,
        (snapped >> 8) & 0xFF,
        snapped & 0xFF,
        alpha,
      );
    }
  }
}

int _nearestPaletteColor(int r, int g, int b) {
  var best = _palette.first;
  var bestDistance = 1 << 62;
  for (final color in _palette) {
    final pr = (color >> 16) & 0xFF;
    final pg = (color >> 8) & 0xFF;
    final pb = color & 0xFF;
    final distance =
        _channelDistance(r, pr) +
        _channelDistance(g, pg) +
        _channelDistance(b, pb);
    if (distance < bestDistance) {
      bestDistance = distance;
      best = color;
    }
  }
  return best;
}

int _channelDistance(int a, int b) {
  final delta = a - b;
  return delta * delta;
}

void _addPixelOutline(img.Image image) {
  final source = img.Image.from(image);
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      if (source.getPixel(x, y).a > 0) continue;
      var touchesVisible = false;
      for (var oy = -1; oy <= 1; oy++) {
        for (var ox = -1; ox <= 1; ox++) {
          if (ox == 0 && oy == 0) continue;
          final nx = x + ox;
          final ny = y + oy;
          if (nx < 0 || nx >= image.width || ny < 0 || ny >= image.height) {
            continue;
          }
          if (source.getPixel(nx, ny).a > 160) {
            touchesVisible = true;
          }
        }
      }
      if (touchesVisible) {
        image.setPixelRgba(
          x,
          y,
          (_outline >> 16) & 0xFF,
          (_outline >> 8) & 0xFF,
          _outline & 0xFF,
          255,
        );
      }
    }
  }
}

void _cleanAlpha(img.Image image) {
  for (var y = 0; y < image.height; y++) {
    for (var x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.a == 0) {
        image.setPixelRgba(
          x,
          y,
          (_transparent >> 16) & 0xFF,
          (_transparent >> 8) & 0xFF,
          _transparent & 0xFF,
          0,
        );
      }
    }
  }
}
