import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/services/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    SaveService.resetForTest();
  });

  test('slime unlocks when reaching the unlock floor', () async {
    final save = await SaveService.load();
    expect(save.slimeUnlocked, isFalse);

    expect(await save.reportFloorReached(2), isFalse);
    expect(save.slimeUnlocked, isFalse);

    expect(await save.reportFloorReached(SaveService.slimeUnlockFloor), isTrue);
    expect(save.slimeUnlocked, isTrue);

    // Reported only once.
    expect(await save.reportFloorReached(5), isFalse);
    expect(save.bestFloor, 5);
  });

  test('run totals accumulate', () async {
    final save = await SaveService.load();
    await save.reportRunEnded(coins: 10, kills: 3);
    await save.reportRunEnded(coins: 5, kills: 2);
    expect(save.totalCoins, 15);
    expect(save.totalKills, 5);
  });
}
