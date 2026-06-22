import 'package:flame/components.dart';

class PoopSplatEffect extends SpriteComponent {
  PoopSplatEffect({
    required Sprite sprite,
    required Vector2 position,
    required Vector2 size,
    this.lifetime = 0.7,
    double angle = 0,
    int priority = 6,
  }) : super(
         sprite: sprite,
         anchor: Anchor.center,
         position: position,
         size: size,
         angle: angle,
         priority: priority,
       );

  double lifetime;

  @override
  void update(double dt) {
    super.update(dt);

    lifetime -= dt;
    if (lifetime <= 0) {
      removeFromParent();
    }
  }
}
