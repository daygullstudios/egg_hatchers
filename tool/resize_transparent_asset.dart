import 'dart:io';

import 'package:image/image.dart' as image;

void main(List<String> args) {
  if (args.length != 3) {
    stderr.writeln(
      'Usage: dart run tool/resize_transparent_asset.dart <input> <output> <size>',
    );
    exitCode = 64;
    return;
  }

  final source = image.decodePng(File(args[0]).readAsBytesSync());
  if (source == null) {
    stderr.writeln('Could not decode ${args[0]}');
    exitCode = 65;
    return;
  }

  final size = int.parse(args[2]);
  final resized = image.copyResize(
    source,
    width: size,
    height: size,
    interpolation: image.Interpolation.cubic,
  );
  File(args[1])
    ..createSync(recursive: true)
    ..writeAsBytesSync(image.encodePng(resized, level: 9));
}
