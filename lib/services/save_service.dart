import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Persistent progression: unlocks and records.
class SaveService {
  SaveService._(this._prefs);

  static const _kSlimeUnlocked = 'slime_unlocked';
  static const _kBestFloor = 'best_floor';
  static const _kTotalCoins = 'total_coins';
  static const _kTotalKills = 'total_kills';

  /// Reaching this floor unlocks the Slime hero.
  static const slimeUnlockFloor = 3;

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

  Future<void> unlockSlime() => _prefs.setBool(_kSlimeUnlocked, true);

  /// Returns true when this run just unlocked the Slime.
  Future<bool> reportFloorReached(int floor) async {
    var justUnlocked = false;
    if (floor > bestFloor) {
      await _prefs.setInt(_kBestFloor, floor);
    }
    if (!slimeUnlocked && floor >= slimeUnlockFloor) {
      await unlockSlime();
      justUnlocked = true;
    }
    return justUnlocked;
  }

  Future<void> reportRunEnded({required int coins, required int kills}) async {
    await _prefs.setInt(_kTotalCoins, totalCoins + coins);
    await _prefs.setInt(_kTotalKills, totalKills + kills);
  }
}
