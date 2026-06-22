import 'dart:ui';

import 'package:flame/components.dart';
import 'package:toilet_survivor/config/game_config.dart';

enum Direction { front, left, right, back }

class Player extends SpriteAnimationComponent {
  Player({
    required Map<Direction, SpriteAnimation> idleAnimations,
    required Map<Direction, SpriteAnimation> walkAnimations,
    required this.joystick,
    required Vector2 position,
  }) : _idleAnimations = idleAnimations,
       _walkAnimations = walkAnimations,
       hp = GameConfig.playerMaxHp,
       super(
         animation: idleAnimations[Direction.front],
         anchor: Anchor.center,
         position: position,
         size: Vector2.all(GameConfig.playerSize),
         priority: 10,
       );

  final JoystickComponent joystick;
  final Map<Direction, SpriteAnimation> _idleAnimations;
  final Map<Direction, SpriteAnimation> _walkAnimations;
  double hp;
  final Vector2 previousPosition = Vector2.zero();
  final Vector2 lastMoveDirection = Vector2(0, 1);
  Direction facing = Direction.front;
  bool movedThisFrame = false;
  bool _isMoving = false;
  final Vector2 _slideVelocity = Vector2.zero();
  double _slideTime = 0;
  double _damageFlashTimer = 0;
  double _invincibilityTimer = 0;

  bool get isInvincible => _invincibilityTimer > 0;

  @override
  void update(double dt) {
    super.update(dt);

    if (_damageFlashTimer > 0) {
      _damageFlashTimer -= dt;
    }
    if (_invincibilityTimer > 0) {
      _invincibilityTimer -= dt;
    }

    _updateColorFilter();
  }

  void updateControlledMovement(
    double dt,
    bool Function(Vector2 position) isBlocked,
  ) {
    final movement = joystick.relativeDelta.clone();
    final joystickIsMoving = movement.length2 > 0.04;
    final movementDelta = Vector2.zero();
    movedThisFrame = false;

    if (joystickIsMoving) {
      movement.normalize();
      lastMoveDirection.setFrom(movement);
      facing = directionFromVector(movement, fallback: facing);
      movementDelta.add(movement * GameConfig.playerSpeed * dt);
    }

    if (_slideTime > 0) {
      final slideFactor = (_slideTime / GameConfig.sludgeSlideDuration).clamp(
        0.0,
        1.0,
      );
      movementDelta.add(_slideVelocity * slideFactor * dt);
      _slideTime -= dt;
      if (_slideTime <= 0) {
        stopSlide();
      }
    }

    if (movementDelta.length2 > 0) {
      previousPosition.setFrom(position);
      _moveAxisSeparated(movementDelta, isBlocked);
    }

    _setAnimation(joystickIsMoving, facing);
  }

  bool takeDamage(double amount) {
    if (isInvincible || hp <= 0) {
      return false;
    }

    hp = (hp - amount).clamp(0, GameConfig.playerMaxHp).toDouble();
    _damageFlashTimer = GameConfig.playerDamageFlashDuration;
    _updateColorFilter();
    return true;
  }

  void startSlide(Vector2 direction) {
    final slideDirection = direction.clone();
    if (slideDirection.length2 == 0) {
      slideDirection.setFrom(lastMoveDirection);
    }
    if (slideDirection.length2 == 0) {
      slideDirection.setValues(0, 1);
    }

    slideDirection.normalize();
    lastMoveDirection.setFrom(slideDirection);
    _slideVelocity.setFrom(slideDirection * GameConfig.sludgeSlideSpeed);
    _slideTime = GameConfig.sludgeSlideDuration;
  }

  void stopSlide() {
    _slideVelocity.setZero();
    _slideTime = 0;
  }

  void revive(double hpAmount, {required double invincibilityDuration}) {
    hp = hpAmount.clamp(1, GameConfig.playerMaxHp).toDouble();
    _damageFlashTimer = 0;
    _invincibilityTimer = invincibilityDuration;
    stopSlide();
    _updateColorFilter();
  }

  void reset(Vector2 spawnPosition) {
    position = spawnPosition;
    previousPosition.setFrom(spawnPosition);
    lastMoveDirection.setValues(0, 1);
    movedThisFrame = false;
    _slideVelocity.setZero();
    _slideTime = 0;
    _damageFlashTimer = 0;
    _invincibilityTimer = 0;
    paint.colorFilter = null;
    hp = GameConfig.playerMaxHp;
    facing = Direction.front;
    _setAnimation(false, facing, force: true);
  }

  void revertToPreviousPosition() {
    position = previousPosition.clone();
    stopSlide();
    movedThisFrame = false;
  }

  void _moveAxisSeparated(
    Vector2 movementDelta,
    bool Function(Vector2 position) isBlocked,
  ) {
    var xBlocked = false;
    var yBlocked = false;

    if (movementDelta.x != 0) {
      final nextPosition = position.clone()..x += movementDelta.x;
      _clampPosition(nextPosition);
      if (isBlocked(nextPosition)) {
        xBlocked = true;
      } else if (nextPosition.x != position.x) {
        position.x = nextPosition.x;
        movedThisFrame = true;
      }
    }

    if (movementDelta.y != 0) {
      final nextPosition = position.clone()..y += movementDelta.y;
      _clampPosition(nextPosition);
      if (isBlocked(nextPosition)) {
        yBlocked = true;
      } else if (nextPosition.y != position.y) {
        position.y = nextPosition.y;
        movedThisFrame = true;
      }
    }

    if (xBlocked) {
      _slideVelocity.x = 0;
    }
    if (yBlocked) {
      _slideVelocity.y = 0;
    }
    if (_slideVelocity.length2 == 0) {
      _slideTime = 0;
    }
  }

  void _setAnimation(
    bool nextIsMoving,
    Direction nextDirection, {
    bool force = false,
  }) {
    final animationDirection = nextDirection == Direction.right
        ? Direction.left
        : nextDirection;
    final nextAnimation = nextIsMoving
        ? _walkAnimations[animationDirection]
        : _idleAnimations[animationDirection];
    final shouldFlip = nextDirection == Direction.right;

    // The sheet's right-facing column is unreliable, so right uses the
    // left/side frames mirrored around the centered anchor.
    scale.x = shouldFlip ? -scale.x.abs() : scale.x.abs();

    if (force || _isMoving != nextIsMoving || animation != nextAnimation) {
      _isMoving = nextIsMoving;
      animation = nextAnimation;
      animationTicker?.reset();
    }

    playing = nextIsMoving;
  }

  void _updateColorFilter() {
    if (_damageFlashTimer > 0) {
      paint.colorFilter = const ColorFilter.mode(
        Color(0x99FF3A3A),
        BlendMode.srcATop,
      );
      return;
    }

    if (_invincibilityTimer > 0) {
      final blinkIsVisible = (_invincibilityTimer * 12).floor().isEven;
      paint.colorFilter = blinkIsVisible
          ? const ColorFilter.mode(Color(0x77DFFFF2), BlendMode.srcATop)
          : null;
      return;
    }

    paint.colorFilter = null;
  }

  void _clampPosition(Vector2 targetPosition) {
    final halfSize = GameConfig.playerSize / 2;
    targetPosition
      ..x = targetPosition.x
          .clamp(halfSize, GameConfig.worldWidth - halfSize)
          .toDouble()
      ..y = targetPosition.y
          .clamp(halfSize, GameConfig.worldHeight - halfSize)
          .toDouble();
  }
}

Direction directionFromVector(
  Vector2 vector, {
  Direction fallback = Direction.front,
}) {
  final dx = vector.x;
  final dy = vector.y;
  final absDx = dx.abs();

  if (dy > absDx) {
    return Direction.front;
  }
  if (-dy > absDx) {
    return Direction.back;
  }
  if (dx > 0) {
    return Direction.right;
  }
  if (dx < 0) {
    return Direction.left;
  }
  return fallback;
}
