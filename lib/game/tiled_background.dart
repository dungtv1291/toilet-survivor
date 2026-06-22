import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:toilet_survivor/config/game_config.dart';

class TiledBackground extends PositionComponent {
  TiledBackground({required this.tileSprite}) : super(priority: -100);

  Sprite? tileSprite;
  final Paint _fallbackPaint = Paint()..color = const Color(0xFF111A18);
  final Vector2 _tilePosition = Vector2.zero();
  final Vector2 _tileSize = Vector2.zero();

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final sprite = tileSprite;
    if (sprite == null) {
      canvas.drawRect(
        const Rect.fromLTWH(
          0,
          0,
          GameConfig.worldWidth,
          GameConfig.worldHeight,
        ),
        _fallbackPaint,
      );
      return;
    }

    final sourceSize = sprite.srcSize;
    final tileWidth = GameConfig.tileSize;
    final tileHeight = sourceSize.x == 0
        ? tileWidth
        : tileWidth * sourceSize.y / sourceSize.x;
    _tileSize.setValues(tileWidth, tileHeight);

    for (var y = 0.0; y < GameConfig.worldHeight; y += tileHeight) {
      for (var x = 0.0; x < GameConfig.worldWidth; x += tileWidth) {
        _tilePosition.setValues(x, y);
        sprite.render(canvas, position: _tilePosition, size: _tileSize);
      }
    }
  }
}
