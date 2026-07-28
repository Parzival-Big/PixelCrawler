import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';
import '../pixel_crawler_game.dart';
import 'dungeon_renderer.dart';
import 'solid_obstacle.dart';

/// Door between rooms.
///
/// Facing follows the wall of the *current* room (shared wall tiles flip
/// when you enter the neighbour). North doors draw above the hero so it
/// looks like they walk under the lintel / portcullis.
class Door extends SpriteComponent
    with HasGameReference<PixelCrawlerGame>, SolidObstacle {
  Door({required this.spawn})
      : super(
          position: Vector2(
            spawn.pos.x * tileSize,
            spawn.pos.y * tileSize,
          ),
          size: Vector2.all(tileSize),
          anchor: Anchor.topLeft,
        );

  final DoorSpawn spawn;
  bool open = false;
  DoorDir _displayDir = DoorDir.north;

  /// Above any y-sorted character so north lintels cover the hero.
  static const underpassPriority = 100000;

  /// Just above the baked dungeon, behind characters.
  static const behindPriority = -9995;

  @override
  double get solidWidth => open ? 0 : tileSize;
  @override
  double get solidHeight => open ? 0 : tileSize;

  /// Door uses top-left anchoring (wall tile space), not bottom-center.
  @override
  Rect get solidRect {
    if (open) return Rect.zero;
    return Rect.fromLTWH(position.x, position.y, tileSize, tileSize);
  }

  /// Which way this doorway faces from the room the player is in.
  DoorDir facingForRoom(RoomInfo? room) {
    if (room == null) return spawn.dir;
    final edge = _edgeOnRoom(room);
    return edge ?? spawn.dir;
  }

  /// True when this tile sits on [room]'s outer wall ring.
  bool isOnPerimeterOf(RoomInfo? room) {
    if (room == null) return false;
    return _edgeOnRoom(room) != null;
  }

  DoorDir? _edgeOnRoom(RoomInfo room) {
    final outer = room.outerBounds;
    final x = spawn.pos.x;
    final y = spawn.pos.y;
    final right = outer.left + outer.width - 1;
    final bottom = outer.top + outer.height - 1;
    if (x < outer.left || x > right || y < outer.top || y > bottom) {
      return null;
    }
    if (y == outer.top) return DoorDir.north;
    if (y == bottom) return DoorDir.south;
    if (x == outer.left) return DoorDir.west;
    if (x == right) return DoorDir.east;
    return null;
  }

  @override
  Future<void> onLoad() async {
    open = !spawn.locked;
    _displayDir = spawn.dir;
    opacity = 0;
    _applyVisuals();
  }

  SpriteSpec _specFor({required bool opened, required DoorDir dir}) {
    if (opened) {
      return switch (dir) {
        DoorDir.north => GameAssets.doorOpenN,
        DoorDir.south => GameAssets.doorOpenS,
        DoorDir.east => GameAssets.doorOpenE,
        DoorDir.west => GameAssets.doorOpenW,
      };
    }
    if (spawn.bossDoor) {
      return switch (dir) {
        DoorDir.north => GameAssets.doorBossN,
        DoorDir.south => GameAssets.doorBossS,
        DoorDir.east => GameAssets.doorBossE,
        DoorDir.west => GameAssets.doorBossW,
      };
    }
    if (spawn.locked) {
      return switch (dir) {
        DoorDir.north => GameAssets.doorLockedN,
        DoorDir.south => GameAssets.doorLockedS,
        DoorDir.east => GameAssets.doorLockedE,
        DoorDir.west => GameAssets.doorLockedW,
      };
    }
    return switch (dir) {
      DoorDir.north => GameAssets.doorClosedN,
      DoorDir.south => GameAssets.doorClosedS,
      DoorDir.east => GameAssets.doorClosedE,
      DoorDir.west => GameAssets.doorClosedW,
    };
  }

  void _applyVisuals() {
    sprite = _specFor(opened: open, dir: _displayDir).sprite();
    // North wall doors sit in front of the hero (walk-under lintel).
    // Other sides stay behind so the hero walks in front of the frame.
    priority =
        _displayDir == DoorDir.north ? underpassPriority : behindPriority;
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0) return;
    super.render(canvas);
  }

  @override
  void update(double dt) {
    super.update(dt);

    final room = game.currentRoom;
    final onPerimeter = isOnPerimeterOf(room);
    opacity = onPerimeter ? 1 : 0;
    if (!onPerimeter) return;

    final facing = facingForRoom(room);
    if (facing != _displayDir) {
      _displayDir = facing;
      _applyVisuals();
    }

    if (open) return;
    final player = game.player;
    if (player == null || player.isDead) return;

    final doorCenter = Vector2(
      spawn.pos.x * tileSize + tileSize / 2,
      spawn.pos.y * tileSize + tileSize / 2,
    );
    if (player.position.distanceTo(doorCenter) > 20) return;

    if (spawn.locked) {
      if (game.tryUseKey()) {
        open = true;
        _applyVisuals();
      }
    } else {
      open = true;
      _applyVisuals();
    }
  }
}
