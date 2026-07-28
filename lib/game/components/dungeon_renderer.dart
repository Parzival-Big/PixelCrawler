import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';
import '../pixel_crawler_game.dart';

const double tileSize = 16;

/// Visual scale for dungeon tiles (floor, walls, doors, torches, traps).
/// Pack art is 16×16; keep drawing 1:1 (boss sprites stay 1.5× separately).
const double tileVisualScale = 1.0;

/// Alias kept for wall/door/torch call sites.
const double wallVisualScale = tileVisualScale;

double get tileVisualSize => tileSize * tileVisualScale;

double get wallVisualSize => tileVisualSize;

double get tileOverhang => (tileVisualSize - tileSize) / 2;

double get wallOverhang => tileOverhang;

Vector2 tileVisualOffset([double ox = 0, double oy = 0]) =>
    Vector2(-tileOverhang + ox, -tileOverhang + oy);

Vector2 wallVisualOffset([double ox = 0, double oy = 0]) =>
    tileVisualOffset(ox, oy);

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
    // Margin so scaled tile sprites are not clipped at the room edge.
    final margin = tileOverhang;
    final imgW = w * tileSize + margin * 2;
    final imgH = h * tileSize + margin * 2;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final floorSheet = GameAssets.floorTiles;
    final stairsSprite = GameAssets.stairs.sprite();
    final aoPaint = ui.Paint()..color = const ui.Color(0x3D000000);
    final drawSize = Vector2.all(tileVisualSize);
    final bg = ui.Paint()..color = const ui.Color(0xFF0E222B);
    canvas.drawRect(ui.Rect.fromLTWH(0, 0, imgW, imgH), bg);

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final tx = outer.left + x;
        final ty = outer.top + y;
        final t = map.tileAt(tx, ty);
        final pos = Vector2(margin + x * tileSize, margin + y * tileSize);
        final drawPos = pos + tileVisualOffset();
        switch (t) {
          case TileType.empty:
            break;
          case TileType.floor:
            final r = (tx * 73856093 ^ ty * 19349663) % 23;
            final variant = r < 20 ? r % 2 : (r == 20 ? 2 : 3);
            floorSheet.frame(variant).render(
                  canvas,
                  position: drawPos,
                  size: drawSize,
                );
            if (map.tileAt(tx, ty - 1) == TileType.wall) {
              canvas.drawRect(
                ui.Rect.fromLTWH(
                  pos.x,
                  pos.y,
                  tileSize,
                  3 * tileVisualScale,
                ),
                aoPaint,
              );
            }
          case TileType.trapSmall:
          case TileType.trapBig:
            floorSheet.frame(0).render(
                  canvas,
                  position: drawPos,
                  size: drawSize,
                );
          case TileType.pit:
            GameAssets.pit.sprite().render(
                  canvas,
                  position: drawPos,
                  size: drawSize,
                );
          case TileType.wall:
            // Doors / torches replace the wall face; still bake a base tile.
            final name = wallTileNameFor(map, tx, ty, room: room);
            if (name != null) {
              final sheet = GameAssets.wallTiles[name]!;
              final variant = (tx * 7 + ty * 13) % (sheet.frames >= 2 ? 2 : 1);
              sheet.frame(variant).render(
                    canvas,
                    position: drawPos,
                    size: drawSize,
                  );
            }
          case TileType.stairs:
            stairsSprite.render(canvas, position: drawPos, size: drawSize);
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

