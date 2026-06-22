import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:toilet_survivor/config/game_config.dart';

class Bullet extends SpriteComponent {
  Bullet({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 direction,
  }) : velocity = _normalized(direction) * GameConfig.bulletSpeed,
       super(
         sprite: sprite,
         anchor: Anchor.center,
         position: position,
         size: Vector2(GameConfig.bulletWidth, GameConfig.bulletHeight),
         angle: math.atan2(direction.y, direction.x),
         priority: 12,
       );

  final Vector2 velocity;

  @override
  void update(double dt) {
    super.update(dt);

    position += velocity * dt;
    if (_isOutsideScreen()) {
      removeFromParent();
    }
  }

  bool _isOutsideScreen() {
    const padding = GameConfig.spawnPadding;
    return position.x < -padding ||
        position.x > GameConfig.worldWidth + padding ||
        position.y < -padding ||
        position.y > GameConfig.worldHeight + padding;
  }
}

Vector2 _normalized(Vector2 vector) {
  if (vector.length2 == 0) {
    return Vector2(1, 0);
  }
  return vector.clone()..normalize();
}
