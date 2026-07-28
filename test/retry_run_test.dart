import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/components/player.dart';
import 'package:pixel_crawler/game/heroes.dart';
import 'package:pixel_crawler/game/pixel_crawler_game.dart';
import 'package:pixel_crawler/services/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SaveService.resetForTest();
    await SaveService.load();
  });

  testWithGame<PixelCrawlerGame>(
    'restartRun keeps the hero and resets the dungeon run',
    () => PixelCrawlerGame(heroType: HeroType.mage),
    (game) async {
      game.overlays.addEntry(Overlays.gameOver, (context, g) => const SizedBox.shrink());
      game.update(0);
      expect(game.heroType, HeroType.mage);
      expect(game.player, isNotNull);

      game.floor = 5;
      game.kills = 20;
      game.keys = 3;
      game.bossKeys = 1;
      game.coins = 40;
      SessionBonus.extraDamage = 2;

      await game.onPlayerDied();
      expect(game.overlays.isActive(Overlays.gameOver), isTrue);
      expect(game.paused, isTrue);

      await game.restartRun();
      game.update(0);

      expect(game.heroType, HeroType.mage);
      expect(game.floor, 1);
      expect(game.kills, 0);
      expect(game.keys, 0);
      expect(game.bossKeys, 0);
      expect(game.coins, 0);
      expect(SessionBonus.extraDamage, 0);
      expect(game.overlays.isActive(Overlays.gameOver), isFalse);
      expect(game.paused, isFalse);
      expect(game.player, isNotNull);
      expect(game.player!.isDead, isFalse);
      expect(game.player!.hp, game.player!.maxHp);
      expect(game.currentRoom, isNotNull);
    },
  );
}
