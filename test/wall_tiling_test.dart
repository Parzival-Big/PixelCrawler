import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/config/game_assets.dart';
import 'package:pixel_crawler/game/components/dungeon_renderer.dart';
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

  test('torches use pack side top/bottom/left/right matching wall face', () {
    final map = DungeonGenerator(floor: 1, seed: 7).generate();
    expect(map.torchSpawns, isNotEmpty);

    final sidesSeen = <WallSide>{};
    for (final t in map.torchSpawns) {
      expect(map.tileAt(t.pos.x, t.pos.y), TileType.wall);
      expect(map.isDoorTile(t.pos.x, t.pos.y), isFalse);
      final d = t.side.floorDelta;
      expect(map.isWalkable(t.pos.x + d.x, t.pos.y + d.y), isTrue);

      // Sprite strip key matches wall side name.
      expect(
        GameAssets.torchWallFor(t.side.assetKey).path,
        'tiles/torch_wall_${t.side.assetKey}.png',
      );
      sidesSeen.add(t.side);
    }

    // Across a whole floor we should see more than one wall side used.
    expect(sidesSeen.length, greaterThan(1));
  });

  test('torch asset strips exist for every wall side', () {
    for (final side in WallSide.values) {
      final spec = GameAssets.torchWallFor(side.assetKey);
      expect(spec.path, 'tiles/torch_wall_${side.assetKey}.png');
      expect(spec.frames, 4);
    }
  });
}
