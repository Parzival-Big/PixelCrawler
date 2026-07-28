import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';
import '../pixel_crawler_game.dart';

const double tileSize = 16;

/// Visual scale for walls, doors and wall torches (pack tiles stay 16²).
const double wallVisualScale = 1.5;

/// Drawn size of a wall / door / wall-torch sprite.
double get wallVisualSize => tileSize * wallVisualScale;

/// Extra pixels on each side when a 16px tile is drawn at [wallVisualScale].
double get wallOverhang => (wallVisualSize - tileSize) / 2;

/// Top-left offset so a 1.5× sprite stays centred on its tile.
Vector2 wallVisualOffset([double ox = 0, double oy = 0]) =>
    Vector2(-wallOverhang + ox, -wallOverhang + oy);

/// True when tile (tx, ty) lies in the current room's wall ring + interior.
bool tileInCurrentRoom(PixelCrawlerGame game, int tx, int ty) {
  final room = game.currentRoom;
  if (room == null) return false;
  final o = room.outerBounds;
  return tx >= o.left &&
      tx < o.left + o.width &&
      ty >= o.top &&
      ty < o.top + o.height;
}

/// Bakes only the *current* room (Isaac-style: no neighbour peek).
///
/// Rebuilds when [PixelCrawlerGame.currentRoom] changes. Wall autotiling
/// only considers floor inside that room so shared walls face inward.
class DungeonRenderer extends SpriteComponent
    with HasGameReference<PixelCrawlerGame> {
  DungeonRenderer(this.map) : super(priority: -10000, position: Vector2.zero());

  final DungeonMap map;
  String? _bakedKey;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _bakeCurrentRoom();
  }

  @override
  void update(double dt) {
    super.update(dt);
    final key = game.currentRoom?.gridKey;
    if (key != _bakedKey) {
      _bakeCurrentRoom();
    }
  }

  void _bakeCurrentRoom() {
    final room = game.currentRoom;
    _bakedKey = room?.gridKey;
    if (room == null) {
      sprite = null;
      size = Vector2.zero();
      return;
    }

    final outer = room.outerBounds;
    final w = outer.width;
    final h = outer.height;
    // Margin so 1.5× wall sprites are not clipped at the room edge.
    final margin = wallOverhang;
    final imgW = w * tileSize + margin * 2;
    final imgH = h * tileSize + margin * 2;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final floorSheet = GameAssets.floorTiles;
    final stairsSprite = GameAssets.stairs.sprite();
    final aoPaint = ui.Paint()..color = const ui.Color(0x3D000000);
    final floorSize = Vector2.all(tileSize);
    final wallSize = Vector2.all(wallVisualSize);
    final bg = ui.Paint()..color = const ui.Color(0xFF0E222B);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, imgW, imgH), bg);

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final tx = outer.left + x;
        final ty = outer.top + y;
        final t = map.tileAt(tx, ty);
        final pos = Vector2(margin + x * tileSize, margin + y * tileSize);
        switch (t) {
          case TileType.empty:
            break;
          case TileType.floor:
            final r = (tx * 73856093 ^ ty * 19349663) % 23;
            final variant = r < 20 ? r % 2 : (r == 20 ? 2 : 3);
            floorSheet.frame(variant).render(
                  canvas,
                  position: pos,
                  size: floorSize,
                );
            if (map.tileAt(tx, ty - 1) == TileType.wall) {
              canvas.drawRect(
                ui.Rect.fromLTWH(pos.x, pos.y, tileSize, 3),
                aoPaint,
              );
            }
          case TileType.trapSmall:
          case TileType.trapBig:
            floorSheet.frame(0).render(canvas, position: pos, size: floorSize);
          case TileType.pit:
            GameAssets.pit.sprite().render(canvas, position: pos, size: floorSize);
          case TileType.wall:
            // Doors / torches replace the wall face; still bake a base tile.
            final name = wallTileNameFor(map, tx, ty, room: room);
            if (name != null) {
              final sheet = GameAssets.wallTiles[name]!;
              final variant = (tx * 7 + ty * 13) % (sheet.frames >= 2 ? 2 : 1);
              sheet.frame(variant).render(
                    canvas,
                    position: pos + wallVisualOffset(),
                    size: wallSize,
                  );
            }
          case TileType.stairs:
            stairsSprite.render(canvas, position: pos, size: floorSize);
        }
      }
    }

    final image = recorder.endRecording().toImageSync(
          imgW.round(),
          imgH.round(),
        );
    sprite = Sprite(image);
    size = Vector2(imgW, imgH);
    position = Vector2(
      outer.left * tileSize - margin,
      outer.top * tileSize - margin,
    );
  }
}

/// Soft additive glow used under torches and fire pots.
class GlowComponent extends PositionComponent
    with HasGameReference<PixelCrawlerGame> {
  GlowComponent({
    required Vector2 center,
    this.radius = 26,
    this.tileX,
    this.tileY,
  }) : super(position: center, priority: -9999, anchor: Anchor.center);

  final double radius;

  /// When set, glow only renders while this tile is in the current room.
  final int? tileX;
  final int? tileY;

  double _t = 0;
  bool _visible = true;

  @override
  void update(double dt) {
    _t += dt;
    if (tileX != null && tileY != null) {
      _visible = tileInCurrentRoom(game, tileX!, tileY!);
    }
  }

  @override
  void render(ui.Canvas canvas) {
    if (!_visible) return;
    final flicker =
        1 + 0.06 * (_t * 7).remainder(1.0) * ((_t * 13).floor().isEven ? 1 : -1);
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
