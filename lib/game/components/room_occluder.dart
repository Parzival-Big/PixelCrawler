import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../pixel_crawler_game.dart';
import 'door.dart';
import 'dungeon_renderer.dart';

/// Safety mask around the current room (letterbox / any stray neighbour tile).
///
/// Primary isolation is [DungeonRenderer] baking only the active room; this
/// covers anything that might still draw outside that rect.
class RoomOccluder extends PositionComponent
    with HasGameReference<PixelCrawlerGame> {
  RoomOccluder()
      : super(
          position: Vector2.zero(),
          size: Vector2.zero(),
          priority: Door.underpassPriority + 1,
        );

  static final _paint = ui.Paint()..color = const ui.Color(0xFF0E222B);

  static const _extent = 4000.0;

  @override
  void render(ui.Canvas canvas) {
    final room = game.currentRoom;
    if (room == null) return;
    final outer = room.outerBounds;
    final left = outer.left * tileSize;
    final top = outer.top * tileSize;
    final right = (outer.left + outer.width) * tileSize;
    final bottom = (outer.top + outer.height) * tileSize;

    canvas.drawRect(
      ui.Rect.fromLTRB(left - _extent, top - _extent, right + _extent, top),
      _paint,
    );
    canvas.drawRect(
      ui.Rect.fromLTRB(
        left - _extent,
        bottom,
        right + _extent,
        bottom + _extent,
      ),
      _paint,
    );
    canvas.drawRect(
      ui.Rect.fromLTRB(left - _extent, top, left, bottom),
      _paint,
    );
    canvas.drawRect(
      ui.Rect.fromLTRB(right, top, right + _extent, bottom),
      _paint,
    );
  }
}
