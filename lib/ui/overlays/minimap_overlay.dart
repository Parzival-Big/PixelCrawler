import 'package:flutter/material.dart';

import '../../game/dungeon/dungeon_map.dart';
import '../../game/pixel_crawler_game.dart';
import '../theme.dart';

/// Sparse Binding-of-Isaac style minimap (top-right).
class MiniMapOverlay extends StatelessWidget {
  const MiniMapOverlay({super.key, required this.game});

  final PixelCrawlerGame game;

  static const _cell = 10.0;
  static const _gap = 2.0;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.roomMapNotifier,
      builder: (_, _, _) {
        if (!game.discoveredRooms.contains(game.currentRoom?.gridKey ?? '')) {
          // Still paint after first discover.
        }
        final rooms = game.map.roomInfos;
        if (rooms.isEmpty) return const SizedBox.shrink();

        var minX = rooms.first.gridX;
        var maxX = minX;
        var minY = rooms.first.gridY;
        var maxY = minY;
        for (final r in rooms) {
          minX = r.gridX < minX ? r.gridX : minX;
          maxX = r.gridX > maxX ? r.gridX : maxX;
          minY = r.gridY < minY ? r.gridY : minY;
          maxY = r.gridY > maxY ? r.gridY : maxY;
        }

        final cols = maxX - minX + 1;
        final rows = maxY - minY + 1;
        final w = cols * (_cell + _gap) - _gap;
        final h = rows * (_cell + _gap) - _gap;

        return SizedBox(
          width: w,
          height: h,
          child: Stack(
            children: [
              for (final r in rooms)
                if (game.discoveredRooms.contains(r.gridKey))
                  Positioned(
                    left: (r.gridX - minX) * (_cell + _gap),
                    top: (r.gridY - minY) * (_cell + _gap),
                    child: _RoomCell(
                      kind: r.kind,
                      current: game.currentRoom?.gridKey == r.gridKey,
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _RoomCell extends StatelessWidget {
  const _RoomCell({required this.kind, required this.current});

  final RoomKind kind;
  final bool current;

  @override
  Widget build(BuildContext context) {
    Color fill;
    switch (kind) {
      case RoomKind.start:
        fill = PixelColors.green;
      case RoomKind.boss:
        fill = PixelColors.red;
      case RoomKind.shop:
        fill = PixelColors.gold;
      case RoomKind.treasure:
        fill = const Color(0xFFB9DDA7);
      case RoomKind.combat:
        fill = PixelColors.surfaceLight;
    }
    return Container(
      width: MiniMapOverlay._cell,
      height: MiniMapOverlay._cell,
      decoration: BoxDecoration(
        color: fill,
        border: Border.all(
          color: current ? PixelColors.text : PixelColors.bg,
          width: current ? 2 : 1,
        ),
      ),
    );
  }
}
