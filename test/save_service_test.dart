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
      isFalse,
    );
    expect(save.slimeUnlocked, isFalse);
    expect(save.bestFloorFor(HeroType.knight), SaveService.slimeUnlockFloor);

    for (final hero in [
      HeroType.mage,
      HeroType.hunter,
    ]) {
      expect(await save.reportFloorReached(20, hero), isFalse);
    }

    // The last required hero unlocks it.
    expect(await save.reportFloorReached(20, HeroType.rogue), isTrue);
    expect(save.slimeUnlocked, isTrue);
    expect(save.slimeRequirementsMet, isTrue);

    // Reported only once.
    expect(await save.reportFloorReached(25, HeroType.knight), isFalse);
  });

  test('slime runs do not count toward the unlock', () async {
    final save = await SaveService.load();
    await save.reportFloorReached(20, HeroType.slime);
    expect(save.bestFloorFor(HeroType.slime), 0);
    expect(save.slimeUnlocked, isFalse);
  });

  test('run totals accumulate', () async {
    final save = await SaveService.load();
    await save.reportRunEnded(coins: 10, kills: 3);
    await save.reportRunEnded(coins: 5, kills: 2);
    expect(save.totalCoins, 15);
    expect(save.totalKills, 5);
  });
}
