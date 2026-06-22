import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HudPanelComponent extends PositionComponent {
  HudPanelComponent({
    required this.cornerSprite,
    required this.slimeDripSprite,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, priority: 99);

  static const Color normalColor = Color(0xCC0B1512);
  static const Color damageColor = Color(0xDD4A1515);

  final Sprite cornerSprite;
  final Sprite slimeDripSprite;
  final Paint _backgroundPaint = Paint()..color = normalColor;
  final Paint _borderPaint = Paint()
    ..color = const Color(0xBB7EE631)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;
  final Paint _innerBorderPaint = Paint()
    ..color = const Color(0x55304A28)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _cornerPaint = Paint()..filterQuality = FilterQuality.none;
  final Paint _dripPaint = Paint()
    ..filterQuality = FilterQuality.none
    ..color = const Color(0xBFFFFFFF);

  set color(Color color) {
    _backgroundPaint.color = color;
  }

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & Size(size.x, size.y);
    canvas
      ..drawRect(rect, _backgroundPaint)
      ..drawRect(rect.deflate(1), _borderPaint)
      ..drawRect(rect.deflate(4), _innerBorderPaint);

    final cornerSize = Vector2(size.y * 0.34, size.y * 0.40);
    _renderCorner(canvas, cornerSize, const Offset(1, 1), false, false);
    _renderCorner(
      canvas,
      cornerSize,
      Offset(size.x - cornerSize.x - 1, 1),
      true,
      false,
    );

    final topDripSize = Vector2(size.y * 0.30, size.y * 0.36);
    slimeDripSprite.render(
      canvas,
      position: Vector2(size.x * 0.70, 0),
      size: topDripSize,
      overridePaint: _dripPaint,
    );
  }

  void _renderCorner(
    Canvas canvas,
    Vector2 cornerSize,
    Offset offset,
    bool flipX,
    bool flipY,
  ) {
    canvas.save();
    canvas.translate(offset.dx + (flipX ? cornerSize.x : 0), offset.dy);
    canvas.scale(flipX ? -1 : 1, flipY ? -1 : 1);
    if (flipY) {
      canvas.translate(0, -cornerSize.y);
    }
    cornerSprite.render(canvas, size: cornerSize, overridePaint: _cornerPaint);
    canvas.restore();
  }
}
