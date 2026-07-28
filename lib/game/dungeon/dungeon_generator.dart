import 'dart:math';

import 'dungeon_map.dart';

/// Classic rooms-and-corridors generator.
///
/// Rooms are carved at random non-overlapping positions, then connected in
/// sequence with L-shaped corridors. Solid cells touching a floor cell
/// become walls; everything else stays empty (not rendered).
class DungeonGenerator {
  DungeonGenerator({required this.floor, int? seed})
      : _rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  final int floor;
  final Random _rng;

  DungeonMap generate() {
    final size = (34 + floor * 3).clamp(34, 56);
    final map = DungeonMap(size, size);
    final roomTarget = (5 + floor).clamp(5, 11);

    _carveRooms(map, roomTarget);
    _connectRooms(map);
    _raiseWalls(map);
    _placeContent(map);
    return map;
  }

  void _carveRooms(DungeonMap map, int target) {
    var attempts = 0;
    while (map.rooms.length < target && attempts < 200) {
      attempts++;
      final w = 5 + _rng.nextInt(6);
      final h = 5 + _rng.nextInt(5);
      final x = 2 + _rng.nextInt(map.width - w - 4);
      final y = 2 + _rng.nextInt(map.height - h - 4);
      final room = Rectangle(x, y, w, h);
      final padded = Rectangle(x - 2, y - 2, w + 4, h + 4);
      if (map.rooms.any((r) => r.intersects(padded))) continue;
      map.rooms.add(room);
      for (var ty = y; ty < y + h; ty++) {
        for (var tx = x; tx < x + w; tx++) {
          map.setTile(tx, ty, TileType.floor);
        }
      }
    }
  }

  void _connectRooms(DungeonMap map) {
    for (var i = 1; i < map.rooms.length; i++) {
      final a = _center(map.rooms[i - 1]);
      final b = _center(map.rooms[i]);
      if (_rng.nextBool()) {
        _hCorridor(map, a.x, b.x, a.y);
        _vCorridor(map, a.y, b.y, b.x);
      } else {
        _vCorridor(map, a.y, b.y, a.x);
        _hCorridor(map, a.x, b.x, b.y);
      }
    }
  }

  Point<int> _center(Rectangle<int> r) =>
      Point(r.left + r.width ~/ 2, r.top + r.height ~/ 2);

  void _hCorridor(DungeonMap map, int x1, int x2, int y) {
    for (var x = min(x1, x2); x <= max(x1, x2); x++) {
      map.setTile(x, y, TileType.floor);
      map.setTile(x, y + 1, TileType.floor);
    }
  }

  void _vCorridor(DungeonMap map, int y1, int y2, int x) {
    for (var y = min(y1, y2); y <= max(y1, y2); y++) {
      map.setTile(x, y, TileType.floor);
      map.setTile(x + 1, y, TileType.floor);
    }
  }

  void _raiseWalls(DungeonMap map) {
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.tileAt(x, y) != TileType.empty) continue;
        var touchesFloor = false;
        for (var dy = -1; dy <= 1 && !touchesFloor; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            if (map.tileAt(x + dx, y + dy) == TileType.floor) {
              touchesFloor = true;
              break;
            }
          }
        }
        if (touchesFloor) map.setTile(x, y, TileType.wall);
      }
    }
  }

  void _placeContent(DungeonMap map) {
    final rooms = map.rooms;
    final start = rooms.first;
    map.playerSpawn = _center(start);

    // Stairs go in the room farthest from the spawn.
    var far = rooms.last;
    var best = -1.0;
    for (final r in rooms.skip(1)) {
      final d = _center(r).distanceTo(map.playerSpawn).toDouble();
      if (d > best) {
        best = d;
        far = r;
      }
    }
    map.stairsPos = _center(far);
    map.setTile(map.stairsPos.x, map.stairsPos.y, TileType.stairs);

    final used = <Point<int>>{map.playerSpawn, map.stairsPos};

    Point<int>? randomSpotIn(Rectangle<int> room, {int margin = 1}) {
      for (var i = 0; i < 24; i++) {
        final p = Point(
          room.left + margin + _rng.nextInt(max(1, room.width - margin * 2)),
          room.top + margin + _rng.nextInt(max(1, room.height - margin * 2)),
        );
        if (used.contains(p) || !map.isWalkable(p.x, p.y)) continue;
        used.add(p);
        return p;
      }
      return null;
    }

    // Monsters: none in the starting room.
    final monsterCount = (3 + floor * 2).clamp(3, 14);
    final hostileRooms = rooms.skip(1).toList();
    for (var i = 0; i < monsterCount && hostileRooms.isNotEmpty; i++) {
      final room = hostileRooms[_rng.nextInt(hostileRooms.length)];
      final p = randomSpotIn(room);
      if (p != null && p.distanceTo(map.playerSpawn) > 6) {
        map.monsterSpawns.add(p);
      }
    }

    // Loot.
    final chestCount = 1 + _rng.nextInt(2);
    for (var i = 0; i < chestCount && hostileRooms.isNotEmpty; i++) {
      final p = randomSpotIn(hostileRooms[_rng.nextInt(hostileRooms.length)]);
      if (p != null) map.chestSpawns.add(p);
    }
    for (var i = 0; i < 6 + _rng.nextInt(5); i++) {
      final p = randomSpotIn(rooms[_rng.nextInt(rooms.length)]);
      if (p != null) map.coinSpawns.add(p);
    }
    if (_rng.nextDouble() < 0.8) {
      final p = randomSpotIn(rooms[_rng.nextInt(rooms.length)]);
      if (p != null) map.potionSpawns.add(p);
    }

    // Decorative props along room edges, plus an occasional fire pot.
    for (final room in rooms) {
      final decorCount = _rng.nextInt(3);
      for (var i = 0; i < decorCount; i++) {
        final p = randomSpotIn(room);
        if (p != null && p.distanceTo(map.playerSpawn) > 3) {
          map.decorSpawns.add((p, _rng.nextInt(5)));
        }
      }
      if (_rng.nextDouble() < 0.35) {
        final p = randomSpotIn(room);
        if (p != null) map.firePotSpawns.add(p);
      }
    }

    // Torches on south-facing wall faces.
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.tileAt(x, y) == TileType.wall &&
            map.tileAt(x, y + 1) == TileType.floor &&
            _rng.nextDouble() < 0.14) {
          map.torchSpawns.add(Point(x, y));
        }
      }
    }
  }
}
