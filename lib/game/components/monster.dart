import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../monsters.dart';
import 'attacks.dart';
import 'dungeon_renderer.dart';
import 'game_character.dart';
import 'pickups.dart';
import 'shop_pedestal.dart';

class Monster extends GameCharacter {
  Monster({
    required this.def,
    required super.position,
    required int floor,
  })  : isBoss = def.type == MonsterType.boss,
        _floor = floor,
        super(
          frameSize: def.anim.size *
              (def.type == MonsterType.boss ? bossScale : 1.0),
          maxHp: def.baseHp + def.hpPerFloor * (floor - 1),
        );

  static const bossScale = 1.5;

  final MonsterDef def;
  final int _floor;
  final _rng = Random();

  bool isBoss;

  @override
  bool get blockedByDoors => true;

  @override
  bool get canFly => def.flies;

  @override
  double get feetWidth => isBoss ? 9 * bossScale : 9;

  @override
  double get feetHeight => isBoss ? 5 * bossScale : 5;

  double get _contactRange => isBoss ? 11 * bossScale : 11;

  double _contactTimer = 0;
  double _wanderTimer = 0;
  double _erraticPhase = 0;
  double _shotTimer = 0;
  Vector2 _wanderDir = Vector2.zero();

  /// True while the player is in the same room (Isaac-style activation).
  bool get isActivated {
    final room = game.currentRoom;
    if (room == null) return false;
    final info = game.map.roomInfoContaining(
      position.x ~/ tileSize,
      position.y ~/ tileSize,
    );
    return info?.gridKey == room.gridKey;
  }

  @override
  Future<void> onLoad() async {
    animation = def.anim.animation();
    _erraticPhase = _rng.nextDouble() * pi * 2;
    _shotTimer = _rng.nextDouble() * def.projectileCooldown;
    // Hidden until the first update confirms this is the active room.
    opacity = 0;
    animationTicker?.paused = true;
  }

  @override
  void update(double dt) {
    // Frozen + invisible until the player enters this room (no spoil through
    // doorways / letterbox edges).
    if (!isActivated) {
      opacity = 0;
      animationTicker?.paused = true;
      return;
    }
    opacity = 1;
    animationTicker?.paused = false;

    super.update(dt);
    final player = game.player;
    if (player == null || isDead || player.isDead) return;

    _contactTimer -= dt;
    _shotTimer -= dt;
    final toPlayer = player.position - position;
    final dist = toPlayer.length;

    Vector2 move;
    if (dist < def.aggroRange) {
      final dir = toPlayer.normalized();
      if (def.ranged) {
        // Keep preferred distance: close in if too far, back off if too close.
        if (dist > def.preferredRange + 12) {
          move = dir;
        } else if (dist < def.preferredRange - 12) {
          move = -dir;
        } else {
          move = Vector2(-dir.y, dir.x) * (_rng.nextBool() ? 1 : -1) * 0.35;
        }
        if (_shotTimer <= 0 && dist < def.aggroRange) {
          _shotTimer = def.projectileCooldown;
          _fireAt(dir);
        }
      } else {
        move = dir;
      }
      if (def.erratic) {
        _erraticPhase += dt * 6;
        final side = Vector2(-move.y, move.x)..scale(sin(_erraticPhase) * 0.7);
        move = (move + side)..normalize();
      }
    } else {
      _wanderTimer -= dt;
      if (_wanderTimer <= 0) {
        _wanderTimer = 1 + _rng.nextDouble() * 2;
        _wanderDir = _rng.nextBool()
            ? Vector2.zero()
            : (Vector2(_rng.nextDouble() - 0.5, _rng.nextDouble() - 0.5)
              ..normalize());
      }
      move = _wanderDir * 0.4;
    }

    if (move.length2 > 0) {
      moveAndCollide(move * def.speed * dt);
      faceDirection(move.x);
    }

    if (dist < _contactRange && _contactTimer <= 0) {
      _contactTimer = 0.8;
      player.receiveContactDamage(def.damage);
    }
  }

  void _fireAt(Vector2 dir) {
    final origin = position - Vector2(0, size.y / 2);
    switch (def.type) {
      case MonsterType.skeletonNecromancer:
        game.world.add(EnemyProjectile.bolt(
          origin: origin,
          direction: dir,
          damage: def.damage,
        ));
      case MonsterType.skeletonArcher:
      case MonsterType.flyingEye:
        game.world.add(EnemyProjectile.arrow(
          origin: origin,
          direction: dir,
          damage: def.damage,
        ));
      default:
        game.world.add(EnemyProjectile.arrow(
          origin: origin,
          direction: dir,
          damage: def.damage,
        ));
    }
  }

  @override
  bool receiveDamage(int amount) {
    if (!isActivated) return false;
    return super.receiveDamage(amount);
  }

  @override
  void onDeath() {
    game.onMonsterKilled();
    for (var i = 0; i < def.coinDrop; i++) {
      game.world.add(CoinPickup(
        position: position +
            Vector2((_rng.nextDouble() - 0.5) * 10, (_rng.nextDouble() - 0.5) * 8),
        autoCollect: true,
      ));
    }
    if (isBoss || def.type == MonsterType.boss) {
      game.world.add(KeyPickup(position: position.clone(), boss: true));
    } else if (_rng.nextDouble() < 0.08) {
      game.world.add(KeyPickup(position: position.clone()));
    }
    if (_rng.nextDouble() < 0.10 + _floor * 0.005) {
      game.world.add(PotionPickup.red(position: position.clone()));
    }
    removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    if (opacity <= 0) return;
    super.render(canvas);
    if (hp < maxHp) {
      final barW = isBoss ? 18.0 : 12.0;
      final x = (size.x - barW) / 2;
      canvas.drawRect(
        ui.Rect.fromLTWH(x, -3, barW, 2),
        ui.Paint()..color = const ui.Color(0xAA15323D),
      );
      canvas.drawRect(
        ui.Rect.fromLTWH(x, -3, barW * hp / maxHp, 2),
        ui.Paint()..color = const ui.Color(0xFFB9DDA7),
      );
    }
  }
}
