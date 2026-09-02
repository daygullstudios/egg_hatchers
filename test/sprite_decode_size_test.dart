import 'package:egg_hatchers/utils/sprite_decode_size.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sprite decoding uses reusable device-aware size buckets', () {
    expect(
      SpriteDecodeSize.forDisplay(
        logicalSize: 32,
        devicePixelRatio: 1,
        maxSourceWidth: 512,
      ),
      64,
    );
    expect(
      SpriteDecodeSize.forDisplay(
        logicalSize: 48,
        devicePixelRatio: 2,
        maxSourceWidth: 512,
      ),
      128,
    );
    expect(
      SpriteDecodeSize.forDisplay(
        logicalSize: 120,
        devicePixelRatio: 3,
        maxSourceWidth: 512,
      ),
      512,
    );
    expect(
      SpriteDecodeSize.forDisplay(
        logicalSize: 220,
        devicePixelRatio: 3,
        maxSourceWidth: 256,
      ),
      256,
    );
  });
}
