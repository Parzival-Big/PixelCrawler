import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/heroes.dart';
import 'package:pixel_crawler/services/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SaveService.resetForTest();
  });

  test('slime unlocks only when every base hero reaches floor 20', () async {
    final save = await SaveService.load();
    expect(save.slimeUnlocked, isFalse);

    // One hero alone is not enough.
    expect(
      await save.reportFloorReached(SaveService.slimeUnlockFloor, HeroType.knight),
      isEmpty,
    );
    expect(save.slimeUnlocked, isFalse);
    expect(save.bestFloorFor(HeroType.knight), SaveService.slimeUnlockFloor);

    for (final hero in [
      HeroType.mage,
      HeroType.hunter,
    ]) {
      expect(await save.reportFloorReached(20, hero), isEmpty);
    }

    // The last required hero unlocks it.
    expect(
      await save.reportFloorReached(20, HeroType.rogue),
      contains(HeroType.slime),
    );
    expect(save.slimeUnlocked, isTrue);
    expect(save.slimeRequirementsMet, isTrue);
    expect(save.isRevealed(HeroType.mummy), isTrue);

    // Reported only once.
    expect(await save.reportFloorReached(25, HeroType.knight), isEmpty);
  });

  test('mummy unlocks at floor 50 with slime', () async {
    final save = await SaveService.load();
    // Unlock slime first so mummy is revealed.
    for (final h in SaveService.slimeUnlockHeroes) {
      await save.reportFloorReached(20, h);
    }
    expect(save.isRevealed(HeroType.mummy), isTrue);
    expect(save.isUnlocked(HeroType.mummy), isFalse);

    expect(await save.reportFloorReached(50, HeroType.slime),
        contains(HeroType.mummy));
    expect(save.isUnlocked(HeroType.mummy), isTrue);
  });

  test('mushroom needs hunter and knight at 50', () async {
    final save = await SaveService.load();
    await save.reportFloorReached(50, HeroType.hunter);
    expect(await save.reportFloorReached(50, HeroType.knight),
        contains(HeroType.mushroom));
    expect(save.isUnlocked(HeroType.mushroom), isTrue);
  });

  test('witch unlocks at 70 with mage; dragon needs everyone at 100', () async {
    final save = await SaveService.load();
    expect(await save.reportFloorReached(70, HeroType.mage),
        contains(HeroType.witch));
    expect(save.isUnlocked(HeroType.witch), isTrue);
    expect(save.isRevealed(HeroType.dragon), isTrue);

    for (final h in HeroType.values.where((h) => h != HeroType.dragon)) {
      await save.reportFloorReached(100, h);
    }
    expect(save.isUnlocked(HeroType.dragon), isTrue);
  });

  test('run totals accumulate', () async {
    final save = await SaveService.load();
    await save.reportRunEnded(coins: 10, kills: 3);
    await save.reportRunEnded(coins: 5, kills: 2);
    expect(save.totalCoins, 15);
    expect(save.totalKills, 5);
  });
}
