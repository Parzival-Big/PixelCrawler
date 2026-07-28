import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/heroes.dart';

/// Persistent progression: unlocks and lifetime records.
class SaveService {
  SaveService._(this._prefs);

  static const _kBestFloor = 'best_floor';
  static const _kTotalCoins = 'total_coins';
  static const _kTotalKills = 'total_kills';

  static SaveService? _instance;
  final SharedPreferences _prefs;

  static Future<SaveService> load() async {
    return _instance ??= SaveService._(await SharedPreferences.getInstance());
  }

  static SaveService get instance => _instance!;

  @visibleForTesting
  static void resetForTest() => _instance = null;

  int get bestFloor => _prefs.getInt(_kBestFloor) ?? 0;
  int get totalCoins => _prefs.getInt(_kTotalCoins) ?? 0;
  int get totalKills => _prefs.getInt(_kTotalKills) ?? 0;

  int bestFloorFor(HeroType hero) =>
      _prefs.getInt('best_floor_${hero.name}') ?? 0;

  bool isUnlocked(HeroType hero) {
    final def = heroes[hero]!;
    final rule = def.unlock;
    if (rule == null) return true;
    return rule.requiredHeroes
        .every((h) => bestFloorFor(h) >= rule.floor);
  }

  /// Whether the locked card should appear in the roster.
  bool isRevealed(HeroType hero) {
    final rule = heroes[hero]!.unlock;
    if (rule == null) return true;
    final gate = rule.revealAfterUnlock;
    if (gate == null) return true;
    return isUnlocked(gate);
  }

  /// Heroes shown on the select screen (starters + revealed unlockables).
  List<HeroDef> get visibleHeroes => [
        for (final def in heroes.values)
          if (isRevealed(def.type)) def,
      ];

  /// Returns the set of heroes that were just unlocked by this report.
  Future<Set<HeroType>> reportFloorReached(int floor, HeroType hero) async {
    if (floor > bestFloor) {
      await _prefs.setInt(_kBestFloor, floor);
    }
    if (floor > bestFloorFor(hero)) {
      await _prefs.setInt('best_floor_${hero.name}', floor);
    }

    final newly = <HeroType>{};
    for (final def in heroes.values) {
      final rule = def.unlock;
      if (rule == null) continue;
      final key = 'unlocked_${def.type.name}';
      final already = _prefs.getBool(key) ?? false;
      if (!already && isUnlocked(def.type)) {
        await _prefs.setBool(key, true);
        newly.add(def.type);
      }
    }
    return newly;
  }

  /// Back-compat helpers used by older UI/tests.
  bool get slimeUnlocked => isUnlocked(HeroType.slime);
  static const slimeUnlockFloor = 20;
  static const slimeUnlockHeroes = <HeroType>[
    HeroType.knight,
    HeroType.mage,
    HeroType.hunter,
    HeroType.rogue,
  ];
  bool get slimeRequirementsMet => isUnlocked(HeroType.slime);
  Future<void> unlockSlime() async {
    await _prefs.setInt('best_floor_knight', slimeUnlockFloor);
    await _prefs.setInt('best_floor_mage', slimeUnlockFloor);
    await _prefs.setInt('best_floor_hunter', slimeUnlockFloor);
    await _prefs.setInt('best_floor_rogue', slimeUnlockFloor);
    await _prefs.setBool('unlocked_slime', true);
  }

  Future<void> reportRunEnded({required int coins, required int kills}) async {
    if (coins > 0) {
      await _prefs.setInt(_kTotalCoins, totalCoins + coins);
    }
    if (kills > 0) {
      await _prefs.setInt(_kTotalKills, totalKills + kills);
    }
  }
}
