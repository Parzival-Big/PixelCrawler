import '../config/game_assets.dart';

enum AttackStyle { melee, fireball, arrow }

enum HeroType { knight, mage, hunter, rogue, slime }

class HeroDef {
  const HeroDef({
    required this.type,
    required this.name,
    required this.description,
    required this.anim,
    required this.maxHp,
    required this.damage,
    required this.speed,
    required this.attackCooldown,
    required this.style,
    this.critChance = 0,
    this.unlockable = false,
  });

  final HeroType type;
  final String name;
  final String description;
  final AnimSpec anim;

  /// Health in half-hearts (2 = one heart).
  final int maxHp;
  final int damage;
  final double speed;
  final double attackCooldown;
  final AttackStyle style;
  final double critChance;
  final bool unlockable;

  /// 1..5 pips shown in the character-select UI.
  int get hpPips => (maxHp / 3).ceil().clamp(1, 5);
  int get atkPips => style == AttackStyle.fireball
      ? 5
      : (damage + (critChance > 0 ? 1 : 0)).clamp(1, 5);
  int get spdPips => ((speed - 40) / 12).round().clamp(1, 5);
}

const heroes = <HeroType, HeroDef>{
  HeroType.knight: HeroDef(
    type: HeroType.knight,
    name: 'Knight',
    description: 'Corazzato e instancabile.\nSpada ad ampio raggio.',
    anim: GameAssets.knight,
    maxHp: 12,
    damage: 3,
    speed: 68,
    attackCooldown: 0.5,
    style: AttackStyle.melee,
  ),
  HeroType.mage: HeroDef(
    type: HeroType.mage,
    name: 'Mage',
    description: 'Fragile ma devastante.\nPalle di fuoco esplosive.',
    anim: GameAssets.mage,
    maxHp: 6,
    damage: 4,
    speed: 62,
    attackCooldown: 0.75,
    style: AttackStyle.fireball,
  ),
  HeroType.hunter: HeroDef(
    type: HeroType.hunter,
    name: 'Hunter',
    description: 'Occhio di falco.\nFrecce rapide e precise.',
    anim: GameAssets.hunter,
    maxHp: 8,
    damage: 2,
    speed: 76,
    attackCooldown: 0.35,
    style: AttackStyle.arrow,
  ),
  HeroType.rogue: HeroDef(
    type: HeroType.rogue,
    name: 'Rogue',
    description: 'Veloce e letale.\nPugnalate critiche.',
    anim: GameAssets.rogue,
    maxHp: 8,
    damage: 2,
    speed: 92,
    attackCooldown: 0.28,
    style: AttackStyle.melee,
    critChance: 0.3,
  ),
  HeroType.slime: HeroDef(
    type: HeroType.slime,
    name: 'Slime',
    description: 'Il re degli slime!\nRimbalza sui nemici.',
    anim: GameAssets.slimeHero,
    maxHp: 10,
    damage: 2,
    speed: 84,
    attackCooldown: 0.34,
    style: AttackStyle.melee,
    unlockable: true,
  ),
};
