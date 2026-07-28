import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';

const double tileSize = 16;

/// Bakes the whole static floor into a single image for cheap rendering.
///
/// Walls are auto-tiled: the pack provides directional wall tiles whose
/// shaded edge must face the floor, plus inner/outer corner tiles. On top
/// of that the 2.5D feel comes from ambient-occlusion bands under
/// south-facing walls and y-sorted entities.
class DungeonRenderer extends SpriteComponent {
  DungeonRenderer(this.map) : super(priority: -10000, position: Vector2.zero());

  final DungeonMap map;

  @override
  Future<void> onLoad() async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final floorSheet = GameAssets.floorTiles;
    final stairsSprite = GameAssets.stairs.sprite();

    final aoPaint = ui.Paint()..color = const ui.Color(0x3D000000);
    final sizeVec = Vector2.all(tileSize);

    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final t = map.tileAt(x, y);
        final pos = Vector2(x * tileSize, y * tileSize);
        switch (t) {
          case TileType.empty:
            break;
          case TileType.floor:
            // Mostly plain tiles with sporadic cracked/flower variants.
            final r = (x * 73856093 ^ y * 19349663) % 23;
            final variant = r < 20 ? r % 2 : (r == 20 ? 2 : 3);
            floorSheet.frame(variant).render(canvas, position: pos, size: sizeVec);
            if (map.tileAt(x, y - 1) == TileType.wall) {
              canvas.drawRect(
                ui.Rect.fromLTWH(pos.x, pos.y, tileSize, 3),
                aoPaint,
              );
            }
          case TileType.trapSmall:
          case TileType.trapBig:
            // Base floor under traps; animated overlay is a component.
            floorSheet.frame(0).render(canvas, position: pos, size: sizeVec);
          case TileType.pit:
            GameAssets.pit.sprite().render(canvas, position: pos, size: sizeVec);
          case TileType.wall:
            final name = _wallTileName(x, y);
            if (name != null) {
              final sheet = GameAssets.wallTiles[name]!;
              final variant = (x * 7 + y * 13) % sheet.frames;
              sheet.frame(variant).render(canvas, position: pos, size: sizeVec);
            }
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

  /// Picks the wall tile orientation from the walkable neighbours.
  String? _wallTileName(int x, int y) {
    bool f(int dx, int dy) => map.isWalkable(x + dx, y + dy);
    final n = f(0, -1), s = f(0, 1), w = f(-1, 0), e = f(1, 0);

    // Floor on two orthogonal sides: inner corner (the wall band bends
    // around the floor).
    if (s && e) return 'inner_br';
    if (s && w) return 'inner_bl';
    if (n && e) return 'inner_tr';
    if (n && w) return 'inner_tl';

    // Floor on one side: straight wall.
    if (s) return 'bottom';
    if (n) return 'top';
    if (w) return 'left';
    if (e) return 'right';

    // Floor only diagonally: outer corner.
    if (f(1, 1)) return 'outer_br';
    if (f(-1, 1)) return 'outer_bl';
    if (f(1, -1)) return 'outer_tr';
    if (f(-1, -1)) return 'outer_tl';
    return null;
  }
}

/// Soft additive glow used under torches and fire pots.
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
        [const ui.Color(0x2EB9DDA7), const ui.Color(0x00B9DDA7)],
      )
      ..blendMode = ui.BlendMode.plus;
    canvas.drawCircle(ui.Offset.zero, r, paint);
  }
}
