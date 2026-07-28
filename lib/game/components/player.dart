import 'dart:math';

import 'package:flame/components.dart';

import '../heroes.dart';
import '../store_catalog.dart';
import 'attacks.dart';
import 'game_character.dart';
import 'monster.dart';

class Player extends GameCharacter {
  Player({required this.def, required super.position})
      : super(
          frameSize: def.anim.size * visualScale,
          maxHp: def.maxHp + SessionBonus.extraHp,
        );

  /// Visual (and feet) size relative to the raw sprite frame.
  static const visualScale = 0.8;

  final HeroDef def;
  final _rng = Random();

  Vector2 facing = Vector2(1, 0);
  double _attackTimer = 0;
  double _invulnTimer = 0;

  static const aimRange = 130.0;

  @override
  double get feetWidth => 9 * visualScale;

  @override
  double get feetHeight => 5 * visualScale;

  double get moveSpeed => def.speed + SessionBonus.extraSpeed;

  double get attackCooldown =>
      (def.attackCooldown - SessionBonus.extraCooldown).clamp(0.15, 2.0);

  @override
  Future<void> onLoad() async {
    animation = def.anim.animation();
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (isDead) return;
    _attackTimer -= dt;
    _invulnTimer -= dt;

    final input = game.moveInput();
    if (input.length2 > 0.01) {
      final delta = input.normalized() * moveSpeed * dt;
      moveAndCollide(delta);
      facing = input.normalized();
      faceDirection(input.x);
    }

    // Invulnerability blink.
    opacity = _invulnTimer > 0 && (_invulnTimer * 12).floor().isOdd ? 0.4 : 1;

    if (game.attackHeld) tryAttack();
  }

  void tryAttack() {
    if (_attackTimer > 0 || isDead) return;
    _attackTimer = attackCooldown;

    // Auto-aim at the nearest monster in range, otherwise use facing.
    var dir = facing.clone();
    Monster? nearest;
    var bestD = aimRange;
    for (final m in game.world.children.query<Monster>()) {
      final d = m.position.distanceTo(position);
      if (d < bestD) {
        bestD = d;
        nearest = m;
      }
    }
    if (nearest != null) {
      dir = (nearest.position - position)..normalize();
    }
    faceDirection(dir.x);

    var dmg = def.damage + SessionBonus.extraDamage;
    if (def.critChance > 0 && _rng.nextDouble() < def.critChance) {
      dmg *= 2;
    }

    switch (def.style) {
      case AttackStyle.melee:
        game.world.add(MeleeSwing(
          origin: position - Vector2(0, size.y / 2),
          direction: dir,
          damage: dmg,
        ));
      case AttackStyle.fireball:
        game.world.add(Projectile.fireball(
          origin: position - Vector2(0, size.y / 2),
          direction: dir,
          damage: dmg,
        ));
      case AttackStyle.arrow:
        game.world.add(Projectile.arrow(
          origin: position - Vector2(0, size.y / 2),
          direction: dir,
          damage: dmg,
        ));
      case AttackStyle.bone:
        game.world.add(Projectile.bone(
          origin: position - Vector2(0, size.y / 2),
          direction: dir,
          damage: dmg,
        ));
    }
  }

  void receiveContactDamage(int amount) {
    if (_invulnTimer > 0 || isDead) return;
    _invulnTimer = 0.7;
    final mitigated = (amount - SessionBonus.extraDefense).clamp(0, amount);
    if (mitigated <= 0) return;
    receiveDamage(mitigated);
    game.hpNotifier.value = hp;
  }

  void heal(int amount) {
    hp = (hp + amount).clamp(0, maxHp);
    game.hpNotifier.value = hp;
  }

  @override
  void onDeath() {
    game.onPlayerDied();
  }
}

/// Bonuses active for the current run only (shop + blue potions).
class SessionBonus {
  static int extraHp = 0;
  static int extraDamage = 0;
  static int extraDefense = 0;
  static double extraSpeed = 0;
  static double extraCooldown = 0;
  static final levels = <String, int>{};

  static void reset() {
    extraHp = 0;
    extraDamage = 0;
    extraDefense = 0;
    extraSpeed = 0;
    extraCooldown = 0;
    levels.clear();
  }

  static int levelOf(StoreUpgrade upgrade) => levels[upgrade.id] ?? 0;

  static void bumpLevel(StoreUpgrade upgrade) {
    levels[upgrade.id] = levelOf(upgrade) + 1;
  }
}
