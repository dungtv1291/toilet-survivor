import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:toilet_survivor/config/game_config.dart';

enum StinkCloudKind { small, skull }

class StinkCloudHazard extends PositionComponent with HasPaint {
  StinkCloudHazard({
    required this.kind,
    required this.sprite,
    required Vector2 position,
    required Vector2 size,
    required this.damage,
    required this.tickInterval,
    required this.collisionRadius,
    required this.fadeInDuration,
    required this.fadeOutDuration,
    required this.opacityAlpha,
    required double lifetime,
  }) : _lifetime = lifetime,
       super(
         anchor: Anchor.center,
         position: position,
         size: size,
         priority: 13,
       ) {
    _updateOpacity();
  }

  final StinkCloudKind kind;
  final Sprite sprite;
  final double damage;
  final double tickInterval;
  final double collisionRadius;
  final double fadeInDuration;
  final double fadeOutDuration;
  final int opacityAlpha;
  final double _lifetime;
  double _age = 0;
  double _tickTimer = GameConfig.stinkCloudTickInterval;

  bool tryDamage(Vector2 playerPosition, double playerRadius, double dt) {
    final radius = collisionRadius + playerRadius;
    if (position.distanceToSquared(playerPosition) > radius * radius) {
      return false;
    }

    _tickTimer -= dt;
    if (_tickTimer > 0) {
      return false;
    }

    _tickTimer = tickInterval;
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    _age += dt;
    if (_age >= _lifetime) {
      removeFromParent();
      return;
    }

    _updateOpacity();
  }

  void _updateOpacity() {
    final remaining = _lifetime - _age;
    var fade = 1.0;

    if (fadeInDuration > 0 && _age < fadeInDuration) {
      fade = _age / fadeInDuration;
    } else if (fadeOutDuration > 0 && remaining < fadeOutDuration) {
      fade = remaining / fadeOutDuration;
    }

    final pulse = 0.9 + math.sin(_age * math.pi * 3.0) * 0.1;
    final alpha = (opacityAlpha * fade * pulse).round().clamp(0, 255);
    paint.color = Color.fromARGB(alpha, 255, 255, 255);
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
