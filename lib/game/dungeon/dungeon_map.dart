import 'dart:math';

enum TileType { empty, floor, wall, stairs, pit, trapSmall, trapBig }

enum RoomKind { start, combat, treasure, shop, boss }

enum DoorDir { north, south, east, west }

/// Pack wall side for directional tiles / torches (`top` = north wall, etc.).
enum WallSide {
  top,
  bottom,
  left,
  right;

  /// Floor neighbour that faces into the room for this wall side.
  Point<int> get floorDelta => switch (this) {
        WallSide.top => const Point(0, 1),
        WallSide.bottom => const Point(0, -1),
        WallSide.left => const Point(1, 0),
        WallSide.right => const Point(-1, 0),
      };

  String get assetKey => name;

  /// Only straight wall faces — corner tile names return null.
  static WallSide? fromAssetKey(String? key) => switch (key) {
        'top' => WallSide.top,
        'bottom' => WallSide.bottom,
        'left' => WallSide.left,
        'right' => WallSide.right,
        _ => null,
      };
}

/// A door opening between two rooms (one shared cell, one open/closed state).
class DoorSpawn {
  DoorSpawn({
    required this.pos,
    required this.dir,
    required this.locked,
    this.bossDoor = false,
    Set<String>? roomKeys,
  }) : roomKeys = roomKeys ?? {};

  final Point<int> pos;
  final DoorDir dir;

  /// Needs a normal key to open.
  final bool locked;

  /// Visual boss door (entrance to boss room).
  final bool bossDoor;

  /// Grid keys of the two rooms this doorway connects.
  final Set<String> roomKeys;

  /// Set when a locked door is unlocked with a key (persists both sides).
  bool unlocked = false;
}

/// Wall-mounted torch spawn (sprite strip chosen by [side]).
class TorchSpawn {
  TorchSpawn({required this.pos, required this.side});

  final Point<int> pos;
  final WallSide side;
}

/// Shop pedestal placed in a shop room.
class ShopPedestalSpawn {
  ShopPedestalSpawn({
    required this.pos,
    required this.upgradeId,
    required this.cost,
  });

  final Point<int> pos;
  final String upgradeId;
  final int cost;
}

class RoomInfo {
  RoomInfo({
    required this.bounds,
    required this.kind,
    required this.gridX,
    required this.gridY,
  });

  /// Interior floor rectangle (no walls).
  final Rectangle<int> bounds;
  final RoomKind kind;
  final int gridX;
  final int gridY;

  /// Outer rectangle including the surrounding wall ring.
  Rectangle<int> get outerBounds => Rectangle(
        bounds.left - 1,
        bounds.top - 1,
        bounds.width + 2,
        bounds.height + 2,
      );

  String get gridKey => '$gridX,$gridY';
}

/// Grid model of one dungeon floor. Coordinates are in tile units.
class DungeonMap {
  DungeonMap(this.width, this.height)
      : tiles = List.filled(width * height, TileType.empty);

  final int width;
  final int height;
  final List<TileType> tiles;

  final rooms = <Rectangle<int>>[];
  final roomInfos = <RoomInfo>[];
  late Point<int> playerSpawn;
  late Point<int> stairsPos;
  final monsterSpawns = <Point<int>>[];
  final chestSpawns = <Point<int>>[];
  final coinSpawns = <Point<int>>[];
  final potionSpawns = <Point<int>>[];
  final doorSpawns = <DoorSpawn>[];
  final shopPedestals = <ShopPedestalSpawn>[];
  Point<int>? bossSpawn;
  bool hasShopRoom = false;

  /// Wall torches: position + pack side (`top`/`bottom`/`left`/`right`).
  final torchSpawns = <TorchSpawn>[];

  /// Decorative props (index into GameAssets.decor) and fire pots.
  final decorSpawns = <(Point<int>, int)>[];
  final firePotSpawns = <Point<int>>[];

  TileType tileAt(int x, int y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return TileType.empty;
    return tiles[y * width + x];
  }

  void setTile(int x, int y, TileType t) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    tiles[y * width + x] = t;
  }

  bool isWalkable(int x, int y) {
    final t = tileAt(x, y);
    return t == TileType.floor ||
        t == TileType.stairs ||
        t == TileType.trapSmall ||
        t == TileType.trapBig;
  }

  /// Walkable tiles plus pits — for flying monsters and ranged shots.
  bool isFlyable(int x, int y) {
    final t = tileAt(x, y);
    return isWalkable(x, y) || t == TileType.pit;
  }

  /// Walls and void stop projectiles; pits and traps do not.
  bool blocksProjectile(int x, int y) {
    final t = tileAt(x, y);
    return t == TileType.wall || t == TileType.empty;
  }

  /// True for tiles that deal spike damage when stood on.
  bool isTrap(int x, int y) {
    final t = tileAt(x, y);
    return t == TileType.trapSmall || t == TileType.trapBig;
  }

  bool isDoorTile(int tx, int ty) =>
      doorSpawns.any((d) => d.pos.x == tx && d.pos.y == ty);
  Rectangle<int>? roomContaining(int tx, int ty) {
    for (final r in rooms) {
      if (tx >= r.left &&
          tx < r.left + r.width &&
          ty >= r.top &&
          ty < r.top + r.height) {
        return r;
      }
    }
    return null;
  }

  RoomInfo? roomInfoContaining(int tx, int ty) {
    for (final info in roomInfos) {
      final r = info.bounds;
      if (tx >= r.left &&
          tx < r.left + r.width &&
          ty >= r.top &&
          ty < r.top + r.height) {
        return info;
      }
    }
    return null;
  }
}

/// Picks the wall tile orientation from walkable neighbours.
///
/// Pack names match room sides: `top` = north wall, `bottom` = south,
/// `left` = west, `right` = east.
///
/// When [room] is set, only floor inside that room's interior counts — so a
/// shared wall between two rooms faces into the room being rendered.
String? wallTileNameFor(
  DungeonMap map,
  int x,
  int y, {
  RoomInfo? room,
}) {
  bool f(int dx, int dy) {
    final nx = x + dx;
    final ny = y + dy;
    if (room != null) {
      final b = room.bounds;
      if (nx < b.left ||
          nx >= b.left + b.width ||
          ny < b.top ||
          ny >= b.top + b.height) {
        return false;
      }
    }
    return map.isWalkable(nx, ny);
  }

  final n = f(0, -1), s = f(0, 1), w = f(-1, 0), e = f(1, 0);

  if (s && e) return 'inner_tl';
  if (s && w) return 'inner_tr';
  if (n && e) return 'inner_bl';
  if (n && w) return 'inner_br';

  if (s) return 'top';
  if (n) return 'bottom';
  if (e) return 'left';
  if (w) return 'right';

  if (f(1, 1)) return 'inner_tl';
  if (f(-1, 1)) return 'inner_tr';
  if (f(1, -1)) return 'inner_bl';
  if (f(-1, -1)) return 'inner_br';

  final wallN = map.tileAt(x, y - 1) == TileType.wall;
  final wallS = map.tileAt(x, y + 1) == TileType.wall;
  final wallW = map.tileAt(x - 1, y) == TileType.wall;
  final wallE = map.tileAt(x + 1, y) == TileType.wall;
  if (wallS && wallE && !wallN && !wallW) return 'outer_tl';
  if (wallS && wallW && !wallN && !wallE) return 'outer_tr';
  if (wallN && wallE && !wallS && !wallW) return 'outer_bl';
  if (wallN && wallW && !wallS && !wallE) return 'outer_br';
  return null;
}
