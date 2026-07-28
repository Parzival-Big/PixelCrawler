import 'dart:math';

import '../store_catalog.dart';
import 'dungeon_map.dart';
import 'room_layouts.dart';

/// Binding-of-Isaac style floor: a graph of fixed-size rooms with doors,
/// pits, traps, a boss room (stairs + boss key), and an optional shop room.
class DungeonGenerator {
  DungeonGenerator({
    required this.floor,
    this.shopChance = 0.05,
    int? seed,
  }) : _rng = Random(seed ?? DateTime.now().millisecondsSinceEpoch);

  final int floor;
  final double shopChance;
  final Random _rng;

  /// Interior size of each room (Isaac-like).
  static const interiorW = 13;
  static const interiorH = 9;

  /// Cell stride including shared walls.
  static const strideX = interiorW + 1;
  static const strideY = interiorH + 1;

  DungeonMap generate() {
    final roomCount = (6 + floor).clamp(6, 12);
    final graph = _buildRoomGraph(roomCount);

    // Assign kinds.
    final startId = 0;
    var bossId = 0;
    var bestDist = -1;
    for (final e in graph.entries) {
      final d = (e.value.gx - graph[startId]!.gx).abs() +
          (e.value.gy - graph[startId]!.gy).abs();
      if (d >= bestDist) {
        bestDist = d;
        bossId = e.key;
      }
    }

    final includeShop = _rng.nextDouble() < shopChance;
    int? shopId;
    if (includeShop) {
      final candidates = graph.keys
          .where((id) => id != startId && id != bossId)
          .toList();
      if (candidates.isNotEmpty) {
        shopId = candidates[_rng.nextInt(candidates.length)];
      }
    }

    // Treasure: one random non-special room.
    int? treasureId;
    final treasurePool = graph.keys
        .where((id) => id != startId && id != bossId && id != shopId)
        .toList();
    if (treasurePool.isNotEmpty) {
      treasureId = treasurePool[_rng.nextInt(treasurePool.length)];
    }

    RoomKind kindOf(int id) {
      if (id == startId) return RoomKind.start;
      if (id == bossId) return RoomKind.boss;
      if (id == shopId) return RoomKind.shop;
      if (id == treasureId) return RoomKind.treasure;
      return RoomKind.combat;
    }

    // Compute map bounds from graph.
    var minGx = 0, maxGx = 0, minGy = 0, maxGy = 0;
    for (final n in graph.values) {
      minGx = min(minGx, n.gx);
      maxGx = max(maxGx, n.gx);
      minGy = min(minGy, n.gy);
      maxGy = max(maxGy, n.gy);
    }
    final pad = 2;
    final mapW = (maxGx - minGx + 1) * strideX + 1 + pad * 2;
    final mapH = (maxGy - minGy + 1) * strideY + 1 + pad * 2;
    final map = DungeonMap(mapW, mapH);
    map.hasShopRoom = shopId != null;

    Point<int> originOf(_GraphNode n) => Point(
          pad + (n.gx - minGx) * strideX,
          pad + (n.gy - minGy) * strideY,
        );

    // Carve rooms.
    final layouts = RoomLayouts(_rng);
    for (final e in graph.entries) {
      final node = e.value;
      final o = originOf(node);
      final interior = Rectangle(
        o.x + 1,
        o.y + 1,
        interiorW,
        interiorH,
      );
      _carveRoom(map, o);
      map.rooms.add(interior);
      map.roomInfos.add(RoomInfo(
        bounds: interior,
        kind: kindOf(e.key),
        gridX: node.gx,
        gridY: node.gy,
      ));
      layouts.apply(map, interior, kindOf(e.key));
      _clearDoorApproaches(map, interior);
    }

    // Connect neighbors with door openings.
    final seenEdges = <String>{};
    for (final e in graph.entries) {
      for (final nId in e.value.neighbors) {
        final a = min(e.key, nId);
        final b = max(e.key, nId);
        final key = '$a-$b';
        if (!seenEdges.add(key)) continue;
        _connectRooms(
          map,
          graph[e.key]!,
          graph[nId]!,
          originOf,
          kindOf(e.key),
          kindOf(nId),
        );
      }
    }

    _raiseWalls(map);
    _placeContent(map, startId: startId, bossId: bossId, shopId: shopId);
    return map;
  }

  /// Random-walk room graph (Isaac classic).
  Map<int, _GraphNode> _buildRoomGraph(int target) {
    final nodes = <int, _GraphNode>{
      0: _GraphNode(0, 0),
    };
    final occupied = <Point<int>>{const Point(0, 0)};
    var nextId = 1;
    var guard = 0;
    while (nodes.length < target && guard < 400) {
      guard++;
      final ids = nodes.keys.toList()..shuffle(_rng);
      final from = nodes[ids.first]!;
      final dirs = <Point<int>>[
        const Point(1, 0),
        const Point(-1, 0),
        const Point(0, 1),
        const Point(0, -1),
      ]..shuffle(_rng);
      for (final d in dirs) {
        final p = Point(from.gx + d.x, from.gy + d.y);
        if (occupied.contains(p)) continue;
        // Soft limit sprawl.
        if (p.x.abs() > 4 || p.y.abs() > 4) continue;
        final id = nextId++;
        final node = _GraphNode(p.x, p.y);
        nodes[id] = node;
        occupied.add(p);
        // Link to all orthogonal neighbors already placed.
        for (final other in nodes.entries) {
          if (other.key == id) continue;
          final dx = (other.value.gx - node.gx).abs();
          final dy = (other.value.gy - node.gy).abs();
          if (dx + dy == 1) {
            node.neighbors.add(other.key);
            other.value.neighbors.add(id);
          }
        }
        break;
      }
    }
    return nodes;
  }

  void _carveRoom(DungeonMap map, Point<int> origin) {
    // Full cell including walls as floor first; walls raised later.
    for (var y = 0; y <= interiorH + 1; y++) {
      for (var x = 0; x <= interiorW + 1; x++) {
        final edge = x == 0 ||
            y == 0 ||
            x == interiorW + 1 ||
            y == interiorH + 1;
        map.setTile(
          origin.x + x,
          origin.y + y,
          edge ? TileType.wall : TileType.floor,
        );
      }
    }
  }

  /// Keep a short walkable path from each wall midpoint toward the center
  /// so layouts with pits never seal doorways.
  void _clearDoorApproaches(DungeonMap map, Rectangle<int> room) {
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    final entries = [
      Point(cx, room.top),
      Point(cx, room.top + room.height - 1),
      Point(room.left, cy),
      Point(room.left + room.width - 1, cy),
    ];
    for (final e in entries) {
      var x = e.x;
      var y = e.y;
      for (var step = 0; step < 3; step++) {
        if (map.tileAt(x, y) == TileType.pit || map.isTrap(x, y)) {
          map.setTile(x, y, TileType.floor);
        }
        x += (cx - e.x).sign;
        y += (cy - e.y).sign;
      }
    }
  }

  void _connectRooms(
    DungeonMap map,
    _GraphNode a,
    _GraphNode b,
    Point<int> Function(_GraphNode) originOf,
    RoomKind kindA,
    RoomKind kindB,
  ) {
    final oa = originOf(a);
    final dx = b.gx - a.gx;
    final dy = b.gy - a.gy;

    late Point<int> doorA;
    late DoorDir dirA;

    if (dx == 1 && dy == 0) {
      // A west of B — shared east wall of A.
      final midY = 1 + interiorH ~/ 2;
      doorA = Point(oa.x + interiorW + 1, oa.y + midY);
      dirA = DoorDir.east;
    } else if (dx == -1 && dy == 0) {
      final midY = 1 + interiorH ~/ 2;
      doorA = Point(oa.x, oa.y + midY);
      dirA = DoorDir.west;
    } else if (dy == 1 && dx == 0) {
      final midX = 1 + interiorW ~/ 2;
      doorA = Point(oa.x + midX, oa.y + interiorH + 1);
      dirA = DoorDir.south;
    } else if (dy == -1 && dx == 0) {
      final midX = 1 + interiorW ~/ 2;
      doorA = Point(oa.x + midX, oa.y);
      dirA = DoorDir.north;
    } else {
      return;
    }

    // Shared wall cell becomes the doorway; directional door tile sits here.
    map.setTile(doorA.x, doorA.y, TileType.floor);

    final toBoss = kindA == RoomKind.boss || kindB == RoomKind.boss;
    final fromStart = kindA == RoomKind.start || kindB == RoomKind.start;
    final locked = !toBoss && !fromStart && _rng.nextDouble() < 0.35;

    map.doorSpawns.add(DoorSpawn(
      pos: doorA,
      dir: dirA,
      locked: locked,
      bossDoor: toBoss,
    ));
  }

  void _raiseWalls(DungeonMap map) {
    // Ensure empty cells touching floor become walls (for corridor seams).
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.tileAt(x, y) != TileType.empty) continue;
        var touches = false;
        for (var dy = -1; dy <= 1 && !touches; dy++) {
          for (var dx = -1; dx <= 1; dx++) {
            final t = map.tileAt(x + dx, y + dy);
            if (t == TileType.floor ||
                t == TileType.stairs ||
                t == TileType.trapSmall ||
                t == TileType.trapBig ||
                t == TileType.pit) {
              touches = true;
              break;
            }
          }
        }
        if (touches) map.setTile(x, y, TileType.wall);
      }
    }
  }

  void _placeContent(
    DungeonMap map, {
    required int startId,
    required int bossId,
    required int? shopId,
  }) {
    final infos = map.roomInfos;
    final start = infos.firstWhere((r) => r.kind == RoomKind.start);
    final boss = infos.firstWhere((r) => r.kind == RoomKind.boss);
    map.playerSpawn = _center(start.bounds);

    // Stairs + boss in boss room.
    map.stairsPos = _center(boss.bounds);
    map.setTile(map.stairsPos.x, map.stairsPos.y, TileType.stairs);
    map.bossSpawn = Point(map.stairsPos.x, map.stairsPos.y - 2);
    if (!map.isWalkable(map.bossSpawn!.x, map.bossSpawn!.y)) {
      map.bossSpawn = Point(map.stairsPos.x, map.stairsPos.y + 2);
    }
    // Clear pits under boss/stairs.
    for (final p in [map.stairsPos, map.bossSpawn!]) {
      if (map.tileAt(p.x, p.y) == TileType.pit || map.isTrap(p.x, p.y)) {
        map.setTile(p.x, p.y, p == map.stairsPos ? TileType.stairs : TileType.floor);
      }
    }

    final used = <Point<int>>{map.playerSpawn, map.stairsPos, map.bossSpawn!};

    Point<int>? randomSpotIn(Rectangle<int> room, {int margin = 1}) {
      for (var i = 0; i < 30; i++) {
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

    // Shop pedestals: 3 items, cost 30–50.
    if (shopId != null) {
      final shop = infos.firstWhere((r) => r.kind == RoomKind.shop);
      final catalog = StoreCatalog.shopRoomPool;
      final picks = List.of(catalog)..shuffle(_rng);
      final cx = shop.bounds.left + shop.bounds.width ~/ 2;
      final cy = shop.bounds.top + shop.bounds.height ~/ 2;
      final spots = [
        Point(cx - 3, cy),
        Point(cx, cy),
        Point(cx + 3, cy),
      ];
      for (var i = 0; i < 3; i++) {
        final p = spots[i];
        map.setTile(p.x, p.y, TileType.floor);
        used.add(p);
        map.shopPedestals.add(ShopPedestalSpawn(
          pos: p,
          upgradeId: picks[i % picks.length].id,
          cost: 30 + _rng.nextInt(21),
        ));
      }
    }

    // Monsters in combat / treasure rooms.
    for (final info in infos) {
      if (info.kind == RoomKind.start ||
          info.kind == RoomKind.shop ||
          info.kind == RoomKind.boss) {
        continue;
      }
      final count = info.kind == RoomKind.treasure
          ? 1 + _rng.nextInt(2)
          : (2 + floor ~/ 2 + _rng.nextInt(2)).clamp(2, 6);
      for (var i = 0; i < count; i++) {
        final p = randomSpotIn(info.bounds);
        if (p != null) map.monsterSpawns.add(p);
      }
    }

    // Chests: always on a tile reachable from the room center (and thus
    // from the door approaches). Prefer the far side of treasure rooms.
    for (final info in infos) {
      if (info.kind == RoomKind.treasure) {
        final a = _placeReachableChest(map, info.bounds, used, preferFar: true);
        if (a != null) map.chestSpawns.add(a);
        final b = _placeReachableChest(map, info.bounds, used, preferFar: true);
        if (b != null) map.chestSpawns.add(b);
      } else if (info.kind == RoomKind.combat && _rng.nextDouble() < 0.35) {
        final p = _placeReachableChest(map, info.bounds, used);
        if (p != null) map.chestSpawns.add(p);
      }
    }

    // Coins / potions.
    for (var i = 0; i < 5 + _rng.nextInt(5); i++) {
      final room = infos[_rng.nextInt(infos.length)].bounds;
      final p = randomSpotIn(room);
      if (p != null) map.coinSpawns.add(p);
    }
    if (_rng.nextDouble() < 0.7) {
      final p = randomSpotIn(
        infos[_rng.nextInt(infos.length)].bounds,
      );
      if (p != null) map.potionSpawns.add(p);
    }

    // Fire pots + torches.
    for (final info in infos) {
      if (info.kind != RoomKind.shop && _rng.nextDouble() < 0.3) {
        final p = randomSpotIn(info.bounds);
        if (p != null) map.firePotSpawns.add(p);
      }
    }
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        if (map.tileAt(x, y) == TileType.wall &&
            map.isWalkable(x, y + 1) &&
            _rng.nextDouble() < 0.1) {
          map.torchSpawns.add(Point(x, y));
        }
      }
    }
  }

  Point<int> _center(Rectangle<int> r) =>
      Point(r.left + r.width ~/ 2, r.top + r.height ~/ 2);

  /// Picks a walkable chest spot reachable from the room center. If needed,
  /// carves a short floor path so the chest is never stranded on an island.
  Point<int>? _placeReachableChest(
    DungeonMap map,
    Rectangle<int> room,
    Set<Point<int>> used, {
    bool preferFar = false,
  }) {
    final center = _center(room);
    // Ensure the center itself is floor (layouts may have trapped it).
    if (!map.isWalkable(center.x, center.y)) {
      map.setTile(center.x, center.y, TileType.floor);
    }

    final candidates = <Point<int>>[];
    for (var y = room.top + 1; y < room.top + room.height - 1; y++) {
      for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
        final p = Point(x, y);
        if (used.contains(p)) continue;
        if (!map.isWalkable(x, y) && map.tileAt(x, y) != TileType.pit) {
          continue;
        }
        candidates.add(p);
      }
    }
    if (candidates.isEmpty) return null;

    if (preferFar) {
      candidates.sort(
        (a, b) => b.distanceTo(center).compareTo(a.distanceTo(center)),
      );
    } else {
      candidates.shuffle(_rng);
    }

    for (final p in candidates.take(24)) {
      // Clear the destination and a Manhattan path from center → chest.
      _carvePath(map, center, p);
      if (_reachable(map, center, p)) {
        map.setTile(p.x, p.y, TileType.floor);
        used.add(p);
        return p;
      }
    }
    return null;
  }

  void _carvePath(DungeonMap map, Point<int> from, Point<int> to) {
    var x = from.x;
    var y = from.y;
    while (x != to.x) {
      x += (to.x - x).sign;
      final t = map.tileAt(x, y);
      if (t == TileType.pit || map.isTrap(x, y) || t == TileType.empty) {
        map.setTile(x, y, TileType.floor);
      }
    }
    while (y != to.y) {
      y += (to.y - y).sign;
      final t = map.tileAt(x, y);
      if (t == TileType.pit || map.isTrap(x, y) || t == TileType.empty) {
        map.setTile(x, y, TileType.floor);
      }
    }
  }

  bool _reachable(DungeonMap map, Point<int> from, Point<int> to) {
    if (!map.isWalkable(from.x, from.y) || !map.isWalkable(to.x, to.y)) {
      return false;
    }
    final seen = <Point<int>>{from};
    final q = <Point<int>>[from];
    while (q.isNotEmpty) {
      final p = q.removeAt(0);
      if (p == to) return true;
      for (final d in const [
        Point(1, 0),
        Point(-1, 0),
        Point(0, 1),
        Point(0, -1),
      ]) {
        final n = Point(p.x + d.x, p.y + d.y);
        if (seen.contains(n) || !map.isWalkable(n.x, n.y)) continue;
        seen.add(n);
        q.add(n);
      }
    }
    return false;
  }
}

class _GraphNode {
  _GraphNode(this.gx, this.gy);
  final int gx;
  final int gy;
  final neighbors = <int>[];
}
