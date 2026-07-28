import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/components/monster.dart';
import 'package:pixel_crawler/game/components/player.dart';
import 'package:pixel_crawler/game/heroes.dart';
import 'package:pixel_crawler/game/pixel_crawler_game.dart';
import 'package:pixel_crawler/game/store_catalog.dart';
import 'package:pixel_crawler/services/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Boots the real game (with the real bundled assets) for every hero and
/// runs a few simulated seconds of gameplay.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SaveService.resetForTest();
    await SaveService.load();
  });

  test('merchant spawn chance starts at 5% and rises with pity', () {
    expect(PixelCrawlerGame.shopChance, 0.05);
    expect(PixelCrawlerGame.shopPityStep, 0.05);
    final game = PixelCrawlerGame(heroType: HeroType.knight);
    expect(game.currentShopChance, 0.05);
    game.floorsWithoutShop = 3;
    expect(game.currentShopChance, closeTo(0.20, 1e-9));
  });

  for (final hero in HeroType.values) {
    testWithGame<PixelCrawlerGame>(
      'game boots and simulates with $hero',
      () => PixelCrawlerGame(heroType: hero),
      (game) async {
        game.update(0);

        expect(game.player, isNotNull);
        expect(game.player!.isMounted, isTrue);
        expect(game.world.children.query<Monster>(), isNotEmpty);
        expect(
          game.map.isWalkable(
            game.player!.position.x ~/ 16,
            game.player!.position.y ~/ 16,
          ),
          isTrue,
        );

        for (var i = 0; i < 180; i++) {
          game.update(1 / 60);
        }

        // Floor change usually skips the merchant (5% chance); either path
        // must leave a playable floor.
        final oldFloor = game.floor;
        await game.goToNextFloor();
        expect(game.floor, oldFloor + 1);
        if (game.overlays.isActive(Overlays.shop)) {
          await game.finishShopAndEnterFloor();
        }
        game.update(0);
        expect(game.overlays.isActive(Overlays.shop), isFalse);
        expect(game.player!.isMounted, isTrue);
        for (var i = 0; i < 60; i++) {
          game.update(1 / 60);
        }
      },
    );
  }

  testWithGame<PixelCrawlerGame>(
    'forced merchant visit can be closed and continues the run',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      game.overlays.addEntry(
        Overlays.shop,
        (context, g) => const SizedBox.shrink(),
      );
      game.pauseEngine();
      game.overlays.add(Overlays.shop);
      expect(game.overlays.isActive(Overlays.shop), isTrue);
      await game.finishShopAndEnterFloor();
      expect(game.overlays.isActive(Overlays.shop), isFalse);
      expect(game.player!.isMounted, isTrue);
    },
  );

  testWithGame<PixelCrawlerGame>(
    'between-floor shop spends run coins on temporary upgrades',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      SessionBonus.reset();
      game.addCoins(40);

      expect(game.buyShopUpgrade(StoreCatalog.damage), isTrue);
      expect(SessionBonus.extraDamage, 1);
      expect(game.coins, 40 - StoreCatalog.damage.baseCost);

      expect(game.buyShopUpgrade(StoreCatalog.maxHp), isTrue);
      expect(SessionBonus.extraHp, StoreCatalog.maxHp.perLevel);
      expect(
        game.player!.maxHp,
        heroes[HeroType.knight]!.maxHp + SessionBonus.extraHp,
      );

      game.player!.hp = 2;
      game.hpNotifier.value = 2;
      expect(game.buyShopUpgrade(StoreCatalog.heal), isTrue);
      expect(game.player!.hp, greaterThan(2));

      game.coins = 0;
      game.coinsNotifier.value = 0;
      expect(game.buyShopUpgrade(StoreCatalog.speed), isFalse);
      expect(SessionBonus.extraSpeed, 0);
    },
  );
}
