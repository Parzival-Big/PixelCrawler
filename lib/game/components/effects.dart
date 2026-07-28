import 'package:flame/components.dart';
import 'package:flutter/painting.dart';

/// Damage number that floats up and fades out.
class FloatingText extends TextComponent {
  FloatingText({
    required String text,
    required Vector2 position,
    Color color = const Color(0xFFB9DDA7),
  }) : super(
          text: text,
          position: position,
          anchor: Anchor.bottomCenter,
          priority: 100000,
          textRenderer: TextPaint(
            style: TextStyle(
              fontFamily: 'PressStart2P',
              fontSize: 5,
              color: color,
              shadows: const [Shadow(color: Color(0xFF0E222B), offset: Offset(1, 1))],
            ),
          ),
        );

  double _t = 0;
  static const _life = 0.6;

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    position.y -= 18 * dt;
    if (_t >= _life) removeFromParent();
  }
}
