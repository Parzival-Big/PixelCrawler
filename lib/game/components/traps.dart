import 'dart:math';

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../pixel_crawler_game.dart';
import 'dungeon_renderer.dart';

/// Spike trap tile that damages the player while standing on it.
class SpikeTrap extends SpriteAnimationComponent
    with HasGameReference<PixelCrawlerGame> {
  SpikeTrap({required this.tile, required this.big})
      : super(
          position: Vector2(tile.x * tileSize, tile.y * tileSize),
          size: Vector2.all(tileSize),
          anchor: Anchor.topLeft,
          priority: -9990,
        );

  final Point<int> tile;
  final bool big;
  double _cooldown = 0;

  int get damage => big ? 2 : 1;

  @override
  Future<void> onLoad() async {
    animation = (big ? GameAssets.trapBig : GameAssets.trapSmall).animation();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _cooldown -= dt;
    final player = game.player;
    if (player == null || player.isDead || _cooldown > 0) return;
    final tx = player.position.x ~/ tileSize;
    final ty = player.position.y ~/ tileSize;
    if (tx == tile.x && ty == tile.y) {
      _cooldown = 0.7;
      player.receiveContactDamage(damage);
    }
  }
}
