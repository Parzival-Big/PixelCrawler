import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';

const double tileSize = 16;

/// Bakes the whole static floor into a single image for cheap rendering.
///
/// The 2.5D look comes from three tricks:
///  * wall cells whose south neighbour is walkable render a brick *face*
///    (a vertical surface) instead of a flat top;
///  * floor cells right under a face get an ambient-occlusion shadow band;
///  * everything else (entities) is y-sorted above this layer.
class DungeonRenderer extends SpriteComponent {
  DungeonRenderer(this.map) : super(priority: -10000, position: Vector2.zero());

  final DungeonMap map;

  @override
  Future<void> onLoad() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final floorSheet = GameAssets.floorTiles;
    final wallFront = GameAssets.wallFront.sprite();
    final wallTop = GameAssets.wallTop.sprite();
    final stairsSprite = GameAssets.stairs.sprite();

    final aoPaint = ui.Paint()..color = const ui.Color(0x55000000);
    final sizeVec = Vector2.all(tileSize);

    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final t = map.tileAt(x, y);
        final pos = Vector2(x * tileSize, y * tileSize);
        switch (t) {
          case TileType.empty:
            break;
          case TileType.floor:
            floorSheet
                .frame((x * 7 + y * 13) % floorSheet.frames)
                .render(canvas, position: pos, size: sizeVec);
            if (map.tileAt(x, y - 1) == TileType.wall) {
              canvas.drawRect(
                ui.Rect.fromLTWH(pos.x, pos.y, tileSize, 4),
                aoPaint,
              );
            }
          case TileType.wall:
            final faces = map.isWalkable(x, y + 1);
            (faces ? wallFront : wallTop)
                .render(canvas, position: pos, size: sizeVec);
          case TileType.stairs:
            stairsSprite.render(canvas, position: pos, size: sizeVec);
        }
      }
    }

    final image = recorder
        .endRecording()
        .toImageSync(map.width * 16, map.height * 16);
    sprite = Sprite(image);
    size = Vector2(map.width * tileSize, map.height * tileSize);
  }
}

/// Warm additive glow used under torches.
class GlowComponent extends PositionComponent {
  GlowComponent({required Vector2 center, this.radius = 26})
      : super(position: center, priority: -9999, anchor: Anchor.center);

  final double radius;
  double _t = 0;

  @override
  void update(double dt) {
    _t += dt;
  }

  @override
  void render(ui.Canvas canvas) {
    final flicker = 1 + 0.06 * (_t * 7).remainder(1.0) * ((_t * 13).floor().isEven ? 1 : -1);
    final r = radius * flicker;
    final paint = ui.Paint()
      ..shader = ui.Gradient.radial(
        ui.Offset.zero,
        r,
        [const ui.Color(0x30FFAA44), const ui.Color(0x00FFAA44)],
      )
      ..blendMode = ui.BlendMode.plus;
    canvas.drawCircle(ui.Offset.zero, r, paint);
  }
}
