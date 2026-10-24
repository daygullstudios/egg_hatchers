import 'dart:io';
import 'package:image/image.dart' as img;

// Builds editor reference data only; shipped artwork stays in the PNG files.
void main() {
  final output = StringBuffer(
    "import '../models/custom_sprite_data.dart';\n\nconst halloweenSpriteReferences = <String, CustomSpriteData>{\n",
  );
  for (final id in ['pumpkin_prowler', 'lantern_wraith', 'count_nocturne']) {
    final source = img.decodePng(
      File('assets/images/animals/$id.png').readAsBytesSync(),
    )!;
    final small = img.copyResize(
      source,
      width: 16,
      height: 16,
      interpolation: img.Interpolation.average,
    );
    output.writeln("'$id': CustomSpriteData(pixels: [");
    for (final p in small) {
      output.writeln(
        p.a < 100
            ? 'null,'
            : '0xFF${p.r.toInt().toRadixString(16).padLeft(2, '0')}${p.g.toInt().toRadixString(16).padLeft(2, '0')}${p.b.toInt().toRadixString(16).padLeft(2, '0')},',
      );
    }
    output.writeln(']),');
  }
  output.writeln('};');
  File(
    'lib/data/halloween_sprite_references.dart',
  ).writeAsStringSync(output.toString());
}
