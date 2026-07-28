import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../dungeon/dungeon_map.dart';
import '../pixel_crawler_game.dart';
import '../store_catalog.dart';
import 'dungeon_renderer.dart';

/// Pedestal in the shop room: pay [cost] coins to buy the upgrade once.
class ShopPedestal extends PositionComponent
    with HasGameReference<PixelCrawlerGame> {
  ShopPedestal({required this.spawn})
      : super(
          position: Vector2(
            spawn.pos.x * tileSize + tileSize / 2,
            spawn.pos.y * tileSize + tileSize - 2,
          ),
          size: Vector2(16, 28),
          anchor: Anchor.bottomCenter,
        );

  final ShopPedestalSpawn spawn;
  bool _bought = false;
  late final StoreUpgrade upgrade;
  late final Sprite _icon;

  @override
  Future<void> onLoad() async {
    upgrade = StoreCatalog.byId(spawn.upgradeId);
    _icon = _iconFor(upgrade).sprite();
    priority = (position.y * 10).round();
  }

  SpriteSpec _iconFor(StoreUpgrade u) {
    switch (u.unit) {
      case StoreUnit.vitaQuarter:
      case StoreUnit.halfHearts:
      case StoreUnit.heal:
        return GameAssets.heartFull;
      case StoreUnit.damage:
        return GameAssets.sword;
      case StoreUnit.defense:
        return GameAssets.shield;
      case StoreUnit.speed:
        return GameAssets.boot;
      case StoreUnit.cooldownHundredths:
        return GameAssets.arrow;
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_bought) return;
    final player = game.player;
    if (player == null || player.isDead) return;
    if (player.position.distanceTo(position) < 14) {
      if (game.buyShopPedestal(upgrade, spawn.cost)) {
        _bought = true;
      }
    }
  }

  @override
  void render(ui.Canvas canvas) {
    final base = ui.Paint()..color = const ui.Color(0xFF1E4250);
    canvas.drawRect(const ui.Rect.fromLTWH(2, 16, 12, 6), base);
    final top = ui.Paint()..color = const ui.Color(0xFF68A08A);
    canvas.drawRect(const ui.Rect.fromLTWH(1, 14, 14, 3), top);

    if (!_bought) {
      _icon.render(canvas, position: Vector2(0, 0), size: Vector2.all(16));
      // Price as tiny bars: each 10 coins ≈ one pip (visual hint) + digit via
      // overlapping coin sprite scaled down would be heavy — draw cost pips.
      final pip = ui.Paint()..color = const ui.Color(0xFFB9DDA7);
      final n = (spawn.cost / 10).round().clamp(3, 5);
      for (var i = 0; i < n; i++) {
        canvas.drawRect(ui.Rect.fromLTWH(2.0 + i * 2.5, 24, 2, 2), pip);
      }
    }
  }
}

/// Key pickup (normal or boss).
class KeyPickup extends SpriteComponent
    with HasGameReference<PixelCrawlerGame> {
  KeyPickup({required Vector2 position, this.boss = false})
      : super(
          position: position,
          size: Vector2.all(16),
          anchor: Anchor.bottomCenter,
        );

  final bool boss;
  double _bob = 0;

  @override
  Future<void> onLoad() async {
    sprite = (boss ? GameAssets.keyBoss : GameAssets.key).sprite();
    priority = (position.y * 10).round();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bob += dt;
    priority = (position.y * 10).round();
    final player = game.player;
    if (player != null &&
        !player.isDead &&
        player.position.distanceTo(position) < 12) {
      if (boss) {
        game.addBossKey(1);
      } else {
        game.addKey(1);
      }
      removeFromParent();
    }
  }

  @override
  void render(ui.Canvas canvas) {
    canvas.save();
    canvas.translate(0, sin(_bob * 4) * 1.2 - 1);
    super.render(canvas);
    canvas.restore();
  }
}
