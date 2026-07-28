/// Upgrades sold in the on-floor shop room. Effects last for the current run.
class StoreUpgrade {
  const StoreUpgrade({
    required this.id,
    required this.name,
    required this.description,
    required this.baseCost,
    required this.costStep,
    required this.maxLevel,
    required this.perLevel,
    required this.unit,
    required this.iconAsset,
  });

  final String id;
  final String name;
  final String description;
  final int baseCost;
  final int costStep;
  final int maxLevel;
  final int perLevel;
  final StoreUnit unit;
  final String iconAsset;

  int costForLevel(int currentLevel) => baseCost + costStep * currentLevel;
}

enum StoreUnit {
  /// +1 HP (¼ cuore when 4 HP = 1 cuore) and full heal.
  vitaQuarter,
  damage,
  defense,
  speed,
  cooldownHundredths,
  halfHearts,
  heal,
}

/// On-floor shop catalog (3 pedestals, prices rolled 30–50).
class StoreCatalog {
  StoreCatalog._();

  static const vita = StoreUpgrade(
    id: 'vita',
    name: 'VITA',
    description: '+1/4 cuore max\ne cura tutta la vita',
    baseCost: 35,
    costStep: 0,
    maxLevel: 8,
    perLevel: 1,
    unit: StoreUnit.vitaQuarter,
    iconAsset: 'assets/images/ui/heart_full.png',
  );

  static const damage = StoreUpgrade(
    id: 'atk',
    name: 'ATTACCO',
    description: '+1 danno\n(questa run)',
    baseCost: 40,
    costStep: 0,
    maxLevel: 8,
    perLevel: 1,
    unit: StoreUnit.damage,
    iconAsset: 'assets/images/objects/sword.png',
  );

  static const defense = StoreUpgrade(
    id: 'def',
    name: 'DIFESA',
    description: '-1 danno subito\n(questa run)',
    baseCost: 40,
    costStep: 0,
    maxLevel: 5,
    perLevel: 1,
    unit: StoreUnit.defense,
    iconAsset: 'assets/images/objects/shield.png',
  );

  static const speed = StoreUpgrade(
    id: 'move',
    name: 'VELOCITA',
    description: '+10 velocita\nmovimento',
    baseCost: 35,
    costStep: 0,
    maxLevel: 6,
    perLevel: 10,
    unit: StoreUnit.speed,
    iconAsset: 'assets/images/objects/boot.png',
  );

  static const attackSpeed = StoreUpgrade(
    id: 'atk_spd',
    name: 'ATT. RAPIDO',
    description: 'Attacchi piu\nrapidi',
    baseCost: 40,
    costStep: 0,
    maxLevel: 5,
    perLevel: 5,
    unit: StoreUnit.cooldownHundredths,
    iconAsset: 'assets/images/effects/arrow.png',
  );

  /// Pool for the 3 shop-room pedestals.
  static const shopRoomPool = <StoreUpgrade>[
    vita,
    damage,
    defense,
    speed,
    attackSpeed,
  ];

  static StoreUpgrade byId(String id) =>
      shopRoomPool.firstWhere((u) => u.id == id);

  /// Legacy aliases used by older shop overlay / tests.
  static const heal = vita;
  static const maxHp = vita;
  static const all = shopRoomPool;
}
