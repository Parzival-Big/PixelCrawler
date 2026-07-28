import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/config/game_assets.dart';
import 'package:pixel_crawler/game/components/attacks.dart';
import 'package:pixel_crawler/game/components/pickups.dart';
import 'package:pixel_crawler/game/components/solid_obstacle.dart';
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
    'solid props block player movement and projectiles',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      final player = game.player!;

      // Find an open tile to the right of the player and plant a barrel there.
      final barrel = Decor(
        position: player.position + Vector2(12, 0),
        spec: GameAssets.decor.first,
        solid: true,
      );
      game.world.add(barrel);
      await barrel.loaded;
      game.update(0);

      expect(game.world.children.whereType<SolidObstacle>(), isNotEmpty);
      expect(
        game.solidBlocksFeet(
          barrel.position.x,
          barrel.position.y,
          player.feetWidth,
          player.feetHeight,
        ),
        isTrue,
      );

      // Trying to walk into the barrel should leave the player short of it.
      final before = player.position.clone();
      for (var i = 0; i < 30; i++) {
        player.moveAndCollide(Vector2(2, 0));
      }
      expect(player.position.x, lessThan(barrel.position.x - 2));
      expect(player.position.x, greaterThan(before.x));

      // A projectile aimed through the barrel must explode on contact.
      final shot = Projectile.arrow(
        origin: player.position - Vector2(0, player.size.y / 2),
        direction: Vector2(1, 0),
        damage: 1,
      );
      game.world.add(shot);
      await shot.loaded;
      for (var i = 0; i < 60; i++) {
        game.update(1 / 60);
        if (!shot.isMounted) break;
      }
      expect(shot.isMounted, isFalse);
      // It must have died near the barrel, not after flying past it.
      expect(shot.position.x, lessThan(barrel.position.x + 20));
    },
  );

  testWithGame<PixelCrawlerGame>(
    'floor litter (skull/bone) does not block movement',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      final player = game.player!;
      final litter = Decor(
        position: player.position + Vector2(10, 0),
        spec: GameAssets.decor[3],
        solid: false,
      );
      game.world.add(litter);
      await litter.loaded;

      expect(
        game.solidBlocksFeet(
          litter.position.x,
          litter.position.y,
          player.feetWidth,
          player.feetHeight,
        ),
        isFalse,
      );

      for (var i = 0; i < 20; i++) {
        player.moveAndCollide(Vector2(2, 0));
      }
      expect(player.position.x, greaterThan(litter.position.x));
    },
  );
}
