import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';
import '../monsters.dart';
import '../pixel_crawler_game.dart';
import 'attacks.dart';
import 'monster.dart';
import 'player.dart';
import 'shop_pedestal.dart';
import 'solid_obstacle.dart';
import 'dungeon_renderer.dart';

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
  CoinPickup({
    required super.position,
    this.autoCollect = false,
  });

  /// Monster drops fly to the player (also recovers coins that land in pits).
  final bool autoCollect;
  static const _magnetSpeed = 110.0;

  @override
  Future<void> onLoad() async {
    animation = GameAssets.coin.animation();
  }

  @override
  void update(double dt) {
    final player = game.player;
    if (autoCollect && player != null && !player.isDead) {
      final toPlayer = player.position - position;
      final dist = toPlayer.length;
      if (dist < 4) {
        onCollected(player);
        removeFromParent();
        return;
      }
      position += toPlayer.normalized() * _magnetSpeed * dt;
      priority = (position.y * 10).round();
      return;
    }

    // Coins sitting in pits are unreachable on foot.
    if (!autoCollect) {
      final tx = position.x ~/ tileSize;
      final ty = position.y ~/ tileSize;
      if (game.map.tileAt(tx, ty) == TileType.pit) {
        priority = (position.y * 10).round();
        return;
      }
    }
    super.update(dt);
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

/// Lit bomb dropped from chests. Explodes after [fuse] seconds and can kill
/// the player (and nearby monsters).
class BombPickup extends SpriteAnimationComponent
    with HasGameReference<PixelCrawlerGame> {
  BombPickup({required Vector2 position, this.fuse = 1.3})
      : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.bottomCenter,
        );

  final double fuse;
  double _t = 0;
  static const blastRadius = 28.0;
  static const blastDamage = 99;

  @override
  Future<void> onLoad() async {
    animation = GameAssets.bomb.animation(stepTimeOverride: 0.12);
    priority = (position.y * 10).round() + 2;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _t += dt;
    priority = (position.y * 10).round() + 2;
    // Speed up blink as fuse runs out.
    final remaining = (fuse - _t).clamp(0.0, fuse);
    animationTicker?.clock;
    if (_t >= fuse) {
      _detonate();
    } else if (remaining < 0.5) {
      opacity = ((_t * 16).floor().isOdd) ? 0.35 : 1;
    }
  }

  void _detonate() {
    game.world.add(ExplosionPuff(position: position.clone(), radius: blastRadius));
    final player = game.player;
      if (player != null && !player.isDead) {
      if (player.position.distanceTo(position) <= blastRadius) {
        // Bombs ignore brief invulnerability frames and can one-shot.
        player.receiveDamage(blastDamage);
        game.hpNotifier.value = player.hp;
      }
    }
    for (final m in game.world.children.query<Monster>().toList()) {
      if (m.position.distanceTo(position) <= blastRadius) {
        m.receiveDamage(blastDamage);
      }
    }
    removeFromParent();
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
      final toward = player.position - position;
      final dir = toward.length2 > 0.01
          ? toward.normalized()
          : Vector2(0, 1);
      Vector2 toss(double dist, [double side = 0]) {
        final perp = Vector2(-dir.y, dir.x) * side;
        return position + dir * dist + perp;
      }

      final n = 2 + _rng.nextInt(3);
      for (var i = 0; i < n; i++) {
        final side = (_rng.nextDouble() - 0.5) * 14;
        game.world.add(CoinPickup(
          position: toss(10 + _rng.nextDouble() * 10, side),
        ));
      }
      // No blue (max-HP) potions from chests — only healing reds.
      if (_rng.nextDouble() < 0.30) {
        game.world.add(PotionPickup.red(
          position: toss(14, (_rng.nextDouble() - 0.5) * 8),
        ));
      }
      if (_rng.nextDouble() < 0.28) {
        game.world.add(BombPickup(
          position: toss(12, (_rng.nextDouble() - 0.5) * 10),
        ));
      }
      if (_rng.nextDouble() < 0.45) {
        game.world.add(KeyPickup(
          position: toss(11, (_rng.nextDouble() - 0.5) * 8),
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
      // Stairs require the boss key dropped by the floor boss.
      if (!game.tryUseBossKey()) return;
      _used = true;
      game.goToNextFloor();
    }
  }
}

/// Animated torch overlay on a south wall (`wall_bottom` / torch_wall art).
class Torch extends SpriteAnimationComponent {
  Torch({required Vector2 position})
      : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.topLeft,
          // Above baked walls, below the hero and door frames.
          priority: -9990,
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

/// Static decorative prop (barrel, crate, table, skull, bones...), y-sorted.
///
/// All decor kinds block feet and projectiles. Skulls and bones may
/// transmute into a skeleton while the player lingers in the same room
/// (1-in-10 chance each check).
class Decor extends SpriteComponent
    with HasGameReference<PixelCrawlerGame>, SolidObstacle {
  Decor({
    required Vector2 position,
    required this.spec,
    this.kind = 0,
  }) : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.bottomCenter,
        );

  final SpriteSpec spec;

  /// Index into [GameAssets.decor] (3 = skull, 4 = bone).
  final int kind;

  final _rng = Random();
  double _transformTimer = 0;
  bool _transformed = false;

  bool get isBoneLitter => kind >= 3;

  @override
  double get solidWidth => 11;
  @override
  double get solidHeight => 9;

  @override
  Future<void> onLoad() async {
    sprite = spec.sprite();
    priority = (position.y * 10).round();
    _transformTimer = 2 + _rng.nextDouble() * 3;
  }

  @override
  void update(double dt) {
    super.update(dt);
    priority = (position.y * 10).round();
    if (!isBoneLitter || _transformed) return;

    final player = game.player;
    if (player == null || player.isDead) return;

    // Only roll while the player shares this room.
    if (!game.playerSharesRoomWith(position)) return;

    _transformTimer -= dt;
    if (_transformTimer > 0) return;
    _transformTimer = 4 + _rng.nextDouble() * 4;

    // 1-in-10 chance to become a random available skeleton.
    if (_rng.nextInt(10) != 0) return;

    _transformed = true;
    final type = skeletonVariants[_rng.nextInt(skeletonVariants.length)];
    game.world.add(Monster(
      def: monsters[type]!,
      position: position.clone(),
      floor: game.floor,
    ));
    removeFromParent();
  }
}
