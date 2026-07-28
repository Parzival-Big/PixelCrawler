/// Upgrades sold between floors. Effects last for the current run only.
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

enum StoreUnit { halfHearts, damage, speed, cooldownHundredths, heal }

/// Between-floor merchant catalog (run-scoped).
class StoreCatalog {
  StoreCatalog._();

  static const heal = StoreUpgrade(
    id: 'heal',
    name: 'POZIONE',
    description: 'Cura 2 cuori\nsubito',
    baseCost: 6,
    costStep: 2,
    maxLevel: 99,
    perLevel: 4,
    unit: StoreUnit.heal,
    iconAsset: 'assets/images/objects/potion_red.png',
  );

  static const maxHp = StoreUpgrade(
    id: 'max_hp',
    name: 'CUORE EXTRA',
    description: '+1 cuore di vita\nmassima (questa run)',
    baseCost: 12,
    costStep: 8,
    maxLevel: 5,
    perLevel: 2,
    unit: StoreUnit.halfHearts,
    iconAsset: 'assets/images/ui/heart_full.png',
  );

  static const damage = StoreUpgrade(
    id: 'damage',
    name: 'LAMA',
    description: '+1 danno\n(questa run)',
    baseCost: 14,
    costStep: 10,
    maxLevel: 5,
    perLevel: 1,
    unit: StoreUnit.damage,
    iconAsset: 'assets/images/objects/sword.png',
  );

  static const speed = StoreUpgrade(
    id: 'speed',
    name: 'STIVALI',
    description: '+8 velocita\n(questa run)',
    baseCost: 10,
    costStep: 8,
    maxLevel: 5,
    perLevel: 8,
    unit: StoreUnit.speed,
    iconAsset: 'assets/images/objects/boot.png',
  );

  static const attackSpeed = StoreUpgrade(
    id: 'attack_speed',
    name: 'RAFFICA',
    description: 'Attacchi piu\nrapidi (questa run)',
    baseCost: 12,
    costStep: 10,
    maxLevel: 4,
    perLevel: 4,
    unit: StoreUnit.cooldownHundredths,
    iconAsset: 'assets/images/effects/arrow.png',
  );

  /// Offered in the between-floor shop (heal is always available).
  static const all = <StoreUpgrade>[heal, maxHp, damage, speed, attackSpeed];
}
