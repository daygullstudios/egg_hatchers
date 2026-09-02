class SpriteDecodeSize {
  SpriteDecodeSize._();

  static int forDisplay({
    required double logicalSize,
    required double devicePixelRatio,
    required int maxSourceWidth,
  }) {
    final target = (logicalSize * devicePixelRatio).ceil();
    for (final bucket in const [64, 128, 256, 512]) {
      if (target <= bucket) return bucket.clamp(1, maxSourceWidth);
    }
    return maxSourceWidth;
  }
}
