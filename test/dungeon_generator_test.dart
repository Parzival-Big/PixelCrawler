import 'dart:collection';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_generator.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_map.dart';

/// BFS over walkable tiles.
bool reachable(DungeonMap map, Point<int> from, Point<int> to) {
  final visited = <Point<int>>{from};
  final queue = Queue<Point<int>>()..add(from);
  while (queue.isNotEmpty) {
    final p = queue.removeFirst();
    if (p == to) return true;
    for (final d in const [Point(1, 0), Point(-1, 0), Point(0, 1), Point(0, -1)]) {
      final n = Point(p.x + d.x, p.y + d.y);
      if (!visited.contains(n) && map.isWalkable(n.x, n.y)) {
        visited.add(n);
        queue.add(n);
      }
    }
  }
  return false;
}

void main() {
  group('DungeonGenerator', () {
    for (var floor = 1; floor <= 8; floor++) {
      for (var seed = 0; seed < 5; seed++) {
        test('floor $floor seed $seed is playable', () {
          final map = DungeonGenerator(floor: floor, seed: seed).generate();

          expect(map.rooms.length, greaterThanOrEqualTo(2));
          expect(map.isWalkable(map.playerSpawn.x, map.playerSpawn.y), isTrue,
              reason: 'player spawn must be walkable');
          expect(map.tileAt(map.stairsPos.x, map.stairsPos.y), TileType.stairs);
          expect(reachable(map, map.playerSpawn, map.stairsPos), isTrue,
              reason: 'stairs must be reachable from spawn');
          expect(map.monsterSpawns, isNotEmpty);
          expect(map.bossSpawn, isNotNull);
          expect(map.doorSpawns, isNotEmpty);
          expect(
            map.roomInfos.any((r) => r.kind == RoomKind.boss),
            isTrue,
          );

          // Every chest must be reachable from the player spawn (tile path).
          for (final chest in map.chestSpawns) {
            expect(map.isWalkable(chest.x, chest.y), isTrue,
                reason: 'chest at $chest must be walkable');
            expect(reachable(map, map.playerSpawn, chest), isTrue,
                reason: 'chest at $chest must be reachable from spawn');
          }

          for (final p in [
            ...map.monsterSpawns,
            ...map.chestSpawns,
            ...map.coinSpawns,
            ...map.potionSpawns,
          ]) {
            expect(map.isWalkable(p.x, p.y), isTrue,
                reason: 'entity at $p must be on a walkable tile');
          }

          // Every torch hangs on a wall with floor below (a visible face).
          for (final t in map.torchSpawns) {
            expect(map.tileAt(t.x, t.y), TileType.wall);
            expect(map.isWalkable(t.x, t.y + 1), isTrue);
          }
        });
      }
    }

    test('difficulty scales with floor', () {
      final easy = DungeonGenerator(floor: 1, seed: 42).generate();
      final hard = DungeonGenerator(floor: 6, seed: 42).generate();
      expect(hard.monsterSpawns.length, greaterThan(easy.monsterSpawns.length));
    });
  });
}
