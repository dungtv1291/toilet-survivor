import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:toilet_survivor/config/game_config.dart';
import 'package:toilet_survivor/game/player.dart';

enum EnemyType { basic, snake, boss }

typedef EnemyBlockedCheck = bool Function(Vector2 position, double radius);

class EnemyStats {
  const EnemyStats({
    required this.size,
    required this.speed,
    required this.hp,
    required this.radius,
    required this.score,
  });

  final Vector2 size;
  final double speed;
  final double hp;
  final double radius;
  final int score;
}

class Enemy extends SpriteAnimationComponent {
  Enemy({
    required this.type,
    required this.directionAnimations,
    required this.mirroredDirections,
    required this.stats,
    required this.target,
    this.isBlocked,
    required Vector2 position,
  }) : hp = stats.hp,
       super(
         animation: directionAnimations[Direction.front],
         anchor: Anchor.center,
         position: position,
         size: stats.size.clone(),
         priority: 8,
       );

  final EnemyType type;
  final Map<Direction, SpriteAnimation> directionAnimations;
  final Set<Direction> mirroredDirections;
  final EnemyStats stats;
  final Player target;
  final EnemyBlockedCheck? isBlocked;
  double hp;
  double visualEffectTimer = 0;
  double hazardTimer = 0;
  bool lowHpStinkEmitted = false;
  double _contactCooldown = 0;
  Direction facing = Direction.front;

  final Paint _hpBackPaint = Paint()..color = const Color(0xCC210707);
  final Paint _hpFillPaint = Paint()..color = const Color(0xFFE53935);
  final Paint _hpBorderPaint = Paint()
    ..color = const Color(0xEEFFF0F0)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;

  bool get isDead => hp <= 0;
  bool get canDamagePlayer => _contactCooldown <= 0;

  @override
  void update(double dt) {
    super.update(dt);

    _contactCooldown -= dt;

    final movement = target.position - position;
    if (movement.length2 == 0) {
      playing = false;
      return;
    }

    movement.normalize();
    final nextFacing = _directionFromMovement(movement);
    if (nextFacing != facing) {
      facing = nextFacing;
      final nextAnimation = directionAnimations[facing];
      if (animation != nextAnimation) {
        animation = nextAnimation;
      }
    }

    scale.x = mirroredDirections.contains(facing)
        ? -scale.x.abs()
        : scale.x.abs();
    playing = true;
    final movementDelta = movement * stats.speed * dt;
    final blockedCheck = isBlocked;
    if (blockedCheck == null) {
      position += movementDelta;
    } else {
      _moveAxisSeparated(movementDelta, blockedCheck);
    }
  }

  @override
  void render(Canvas canvas) {
    if (type == EnemyType.snake) {
      _renderSnakeFrame(canvas);
    } else {
      super.render(canvas);
    }

    if (type == EnemyType.boss) {
      _renderBossHpBar(canvas);
    }
  }

  void takeDamage(double amount) {
    hp -= amount;
  }

  void markDamageDealt() {
    _contactCooldown = GameConfig.enemyContactCooldown;
  }

  void _moveAxisSeparated(
    Vector2 movementDelta,
    EnemyBlockedCheck blockedCheck,
  ) {
    final radius = stats.radius * GameConfig.enemyPropAvoidanceRadiusScale;
    var moved = false;
    var xBlocked = false;
    var yBlocked = false;

    if (movementDelta.x != 0) {
      final nextPosition = position.clone()..x += movementDelta.x;
      _clampPosition(nextPosition);
      if (blockedCheck(nextPosition, radius)) {
        xBlocked = true;
      } else if (nextPosition.x != position.x) {
        position.x = nextPosition.x;
        moved = true;
      }
    }

    if (movementDelta.y != 0) {
      final nextPosition = position.clone()..y += movementDelta.y;
      _clampPosition(nextPosition);
      if (blockedCheck(nextPosition, radius)) {
        yBlocked = true;
      } else if (nextPosition.y != position.y) {
        position.y = nextPosition.y;
        moved = true;
      }
    }

    if (!moved && xBlocked && yBlocked) {
      _trySideStep(movementDelta, radius, blockedCheck);
    }
  }

  void _trySideStep(
    Vector2 movementDelta,
    double radius,
    EnemyBlockedCheck blockedCheck,
  ) {
    if (movementDelta.length2 == 0) {
      return;
    }

    final sideStep = Vector2(-movementDelta.y, movementDelta.x);
    if (sideStep.length2 == 0) {
      return;
    }

    final leftCandidate = position + sideStep;
    final rightCandidate = position - sideStep;
    _clampPosition(leftCandidate);
    _clampPosition(rightCandidate);

    final leftIsBlocked = blockedCheck(leftCandidate, radius);
    final rightIsBlocked = blockedCheck(rightCandidate, radius);
    if (leftIsBlocked && rightIsBlocked) {
      return;
    }

    if (rightIsBlocked ||
        (!leftIsBlocked &&
            leftCandidate.distanceToSquared(target.position) <=
                rightCandidate.distanceToSquared(target.position))) {
      position.setFrom(leftCandidate);
      return;
    }

    position.setFrom(rightCandidate);
  }

  void _clampPosition(Vector2 targetPosition) {
    final halfWidth = size.x / 2;
    final halfHeight = size.y / 2;
    targetPosition
      ..x = targetPosition.x
          .clamp(halfWidth, GameConfig.worldWidth - halfWidth)
          .toDouble()
      ..y = targetPosition.y
          .clamp(halfHeight, GameConfig.worldHeight - halfHeight)
          .toDouble();
  }

  void _renderSnakeFrame(Canvas canvas) {
    final sprite = animationTicker?.getSprite();
    if (sprite == null) {
      return;
    }

    final sourceSize = sprite.srcSize;
    final renderBox = _snakeRenderBox();
    final fitScale = math.min(
      renderBox.x / sourceSize.x,
      renderBox.y / sourceSize.y,
    );
    final renderSize = Vector2(
      sourceSize.x * fitScale,
      sourceSize.y * fitScale,
    );
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

  Vector2 _snakeRenderBox() {
    return Vector2(
      GameConfig.snakeEnemySideWidth,
      GameConfig.snakeEnemySideHeight,
    );
  }

  Direction _directionFromMovement(Vector2 movement) {
    if (type != EnemyType.snake) {
      return directionFromVector(movement, fallback: facing);
    }

    if (movement.x > 0.02) {
      return Direction.right;
    }
    if (movement.x < -0.02) {
      return Direction.left;
    }
    return facing == Direction.left ? Direction.left : Direction.right;
  }

  void _renderBossHpBar(Canvas canvas) {
    final ratio = (hp / stats.hp).clamp(0, 1).toDouble();
    const barWidth = GameConfig.bossHpBarWidth;
    const barHeight = GameConfig.bossHpBarHeight;
    final left = (size.x - barWidth) / 2;
    final top = -GameConfig.bossHpBarOffsetY;
    final backgroundRect = Rect.fromLTWH(left, top, barWidth, barHeight);
    final fillRect = Rect.fromLTWH(left, top, barWidth * ratio, barHeight);
    final radius = Radius.circular(barHeight / 2);

    canvas
      ..drawRRect(RRect.fromRectAndRadius(backgroundRect, radius), _hpBackPaint)
      ..drawRRect(RRect.fromRectAndRadius(fillRect, radius), _hpFillPaint)
      ..drawRRect(
        RRect.fromRectAndRadius(backgroundRect, radius),
        _hpBorderPaint,
      );
  }
}
