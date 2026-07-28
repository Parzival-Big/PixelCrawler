import 'dart:math';

import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/components/door.dart';
import 'package:pixel_crawler/game/components/room_occluder.dart';
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
      expect(component.isOnPerimeterOf(room), isTrue);
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

    final outsider = map.roomInfos
        .where((r) => !component.isOnPerimeterOf(r))
        .toList();
    for (final room in outsider) {
      expect(component.isOnPerimeterOf(room), isFalse);
    }
  });

  test('stairs are not forced into the boss room', () {
    for (var seed = 0; seed < 8; seed++) {
      final map = DungeonGenerator(floor: 2, seed: seed).generate();
      final boss = map.roomInfos.firstWhere((r) => r.kind == RoomKind.boss);
      final stairRoom = map.roomInfoContaining(map.stairsPos.x, map.stairsPos.y);
      expect(stairRoom, isNotNull);
      expect(
        stairRoom!.kind,
        isNot(RoomKind.boss),
        reason: 'seed $seed: stairs should leave the boss room',
      );
      expect(boss.bounds.containsPoint(map.bossSpawn!), isTrue);
    }
  });

  testWithGame<PixelCrawlerGame>(
    'only current-room perimeter doors are visible; open doors split layers',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      final room = game.currentRoom!;
      final doors = game.world.children.query<Door>().toList();
      expect(doors, isNotEmpty);
      expect(game.world.children.query<DoorLintel>(), isNotEmpty);

      var visible = 0;
      for (final door in doors) {
        game.update(0);
        if (door.isOnPerimeterOf(room)) {
          visible++;
          expect(door.opacity, 1);
          // Open → opening behind hero; closed → full door in front.
          if (door.open) {
            expect(door.priority, Door.behindPriority);
          } else {
            expect(door.priority, Door.underpassPriority);
          }
        } else {
          expect(door.opacity, 0);
        }
      }
      expect(visible, greaterThan(0));

      final occluder = game.world.children.query<RoomOccluder>().first;
      expect(occluder.priority, greaterThan(Door.underpassPriority));
    },
  );

  group('door frame / opening by facing', () {
    Door _door(DoorDir dir) => Door(
          spawn: DoorSpawn(
            pos: const Point(0, 0),
            dir: dir,
            locked: false,
          ),
        );

    test('north: frame top, opening bottom', () {
      final d = _door(DoorDir.north);
      expect(d.frameRect.top, 0);
      expect(d.openingRect.top, greaterThan(0));
      expect(d.frameRect.overlaps(d.openingRect), isFalse);
    });

    test('south: opening top, frame bottom', () {
      final d = _door(DoorDir.south);
      expect(d.openingRect.top, 0);
      expect(d.frameRect.top, greaterThan(0));
      expect(d.frameRect.overlaps(d.openingRect), isFalse);
    });

    test('west: frame left, opening right', () {
      final d = _door(DoorDir.west);
      expect(d.frameRect.left, 0);
      expect(d.openingRect.left, greaterThan(0));
      expect(d.frameRect.overlaps(d.openingRect), isFalse);
    });

    test('east: opening left, frame right', () {
      final d = _door(DoorDir.east);
      expect(d.openingRect.left, 0);
      expect(d.frameRect.left, greaterThan(0));
      expect(d.frameRect.overlaps(d.openingRect), isFalse);
    });
  });
}
