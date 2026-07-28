import 'dart:ui';

import 'package:flame/components.dart';

/// Marks a world object that blocks feet movement and projectiles.
mixin SolidObstacle on PositionComponent {
  /// Width / height of the feet-level solid box, centred on [position].
  double get solidWidth => 10;
  double get solidHeight => 8;

  Rect get solidRect {
    // Components that use Anchor.bottomCenter have their feet at [position].
    final cy = position.y - solidHeight / 2;
    return Rect.fromCenter(
      center: Offset(position.x, cy),
      width: solidWidth,
      height: solidHeight,
    );
  }

  bool overlapsFeet(double cx, double cy, double feetW, double feetH) {
    final feet = Rect.fromCenter(
      center: Offset(cx, cy - feetH / 2),
      width: feetW,
      height: feetH,
    );
    return solidRect.overlaps(feet);
  }

  bool containsWorldPoint(Vector2 point) =>
      solidRect.contains(Offset(point.x, point.y));
}
