import 'dart:math';

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/components/door.dart';
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

  test('door facing flips with the room that owns the shared wall', () {
    final map = DungeonGenerator(floor: 1, seed: 0).generate();
    expect(map.doorSpawns, isNotEmpty);
    expect(map.roomInfos.length, greaterThanOrEqualTo(2));

    // Pick any door and the two rooms that share it (or the one that owns it).
    final door = map.doorSpawns.first;
    final owners = map.roomInfos.where((info) {
      final o = info.outerBounds;
      return door.pos.x >= o.left &&
          door.pos.x < o.left + o.width &&
          door.pos.y >= o.top &&
          door.pos.y < o.top + o.height;
    }).toList();
    expect(owners, isNotEmpty);

    final component = Door(spawn: door);
    for (final room in owners) {
      final facing = component.facingForRoom(room);
      final o = room.outerBounds;
      if (door.pos.y == o.top) {
        expect(facing, DoorDir.north);
      } else if (door.pos.y == o.top + o.height - 1) {
        expect(facing, DoorDir.south);
      } else if (door.pos.x == o.left) {
        expect(facing, DoorDir.west);
      } else if (door.pos.x == o.left + o.width - 1) {
        expect(facing, DoorDir.east);
      }
    }
  });

  testWithGame<PixelCrawlerGame>(
    'north doors in the current room draw above the hero',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      final room = game.currentRoom!;
      final doors = game.world.children.query<Door>().toList();
      expect(doors, isNotEmpty);

      for (final door in doors) {
        game.update(0);
        final facing = door.facingForRoom(room);
        if (facing == DoorDir.north) {
          expect(door.priority, Door.underpassPriority);
        } else {
          expect(door.priority, Door.behindPriority);
        }
      }
    },
  );
}
