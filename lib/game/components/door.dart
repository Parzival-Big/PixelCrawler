import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';
import '../pixel_crawler_game.dart';
import 'dungeon_renderer.dart';
import 'solid_obstacle.dart';

/// Door between rooms.
///
/// One shared doorway cell → one open/closed state visible from both rooms.
/// Facing follows the wall of the *current* room. When open, the dark opening
/// draws behind the hero and the structural frame draws in front.
class Door extends SpriteComponent
    with HasGameReference<PixelCrawlerGame>, SolidObstacle {
  Door({required this.spawn})
      : _displayDir = spawn.dir,
        super(
          position: Vector2(
                spawn.pos.x * tileSize,
                spawn.pos.y * tileSize,
              ) +
              wallVisualOffset(),
          size: Vector2.all(wallVisualSize),
          anchor: Anchor.topLeft,
          priority: behindPriority,
        );

  final DoorSpawn spawn;
  bool open = false;
  DoorDir _displayDir = DoorDir.north;
  DoorLintel? _lintel;

  /// Structural frame above y-sorted characters.
  static const underpassPriority = 100000;

  /// Opening / threshold behind characters.
  static const behindPriority = -9995;

  DoorDir get displayDir => _displayDir;

  /// Structural frame drawn above the hero by [DoorLintel].
  Rect get frameRect {
    const s = wallVisualScale;
    switch (_displayDir) {
      case DoorDir.north:
        return Rect.fromLTWH(0, 0, 16 * s, 7 * s);
      case DoorDir.south:
        return Rect.fromLTWH(0, 9 * s, 16 * s, 7 * s);
      case DoorDir.west:
        return Rect.fromLTWH(0, 0, 7 * s, 16 * s);
      case DoorDir.east:
        return Rect.fromLTWH(9 * s, 0, 7 * s, 16 * s);
    }
  }

  /// Dark passage kept under the hero.
  Rect get openingRect {
    const s = wallVisualScale;
    switch (_displayDir) {
      case DoorDir.north:
        return Rect.fromLTWH(0, 7 * s, 16 * s, 9 * s);
      case DoorDir.south:
        return Rect.fromLTWH(0, 0, 16 * s, 9 * s);
      case DoorDir.west:
        return Rect.fromLTWH(7 * s, 0, 9 * s, 16 * s);
      case DoorDir.east:
        return Rect.fromLTWH(0, 0, 9 * s, 16 * s);
    }
  }

  @override
  double get solidWidth => blocksPassage ? tileSize : 0;
  @override
  double get solidHeight => blocksPassage ? tileSize : 0;

  /// Logical door cell (collision stays 16×16 even if the sprite scales).
  Rect get doorTileRect => Rect.fromLTWH(
        spawn.pos.x * tileSize,
        spawn.pos.y * tileSize,
        tileSize,
        tileSize,
      );

  /// True when the player's feet still touch this doorway.
  bool playerOverlapsDoorway() {
    final p = game.player;
    if (p == null || p.isDead) return false;
    final feet = Rect.fromCenter(
      center: Offset(p.position.x, p.position.y - p.feetHeight / 2),
      width: p.feetWidth,
      height: p.feetHeight,
    );
    return doorTileRect.overlaps(feet);
  }

  /// Closed doors block passage, unless the player is still overlapping the
  /// doorway (avoids soft-locking when a door slams during a room transition).
  bool get blocksPassage {
    if (open || opacity <= 0) return false;
    if (playerOverlapsDoorway()) return false;
    return true;
  }

  @override
  Rect get solidRect {
    if (!blocksPassage) return Rect.zero;
    return doorTileRect;
  }

  DoorDir facingForRoom(RoomInfo? room) {
    if (room == null) return spawn.dir;
    return _edgeOnRoom(room) ?? spawn.dir;
  }

  bool isOnPerimeterOf(RoomInfo? room) {
    if (room == null) return false;
    return _edgeOnRoom(room) != null;
  }

  bool connectsRoom(RoomInfo? room) {
    if (room == null) return false;
    if (spawn.roomKeys.contains(room.gridKey)) return true;
    return isOnPerimeterOf(room);
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
    open = false;
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
    if (spawn.locked && !spawn.unlocked) {
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
    priority = open ? behindPriority : underpassPriority;
    _lintel?.sync();
  }

  void setOpen(bool value) {
    if (open == value) return;
    open = value;
    _applyVisuals();
  }

  @override
  void render(Canvas canvas) {
    if (opacity <= 0 || sprite == null) return;
    if (!open) {
      super.render(canvas);
      return;
    }
    final openRect = openingRect;
    canvas.save();
    canvas.clipRect(openRect);
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

    // Shared rule for both sides: seal while this room has monsters;
    // open when clear (locked doors need a key once).
    final cleared = game.currentRoomCleared;
    if (!cleared) {
      setOpen(false);
      return;
    }

    if (open) return;

    if (spawn.locked && !spawn.unlocked) {
      final player = game.player;
      if (player == null || player.isDead) return;
      final doorCenter = Vector2(
        spawn.pos.x * tileSize + tileSize / 2,
        spawn.pos.y * tileSize + tileSize / 2,
      );
      if (player.position.distanceTo(doorCenter) > 20) return;
      if (game.tryUseKey()) {
        spawn.unlocked = true;
        setOpen(true);
      }
    } else {
      setOpen(true);
    }
  }
}

/// Structural door frame drawn above the hero.
class DoorLintel extends PositionComponent
    with HasGameReference<PixelCrawlerGame> {
  DoorLintel({required this.door})
      : super(
          position: door.position.clone(),
          size: door.size.clone(),
          anchor: Anchor.topLeft,
          priority: Door.underpassPriority,
        );

  final Door door;

  void sync() {
    position.setFrom(door.position);
    size.setFrom(door.size);
    priority = Door.underpassPriority;
  }

  @override
  void render(Canvas canvas) {
    if (door.opacity <= 0 || !door.open || door.sprite == null) return;
    final frame = door.frameRect;
    canvas.save();
    canvas.clipRect(frame);
    door.sprite!.render(canvas, size: size);
    canvas.restore();
  }
}
