import 'dart:math';

import 'dungeon_map.dart';

/// Isaac-inspired room layout stamps applied to a room's interior.
///
/// Traps and pits follow deliberate patterns (grids, lanes, chokepoints) —
/// never scatter-random placement.
class RoomLayouts {
  RoomLayouts(this._rng);

  final Random _rng;

  void apply(DungeonMap map, Rectangle<int> room, RoomKind kind, {int floor = 1}) {
    switch (kind) {
      case RoomKind.start:
        _startVariant(map, room, floor);
      case RoomKind.shop:
        break; // pedestals placed by generator
      case RoomKind.boss:
        _bossArena(map, room, floor);
      case RoomKind.treasure:
        _treasureGauntlet(map, room);
      case RoomKind.combat:
        _combatVariant(map, room, floor);
    }
  }

  void _startVariant(DungeonMap map, Rectangle<int> room, int floor) {
    switch (_rng.nextInt(3)) {
      case 0:
        _lightDecor(map, room);
      case 1:
        _scatterDecor(map, room, 2 + _rng.nextInt(2));
        _tryPillars(map, room, cornersOnly: true);
      default:
        _lightDecor(map, room);
        if (floor > 1 && _rng.nextDouble() < 0.4) {
          _ringFloorMarks(map, room);
        }
    }
  }

  void _combatVariant(DungeonMap map, Rectangle<int> room, int floor) {
    // Growing pool with floor so later runs feel less repetitive.
    final pool = <void Function(DungeonMap, Rectangle<int>)>[
      _crossPit,
      _spikeCheckerboard,
      _bridgeLanes,
      _diagonalBridges,
      _storage,
      _chokepointTraps,
      _fourPillars,
      _centerArena,
      _sideGalleries,
      _zigzagBridge,
      _sparseHazards,
      _quadPits,
    ];
    final unlocked = (6 + (floor - 1)).clamp(6, pool.length);
    // Avoid reusing the same stamp twice in a row on a floor.
    var idx = _rng.nextInt(unlocked);
    if (_lastCombatIdx == idx && unlocked > 1) {
      idx = (idx + 1 + _rng.nextInt(unlocked - 1)) % unlocked;
    }
    _lastCombatIdx = idx;
    pool[idx](map, room);
  }

  int? _lastCombatIdx;

  void _lightDecor(DungeonMap map, Rectangle<int> room) {
    _scatterDecor(map, room, 1 + _rng.nextInt(2));
  }

  void _bossArena(DungeonMap map, Rectangle<int> room, int floor) {
    // Corner pit pockets; open arena in the middle.
    for (final c in [
      Point(room.left + 1, room.top + 1),
      Point(room.left + room.width - 2, room.top + 1),
      Point(room.left + 1, room.top + room.height - 2),
      Point(room.left + room.width - 2, room.top + room.height - 2),
    ]) {
      _tryPit(map, c.x, c.y);
      _tryPit(map, c.x + (c.x < room.left + room.width / 2 ? 1 : -1), c.y);
      _tryPit(map, c.x, c.y + (c.y < room.top + room.height / 2 ? 1 : -1));
    }
    if (floor >= 3 && _rng.nextDouble() < 0.5) {
      final cx = room.left + room.width ~/ 2;
      final cy = room.top + room.height ~/ 2;
      _tryTrap(map, cx - 2, cy, big: true);
      _tryTrap(map, cx + 2, cy, big: true);
    }
  }

  /// Central walkway to the far side; pits on flanks; small traps flanking
  /// the path just before the chest zone (far end of the room).
  void _treasureGauntlet(DungeonMap map, Rectangle<int> room) {
    final cy = room.top + room.height ~/ 2;
    final cx = room.left + room.width ~/ 2;
    for (var y = room.top + 1; y < room.top + room.height - 1; y++) {
      for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
        final onPath = (y - cy).abs() <= 1 || (x == cx && y < cy);
        if (!onPath) _tryPit(map, x, y);
      }
    }
    // Trap "teeth" along the approach, alternating sides.
    for (var x = room.left + 2; x < room.left + room.width - 2; x++) {
      if ((x - room.left) % 2 == 0) {
        _tryTrap(map, x, cy - 1, big: false);
        _tryTrap(map, x, cy + 1, big: false);
      }
    }
    // Big spikes mark the chest landing pad edges.
    _tryTrap(map, room.left + room.width - 3, cy, big: true);
    _tryTrap(map, room.left + 2, cy, big: true);
  }

  /// Cross-shaped walkway over a pit (center arena).
  void _crossPit(DungeonMap map, Rectangle<int> room) {
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    for (var y = room.top + 1; y < room.top + room.height - 1; y++) {
      for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
        final onCross =
            x == cx || y == cy || (x - cx).abs() + (y - cy).abs() <= 1;
        if (!onCross) _tryPit(map, x, y);
      }
    }
  }

  /// Regular checkerboard of small spikes in the inner area; big spikes on
  /// the four cardinal mid-edges. Perimeter stays clear for routing.
  void _spikeCheckerboard(DungeonMap map, Rectangle<int> room) {
    for (var y = room.top + 2; y < room.top + room.height - 2; y++) {
      for (var x = room.left + 2; x < room.left + room.width - 2; x++) {
        if ((x + y).isEven) {
          _tryTrap(map, x, y, big: false);
        }
      }
    }
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    _tryTrap(map, cx, room.top + 2, big: true);
    _tryTrap(map, cx, room.top + room.height - 3, big: true);
    _tryTrap(map, room.left + 2, cy, big: true);
    _tryTrap(map, room.left + room.width - 3, cy, big: true);
  }

  /// Three horizontal lanes separated by pits; small traps every 3 tiles
  /// on each lane (phase-offset so lanes aren't identical).
  void _bridgeLanes(DungeonMap map, Rectangle<int> room) {
    final mid = room.top + room.height ~/ 2;
    final lanes = [mid - 2, mid, mid + 2];
    for (var y = room.top + 1; y < room.top + room.height - 1; y++) {
      if (lanes.contains(y)) continue;
      for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
        _tryPit(map, x, y);
      }
    }
    for (var i = 0; i < lanes.length; i++) {
      final ly = lanes[i];
      if (ly <= room.top || ly >= room.top + room.height - 1) continue;
      final phase = i; // offset each lane
      for (var x = room.left + 2 + phase; x < room.left + room.width - 2; x += 3) {
        _tryTrap(map, x, ly, big: false);
      }
    }
  }

  /// Diagonal walkways across a pit.
  void _diagonalBridges(DungeonMap map, Rectangle<int> room) {
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    for (var y = room.top + 1; y < room.top + room.height - 1; y++) {
      for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
        final d1 = (x - cx) == (y - cy);
        final d2 = (x - cx) == (cy - y);
        final hub = (x - cx).abs() <= 1 && (y - cy).abs() <= 1;
        if (!d1 && !d2 && !hub) _tryPit(map, x, y);
      }
    }
    // Big trap at the hub as a risk/reward center.
    _tryTrap(map, cx, cy, big: true);
  }

  /// Props along the walls; small traps only in the tile immediately in
  /// front of each prop (guarding loot clutter).
  void _storage(DungeonMap map, Rectangle<int> room) {
    final props = <Point<int>>[];
    // Place props on a ring one tile in from the wall, every other cell.
    for (var x = room.left + 1; x < room.left + room.width - 1; x += 2) {
      props.add(Point(x, room.top + 1));
      props.add(Point(x, room.top + room.height - 2));
    }
    for (var y = room.top + 3; y < room.top + room.height - 3; y += 2) {
      props.add(Point(room.left + 1, y));
      props.add(Point(room.left + room.width - 2, y));
    }
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    for (final p in props) {
      if (!map.isWalkable(p.x, p.y) && map.tileAt(p.x, p.y) != TileType.floor) {
        continue;
      }
      map.setTile(p.x, p.y, TileType.floor);
      map.decorSpawns.add((p, _rng.nextInt(3))); // solid props only
      // Trap toward the room center from the prop.
      final tx = p.x + (cx - p.x).sign;
      final ty = p.y + (cy - p.y).sign;
      if (tx == p.x && ty == p.y) continue;
      _tryTrap(map, tx, ty, big: false);
    }
  }

  /// Side pits creating a narrow north-south chokepoint; a column of big
  /// traps down the center forces a deliberate weave.
  void _chokepointTraps(DungeonMap map, Rectangle<int> room) {
    final cx = room.left + room.width ~/ 2;
    for (var y = room.top + 1; y < room.top + room.height - 1; y++) {
      for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
        if ((x - cx).abs() >= 2) _tryPit(map, x, y);
      }
    }
    // Alternating big/small traps on the corridor, leaving gaps to step through.
    var i = 0;
    for (var y = room.top + 2; y < room.top + room.height - 2; y++) {
      if (i.isEven) {
        _tryTrap(map, cx, y, big: true);
      } else {
        // Gap on center; small traps on the shoulders.
        _tryTrap(map, cx - 1, y, big: false);
        _tryTrap(map, cx + 1, y, big: false);
      }
      i++;
    }
  }

  /// Four solid pillars inset from the corners.
  void _fourPillars(DungeonMap map, Rectangle<int> room) {
    _tryPillars(map, room, cornersOnly: false);
    _scatterDecor(map, room, 1 + _rng.nextInt(2));
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    _tryTrap(map, cx, cy, big: true);
  }

  /// Mostly open floor with a ring of small traps and sparse decor.
  void _centerArena(DungeonMap map, Rectangle<int> room) {
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    for (var y = room.top + 2; y < room.top + room.height - 2; y++) {
      for (var x = room.left + 2; x < room.left + room.width - 2; x++) {
        final dx = (x - cx).abs();
        final dy = (y - cy).abs();
        if (dx == 3 || dy == 3) {
          _tryTrap(map, x, y, big: false);
        }
      }
    }
    _scatterDecor(map, room, 2 + _rng.nextInt(3));
  }

  /// Vertical galleries on the sides with a clear center lane.
  void _sideGalleries(DungeonMap map, Rectangle<int> room) {
    final cx = room.left + room.width ~/ 2;
    for (var y = room.top + 1; y < room.top + room.height - 1; y++) {
      for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
        if ((x - cx).abs() >= 3) {
          if ((y + x).isEven) {
            _tryPit(map, x, y);
          } else {
            _tryTrap(map, x, y, big: false);
          }
        }
      }
    }
    _scatterDecor(map, room, 1);
  }

  /// Zigzag safe path across an otherwise pitted room.
  void _zigzagBridge(DungeonMap map, Rectangle<int> room) {
    final path = <Point<int>>{};
    var x = room.left + 1;
    var y = room.top + room.height ~/ 2;
    var dir = 1;
    while (x < room.left + room.width - 1) {
      path.add(Point(x, y));
      path.add(Point(x, y + dir));
      y += dir;
      if (y <= room.top + 1 || y >= room.top + room.height - 2) dir = -dir;
      x++;
    }
    for (var py = room.top + 1; py < room.top + room.height - 1; py++) {
      for (var px = room.left + 1; px < room.left + room.width - 1; px++) {
        if (!path.contains(Point(px, py))) _tryPit(map, px, py);
      }
    }
  }

  /// Light combat room: few traps, more props — breathing room between denser stamps.
  void _sparseHazards(DungeonMap map, Rectangle<int> room) {
    _scatterDecor(map, room, 3 + _rng.nextInt(3));
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    _tryTrap(map, cx - 3, cy - 2, big: false);
    _tryTrap(map, cx + 3, cy + 2, big: false);
    _tryTrap(map, cx + 2, cy - 3, big: true);
  }

  /// Four pit blocks in the quadrants with a cross of floor between them.
  void _quadPits(DungeonMap map, Rectangle<int> room) {
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    for (var y = room.top + 1; y < room.top + room.height - 1; y++) {
      for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
        final onCross = x == cx || y == cy;
        final inQuad = (x - cx).abs() >= 2 && (y - cy).abs() >= 2;
        if (!onCross && inQuad) _tryPit(map, x, y);
      }
    }
    _tryTrap(map, cx, cy, big: false);
  }

  void _tryPillars(DungeonMap map, Rectangle<int> room, {required bool cornersOnly}) {
    final points = <Point<int>>[
      Point(room.left + 2, room.top + 2),
      Point(room.left + room.width - 3, room.top + 2),
      Point(room.left + 2, room.top + room.height - 3),
      Point(room.left + room.width - 3, room.top + room.height - 3),
    ];
    if (!cornersOnly) {
      points.addAll([
        Point(room.left + 2, room.top + room.height ~/ 2),
        Point(room.left + room.width - 3, room.top + room.height ~/ 2),
      ]);
    }
    for (final p in points) {
      if (map.tileAt(p.x, p.y) == TileType.floor) {
        map.decorSpawns.add((p, _rng.nextInt(3)));
      }
    }
  }

  void _ringFloorMarks(DungeonMap map, Rectangle<int> room) {
    // Soft flavour: a few traps near walls only.
    for (var x = room.left + 2; x < room.left + room.width - 2; x += 3) {
      _tryTrap(map, x, room.top + 2, big: false);
      _tryTrap(map, x, room.top + room.height - 3, big: false);
    }
  }

  void _scatterDecor(DungeonMap map, Rectangle<int> room, int count) {
    for (var i = 0; i < count; i++) {
      final p = _spot(map, room);
      if (p != null) {
        map.decorSpawns.add((p, _rng.nextInt(5)));
      }
    }
  }

  void _tryPit(DungeonMap map, int x, int y) {
    if (map.tileAt(x, y) == TileType.floor) {
      map.setTile(x, y, TileType.pit);
    }
  }

  void _tryTrap(DungeonMap map, int x, int y, {required bool big}) {
    if (map.tileAt(x, y) == TileType.floor) {
      map.setTile(x, y, big ? TileType.trapBig : TileType.trapSmall);
    }
  }

  Point<int>? _spot(DungeonMap map, Rectangle<int> room) {
    for (var i = 0; i < 20; i++) {
      final p = Point(
        room.left + 1 + _rng.nextInt(max(1, room.width - 2)),
        room.top + 1 + _rng.nextInt(max(1, room.height - 2)),
      );
      if (map.tileAt(p.x, p.y) == TileType.floor) return p;
    }
    return null;
  }
}
