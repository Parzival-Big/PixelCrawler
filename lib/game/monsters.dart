import '../config/game_assets.dart';

enum MonsterType { slime, bat, skeleton, goblin }

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

  /// Erratic movers (bats) wobble sideways while chasing.
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
  MonsterType.goblin: MonsterDef(
    type: MonsterType.goblin,
    anim: GameAssets.goblin,
    baseHp: 5,
    hpPerFloor: 1,
    damage: 2,
    speed: 58,
    aggroRange: 130,
    coinDrop: 2,
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
    pool.addAll([MonsterType.goblin, MonsterType.bat]);
  }
  if (floor >= 3) {
    pool.addAll([MonsterType.skeleton, MonsterType.goblin]);
  }
  if (floor >= 5) {
    pool.addAll([MonsterType.skeleton, MonsterType.skeleton]);
  }
  return pool;
}
