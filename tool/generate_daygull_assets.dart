// ignore_for_file: avoid_print

import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Generates the DayGull Egg and its three secret hatchling sprites.
/// Run: dart run tool/generate_daygull_assets.dart
void main() {
  final animalGenerators = <String, img.Image Function(int)>{
    'crossword_beast': _drawCrosswordBeast,
    'boba_bazooka': _drawBobaBazooka,
    'the_hatched_egg': _drawTheHatchedEgg,
  };

  for (final entry in animalGenerators.entries) {
    _writePng('assets/images/animals/${entry.key}.png', entry.value(256));
    _writePng(
      'assets/images/animal_themes/realistic/${entry.key}.png',
      entry.value(512),
    );
  }

  _writePng('assets/images/eggs/daygull_egg.png', _drawDayGullEgg(256));
  _writePng(
    'assets/images/egg_themes/retro_pixel/daygull.png',
    _drawDayGullRetroEgg(256),
  );
  _writePng(
    'assets/images/egg_themes/realistic/daygull.png',
    _drawDayGullEgg(512),
  );
}

void _writePng(String path, img.Image image) {
  final file = File(path);
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(img.encodePng(image));
  print('Wrote $path');
}

img.Image _canvas(int size) =>
    img.Image(width: size, height: size, numChannels: 4);

img.ColorRgba8 _c(int r, int g, int b, [int a = 255]) =>
    img.ColorRgba8(r, g, b, a);

int _scale(img.Image image, num value) => (value * image.width / 256).round();

void _set(img.Image image, int x, int y, img.ColorRgba8 color) {
  if (x < 0 || y < 0 || x >= image.width || y >= image.height) return;
  image.setPixel(x, y, color);
}

void _fillRect(
  img.Image image,
  num left,
  num top,
  num right,
  num bottom,
  img.ColorRgba8 color,
) {
  final l = _scale(image, left);
  final t = _scale(image, top);
  final r = _scale(image, right);
  final b = _scale(image, bottom);
  for (var y = t; y <= b; y++) {
    for (var x = l; x <= r; x++) {
      _set(image, x, y, color);
    }
  }
}

void _fillRoundedRect(
  img.Image image,
  num left,
  num top,
  num right,
  num bottom,
  num radius,
  img.ColorRgba8 color,
) {
  final l = _scale(image, left);
  final t = _scale(image, top);
  final r = _scale(image, right);
  final b = _scale(image, bottom);
  final rad = math.max(1, _scale(image, radius));
  for (var y = t; y <= b; y++) {
    for (var x = l; x <= r; x++) {
      var inside = true;
      if (x < l + rad && y < t + rad) {
        final dx = x - (l + rad);
        final dy = y - (t + rad);
        inside = dx * dx + dy * dy <= rad * rad;
      } else if (x > r - rad && y < t + rad) {
        final dx = x - (r - rad);
        final dy = y - (t + rad);
        inside = dx * dx + dy * dy <= rad * rad;
      } else if (x < l + rad && y > b - rad) {
        final dx = x - (l + rad);
        final dy = y - (b - rad);
        inside = dx * dx + dy * dy <= rad * rad;
      } else if (x > r - rad && y > b - rad) {
        final dx = x - (r - rad);
        final dy = y - (b - rad);
        inside = dx * dx + dy * dy <= rad * rad;
      }
      if (inside) _set(image, x, y, color);
    }
  }
}

void _fillCircle(
  img.Image image,
  num cx,
  num cy,
  num radius,
  img.ColorRgba8 color,
) {
  final ix = _scale(image, cx);
  final iy = _scale(image, cy);
  final ir = math.max(1, _scale(image, radius));
  for (var y = iy - ir; y <= iy + ir; y++) {
    for (var x = ix - ir; x <= ix + ir; x++) {
      final dx = x - ix;
      final dy = y - iy;
      if (dx * dx + dy * dy <= ir * ir) {
        _set(image, x, y, color);
      }
    }
  }
}

void _fillEllipse(
  img.Image image,
  num cx,
  num cy,
  num rx,
  num ry,
  img.ColorRgba8 color,
) {
  final ix = _scale(image, cx);
  final iy = _scale(image, cy);
  final irx = math.max(1, _scale(image, rx));
  final iry = math.max(1, _scale(image, ry));
  for (var y = iy - iry; y <= iy + iry; y++) {
    for (var x = ix - irx; x <= ix + irx; x++) {
      final dx = (x - ix) / irx;
      final dy = (y - iy) / iry;
      if (dx * dx + dy * dy <= 1) {
        _set(image, x, y, color);
      }
    }
  }
}

void _strokeEllipse(
  img.Image image,
  num cx,
  num cy,
  num rx,
  num ry,
  num thickness,
  img.ColorRgba8 color,
) {
  final ix = _scale(image, cx);
  final iy = _scale(image, cy);
  final irx = math.max(1, _scale(image, rx));
  final iry = math.max(1, _scale(image, ry));
  final thick = math.max(1, _scale(image, thickness));
  for (var y = iy - iry - thick; y <= iy + iry + thick; y++) {
    for (var x = ix - irx - thick; x <= ix + irx + thick; x++) {
      final dx = (x - ix) / (irx + thick);
      final dy = (y - iy) / (iry + thick);
      final outer = dx * dx + dy * dy <= 1;
      final innerDx = (x - ix) / math.max(1, irx - thick);
      final innerDy = (y - iy) / math.max(1, iry - thick);
      final inner = innerDx * innerDx + innerDy * innerDy <= 1;
      if (outer && !inner) _set(image, x, y, color);
    }
  }
}

void _drawLine(
  img.Image image,
  num x0,
  num y0,
  num x1,
  num y1,
  num thickness,
  img.ColorRgba8 color,
) {
  final sx0 = _scale(image, x0);
  final sy0 = _scale(image, y0);
  final sx1 = _scale(image, x1);
  final sy1 = _scale(image, y1);
  final steps = math.max((sx1 - sx0).abs(), (sy1 - sy0).abs());
  final radius = math.max(1, _scale(image, thickness) ~/ 2);
  if (steps == 0) {
    _dot(image, sx0, sy0, radius, color);
    return;
  }
  for (var i = 0; i <= steps; i++) {
    final t = i / steps;
    final x = (sx0 + (sx1 - sx0) * t).round();
    final y = (sy0 + (sy1 - sy0) * t).round();
    _dot(image, x, y, radius, color);
  }
}

void _dot(img.Image image, int cx, int cy, int radius, img.ColorRgba8 color) {
  for (var y = cy - radius; y <= cy + radius; y++) {
    for (var x = cx - radius; x <= cx + radius; x++) {
      final dx = x - cx;
      final dy = y - cy;
      if (dx * dx + dy * dy <= radius * radius) {
        _set(image, x, y, color);
      }
    }
  }
}

void _drawEyes(img.Image image, num cx, num cy, num spacing, num radius) {
  _fillCircle(image, cx - spacing, cy, radius, _c(245, 252, 255));
  _fillCircle(image, cx + spacing, cy, radius, _c(245, 252, 255));
  _fillCircle(image, cx - spacing + 1.5, cy + 1, radius * 0.54, _c(18, 24, 42));
  _fillCircle(image, cx + spacing + 1.5, cy + 1, radius * 0.54, _c(18, 24, 42));
  _fillCircle(
    image,
    cx - spacing + 2.5,
    cy - 1.5,
    radius * 0.18,
    _c(255, 255, 255, 210),
  );
  _fillCircle(
    image,
    cx + spacing + 2.5,
    cy - 1.5,
    radius * 0.18,
    _c(255, 255, 255, 210),
  );
}

void _glitchBars(img.Image image, {bool bright = false}) {
  final cyan = bright ? _c(130, 235, 255, 210) : _c(77, 208, 225, 170);
  final purple = bright ? _c(196, 112, 255, 210) : _c(126, 87, 194, 170);
  final navy = _c(10, 23, 58, 190);
  for (final bar in [
    (28, 62, 82, 66, cyan),
    (170, 70, 215, 74, purple),
    (34, 184, 95, 188, purple),
    (160, 196, 224, 200, cyan),
    (110, 222, 145, 226, navy),
  ]) {
    _fillRect(image, bar.$1, bar.$2, bar.$3, bar.$4, bar.$5);
  }
}

void _sparkle(img.Image image, num cx, num cy, img.ColorRgba8 color) {
  _drawLine(image, cx - 5, cy, cx + 5, cy, 1.4, color);
  _drawLine(image, cx, cy - 5, cx, cy + 5, 1.4, color);
  _fillCircle(image, cx, cy, 1.5, color);
}

img.Image _drawCrosswordBeast(int size) {
  final image = _canvas(size);
  _glitchBars(image);

  _fillEllipse(image, 127, 151, 58, 62, _c(15, 32, 74));
  _strokeEllipse(image, 127, 151, 58, 62, 4, _c(4, 10, 28));
  _fillEllipse(image, 126, 87, 48, 38, _c(81, 52, 143));
  _strokeEllipse(image, 126, 87, 48, 38, 4, _c(15, 20, 48));

  _drawLine(image, 88, 68, 58, 44, 8, _c(117, 212, 236));
  _drawLine(image, 166, 68, 198, 43, 8, _c(176, 106, 242));
  _fillCircle(image, 58, 44, 7, _c(210, 247, 255));
  _fillCircle(image, 198, 43, 7, _c(233, 218, 255));

  _fillEllipse(image, 69, 151, 25, 35, _c(52, 70, 142));
  _fillEllipse(image, 187, 151, 25, 35, _c(52, 70, 142));
  _drawLine(image, 64, 149, 35, 172, 7, _c(96, 68, 170));
  _drawLine(image, 192, 149, 222, 171, 7, _c(96, 68, 170));

  _fillRoundedRect(image, 88, 124, 168, 174, 8, _c(236, 244, 255));
  _fillRoundedRect(image, 92, 128, 164, 170, 5, _c(211, 226, 247));
  for (final x in [106, 121, 136, 151]) {
    _fillRect(image, x, 128, x + 2, 170, _c(31, 47, 87));
  }
  for (final y in [139, 151, 162]) {
    _fillRect(image, 92, y, 164, y + 2, _c(31, 47, 87));
  }
  for (final cell in [
    (108, 130, 120, 139),
    (138, 142, 150, 151),
    (94, 153, 106, 162),
    (153, 163, 164, 170),
  ]) {
    _fillRect(image, cell.$1, cell.$2, cell.$3, cell.$4, _c(16, 30, 64));
  }

  _drawEyes(image, 126, 82, 17, 8);
  _fillEllipse(image, 126, 101, 12, 6, _c(20, 23, 43));
  _fillCircle(image, 121, 99, 1.6, _c(105, 224, 255));
  _fillCircle(image, 131, 99, 1.6, _c(205, 141, 255));

  _drawLine(image, 85, 210, 68, 225, 9, _c(53, 66, 122));
  _drawLine(image, 168, 210, 188, 225, 9, _c(53, 66, 122));
  _fillEllipse(image, 67, 226, 17, 7, _c(7, 11, 27));
  _fillEllipse(image, 190, 226, 17, 7, _c(7, 11, 27));
  _sparkle(image, 202, 107, _c(121, 230, 255, 190));
  _sparkle(image, 49, 119, _c(194, 123, 255, 180));

  return image;
}

img.Image _drawBobaBazooka(int size) {
  final image = _canvas(size);
  _glitchBars(image, bright: true);

  _drawLine(image, 77, 91, 56, 42, 6, _c(116, 219, 237));
  _drawLine(image, 181, 91, 202, 42, 6, _c(177, 111, 245));

  _fillRoundedRect(image, 74, 78, 182, 195, 18, _c(238, 191, 123));
  _strokeEllipse(image, 128, 87, 55, 18, 4, _c(61, 35, 74));
  _fillEllipse(image, 128, 82, 52, 19, _c(252, 230, 190));
  _fillEllipse(image, 128, 94, 47, 16, _c(147, 89, 46));
  _fillRoundedRect(image, 82, 109, 174, 189, 12, _c(219, 151, 83));
  _fillRoundedRect(image, 90, 114, 166, 182, 9, _c(245, 187, 108, 205));

  _drawLine(image, 53, 123, 206, 93, 22, _c(30, 45, 91));
  _drawLine(image, 53, 124, 206, 94, 13, _c(113, 207, 236));
  _fillEllipse(image, 207, 94, 21, 17, _c(22, 22, 49));
  _fillEllipse(image, 214, 92, 12, 10, _c(194, 111, 255));
  _fillRoundedRect(image, 81, 111, 105, 133, 5, _c(90, 54, 148));
  _fillRoundedRect(image, 156, 95, 178, 115, 5, _c(90, 54, 148));

  _drawEyes(image, 128, 137, 17, 7);
  _fillEllipse(image, 128, 154, 12, 5, _c(82, 42, 35));

  for (final pearl in [
    (95, 171),
    (113, 181),
    (132, 174),
    (151, 183),
    (164, 168),
  ]) {
    _fillCircle(image, pearl.$1, pearl.$2, 6, _c(51, 32, 55));
    _fillCircle(image, pearl.$1 - 2, pearl.$2 - 2, 1.5, _c(255, 255, 255, 170));
  }

  _drawLine(image, 89, 195, 74, 222, 9, _c(142, 83, 50));
  _drawLine(image, 166, 195, 183, 222, 9, _c(142, 83, 50));
  _fillEllipse(image, 73, 224, 16, 7, _c(67, 42, 39));
  _fillEllipse(image, 184, 224, 16, 7, _c(67, 42, 39));
  _sparkle(image, 217, 76, _c(126, 234, 255, 210));

  return image;
}

img.Image _drawTheHatchedEgg(int size) {
  final image = _canvas(size);
  _glitchBars(image, bright: true);

  _fillEllipse(image, 128, 153, 63, 73, _c(246, 247, 251));
  _strokeEllipse(image, 128, 153, 63, 73, 5, _c(198, 209, 225));
  _fillEllipse(image, 128, 131, 47, 50, _c(255, 215, 83));
  _fillEllipse(image, 118, 113, 18, 14, _c(255, 235, 133, 200));

  _fillRect(image, 70, 122, 186, 176, _c(246, 247, 251));
  for (final crack in [
    (69, 122, 87, 143),
    (87, 143, 105, 123),
    (105, 123, 126, 145),
    (126, 145, 145, 123),
    (145, 123, 165, 143),
    (165, 143, 187, 122),
  ]) {
    _drawLine(image, crack.$1, crack.$2, crack.$3, crack.$4, 4, _c(58, 68, 95));
  }

  _drawEyes(image, 128, 112, 15, 7);
  _fillEllipse(image, 128, 128, 13, 7, _c(236, 128, 35));
  _fillEllipse(image, 128, 127, 8, 4, _c(255, 182, 69));

  _drawLine(image, 88, 151, 57, 128, 9, _c(255, 210, 75));
  _drawLine(image, 168, 151, 201, 128, 9, _c(255, 210, 75));
  _fillCircle(image, 54, 126, 8, _c(255, 236, 132));
  _fillCircle(image, 204, 126, 8, _c(255, 236, 132));

  _fillEllipse(image, 98, 214, 15, 8, _c(232, 153, 43));
  _fillEllipse(image, 158, 214, 15, 8, _c(232, 153, 43));
  _drawLine(image, 67, 189, 103, 188, 5, _c(102, 229, 255, 200));
  _drawLine(image, 151, 199, 198, 198, 5, _c(195, 118, 255, 200));
  _sparkle(image, 201, 75, _c(139, 239, 255, 220));
  _sparkle(image, 52, 83, _c(202, 129, 255, 210));

  return image;
}

img.Image _drawDayGullEgg(int size) {
  final image = _canvas(size);
  _glitchBars(image, bright: true);

  _fillEllipse(image, 128, 137, 63, 86, _c(5, 18, 52));
  _strokeEllipse(image, 128, 137, 63, 86, 5, _c(78, 52, 137));
  _fillEllipse(image, 111, 101, 27, 40, _c(29, 78, 142, 120));
  _fillEllipse(image, 145, 163, 35, 49, _c(132, 83, 215, 100));
  _drawLine(image, 78, 139, 178, 92, 8, _c(120, 227, 249, 210));
  _drawLine(image, 88, 147, 184, 105, 5, _c(205, 120, 255, 190));
  _drawLine(image, 82, 111, 116, 123, 6, _c(218, 236, 255, 230));
  _drawLine(image, 116, 123, 145, 104, 6, _c(218, 236, 255, 230));
  _drawLine(image, 145, 104, 176, 116, 6, _c(218, 236, 255, 230));
  _fillCircle(image, 130, 74, 5, _c(245, 250, 255));
  _fillCircle(image, 137, 74, 5, _c(5, 18, 52));
  _fillRect(image, 84, 179, 171, 185, _c(104, 229, 255, 190));
  _fillRect(image, 101, 191, 190, 197, _c(181, 101, 255, 185));
  _sparkle(image, 76, 70, _c(112, 235, 255, 210));
  _sparkle(image, 187, 154, _c(197, 124, 255, 210));

  return image;
}

img.Image _drawDayGullRetroEgg(int size) {
  final image = _canvas(size);
  const step = 8;
  for (var y = 40; y < 216; y += step) {
    final centerY = (y + step / 2 - 137).abs();
    final width =
        58 * math.sqrt(math.max(0, 1 - centerY * centerY / (86 * 86)));
    final left = 128 - width;
    final right = 128 + width;
    final color = y < 104
        ? _c(8, 25, 66)
        : y < 160
        ? _c(14, 38, 92)
        : _c(29, 35, 92);
    _fillRect(image, left, y, right, y + step - 1, color);
  }
  for (final rect in [
    (82, 94, 170, 101, _c(117, 229, 252, 230)),
    (94, 110, 184, 117, _c(190, 109, 255, 220)),
    (70, 154, 156, 161, _c(117, 229, 252, 220)),
    (98, 176, 190, 183, _c(190, 109, 255, 220)),
  ]) {
    _fillRect(image, rect.$1, rect.$2, rect.$3, rect.$4, rect.$5);
  }
  _strokeEllipse(image, 128, 137, 63, 86, 4, _c(4, 9, 28));
  _drawLine(image, 82, 112, 116, 124, 6, _c(230, 242, 255));
  _drawLine(image, 116, 124, 146, 105, 6, _c(230, 242, 255));
  _drawLine(image, 146, 105, 176, 116, 6, _c(230, 242, 255));

  return image;
}
