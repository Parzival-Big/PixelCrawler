import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../game/heroes.dart';

/// Persistent progression: unlocks and lifetime records.
class SaveService {
  SaveService._(this._prefs);

  static const _kSlimeUnlocked = 'slime_unlocked';
  static const _kBestFloor = 'best_floor';
  static const _kTotalCoins = 'total_coins';
  static const _kTotalKills = 'total_kills';

  /// Floor that every base hero must reach to unlock the Slime.
  static const slimeUnlockFloor = 20;

  /// Heroes that must each hit [slimeUnlockFloor] before Slime unlocks.
  static const slimeUnlockHeroes = <HeroType>[
    HeroType.knight,
    HeroType.mage,
    HeroType.hunter,
    HeroType.rogue,
  ];

  static SaveService? _instance;
  final SharedPreferences _prefs;

  static Future<SaveService> load() async {
    return _instance ??= SaveService._(await SharedPreferences.getInstance());
  }

  static SaveService get instance => _instance!;

  @visibleForTesting
  static void resetForTest() => _instance = null;

  bool get slimeUnlocked => _prefs.getBool(_kSlimeUnlocked) ?? false;
  int get bestFloor => _prefs.getInt(_kBestFloor) ?? 0;
  int get totalCoins => _prefs.getInt(_kTotalCoins) ?? 0;
  int get totalKills => _prefs.getInt(_kTotalKills) ?? 0;

  int bestFloorFor(HeroType hero) =>
      _prefs.getInt('best_floor_${hero.name}') ?? 0;

  /// True once every base hero has reached [slimeUnlockFloor].
  bool get slimeRequirementsMet => slimeUnlockHeroes
      .every((h) => bestFloorFor(h) >= slimeUnlockFloor);

  Future<void> unlockSlime() => _prefs.setBool(_kSlimeUnlocked, true);

  /// Records progress for [hero]. Returns true when this call just unlocked
  /// the Slime.
  Future<bool> reportFloorReached(int floor, HeroType hero) async {
    var justUnlocked = false;
    if (floor > bestFloor) {
      await _prefs.setInt(_kBestFloor, floor);
    }
    if (hero != HeroType.slime && floor > bestFloorFor(hero)) {
      await _prefs.setInt('best_floor_${hero.name}', floor);
    }
    if (!slimeUnlocked && slimeRequirementsMet) {
      await unlockSlime();
      justUnlocked = true;
    }
    return justUnlocked;
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
