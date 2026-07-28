import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../game/heroes.dart';
import '../../game/pixel_crawler_game.dart';
import '../adaptive.dart';
import '../overlays/minimap_overlay.dart';
import '../overlays/shop_overlay.dart';
import '../theme.dart';
import '../widgets/pixel_widgets.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key, required this.heroType});

  final HeroType heroType;

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late PixelCrawlerGame _game;

  @override
  void initState() {
    super.initState();
    _game = PixelCrawlerGame(heroType: widget.heroType);
  }

  void _retry() {
    unawaited(_game.restartRun());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PixelColors.bg,
      body: GameWidget<PixelCrawlerGame>(
        game: _game,
        initialActiveOverlays: const [Overlays.hud],
        overlayBuilderMap: {
          Overlays.hud: (context, game) => _HudOverlay(game: game),
          Overlays.pause: (context, game) => _PauseOverlay(
                game: game,
                onQuit: _quitToMenu,
              ),
          Overlays.gameOver: (context, game) => _GameOverOverlay(
                game: game,
                onRetry: _retry,
                onQuit: _quitToMenu,
              ),
          Overlays.unlock: (context, game) => _UnlockToast(game: game),
          Overlays.shop: (context, game) => ShopOverlay(game: game),
          Overlays.floorTransition: (context, game) =>
              _FloorTransitionOverlay(game: game),
        },
      ),
    );
  }

  void _quitToMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// ------------------------------------------------------------------- HUD

/// Hearts, inventory, floor label, minimap and pause — overlaid on the
/// letterbox around the room (not inside the Flame world).
class _HudOverlay extends StatelessWidget {
  const _HudOverlay({required this.game});

  final PixelCrawlerGame game;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSafeArea(
      child: Stack(
        children: [
          // Hearts + coins/keys — top left
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeartsRow(game: game),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/objects/coin.png',
                      width: 18,
                      height: 18,
                      filterQuality: FilterQuality.none,
                    ),
                    const SizedBox(width: 4),
                    ValueListenableBuilder<int>(
                      valueListenable: game.coinsNotifier,
                      builder: (_, coins, _) => Text(
                        '$coins',
                        style: const TextStyle(
                          fontFamily: pixelFont,
                          fontSize: 10,
                          color: PixelColors.gold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Image.asset(
                      'assets/images/objects/key.png',
                      width: 18,
                      height: 18,
                      filterQuality: FilterQuality.none,
                    ),
                    const SizedBox(width: 4),
                    ValueListenableBuilder<int>(
                      valueListenable: game.keysNotifier,
                      builder: (_, keys, _) => Text(
                        '$keys',
                        style: const TextStyle(
                          fontFamily: pixelFont,
                          fontSize: 10,
                          color: PixelColors.textDim,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Image.asset(
                      'assets/images/objects/key_boss.png',
                      width: 18,
                      height: 18,
                      filterQuality: FilterQuality.none,
                    ),
                    const SizedBox(width: 4),
                    ValueListenableBuilder<int>(
                      valueListenable: game.bossKeysNotifier,
                      builder: (_, keys, _) => Text(
                        '$keys',
                        style: const TextStyle(
                          fontFamily: pixelFont,
                          fontSize: 10,
                          color: PixelColors.gold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Floor label — top center
          Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: ValueListenableBuilder<int>(
                valueListenable: game.floorNotifier,
                builder: (_, floor, _) => Text(
                  'PIANO $floor',
                  style: const TextStyle(
                    fontFamily: pixelFont,
                    fontSize: 12,
                    color: PixelColors.gold,
                    shadows: [
                      Shadow(color: Color(0xFF000000), offset: Offset(2, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Pause — top right
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: PixelButton(
                label: 'STOP',
                fontSize: 8,
                onPressed: game.togglePause,
              ),
            ),
          ),
          // Minimap — under pause
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 48, right: 10),
              child: MiniMapOverlay(game: game),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeartsRow extends StatelessWidget {
  const _HeartsRow({required this.game});

  final PixelCrawlerGame game;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: game.maxHpNotifier,
      builder: (_, maxHp, _) => ValueListenableBuilder<int>(
        valueListenable: game.hpNotifier,
        builder: (_, hp, _) {
          final hearts = (maxHp / 2).ceil();
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < hearts; i++)
                Padding(
                  padding: const EdgeInsets.only(right: 2),
                  child: Image.asset(
                    hp >= (i + 1) * 2
                        ? 'assets/images/ui/heart_full.png'
                        : hp == i * 2 + 1
                            ? 'assets/images/ui/heart_half.png'
                            : 'assets/images/ui/heart_empty.png',
                    width: 22,
                    height: 22,
                    filterQuality: FilterQuality.none,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------- pause

class _PauseOverlay extends StatelessWidget {
  const _PauseOverlay({required this.game, required this.onQuit});

  final PixelCrawlerGame game;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xCC14141C),
      child: Center(
        child: PixelPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'PAUSA',
                style: TextStyle(
                  fontFamily: pixelFont,
                  fontSize: 18,
                  color: PixelColors.gold,
                ),
              ),
              const SizedBox(height: 20),
              PixelButton(label: 'RIPRENDI', onPressed: game.togglePause),
              const SizedBox(height: 12),
              PixelButton(
                label: 'ESCI',
                color: PixelColors.red,
                onPressed: () async {
                  await game.bankAndQuit();
                  game.resumeEngine();
                  onQuit();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------- game over

class _GameOverOverlay extends StatelessWidget {
  const _GameOverOverlay({
    required this.game,
    required this.onRetry,
    required this.onQuit,
  });

  final PixelCrawlerGame game;
  final VoidCallback onRetry;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xDD14141C),
      child: Center(
        child: PixelPanel(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'SEI CADUTO...',
                style: TextStyle(
                  fontFamily: pixelFont,
                  fontSize: 16,
                  color: PixelColors.red,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'PIANO ${game.floor}   MONETE ${game.coins}\n'
                'NEMICI SCONFITTI ${game.kills}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: pixelFont,
                  fontSize: 8,
                  height: 2,
                  color: PixelColors.textDim,
                ),
              ),
              const SizedBox(height: 20),
              PixelButton(
                label: 'RIPROVA',
                color: PixelColors.green,
                textColor: PixelColors.bg,
                onPressed: onRetry,
              ),
              const SizedBox(height: 12),
              PixelButton(label: 'MENU', onPressed: onQuit),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------- unlock

class _UnlockToast extends StatefulWidget {
  const _UnlockToast({required this.game});

  final PixelCrawlerGame game;

  @override
  State<_UnlockToast> createState() => _UnlockToastState();
}

class _UnlockToastState extends State<_UnlockToast> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (mounted &&
          widget.game.overlays.isActive(Overlays.unlock)) {
        widget.game.overlays.remove(Overlays.unlock);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.game.lastUnlocked
        .map((h) => heroes[h]!.name.toUpperCase())
        .join(', ');
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: PixelPanel(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Text(
            'SBLOCCATO: $names',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: pixelFont,
              fontSize: 8,
              color: PixelColors.gold,
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------ floor transition

class _FloorTransitionOverlay extends StatelessWidget {
  const _FloorTransitionOverlay({required this.game});

  final PixelCrawlerGame game;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 720),
        builder: (context, t, _) {
          final opacity = (0.55 + 0.45 * t).clamp(0.0, 1.0);
          return ColoredBox(
            color: Color.fromRGBO(14, 34, 43, opacity),
            child: Center(
              child: Opacity(
                opacity: t.clamp(0.0, 1.0),
                child: Text(
                  'PIANO ${game.floor}',
                  style: const TextStyle(
                    fontFamily: pixelFont,
                    fontSize: 28,
                    color: PixelColors.gold,
                    shadows: [
                      Shadow(color: Color(0xFF000000), offset: Offset(3, 3)),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
