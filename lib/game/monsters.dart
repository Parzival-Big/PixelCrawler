import '../config/game_assets.dart';

enum MonsterType {
  slime,
  bat,
  rat,
  skeleton,
  skeletonArcher,
  skeletonNecromancer,
  spider,
  ghost,
  flyingEye,
  boss,
}

/// Skeleton variants that bone piles / skulls can transmute into.
const skeletonVariants = <MonsterType>[
  MonsterType.skeleton,
  MonsterType.skeletonArcher,
  MonsterType.skeletonNecromancer,
];

class MonsterDef {
  const MonsterDef({
    required this.type,
    required this.anim,
    required this.baseHp,
    required this.hpPerFloor,
    required this.damage,
    required this.speed,
    required this.aggroRange,
    required this.coinDrop,
    this.erratic = false,
    this.ranged = false,
    this.preferredRange = 70,
    this.projectileCooldown = 1.4,
  });

  final MonsterType type;
  final AnimSpec anim;
  final int baseHp;
  final int hpPerFloor;
  final int damage;
  final double speed;
  final double aggroRange;
  final int coinDrop;

  /// Erratic movers (bats, ghosts) wobble sideways while chasing.
  final bool erratic;

  /// Keeps distance and shoots projectiles at the player.
  final bool ranged;
  final double preferredRange;
  final double projectileCooldown;
}

const monsters = <MonsterType, MonsterDef>{
  MonsterType.slime: MonsterDef(
    type: MonsterType.slime,
    anim: GameAssets.slime,
    baseHp: 4,
    hpPerFloor: 1,
    damage: 1,
    speed: 26,
    aggroRange: 90,
    coinDrop: 1,
  ),
  MonsterType.bat: MonsterDef(
    type: MonsterType.bat,
    anim: GameAssets.bat,
    baseHp: 3,
    hpPerFloor: 1,
    damage: 1,
    speed: 52,
    aggroRange: 120,
    coinDrop: 1,
    erratic: true,
  ),
  MonsterType.rat: MonsterDef(
    type: MonsterType.rat,
    anim: GameAssets.rat,
    baseHp: 4,
    hpPerFloor: 1,
    damage: 1,
    speed: 62,
    aggroRange: 130,
    coinDrop: 1,
  ),
  MonsterType.skeleton: MonsterDef(
    type: MonsterType.skeleton,
    anim: GameAssets.skeleton,
    baseHp: 6,
    hpPerFloor: 2,
    damage: 2,
    speed: 38,
    aggroRange: 110,
    coinDrop: 2,
  ),
  MonsterType.skeletonArcher: MonsterDef(
    type: MonsterType.skeletonArcher,
    anim: GameAssets.skeletonArcher,
    baseHp: 5,
    hpPerFloor: 1,
    damage: 2,
    speed: 34,
    aggroRange: 150,
    coinDrop: 2,
    ranged: true,
    preferredRange: 80,
    projectileCooldown: 1.35,
  ),
  MonsterType.skeletonNecromancer: MonsterDef(
    type: MonsterType.skeletonNecromancer,
    anim: GameAssets.skeletonNecromancer,
    baseHp: 7,
    hpPerFloor: 2,
    damage: 2,
    speed: 30,
    aggroRange: 160,
    coinDrop: 3,
    ranged: true,
    preferredRange: 90,
    projectileCooldown: 1.6,
  ),
  MonsterType.spider: MonsterDef(
    type: MonsterType.spider,
    anim: GameAssets.spider,
    baseHp: 5,
    hpPerFloor: 1,
    damage: 2,
    speed: 56,
    aggroRange: 130,
    coinDrop: 2,
  ),
  MonsterType.ghost: MonsterDef(
    type: MonsterType.ghost,
    anim: GameAssets.ghost,
    baseHp: 7,
    hpPerFloor: 2,
    damage: 2,
    speed: 44,
    aggroRange: 150,
    coinDrop: 3,
    erratic: true,
  ),
  MonsterType.flyingEye: MonsterDef(
    type: MonsterType.flyingEye,
    anim: GameAssets.flyingEye,
    baseHp: 4,
    hpPerFloor: 1,
    damage: 1,
    speed: 48,
    aggroRange: 140,
    coinDrop: 2,
    erratic: true,
    ranged: true,
    preferredRange: 75,
    projectileCooldown: 1.2,
  ),
  MonsterType.boss: MonsterDef(
    type: MonsterType.boss,
    anim: GameAssets.devil,
    baseHp: 20,
    hpPerFloor: 4,
    damage: 3,
    speed: 40,
    aggroRange: 180,
    coinDrop: 8,
  ),
};

/// Which monsters can appear on a given floor (weighted picks).
List<MonsterType> spawnPoolForFloor(int floor) {
  final pool = <MonsterType>[
    MonsterType.slime,
    MonsterType.slime,
    MonsterType.bat,
  ];
  if (floor >= 2) {
    pool.addAll([MonsterType.rat, MonsterType.bat]);
  }
  if (floor >= 3) {
    pool.addAll([MonsterType.skeleton, MonsterType.spider]);
  }
  if (floor >= 4) {
    pool.addAll([MonsterType.skeletonArcher, MonsterType.flyingEye]);
  }
  if (floor >= 5) {
    pool.addAll([MonsterType.ghost, MonsterType.skeleton]);
  }
  if (floor >= 7) {
    pool.addAll([
      MonsterType.skeletonNecromancer,
      MonsterType.skeletonArcher,
      MonsterType.flyingEye,
    ]);
  }
  return pool;
}
