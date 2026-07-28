import 'dart:ui';

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';
import '../pixel_crawler_game.dart';
import 'dungeon_renderer.dart';
import 'solid_obstacle.dart';

/// Door between rooms. Uses the pack's directional wall-door tile for the
/// wall side it sits on (n/s/e/w). Locked doors consume a normal key.
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

  @override
  Future<void> onLoad() async {
    open = !spawn.locked;
    _refreshSprite();
    priority = -9995;
  }

  SpriteSpec _specFor({required bool opened}) {
    final dir = spawn.dir;
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

  void _refreshSprite() {
    sprite = _specFor(opened: open).sprite();
  }

  @override
  void update(double dt) {
    super.update(dt);
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
        _refreshSprite();
      }
    } else {
      open = true;
      _refreshSprite();
    }
  }
}
