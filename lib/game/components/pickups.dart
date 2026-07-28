import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../pixel_crawler_game.dart';
import 'player.dart';
import 'solid_obstacle.dart';

/// Base for items collected by touching them.
abstract class Pickup extends SpriteAnimationComponent
    with HasGameReference<PixelCrawlerGame> {
  Pickup({required Vector2 position, this.pickupRadius = 10})
      : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.bottomCenter,
        );

  final double pickupRadius;
  double _bobT = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _bobT += dt;
    priority = (position.y * 10).round();
    final player = game.player;
    if (player != null && !player.isDead &&
        player.position.distanceTo(position) < pickupRadius) {
      onCollected(player);
      removeFromParent();
    }
  }

  void onCollected(Player player);

  @override
  void render(ui.Canvas canvas) {
    canvas.save();
    canvas.translate(0, sin(_bobT * 4) * 1.2 - 1);
    super.render(canvas);
    canvas.restore();
  }
}

class CoinPickup extends Pickup {
  CoinPickup({required super.position});

  @override
  Future<void> onLoad() async {
    animation = GameAssets.coin.animation();
  }

  @override
  void onCollected(Player player) => game.addCoins(1);
}

class PotionPickup extends Pickup {
  PotionPickup.red({required super.position}) : _blue = false;
  PotionPickup.blue({required super.position}) : _blue = true;

  final bool _blue;

  @override
  Future<void> onLoad() async {
    final spec = _blue ? GameAssets.potionBlue : GameAssets.potionRed;
    animation = SpriteAnimation.spriteList([spec.sprite()], stepTime: 1);
  }

  @override
  void onCollected(Player player) {
    if (_blue) {
      // Permanent (for this run) +1 heart, and heals it too.
      SessionBonus.extraHp += 2;
      game.raiseMaxHp(2);
    } else {
      player.heal(2);
    }
  }
}

/// Opens on touch and pops out loot. Blocks movement until opened.
class Chest extends SpriteComponent
    with HasGameReference<PixelCrawlerGame>, SolidObstacle {
  Chest({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.bottomCenter,
        );

  bool _open = false;
  final _rng = Random();

  @override
  double get solidWidth => 12;
  @override
  double get solidHeight => 10;

  @override
  Future<void> onLoad() async {
    sprite = GameAssets.chest.frame(0);
    priority = (position.y * 10).round();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_open) return;
    final player = game.player;
    if (player != null && player.position.distanceTo(position) < 16) {
      _open = true;
      sprite = GameAssets.chest.frame(1);
      final n = 2 + _rng.nextInt(3);
      for (var i = 0; i < n; i++) {
        game.world.add(CoinPickup(
          position: position +
              Vector2((_rng.nextDouble() - 0.5) * 20, 4 + _rng.nextDouble() * 8),
        ));
      }
      if (_rng.nextDouble() < 0.35) {
        game.world.add(PotionPickup.blue(
          position: position + Vector2(0, 14),
        ));
      }
    }
  }
}

/// Stairs to the next floor.
class StairsTrigger extends PositionComponent
    with HasGameReference<PixelCrawlerGame> {
  StairsTrigger({required Vector2 position})
      : super(position: position, size: Vector2.all(16), anchor: Anchor.center);

  bool _used = false;

  @override
  void update(double dt) {
    super.update(dt);
    if (_used) return;
    final player = game.player;
    if (player != null && !player.isDead &&
        player.position.distanceTo(position) < 8) {
      _used = true;
      game.goToNextFloor();
    }
  }
}

/// Animated torch baked into a south-facing wall tile (drawn over the
/// baked wall).
class Torch extends SpriteAnimationComponent {
  Torch({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.topLeft,
          priority: -9998,
        );

  @override
  Future<void> onLoad() async {
    animation = GameAssets.torchWall.animation();
    animationTicker?.clock = Random().nextDouble();
  }
}

/// Standing burning fire pot: a light source placed on the floor,
/// y-sorted with the other entities. Blocks movement and projectiles.
class FirePot extends SpriteAnimationComponent with SolidObstacle {
  FirePot({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.bottomCenter,
        );

  @override
  double get solidWidth => 10;
  @override
  double get solidHeight => 9;

  @override
  Future<void> onLoad() async {
    animation = GameAssets.firePot.animation();
    animationTicker?.clock = Random().nextDouble();
    priority = (position.y * 10).round();
  }
}

/// Static decorative prop (barrel, crate, bones...), y-sorted.
///
/// Chunkier props ([solid] = true) block feet and projectiles; flat floor
/// litter like skulls and bones does not.
class Decor extends SpriteComponent with SolidObstacle {
  Decor({
    required Vector2 position,
    required this.spec,
    this.solid = true,
  }) : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.bottomCenter,
        );

  final SpriteSpec spec;
  final bool solid;

  @override
  double get solidWidth => solid ? 11 : 0;
  @override
  double get solidHeight => solid ? 9 : 0;

  @override
  ui.Rect get solidRect {
    if (!solid) return ui.Rect.zero;
    return super.solidRect;
  }

  @override
  Future<void> onLoad() async {
    sprite = spec.sprite();
    priority = (position.y * 10).round();
  }
}
