import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';
import '../pixel_crawler_game.dart';

const double tileSize = 16;

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
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);

    final floorSheet = GameAssets.floorTiles;
    final stairsSprite = GameAssets.stairs.sprite();
    final aoPaint = ui.Paint()..color = const ui.Color(0x3D000000);
    final sizeVec = Vector2.all(tileSize);
    final bg = ui.Paint()..color = const ui.Color(0xFF0E222B);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, w * tileSize, h * tileSize),
      bg,
    );

    for (var y = 0; y < h; y++) {
      for (var x = 0; x < w; x++) {
        final tx = outer.left + x;
        final ty = outer.top + y;
        final t = map.tileAt(tx, ty);
        final pos = Vector2(x * tileSize, y * tileSize);
        switch (t) {
          case TileType.empty:
            break;
          case TileType.floor:
            final r = (tx * 73856093 ^ ty * 19349663) % 23;
            final variant = r < 20 ? r % 2 : (r == 20 ? 2 : 3);
            floorSheet.frame(variant).render(canvas, position: pos, size: sizeVec);
            if (map.tileAt(tx, ty - 1) == TileType.wall) {
              canvas.drawRect(
                ui.Rect.fromLTWH(pos.x, pos.y, tileSize, 3),
                aoPaint,
              );
            }
          case TileType.trapSmall:
          case TileType.trapBig:
            floorSheet.frame(0).render(canvas, position: pos, size: sizeVec);
          case TileType.pit:
            GameAssets.pit.sprite().render(canvas, position: pos, size: sizeVec);
          case TileType.wall:
            final name = wallTileNameFor(map, tx, ty, room: room);
            if (name != null) {
              final sheet = GameAssets.wallTiles[name]!;
              final variant = (tx * 7 + ty * 13) % (sheet.frames >= 2 ? 2 : 1);
              sheet.frame(variant).render(canvas, position: pos, size: sizeVec);
            }
          case TileType.stairs:
            stairsSprite.render(canvas, position: pos, size: sizeVec);
        }
      }
    }

    final image = recorder.endRecording().toImageSync(
          w * tileSize.toInt(),
          h * tileSize.toInt(),
        );
    sprite = Sprite(image);
    size = Vector2(w * tileSize, h * tileSize);
    position = Vector2(outer.left * tileSize, outer.top * tileSize);
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
