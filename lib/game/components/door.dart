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
/// opening draws *behind* the hero and the structural frame draws *in front*
/// so the hero appears to walk under / through the doorway.
///
/// Frame vs opening depends on facing (from pack sprites):
/// - North: bright lintel on top, dark threshold below
/// - South: dark opening on top, bright wall face below
/// - West: bright frame on the left, dark opening on the right
/// - East: dark opening on the left, bright frame on the right
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
  /// Coords are in the scaled (1.5×) local space of this component.
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

  /// Closed doors on the current room perimeter block feet and shots.
  bool get blocksPassage => !open && opacity > 0;

  @override
  Rect get solidRect {
    if (!blocksPassage) return Rect.zero;
    // Collision stays on the logical 16×16 tile, not the 1.5× visual.
    return Rect.fromLTWH(
      spawn.pos.x * tileSize,
      spawn.pos.y * tileSize,
      tileSize,
      tileSize,
    );
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
    // Always start closed; unlock when the room is clear (Isaac-style).
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
    // Closed doors sit fully in front; open doors split opening/frame.
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
    // Only the dark opening (under the hero).
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

    final cleared = game.currentRoomCleared;
    if (!cleared) {
      if (open) {
        open = false;
        _applyVisuals();
      }
      return;
    }

    // Room clear: unlock / open. Locked doors still need a key on contact.
    if (open) return;
    if (spawn.locked) {
      final player = game.player;
      if (player == null || player.isDead) return;
      final doorCenter = Vector2(
        spawn.pos.x * tileSize + tileSize / 2,
        spawn.pos.y * tileSize + tileSize / 2,
      );
      if (player.position.distanceTo(doorCenter) > 20) return;
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
