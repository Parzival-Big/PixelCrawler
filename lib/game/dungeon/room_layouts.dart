import 'dart:math';

import 'dungeon_map.dart';

/// Isaac-inspired room layout stamps applied to a room's interior.
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
        _treasure(map, room);
      case RoomKind.combat:
        _combatVariant(map, room);
    }
  }

  void _combatVariant(DungeonMap map, Rectangle<int> room) {
    final pick = _rng.nextInt(6);
    switch (pick) {
      case 0:
        _crossPit(map, room);
      case 1:
        _spikeField(map, room);
      case 2:
        _bridgeLanes(map, room);
      case 3:
        _diagonalBridges(map, room);
      case 4:
        _storage(map, room);
      default:
        _mixedHazards(map, room);
    }
  }

  void _lightDecor(DungeonMap map, Rectangle<int> room) {
    _scatterDecor(map, room, 1 + _rng.nextInt(2));
  }

  void _bossArena(DungeonMap map, Rectangle<int> room) {
    // Open center, pit ring fragments toward corners.
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    for (final c in [
      Point(room.left + 1, room.top + 1),
      Point(room.left + room.width - 2, room.top + 1),
      Point(room.left + 1, room.top + room.height - 2),
      Point(room.left + room.width - 2, room.top + room.height - 2),
    ]) {
      if ((c.x - cx).abs() > 2 || (c.y - cy).abs() > 2) {
        _tryPit(map, c.x, c.y);
      }
    }
  }

  void _treasure(DungeonMap map, Rectangle<int> room) {
    // Narrow approach with side pits.
    final cy = room.top + room.height ~/ 2;
    for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
      if (x % 2 == 0) {
        _tryPit(map, x, cy - 2);
        _tryPit(map, x, cy + 2);
      }
    }
  }

  /// Cross-shaped walkway over a pit (center arena).
  void _crossPit(DungeonMap map, Rectangle<int> room) {
    final cx = room.left + room.width ~/ 2;
    final cy = room.top + room.height ~/ 2;
    for (var y = room.top + 1; y < room.top + room.height - 1; y++) {
      for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
        final onCross = x == cx || y == cy || (x - cx).abs() + (y - cy).abs() <= 1;
        if (!onCross) _tryPit(map, x, y);
      }
    }
  }

  /// Dense spike grid with a walkable perimeter.
  void _spikeField(DungeonMap map, Rectangle<int> room) {
    for (var y = room.top + 2; y < room.top + room.height - 2; y++) {
      for (var x = room.left + 2; x < room.left + room.width - 2; x++) {
        if (_rng.nextDouble() < 0.55) {
          map.setTile(
            x,
            y,
            _rng.nextBool() ? TileType.trapSmall : TileType.trapBig,
          );
        }
      }
    }
  }

  /// Three horizontal lanes separated by pits (platforming + flying enemies).
  void _bridgeLanes(DungeonMap map, Rectangle<int> room) {
    final mid = room.top + room.height ~/ 2;
    for (var y = room.top + 1; y < room.top + room.height - 1; y++) {
      if (y == mid || y == mid - 2 || y == mid + 2) continue;
      for (var x = room.left + 1; x < room.left + room.width - 1; x++) {
        _tryPit(map, x, y);
      }
    }
    // Occasional spikes on lanes.
    for (final ly in [mid - 2, mid, mid + 2]) {
      if (ly <= room.top || ly >= room.top + room.height - 1) continue;
      for (var x = room.left + 2; x < room.left + room.width - 2; x += 3) {
        if (_rng.nextDouble() < 0.4) {
          map.setTile(x, ly, TileType.trapSmall);
        }
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
  }

  void _storage(DungeonMap map, Rectangle<int> room) {
    _scatterDecor(map, room, 4 + _rng.nextInt(4));
    if (_rng.nextDouble() < 0.5) {
      final p = _spot(map, room);
      if (p != null) map.setTile(p.x, p.y, TileType.trapSmall);
    }
  }

  void _mixedHazards(DungeonMap map, Rectangle<int> room) {
    for (var i = 0; i < 4 + _rng.nextInt(5); i++) {
      final p = _spot(map, room);
      if (p == null) continue;
      if (_rng.nextBool()) {
        _tryPit(map, p.x, p.y);
      } else {
        map.setTile(
          p.x,
          p.y,
          _rng.nextBool() ? TileType.trapSmall : TileType.trapBig,
        );
      }
    }
    _scatterDecor(map, room, 1 + _rng.nextInt(3));
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
