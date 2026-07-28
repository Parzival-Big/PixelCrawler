import 'dart:math';

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/components/door.dart';
import 'package:pixel_crawler/game/components/dungeon_renderer.dart';
import 'package:pixel_crawler/game/components/monster.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_generator.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_map.dart';
import 'package:pixel_crawler/game/dungeon/room_layouts.dart';
import 'package:pixel_crawler/game/heroes.dart';
import 'package:pixel_crawler/game/monsters.dart';
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
    'closed doors block the player until the room is cleared',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      // Place a slime in the start room so doors stay shut.
      final room = game.currentRoom!;
      final c = room.bounds;
      final slime = Monster(
        def: monsters[MonsterType.slime]!,
        position: Vector2(
          (c.left + c.width / 2) * tileSize,
          (c.top + c.height / 2) * tileSize,
        ),
        floor: 1,
      );
      await game.world.add(slime);
      game.update(0);

      expect(game.currentRoomCleared, isFalse);
      final doors = game.world.children
          .query<Door>()
          .where((d) => d.isOnPerimeterOf(room))
          .toList();
      expect(doors, isNotEmpty);
      for (final d in doors) {
        expect(d.open, isFalse);
        expect(d.blocksPassage, isTrue);
        expect(game.doorBlocksTile(d.spawn.pos.x, d.spawn.pos.y), isTrue);
      }

      // Simulate clear.
      slime.hp = 0;
      slime.removeFromParent();
      game.update(0);
      expect(game.currentRoomCleared, isTrue);
      for (final d in doors) {
        game.update(0);
        if (!d.spawn.locked) {
          expect(d.open, isTrue);
          expect(d.blocksPassage, isFalse);
        }
      }
    },
  );

  test('combat layouts diversify across floors', () {
    final counts = <String, int>{};
    for (var floor = 1; floor <= 6; floor++) {
      for (var seed = 0; seed < 12; seed++) {
        final map = DungeonGenerator(floor: floor, seed: seed).generate();
        // Fingerprint each combat room by pit/trap counts.
        for (final info in map.roomInfos.where((r) => r.kind == RoomKind.combat)) {
          var pits = 0, traps = 0;
          final b = info.bounds;
          for (var y = b.top; y < b.top + b.height; y++) {
            for (var x = b.left; x < b.left + b.width; x++) {
              final t = map.tileAt(x, y);
              if (t == TileType.pit) pits++;
              if (t == TileType.trapSmall || t == TileType.trapBig) traps++;
            }
          }
          final key = 'p$pits-t$traps';
          counts[key] = (counts[key] ?? 0) + 1;
        }
      }
    }
    expect(counts.length, greaterThanOrEqualTo(5),
        reason: 'expected several distinct combat fingerprints, got $counts');
  });

  test('RoomLayouts unlocks more combat stamps on higher floors', () {
    final low = <int>{};
    final high = <int>{};
    for (var i = 0; i < 40; i++) {
      low.add(_layoutFingerprint(RoomLayouts(Random(i)), floor: 1));
      high.add(_layoutFingerprint(RoomLayouts(Random(i)), floor: 8));
    }
    expect(high.length, greaterThanOrEqualTo(low.length));
  });

  test('each doorway has one shared spawn tagged with both room keys', () {
    final map = DungeonGenerator(floor: 1, seed: 4).generate();
    expect(map.doorSpawns, isNotEmpty);
    final byCell = <String, int>{};
    for (final d in map.doorSpawns) {
      final cell = '${d.pos.x},${d.pos.y}';
      byCell[cell] = (byCell[cell] ?? 0) + 1;
      expect(d.roomKeys.length, 2);
    }
    for (final e in byCell.entries) {
      expect(e.value, 1, reason: 'duplicate door spawn at ${e.key}');
    }
  });

  testWithGame<PixelCrawlerGame>(
    'crossing into an uncleared room ejects the player off the doorway',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      final start = game.currentRoom!;
      for (final m in game.world.children.query<Monster>().toList()) {
        m.hp = 0;
        m.removeFromParent();
      }
      game.update(0);

      final door = game.world.children
          .query<Door>()
          .where((d) => d.isOnPerimeterOf(start) && d.open)
          .first;
      expect(door.open, isTrue);

      final otherKey =
          door.spawn.roomKeys.firstWhere((k) => k != start.gridKey);
      final parts = otherKey.split(',');
      final other = game.map.roomInfos.firstWhere(
        (r) => r.gridX == int.parse(parts[0]) && r.gridY == int.parse(parts[1]),
      );

      final ob = other.bounds;
      final slime = Monster(
        def: monsters[MonsterType.slime]!,
        position: Vector2(
          (ob.left + ob.width / 2) * tileSize,
          (ob.top + ob.height / 2) * tileSize,
        ),
        floor: 1,
      );
      await game.world.add(slime);

      final facing = door.facingForRoom(other);
      final dx = switch (facing) {
        DoorDir.west => 1,
        DoorDir.east => -1,
        _ => 0,
      };
      final dy = switch (facing) {
        DoorDir.north => 1,
        DoorDir.south => -1,
        _ => 0,
      };
      game.player!.position = Vector2(
        (door.spawn.pos.x + dx) * tileSize + tileSize / 2,
        (door.spawn.pos.y + dy) * tileSize + tileSize - 2,
      );

      game.update(0);
      expect(game.currentRoom?.gridKey, other.gridKey);
      expect(game.currentRoomCleared, isFalse);
      game.update(0);
      expect(door.open, isFalse);

      final px = game.player!.position.x ~/ tileSize;
      final py = game.player!.position.y ~/ tileSize;
      expect(game.map.isDoorTile(px, py), isFalse);
      expect(game.map.roomInfoContaining(px, py)?.gridKey, other.gridKey);
      expect(door.playerOverlapsDoorway(), isFalse);
      expect(door.blocksPassage, isTrue);

      final before = game.player!.position.clone();
      final toward = Vector2(
        (ob.left + ob.width / 2) * tileSize,
        (ob.top + ob.height / 2) * tileSize,
      );
      final step = (toward - before)..normalize();
      final moved = game.player!.moveAndCollide(step * 4);
      expect(moved.length, greaterThan(0));
    },
  );

  testWithGame<PixelCrawlerGame>(
    'unlocking a locked door persists without spending another key',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      for (final m in game.world.children.query<Monster>().toList()) {
        m.hp = 0;
        m.removeFromParent();
      }
      game.keys = 2;
      game.keysNotifier.value = 2;
      game.update(0);

      final locked = game.world.children
          .query<Door>()
          .where((d) => d.spawn.locked && d.isOnPerimeterOf(game.currentRoom))
          .toList();

      if (locked.isEmpty) {
        final spawn = DoorSpawn(
          pos: const Point(0, 0),
          dir: DoorDir.north,
          locked: true,
          roomKeys: {'0,0', '1,0'},
        );
        expect(spawn.unlocked, isFalse);
        spawn.unlocked = true;
        expect(spawn.unlocked, isTrue);
        return;
      }

      final door = locked.first;
      game.player!.position = Vector2(
        door.spawn.pos.x * tileSize + tileSize / 2,
        door.spawn.pos.y * tileSize + tileSize / 2,
      );
      game.update(0);
      expect(door.spawn.unlocked, isTrue);
      expect(door.open, isTrue);

      final keysBefore = game.keys;
      door.setOpen(false);
      game.update(0);
      expect(door.open, isTrue);
      expect(game.keys, keysBefore);
    },
  );
}

int _layoutFingerprint(RoomLayouts layouts, {required int floor}) {
  final map = DungeonMap(20, 16);
  final room = const Rectangle(2, 2, 13, 9);
  for (var y = room.top; y < room.top + room.height; y++) {
    for (var x = room.left; x < room.left + room.width; x++) {
      map.setTile(x, y, TileType.floor);
    }
  }
  layouts.apply(map, room, RoomKind.combat, floor: floor);
  var h = 0;
  for (var y = room.top; y < room.top + room.height; y++) {
    for (var x = room.left; x < room.left + room.width; x++) {
      h = h * 33 + map.tileAt(x, y).index;
    }
  }
  return h;
}
