import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:toilet_survivor/config/game_config.dart';

class SludgePuddleComponent extends PositionComponent with HasPaint {
  SludgePuddleComponent({
    required this.sprite,
    required Vector2 position,
    required Vector2 size,
    required this.triggersSlide,
    required double opacity,
    double angle = 0,
  }) : super(
         anchor: Anchor.center,
         position: position,
         size: size,
         angle: angle,
         priority: -80,
       ) {
    paint.color = Color.fromARGB(
      (opacity.clamp(0, 1) * 255).round(),
      255,
      255,
      255,
    );
  }

  final Sprite sprite;
  final bool triggersSlide;
  double _cooldownTimer = 0;

  double get triggerRadius =>
      math.min(size.x, size.y) * GameConfig.sludgePuddleTriggerScale;

  bool canTrigger(Vector2 playerPosition, double playerRadius) {
    if (!triggersSlide) {
      return false;
    }
    if (_cooldownTimer > 0) {
      return false;
    }

    final radius = triggerRadius + playerRadius;
    return position.distanceToSquared(playerPosition) <= radius * radius;
  }

  void markTriggered() {
    _cooldownTimer = GameConfig.sludgeSlideCooldown;
  }

  void resetCooldown() {
    _cooldownTimer = 0;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _cooldownTimer -= dt;
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
