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
    setState(() {
      _game = PixelCrawlerGame(heroType: widget.heroType);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<PixelCrawlerGame>.controlled(
        gameFactory: () => _game,
        initialActiveOverlays: const [Overlays.hud],
        overlayBuilderMap: {
          Overlays.hud: (context, game) => _Hud(game: game),
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
              const _FloorTransitionOverlay(),
        },
      ),
    );
  }

  void _quitToMenu() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

// ------------------------------------------------------------------- HUD

class _Hud extends StatelessWidget {
  const _Hud({required this.game});

  final PixelCrawlerGame game;

  @override
  Widget build(BuildContext context) {
    return AdaptiveSafeArea(
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HeartsRow(game: game),
                const SizedBox(height: 6),
                Row(
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
                    fontSize: 10,
                    color: PixelColors.textDim,
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 44, right: 10),
              child: MiniMapOverlay(game: game),
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: PixelButton(
                label: 'II',
                fontSize: 9,
                onPressed: game.togglePause,
              ),
            ),
          ),
          _FloorBanner(game: game),
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

/// Big "PIANO N" splash shown for a moment when entering a new floor.
class _FloorBanner extends StatefulWidget {
  const _FloorBanner({required this.game});

  final PixelCrawlerGame game;

  @override
  State<_FloorBanner> createState() => _FloorBannerState();
}

class _FloorBannerState extends State<_FloorBanner> {
  bool _visible = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    widget.game.floorNotifier.addListener(_show);
    _show();
  }

  void _show() {
    _timer?.cancel();
    setState(() => _visible = true);
    _timer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  void dispose() {
    widget.game.floorNotifier.removeListener(_show);
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: AnimatedOpacity(
        opacity: _visible ? 1 : 0,
        duration: const Duration(milliseconds: 400),
        child: Center(
          child: Text(
            'PIANO ${widget.game.floorNotifier.value}',
            style: const TextStyle(
              fontFamily: pixelFont,
              fontSize: 26,
              color: PixelColors.text,
              shadows: [
                Shadow(color: Color(0xFF000000), offset: Offset(3, 3)),
              ],
            ),
          ),
        ),
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
    Timer(const Duration(seconds: 3), () {
      widget.game.overlays.remove(Overlays.unlock);
    });
  }

  @override
  Widget build(BuildContext context) {
    final names = widget.game.lastUnlocked
        .map((h) => heroes[h]!.name.toUpperCase())
        .join(', ');
    return AdaptiveSafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: PixelPanel(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            color: PixelColors.surfaceLight,
            child: Text(
              names.isEmpty
                  ? 'NUOVO EROE SBLOCCATO!'
                  : 'NUOVO EROE SBLOCCATO: $names!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: pixelFont,
                fontSize: 9,
                color: PixelColors.gold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------ floor transition

class _FloorTransitionOverlay extends StatelessWidget {
  const _FloorTransitionOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 280),
        builder: (context, t, _) {
          return ColoredBox(
            color: Color.fromRGBO(14, 34, 43, t.clamp(0.0, 1.0)),
            child: const SizedBox.expand(),
          );
        },
      ),
    );
  }
}
