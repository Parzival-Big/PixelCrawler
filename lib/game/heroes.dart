import '../config/game_assets.dart';

enum AttackStyle { melee, fireball, arrow, bone }

enum HeroType {
  knight,
  mage,
  hunter,
  rogue,
  slime,
  mummy,
  mushroom,
  witch,
  dragon,
}

/// How a hero becomes available in the roster.
class UnlockRule {
  const UnlockRule({
    required this.floor,
    required this.requiredHeroes,
    this.revealAfterUnlock,
  });

  /// Each [requiredHeroes] must reach this floor.
  final int floor;
  final List<HeroType> requiredHeroes;

  /// If set, the locked card is only shown after this hero is unlocked.
  final HeroType? revealAfterUnlock;
}

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
    this.unlock,
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

  /// Null = always available (starter heroes).
  final UnlockRule? unlock;

  bool get unlockable => unlock != null;

  int get hpPips => (maxHp / 3).ceil().clamp(1, 5);
  int get atkPips => style == AttackStyle.fireball || style == AttackStyle.bone
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
    unlock: UnlockRule(
      floor: 20,
      requiredHeroes: [
        HeroType.knight,
        HeroType.mage,
        HeroType.hunter,
        HeroType.rogue,
      ],
    ),
  ),
  HeroType.mummy: HeroDef(
    type: HeroType.mummy,
    name: 'Mummy',
    description: 'Antico e tenace.\nColpi lenti ma pesanti.',
    anim: GameAssets.mummy,
    maxHp: 14,
    damage: 3,
    speed: 54,
    attackCooldown: 0.55,
    style: AttackStyle.melee,
    unlock: UnlockRule(
      floor: 50,
      requiredHeroes: [HeroType.slime],
      revealAfterUnlock: HeroType.slime,
    ),
  ),
  HeroType.mushroom: HeroDef(
    type: HeroType.mushroom,
    name: 'Mushroom',
    description: 'Spore tossiche.\nAttacco a breve raggio.',
    anim: GameAssets.mushroom,
    maxHp: 9,
    damage: 3,
    speed: 70,
    attackCooldown: 0.4,
    style: AttackStyle.melee,
    unlock: UnlockRule(
      floor: 50,
      requiredHeroes: [HeroType.hunter, HeroType.knight],
    ),
  ),
  HeroType.witch: HeroDef(
    type: HeroType.witch,
    name: 'Witch',
    description: 'Magia oscura.\nProiettili ossei.',
    anim: GameAssets.witch,
    maxHp: 7,
    damage: 4,
    speed: 66,
    attackCooldown: 0.6,
    style: AttackStyle.bone,
    unlock: UnlockRule(
      floor: 70,
      requiredHeroes: [HeroType.mage],
    ),
  ),
  HeroType.dragon: HeroDef(
    type: HeroType.dragon,
    name: 'Dragon',
    description: 'Il re del dungeon.\nAlito di fuoco.',
    anim: GameAssets.dragon,
    maxHp: 16,
    damage: 5,
    speed: 72,
    attackCooldown: 0.65,
    style: AttackStyle.fireball,
    unlock: UnlockRule(
      floor: 100,
      requiredHeroes: [
        HeroType.knight,
        HeroType.mage,
        HeroType.hunter,
        HeroType.rogue,
        HeroType.slime,
        HeroType.mummy,
        HeroType.mushroom,
        HeroType.witch,
      ],
      revealAfterUnlock: HeroType.witch,
    ),
  ),
};
