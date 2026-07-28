import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/components/monster.dart';
import 'package:pixel_crawler/game/heroes.dart';
import 'package:pixel_crawler/game/pixel_crawler_game.dart';
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

        // Simulate ~3 seconds of gameplay: monsters chase, the player
        // auto-aims and fires. Nothing should throw.
        for (var i = 0; i < 180; i++) {
          game.update(1 / 60);
        }

        // Force a floor change and make sure the world rebuilds cleanly.
        final oldFloor = game.floor;
        await game.goToNextFloor();
        game.update(0);
        expect(game.floor, oldFloor + 1);
        expect(game.player!.isMounted, isTrue);
        for (var i = 0; i < 60; i++) {
          game.update(1 / 60);
        }
      },
    );
  }
}
