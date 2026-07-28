import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../pixel_crawler_game.dart';
import 'dungeon_renderer.dart';
import 'monster.dart';

/// Short-lived slash arc that damages monsters in front of the player.
class MeleeSwing extends SpriteAnimationComponent
    with HasGameReference<PixelCrawlerGame> {
  MeleeSwing({
    required Vector2 origin,
    required this.direction,
    required this.damage,
  }) : super(
          position: origin + direction * 12,
          size: Vector2.all(16),
          anchor: Anchor.center,
          angle: atan2(direction.y, direction.x),
          removeOnFinish: true,
        );

  final Vector2 direction;
  final int damage;
  static const hitRadius = 15.0;

  @override
  Future<void> onLoad() async {
    animation = GameAssets.slash.animation(loop: false);
    priority = (position.y * 10).round() + 5;
    for (final m in game.world.children.query<Monster>()) {
      if (!m.isActivated) continue;
      final feet = m.position - Vector2(0, m.size.y / 2);
      if (feet.distanceTo(position) <= hitRadius) {
        m.receiveDamage(damage);
      }
    }
  }
}

/// Arrow / fireball / bone shot travelling in a straight line.
class Projectile extends SpriteAnimationComponent
    with HasGameReference<PixelCrawlerGame> {
  Projectile._({
    required Vector2 origin,
    required Vector2 direction,
    required this.damage,
    required this.speed,
    required this.splashRadius,
    required this.maxRange,
  })  : velocity = direction * speed,
        _start = origin.clone(),
        super(
          position: origin.clone(),
          size: Vector2.all(16),
          anchor: Anchor.center,
          angle: atan2(direction.y, direction.x),
        );

  factory Projectile.arrow({
    required Vector2 origin,
    required Vector2 direction,
    required int damage,
  }) {
    return Projectile._(
      origin: origin,
      direction: direction,
      damage: damage,
      speed: 230,
      splashRadius: 0,
      maxRange: 170,
    ).._spec = GameAssets.arrow;
  }

  factory Projectile.fireball({
    required Vector2 origin,
    required Vector2 direction,
    required int damage,
  }) {
    return Projectile._(
      origin: origin,
      direction: direction,
      damage: damage,
      speed: 140,
      splashRadius: 22,
      maxRange: 150,
    ).._animSpec = GameAssets.fireball;
  }

  factory Projectile.bone({
    required Vector2 origin,
    required Vector2 direction,
    required int damage,
  }) {
    return Projectile._(
      origin: origin,
      direction: direction,
      damage: damage,
      speed: 180,
      splashRadius: 0,
      maxRange: 160,
    ).._spec = GameAssets.bone;
  }

  final Vector2 velocity;
  final int damage;
  final double speed;
  final double splashRadius;
  final double maxRange;
  final Vector2 _start;

  SpriteSpec? _spec;
  AnimSpec? _animSpec;

  @override
  Future<void> onLoad() async {
    if (_animSpec != null) {
      animation = _animSpec!.animation();
    } else if (_spec != null) {
      animation = SpriteAnimation.spriteList([_spec!.sprite()], stepTime: 1);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    priority = (position.y * 10).round() + 5;

    if (position.distanceTo(_start) > maxRange ||
        game.map.blocksProjectile(
            position.x ~/ tileSize, position.y ~/ tileSize) ||
        game.solidBlocksPoint(position)) {
      _explode(hit: null);
      return;
    }

    for (final m in game.world.children.query<Monster>()) {
      if (!m.isActivated) continue;
      final feet = m.position - Vector2(0, m.size.y / 2);
      if (feet.distanceTo(position) < 9) {
        _explode(hit: m);
        return;
      }
    }
  }

  void _explode({Monster? hit}) {
    if (splashRadius > 0) {
      for (final m in game.world.children.query<Monster>()) {
        if (!m.isActivated) continue;
        final feet = m.position - Vector2(0, m.size.y / 2);
        if (feet.distanceTo(position) <= splashRadius) {
          m.receiveDamage(damage);
        }
      }
      game.world.add(ExplosionPuff(position: position.clone(), radius: splashRadius));
    } else {
      hit?.receiveDamage(damage);
    }
    removeFromParent();
  }
}

/// Hostile shot aimed at the player (arrows / dark bolts).
class EnemyProjectile extends SpriteAnimationComponent
    with HasGameReference<PixelCrawlerGame> {
  EnemyProjectile({
    required Vector2 origin,
    required Vector2 direction,
    required this.damage,
    this.speed = 160,
    this.maxRange = 150,
    this._spec,
    this._animSpec,
  })  : velocity = direction.normalized() * speed,
        _start = origin.clone(),
        super(
          position: origin.clone(),
          size: Vector2.all(16),
          anchor: Anchor.center,
          angle: atan2(direction.y, direction.x),
        );

  factory EnemyProjectile.arrow({
    required Vector2 origin,
    required Vector2 direction,
    required int damage,
  }) {
    return EnemyProjectile(
      origin: origin,
      direction: direction,
      damage: damage,
      speed: 170,
      spec: GameAssets.arrow,
    );
  }

  factory EnemyProjectile.bolt({
    required Vector2 origin,
    required Vector2 direction,
    required int damage,
  }) {
    return EnemyProjectile(
      origin: origin,
      direction: direction,
      damage: damage,
      speed: 130,
      maxRange: 140,
      animSpec: GameAssets.fireball,
    );
  }

  final Vector2 velocity;
  final int damage;
  final double speed;
  final double maxRange;
  final Vector2 _start;
  final SpriteSpec? _spec;
  final AnimSpec? _animSpec;

  @override
  Future<void> onLoad() async {
    if (_animSpec != null) {
      animation = _animSpec!.animation();
    } else if (_spec != null) {
      animation = SpriteAnimation.spriteList([_spec!.sprite()], stepTime: 1);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    position += velocity * dt;
    priority = (position.y * 10).round() + 5;

    if (position.distanceTo(_start) > maxRange ||
        game.map.blocksProjectile(
            position.x ~/ tileSize, position.y ~/ tileSize) ||
        game.solidBlocksPoint(position)) {
      removeFromParent();
      return;
    }

    final player = game.player;
    if (player != null && !player.isDead) {
      final feet = player.position - Vector2(0, player.size.y / 2);
      if (feet.distanceTo(position) < 9) {
        player.receiveContactDamage(damage);
        removeFromParent();
      }
    }
  }
}

/// Quick expanding ring shown when a fireball / bomb detonates.
class ExplosionPuff extends PositionComponent {
  ExplosionPuff({required Vector2 position, required this.radius})
      : super(position: position, anchor: Anchor.center);

  final double radius;
  double _t = 0;
  static const _life = 0.25;

  @override
  void update(double dt) {
    _t += dt;
    priority = (position.y * 10).round() + 6;
    if (_t >= _life) removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    final k = (_t / _life).clamp(0.0, 1.0);
    final paint = ui.Paint()
      ..color = ui.Color.fromARGB(((1 - k) * 200).round(), 0xB9, 0xDD, 0xA7)
      ..style = ui.PaintingStyle.stroke
      ..strokeWidth = 3 * (1 - k) + 1;
    canvas.drawCircle(ui.Offset.zero, radius * k, paint);
  }
}
