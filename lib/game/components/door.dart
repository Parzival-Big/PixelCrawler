import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';
import '../pixel_crawler_game.dart';
import 'dungeon_renderer.dart';
import 'solid_obstacle.dart';

/// Door between rooms.
///
/// Facing follows the wall of the *current* room. When open, the dark
/// opening draws *behind* the hero and the lintel / bars draw *in front*
/// so the hero appears to walk under the frame.
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
          priority: behindPriority,
        );

  final DoorSpawn spawn;
  bool open = false;
  DoorDir _displayDir = DoorDir.north;
  DoorLintel? _lintel;

  /// Lintel / frame above y-sorted characters.
  static const underpassPriority = 100000;

  /// Opening / threshold behind characters.
  static const behindPriority = -9995;

  /// How many pixels from the top of the tile are the overhanging frame.
  double get lintelHeight {
    switch (_displayDir) {
      case DoorDir.north:
        return 8;
      case DoorDir.south:
        return 7;
      case DoorDir.east:
      case DoorDir.west:
        return 6;
    }
  }

  @override
  double get solidWidth => open ? 0 : tileSize;
  @override
  double get solidHeight => open ? 0 : tileSize;

  @override
  Rect get solidRect {
    if (open) return Rect.zero;
    return Rect.fromLTWH(position.x, position.y, tileSize, tileSize);
  }

  DoorDir facingForRoom(RoomInfo? room) {
    if (room == null) return spawn.dir;
    return _edgeOnRoom(room) ?? spawn.dir;
  }

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
    _lintel = DoorLintel(door: this);
    await game.world.add(_lintel!);
    _applyVisuals();
  }

  @override
  void onRemove() {
    _lintel?.removeFromParent();
    _lintel = null;
    super.onRemove();
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
    // Closed doors sit fully in front; open doors split opening/lintel.
    priority = open ? behindPriority : underpassPriority;
    _lintel?.sync();
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0 || sprite == null) return;
    if (!open) {
      super.render(canvas);
      return;
    }
    // Only the dark opening / threshold (below the lintel).
    final h = lintelHeight;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, h, size.x, size.y - h));
    super.render(canvas);
    canvas.restore();
  }

  @override
  void update(double dt) {
    super.update(dt);

    final room = game.currentRoom;
    final onPerimeter = isOnPerimeterOf(room);
    opacity = onPerimeter ? 1 : 0;
    _lintel?.sync();
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

/// Top strip of an open door drawn above the hero.
class DoorLintel extends PositionComponent
    with HasGameReference<PixelCrawlerGame> {
  DoorLintel({required this.door})
      : super(
          position: door.position.clone(),
          size: Vector2.all(tileSize),
          anchor: Anchor.topLeft,
          priority: Door.underpassPriority,
        );

  final Door door;

  void sync() {
    position.setFrom(door.position);
    priority = Door.underpassPriority;
  }

  @override
  void render(Canvas canvas) {
    if (door.opacity <= 0 || !door.open || door.sprite == null) return;
    final h = door.lintelHeight;
    canvas.save();
    canvas.clipRect(Rect.fromLTWH(0, 0, size.x, h));
    door.sprite!.render(canvas, size: size);
    canvas.restore();
  }
}
