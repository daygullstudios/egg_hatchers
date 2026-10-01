import 'dart:io';
import 'package:image/image.dart' as img;

void main(List<String> args) {
  final source = img.decodePng(File(args[0]).readAsBytesSync())!;
  final size = int.parse(args[2]);
  const ids = [
    'royal_chicken',
    'crown_fox',
    'gem_dragon',
    'cloud_bunny',
    'sun_lion',
    'cosmic_phoenix',
    'moon_cat',
    'star_fox',
    'galaxy_dragon',
    'unicorn',
  ];
  for (var i = 0; i < ids.length; i++) {
    final x = (i % 5 * source.width / 5).round();
    final y = (i ~/ 5 * source.height / 2).round();
    final cell = img.copyCrop(
      source,
      x: x,
      y: y,
      width: ((i % 5 + 1) * source.width / 5).round() - x,
      height: source.height ~/ 2,
    );
    var left = cell.width, top = cell.height, right = 0, bottom = 0;
    for (final pixel in cell) {
      if (pixel.a > 80) {
        if (pixel.x < left) left = pixel.x;
        if (pixel.y < top) top = pixel.y;
        if (pixel.x > right) right = pixel.x;
        if (pixel.y > bottom) bottom = pixel.y;
      }
    }
    final trimmed = img.copyCrop(
      cell,
      x: left,
      y: top,
      width: right - left + 1,
      height: bottom - top + 1,
    );
    final scale =
        size *
        .9 /
        (trimmed.width > trimmed.height ? trimmed.width : trimmed.height);
    final head = img.copyResize(
      trimmed,
      width: (trimmed.width * scale).round(),
      height: (trimmed.height * scale).round(),
      interpolation: size == 64
          ? img.Interpolation.nearest
          : img.Interpolation.cubic,
    );
    final output = img.Image(width: size, height: size, numChannels: 4);
    img.compositeImage(
      output,
      head,
      dstX: (size - head.width) ~/ 2,
      dstY: (size - head.height) ~/ 2,
    );
    File('${args[1]}/${ids[i]}.png')
      ..createSync(recursive: true)
      ..writeAsBytesSync(img.encodePng(output));
  }
}
