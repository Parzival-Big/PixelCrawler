import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../monsters.dart';
import 'attacks.dart';
import 'game_character.dart';
import 'pickups.dart';

class Monster extends GameCharacter {
  Monster({
    required this.def,
    required super.position,
    required int floor,
  })  : _floor = floor,
        super(
          frameSize: def.anim.size,
          maxHp: def.baseHp + def.hpPerFloor * (floor - 1),
        );

  final MonsterDef def;
  final int _floor;
  final _rng = Random();

  double _contactTimer = 0;
  double _wanderTimer = 0;
  double _erraticPhase = 0;
  double _shotTimer = 0;
  Vector2 _wanderDir = Vector2.zero();

  @override
  Future<void> onLoad() async {
    animation = def.anim.animation();
    _erraticPhase = _rng.nextDouble() * pi * 2;
    _shotTimer = _rng.nextDouble() * def.projectileCooldown;
  }

  @override
  void update(double dt) {
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

    if (dist < 11 && _contactTimer <= 0) {
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
  void onDeath() {
    game.onMonsterKilled();
    for (var i = 0; i < def.coinDrop; i++) {
      game.world.add(CoinPickup(
        position: position +
            Vector2((_rng.nextDouble() - 0.5) * 10, (_rng.nextDouble() - 0.5) * 8),
      ));
    }
    if (_rng.nextDouble() < 0.10 + _floor * 0.005) {
      game.world.add(PotionPickup.red(position: position.clone()));
    }
    removeFromParent();
  }

  @override
  void render(ui.Canvas canvas) {
    super.render(canvas);
    if (hp < maxHp) {
      const barW = 12.0;
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
