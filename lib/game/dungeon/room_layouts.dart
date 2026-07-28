import 'dart:math';

import 'dungeon_map.dart';

/// Isaac-inspired room layout stamps applied to a room's interior.
///
/// Traps and pits follow deliberate patterns (grids, lanes, chokepoints) —
/// never scatter-random placement.
class RoomLayouts {
  RoomLayouts(this._rng);

  final Random _rng;

  void apply(DungeonMap map, Rectangle<int> room, RoomKind kind) {
    switch (kind) {
      case RoomKind.start:
        _lightDecor(map, room);
      case RoomKind.shop:
        break; // pedestals placed by generator
      case RoomKind.boss:
        _bossArena(map, room);
      case RoomKind.treasure:
        _treasureGauntlet(map, room);
      case RoomKind.combat:
        _combatVariant(map, room);
    }
  }

  void _combatVariant(DungeonMap map, Rectangle<int> room) {
    switch (_rng.nextInt(6)) {
      case 0:
        _crossPit(map, room);
      case 1:
        _spikeCheckerboard(map, room);
      case 2:
        _bridgeLanes(map, room);
      case 3:
        _diagonalBridges(map, room);
      case 4:
        _storage(map, room);
      default:
        _chokepointTraps(map, room);
    }
  }

  void _lightDecor(DungeonMap map, Rectangle<int> room) {
    _scatterDecor(map, room, 1 + _rng.nextInt(2));
  }

  void _bossArena(DungeonMap map, Rectangle<int> room) {
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
