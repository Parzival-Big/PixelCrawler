import 'dart:math';

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/components/dungeon_renderer.dart';
import 'package:pixel_crawler/game/components/pickups.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_generator.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_map.dart';
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

  test('shared wall faces into the room being tiled', () {
    final map = DungeonMap(20, 12);
    // Two rooms side by side sharing wall column x=8.
    for (var y = 1; y <= 9; y++) {
      for (var x = 1; x <= 7; x++) {
        map.setTile(x, y, TileType.floor);
      }
      for (var x = 9; x <= 15; x++) {
        map.setTile(x, y, TileType.floor);
      }
    }
    for (var y = 0; y <= 10; y++) {
      for (var x = 0; x <= 16; x++) {
        if (map.tileAt(x, y) == TileType.empty) {
          map.setTile(x, y, TileType.wall);
        }
      }
    }

    final left = RoomInfo(
      bounds: const Rectangle(1, 1, 7, 9),
      kind: RoomKind.combat,
      gridX: 0,
      gridY: 0,
    );
    final right = RoomInfo(
      bounds: const Rectangle(9, 1, 7, 9),
      kind: RoomKind.combat,
      gridX: 1,
      gridY: 0,
    );

    // Shared wall at x=8: from left room → right face; from right → left face.
    expect(wallTileNameFor(map, 8, 5, room: left), 'right');
    expect(wallTileNameFor(map, 8, 5, room: right), 'left');
  });

  testWithGame<PixelCrawlerGame>(
    'dungeon renderer only covers the current room outer bounds',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      final room = game.currentRoom!;
      final outer = room.outerBounds;
      final renderer = game.world.children.query<DungeonRenderer>().first;
      game.update(0);

      expect(renderer.position.x, outer.left * tileSize - wallOverhang);
      expect(renderer.position.y, outer.top * tileSize - wallOverhang);
      expect(renderer.size.x, outer.width * tileSize + wallOverhang * 2);
      expect(renderer.size.y, outer.height * tileSize + wallOverhang * 2);

      // Torches outside the current room are hidden; in-room ones are 1.5×.
      for (final torch in game.world.children.query<Torch>()) {
        game.update(0);
        final inRoom = tileInCurrentRoom(game, torch.tileX, torch.tileY);
        expect(torch.opacity, inRoom ? 1 : 0);
        expect(torch.size.x, wallVisualSize);
      }
    },
  );

  test('generator still places directional torches', () {
    final map = DungeonGenerator(floor: 1, seed: 3).generate();
    expect(map.torchSpawns, isNotEmpty);
    expect(map.roomInfos.length, greaterThan(1));
  });
}
