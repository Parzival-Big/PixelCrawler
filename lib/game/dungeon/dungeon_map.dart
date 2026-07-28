import 'dart:math';

enum TileType { empty, floor, wall, stairs, pit, trapSmall, trapBig }

enum RoomKind { start, combat, treasure, shop, boss }

enum DoorDir { north, south, east, west }

/// A door opening between two rooms.
class DoorSpawn {
  DoorSpawn({
    required this.pos,
    required this.dir,
    required this.locked,
    this.bossDoor = false,
  });

  final Point<int> pos;
  final DoorDir dir;

  /// Needs a normal key to open.
  final bool locked;

  /// Visual boss door (entrance to boss room).
  final bool bossDoor;
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

  /// Wall tiles whose south neighbour is floor: they can host a torch.
  final torchSpawns = <Point<int>>[];

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

  /// True for tiles that deal spike damage when stood on.
  bool isTrap(int x, int y) {
    final t = tileAt(x, y);
    return t == TileType.trapSmall || t == TileType.trapBig;
  }

  /// Room containing tile ([tx], [ty]), or null if outside every room.
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
