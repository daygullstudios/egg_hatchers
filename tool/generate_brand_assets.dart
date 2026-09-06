import 'dart:io';

import 'package:image/image.dart' as image;

/// Deterministic platform exports from the approved Nestarium source artwork.
/// Run from the repository root; existing platform pixel dimensions are kept.
void main() {
  final source = image.decodePng(
    File('assets/branding/nestarium_source.png').readAsBytesSync(),
  );
  if (source == null || source.width != source.height || source.width < 1024) {
    throw StateError(
      'The Nestarium source must be square and at least 1024px.',
    );
  }
  final targets = <String>[
    'assets/images/ui/app_logo.png',
    'web/favicon.png',
    'android/app/src/main/res/drawable-nodpi/launch_image.png',
  ];
  for (final directory in [
    'web/icons',
    'android/app/src/main/res/mipmap-mdpi',
    'android/app/src/main/res/mipmap-hdpi',
    'android/app/src/main/res/mipmap-xhdpi',
    'android/app/src/main/res/mipmap-xxhdpi',
    'android/app/src/main/res/mipmap-xxxhdpi',
    'ios/Runner/Assets.xcassets/AppIcon.appiconset',
    'ios/Runner/Assets.xcassets/LaunchImage.imageset',
    'macos/Runner/Assets.xcassets/AppIcon.appiconset',
  ]) {
    targets.addAll(
      Directory(directory)
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith('.png'))
          .map((file) => file.path.replaceAll('\\', '/')),
    );
  }
  for (final path in targets) {
    final file = File(path);
    final previous = image.decodePng(file.readAsBytesSync());
    if (previous == null) throw StateError('Invalid platform PNG: $path');
    final output = image.Image(width: previous.width, height: previous.height);
    image.fill(output, color: image.ColorRgb8(0, 8, 35));
    // Fit the entire square inside the maskable icon's central safe circle.
    final scale = path.contains('maskable') ? 0.70 : 1.0;
    final edge =
        ((previous.width < previous.height ? previous.width : previous.height) *
                scale)
            .round();
    final resized = image.copyResize(
      source,
      width: edge,
      height: edge,
      interpolation: image.Interpolation.average,
    );
    image.compositeImage(
      output,
      resized,
      dstX: (output.width - edge) ~/ 2,
      dstY: (output.height - edge) ~/ 2,
    );
    file.writeAsBytesSync(image.encodePng(output));
    stdout.writeln('$path: ${output.width}x${output.height}');
  }
  final icon = image.copyResize(
    source,
    width: 256,
    height: 256,
    interpolation: image.Interpolation.average,
  );
  File(
    'windows/runner/resources/app_icon.ico',
  ).writeAsBytesSync(image.encodeIco(icon));
  stdout.writeln('windows/runner/resources/app_icon.ico: generated');
}
