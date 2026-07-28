import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../pixel_crawler_game.dart';
import 'dungeon_renderer.dart';

/// Base class for the player and monsters: sprite-strip animation, drop
/// shadow, grid collision and y-sorted depth (the 2.5D ordering).
abstract class GameCharacter extends SpriteAnimationComponent
    with HasGameReference<PixelCrawlerGame> {
  GameCharacter({
    required Vector2 position,
    required Vector2 frameSize,
    required this.maxHp,
  })  : hp = maxHp,
        super(
          position: position,
          size: frameSize,
          anchor: Anchor.bottomCenter,
        );

  int maxHp;
  int hp;

  /// Feet collision box (world units), centred on [position].
  double get feetWidth => 9;
  double get feetHeight => 5;

  double _flashTime = 0;
  bool get isDead => hp <= 0;

  static final _shadowPaint = ui.Paint()..color = const ui.Color(0x66000000);
  static final _flashPaint = ui.Paint()
    ..colorFilter =
        const ui.ColorFilter.mode(ui.Color(0xCCFFFFFF), ui.BlendMode.srcATop);

  bool _canStand(double cx, double cy) {
    final hw = feetWidth / 2;
    for (final p in [
      (cx - hw, cy - feetHeight),
      (cx + hw, cy - feetHeight),
      (cx - hw, cy),
      (cx + hw, cy),
    ]) {
      if (!game.map.isWalkable(p.$1 ~/ tileSize, p.$2 ~/ tileSize)) {
        return false;
      }
    }
    return !game.solidBlocksFeet(cx, cy, feetWidth, feetHeight);
  }

  /// Axis-separated movement against the tile grid; returns the applied delta.
  Vector2 moveAndCollide(Vector2 delta) {
    final applied = Vector2.zero();
    if (delta.x != 0 && _canStand(position.x + delta.x, position.y)) {
      position.x += delta.x;
      applied.x = delta.x;
    }
    if (delta.y != 0 && _canStand(position.x, position.y + delta.y)) {
      position.y += delta.y;
      applied.y = delta.y;
    }
    return applied;
  }

  void faceDirection(double dx) {
    if (dx > 0 && scale.x < 0) scale.x = 1;
    if (dx < 0 && scale.x > 0) scale.x = -1;
  }

  /// Returns true if the hit killed the character.
  bool receiveDamage(int amount) {
    if (isDead) return false;
    hp -= amount;
    _flashTime = 0.12;
    game.spawnDamageText(amount, position - Vector2(0, size.y));
    if (isDead) {
      onDeath();
      return true;
    }
    return false;
  }

  void onDeath();

  @override
  void update(double dt) {
    super.update(dt);
    if (_flashTime > 0) _flashTime -= dt;
    priority = (position.y * 10).round();
  }

  @override
  void render(ui.Canvas canvas) {
    // Drop shadow under the feet (local space: feet at (width/2, height)).
    canvas.drawOval(
      ui.Rect.fromCenter(
        center: ui.Offset(size.x / 2, size.y - 1),
        width: feetWidth + 3,
        height: 4,
      ),
      _shadowPaint,
    );
    super.render(canvas);
    if (_flashTime > 0) {
      final prev = paint;
      paint = _flashPaint;
      super.render(canvas);
      paint = prev;
    }
  }
}
