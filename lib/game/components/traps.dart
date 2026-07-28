import 'dart:math';

import 'package:flame/components.dart';

import '../../config/game_assets.dart';
import '../pixel_crawler_game.dart';
import 'dungeon_renderer.dart';

enum SpikePhase { off, charging, on }

/// Spike trap with Off → Charging → On cycle. Damages only while On.
/// All traps on a floor share the same phase (unison).
class SpikeTrap extends SpriteComponent
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

  late final SpriteSheetSpec _sheet;
  SpikePhase _phase = SpikePhase.off;
  double _phaseTimer = 0;
  double _damageCooldown = 0;

  int get damage => big ? 2 : 1;

  // Shared cadence so every trap pulses together; charging reads clearly.
  double get _offDuration => big ? 1.0 : 0.9;
  double get _chargeDuration => big ? 0.95 : 0.85;
  double get _onDuration => big ? 0.7 : 0.55;

  double get _cycleLength => _offDuration + _chargeDuration + _onDuration;

  @override
  Future<void> onLoad() async {
    _sheet = big ? GameAssets.trapBig : GameAssets.trapSmall;
    _phaseTimer = 0;
    _applyPhaseFromTimer();
  }

  void _applyPhaseFromTimer() {
    var t = _phaseTimer % _cycleLength;
    if (t < _offDuration) {
      _phase = SpikePhase.off;
    } else if (t < _offDuration + _chargeDuration) {
      _phase = SpikePhase.charging;
    } else {
      _phase = SpikePhase.on;
    }
    sprite = _sheet.frame(_phase.index);
  }

  @override
  void update(double dt) {
    super.update(dt);
    _phaseTimer += dt;
    _damageCooldown -= dt;
    final prev = _phase;
    _applyPhaseFromTimer();
    if (_phase == SpikePhase.on && prev != SpikePhase.on) {
      _damageCooldown = 0;
    }
    if (_phase != SpikePhase.on) return;

    final player = game.player;
    if (player == null || player.isDead || _damageCooldown > 0) return;
    final tx = player.position.x ~/ tileSize;
    final ty = player.position.y ~/ tileSize;
    if (tx == tile.x && ty == tile.y) {
      _damageCooldown = 0.55;
      player.receiveContactDamage(damage);
    }
  }
}
