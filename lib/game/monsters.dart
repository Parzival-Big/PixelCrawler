import '../config/game_assets.dart';

enum MonsterType { slime, bat, rat, skeleton, spider, ghost }

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
  if (floor >= 5) {
    pool.addAll([MonsterType.ghost, MonsterType.skeleton]);
  }
  return pool;
}
