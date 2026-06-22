import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:toilet_survivor/config/game_config.dart';

class PropComponent extends PositionComponent with HasPaint {
  PropComponent({
    required this.sprite,
    required Vector2 position,
    required Vector2 size,
    required this.blocksPlayer,
    Vector2? collisionSize,
    Vector2? collisionOffset,
    Vector2? collisionScale,
  }) : collisionSize = collisionSize?.clone(),
       collisionOffset = collisionOffset?.clone() ?? Vector2.zero(),
       collisionScale =
           collisionScale?.clone() ??
           Vector2(
             GameConfig.propCollisionScaleX,
             GameConfig.propCollisionScaleY,
           ),
       super(
         anchor: Anchor.center,
         position: position,
         size: size,
         priority: -5,
       );

  final Sprite sprite;
  final bool blocksPlayer;
  final Vector2? collisionSize;
  final Vector2 collisionOffset;
  final Vector2 collisionScale;

  Rect get collisionRect {
    final hitboxSize =
        collisionSize?.clone() ?? (_aspectFitSize()..multiply(collisionScale));
    final hitboxCenter = position + collisionOffset;
    return Rect.fromCenter(
      center: Offset(hitboxCenter.x, hitboxCenter.y),
      width: hitboxSize.x,
      height: hitboxSize.y,
    );
  }

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
