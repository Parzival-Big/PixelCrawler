/// Permanent upgrades bought from the merchant with banked coins.
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
  });

  final String id;
  final String name;
  final String description;

  /// Cost of the first purchase; each further level adds [costStep].
  final int baseCost;
  final int costStep;
  final int maxLevel;

  /// Magnitude added per level (see [unit] for how it is interpreted).
  final int perLevel;
  final StoreUnit unit;

  int costForLevel(int currentLevel) => baseCost + costStep * currentLevel;
}

enum StoreUnit { halfHearts, damage, speed, cooldownHundredths }

/// Catalog of everything the merchant sells.
class StoreCatalog {
  StoreCatalog._();

  static const maxHp = StoreUpgrade(
    id: 'max_hp',
    name: 'CUORE D\'ACCIAIO',
    description: '+1 cuore di vita\nmassima permanente',
    baseCost: 40,
    costStep: 25,
    maxLevel: 5,
    perLevel: 2,
    unit: StoreUnit.halfHearts,
  );

  static const damage = StoreUpgrade(
    id: 'damage',
    name: 'LAMA AFFILATA',
    description: '+1 danno a tutti\ngli attacchi',
    baseCost: 50,
    costStep: 30,
    maxLevel: 5,
    perLevel: 1,
    unit: StoreUnit.damage,
  );

  static const speed = StoreUpgrade(
    id: 'speed',
    name: 'STIVALI LEGGERI',
    description: '+8 velocita di\nmovimento',
    baseCost: 45,
    costStep: 25,
    maxLevel: 5,
    perLevel: 8,
    unit: StoreUnit.speed,
  );

  static const attackSpeed = StoreUpgrade(
    id: 'attack_speed',
    name: 'RAFFICA',
    description: 'Attacchi piu\nrapidi (-0.04s)',
    baseCost: 55,
    costStep: 35,
    maxLevel: 4,
    perLevel: 4,
    unit: StoreUnit.cooldownHundredths,
  );

  static const all = <StoreUpgrade>[maxHp, damage, speed, attackSpeed];
}
