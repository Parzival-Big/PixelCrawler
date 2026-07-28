import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/config/game_assets.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_generator.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_map.dart';

void main() {
  test('rectangular room corners use inner_* tiles from pack names', () {
    final map = DungeonMap(5, 5);
    for (var y = 0; y < 5; y++) {
      for (var x = 0; x < 5; x++) {
        final edge = x == 0 || y == 0 || x == 4 || y == 4;
        map.setTile(x, y, edge ? TileType.wall : TileType.floor);
      }
    }

    expect(wallTileNameFor(map, 0, 0), 'inner_tl');
    expect(wallTileNameFor(map, 4, 0), 'inner_tr');
    expect(wallTileNameFor(map, 0, 4), 'inner_bl');
    expect(wallTileNameFor(map, 4, 4), 'inner_br');

    expect(wallTileNameFor(map, 2, 0), 'top');
    expect(wallTileNameFor(map, 2, 4), 'bottom');
    expect(wallTileNameFor(map, 0, 2), 'left');
    expect(wallTileNameFor(map, 4, 2), 'right');
  });

  test('torches resolve to wallTileNameFor for their owning room face', () {
    final map = DungeonGenerator(floor: 1, seed: 7).generate();
    expect(map.torchSpawns, isNotEmpty);

    for (final t in map.torchSpawns) {
      expect(map.tileAt(t.pos.x, t.pos.y), TileType.wall);
      expect(map.isDoorTile(t.pos.x, t.pos.y), isFalse);
      // At least one adjacent room must tile this cell as this spawn's side.
      final match = map.roomInfos.any((info) {
        final o = info.outerBounds;
        if (t.pos.x < o.left ||
            t.pos.x >= o.left + o.width ||
            t.pos.y < o.top ||
            t.pos.y >= o.top + o.height) {
          return false;
        }
        return wallTileNameFor(map, t.pos.x, t.pos.y, room: info) ==
            t.side.assetKey;
      });
      expect(match, isTrue, reason: 'torch at ${t.pos} side ${t.side}');
      expect(
        GameAssets.torchWallFor(t.side.assetKey).path,
        'tiles/torch_wall_${t.side.assetKey}.png',
      );
    }
  });

  test('torch asset strips exist for every wall side', () {
    for (final side in WallSide.values) {
      final spec = GameAssets.torchWallFor(side.assetKey);
      expect(spec.path, 'tiles/torch_wall_${side.assetKey}.png');
      expect(spec.frames, 4);
    }
  });
}
