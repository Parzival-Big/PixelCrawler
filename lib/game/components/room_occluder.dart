import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../pixel_crawler_game.dart';
import 'dungeon_renderer.dart';

/// Opaque panels around the current room so adjacent rooms never peek into
/// the letterboxed / overflow camera area (BoI single-room framing).
class RoomOccluder extends Component with HasGameReference<PixelCrawlerGame> {
  RoomOccluder() : super(priority: 50000);

  static final _paint = ui.Paint()..color = const ui.Color(0xFF0E222B);

  /// Large enough to cover any phone aspect when the room is fitted.
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

    // Above / below / left / right of the room (including wall ring).
    canvas.drawRect(
      ui.Rect.fromLTRB(left - _extent, top - _extent, right + _extent, top),
      _paint,
    );
    canvas.drawRect(
      ui.Rect.fromLTRB(left - _extent, bottom, right + _extent, bottom + _extent),
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
