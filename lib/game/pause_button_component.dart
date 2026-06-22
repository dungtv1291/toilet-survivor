import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

class PauseButtonComponent extends PositionComponent with TapCallbacks {
  PauseButtonComponent({
    required this.onPressed,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size, priority: 120);

  final VoidCallback onPressed;
  final Paint _backgroundPaint = Paint()..color = const Color(0xB40B1512);
  final Paint _borderPaint = Paint()
    ..color = const Color(0xCC7EE631)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.3;
  final Paint _innerBorderPaint = Paint()
    ..color = const Color(0x55304A28)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1;
  final Paint _iconPaint = Paint()..color = const Color(0xFFFFF5C8);
  final Paint _iconShadowPaint = Paint()..color = const Color(0xFF1B1207);

  bool _pressed = false;

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    _pressed = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    _pressed = false;
    onPressed();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    super.onTapCancel(event);
    _pressed = false;
  }

  @override
  void render(Canvas canvas) {
    final rect = Offset.zero & Size(size.x, size.y);
    final radius = Radius.circular(size.x * 0.16);
    final panelRect = RRect.fromRectAndRadius(rect, radius);
    final iconInsetX = size.x * 0.31;
    final iconInsetY = size.y * 0.27;
    final barWidth = size.x * 0.11;
    final barHeight = size.y * 0.44;
    final gap = size.x * 0.14;
    final pressOffset = _pressed ? Offset(1, 1) : Offset.zero;

    canvas
      ..save()
      ..translate(pressOffset.dx, pressOffset.dy)
      ..drawRRect(panelRect, _backgroundPaint)
      ..drawRRect(panelRect.deflate(1), _borderPaint)
      ..drawRRect(panelRect.deflate(4), _innerBorderPaint);

    final firstShadow = Rect.fromLTWH(
      iconInsetX + 1,
      iconInsetY + 1,
      barWidth,
      barHeight,
    );
    final secondShadow = firstShadow.translate(barWidth + gap, 0);
    final firstBar = firstShadow.translate(-1, -1);
    final secondBar = secondShadow.translate(-1, -1);

    canvas
      ..drawRect(firstShadow, _iconShadowPaint)
      ..drawRect(secondShadow, _iconShadowPaint)
      ..drawRect(firstBar, _iconPaint)
      ..drawRect(secondBar, _iconPaint)
      ..restore();
  }
}
