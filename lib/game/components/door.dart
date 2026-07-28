import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';
import '../pixel_crawler_game.dart';
import 'dungeon_renderer.dart';
import 'solid_obstacle.dart';

/// Door between rooms. Locked doors consume a normal key; open doors are passable.
class Door extends SpriteComponent
    with HasGameReference<PixelCrawlerGame>, SolidObstacle {
  Door({required this.spawn})
      : super(
          position: Vector2(
            spawn.pos.x * tileSize + tileSize / 2,
            spawn.pos.y * tileSize + tileSize,
          ),
          size: Vector2.all(tileSize),
          anchor: Anchor.bottomCenter,
        );

  final DoorSpawn spawn;
  bool open = false;

  bool get isVertical =>
      spawn.dir == DoorDir.north || spawn.dir == DoorDir.south;

  @override
  double get solidWidth => open ? 0 : 14;
  @override
  double get solidHeight => open ? 0 : 12;

  @override
  Future<void> onLoad() async {
    open = !spawn.locked && !spawn.bossDoor;
    _refreshSprite();
    priority = (position.y * 10).round();
  }

  void _refreshSprite() {
    final vertical = isVertical;
    if (open) {
      sprite = (vertical ? GameAssets.doorOpenV : GameAssets.doorOpenH).sprite();
    } else if (spawn.bossDoor) {
      sprite = (vertical ? GameAssets.doorBossV : GameAssets.doorBossH).sprite();
      // Boss doors start open so you can fight; stairs need the boss key.
      open = true;
      sprite = (vertical ? GameAssets.doorOpenV : GameAssets.doorOpenH).sprite();
    } else if (spawn.locked) {
      sprite =
          (vertical ? GameAssets.doorLockedV : GameAssets.doorLockedH).sprite();
    } else {
      sprite =
          (vertical ? GameAssets.doorClosedV : GameAssets.doorClosedH).sprite();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (open) return;
    final player = game.player;
    if (player == null || player.isDead) return;
    if (player.position.distanceTo(position) > 18) return;

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
