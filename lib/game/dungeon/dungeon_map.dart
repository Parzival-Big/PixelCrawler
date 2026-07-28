import 'dart:math';

enum TileType { empty, floor, wall, stairs }

/// Grid model of one dungeon floor. Coordinates are in tile units.
class DungeonMap {
  DungeonMap(this.width, this.height)
      : tiles = List.filled(width * height, TileType.empty);

  final int width;
  final int height;
  final List<TileType> tiles;

  final rooms = <Rectangle<int>>[];
  late Point<int> playerSpawn;
  late Point<int> stairsPos;
  final monsterSpawns = <Point<int>>[];
  final chestSpawns = <Point<int>>[];
  final coinSpawns = <Point<int>>[];
  final potionSpawns = <Point<int>>[];

  /// Wall tiles whose south neighbour is floor: they render a brick face
  /// and can host a torch.
  final torchSpawns = <Point<int>>[];

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
    return t == TileType.floor || t == TileType.stairs;
  }
}
