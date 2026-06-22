import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

class DecalComponent extends PositionComponent with HasPaint {
  DecalComponent({
    required this.sprite,
    required Vector2 position,
    required Vector2 size,
    double opacity = 1,
    double angle = 0,
  }) : super(
         anchor: Anchor.center,
         position: position,
         size: size,
         angle: angle,
         priority: -90,
       ) {
    paint.color = Color.fromARGB(
      (opacity.clamp(0, 1) * 255).round(),
      255,
      255,
      255,
    );
  }

  final Sprite sprite;

  @override
  void render(Canvas canvas) {
    final renderSize = _aspectFitSize();
    final renderPosition = Vector2(
      (size.x - renderSize.x) / 2,
      (size.y - renderSize.y) / 2,
    );

    sprite.render(
      canvas,
      position: renderPosition,
      size: renderSize,
      overridePaint: paint,
    );
  }

  Vector2 _aspectFitSize() {
    final sourceSize = sprite.srcSize;
    if (sourceSize.x == 0 || sourceSize.y == 0) {
      return size.clone();
    }

    final fitScale = math.min(size.x / sourceSize.x, size.y / sourceSize.y);
    return Vector2(sourceSize.x * fitScale, sourceSize.y * fitScale);
  }
}
