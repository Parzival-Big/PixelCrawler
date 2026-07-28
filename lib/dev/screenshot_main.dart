// Dev-only entrypoint used to capture screenshots of individual screens:
//
//   flutter build web -t lib/dev/screenshot_main.dart
//   (serve build/web) http://localhost:8080/?screen=menu|select|game|shop
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/heroes.dart';
import '../game/pixel_crawler_game.dart';
import '../services/save_service.dart';
import '../ui/overlays/shop_overlay.dart';
import '../ui/screens/character_select_screen.dart';
import '../ui/screens/game_screen.dart';
import '../ui/screens/main_menu_screen.dart';
import '../ui/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SaveService.load();

  final screen = Uri.base.queryParameters['screen'] ?? 'menu';
  final hero = HeroType.values.asNameMap()[
          Uri.base.queryParameters['hero'] ?? 'knight'] ??
      HeroType.knight;

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildPixelTheme(),
      home: switch (screen) {
        'select' => const CharacterSelectScreen(),
        'game' => GameScreen(heroType: hero),
        'shop' => _ShopScreenshot(heroType: hero),
        _ => const MainMenuScreen(),
      },
    ),
  );
}

/// Boots a real game, gives some coins and opens the between-floor shop.
class _ShopScreenshot extends StatefulWidget {
  const _ShopScreenshot({required this.heroType});
  final HeroType heroType;

  @override
  State<_ShopScreenshot> createState() => _ShopScreenshotState();
}

class _ShopScreenshotState extends State<_ShopScreenshot> {
  late final PixelCrawlerGame _game =
      PixelCrawlerGame(heroType: widget.heroType);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget<PixelCrawlerGame>(
        game: _game,
        overlayBuilderMap: {
          Overlays.hud: (_, _) => const SizedBox.shrink(),
          Overlays.shop: (_, game) => ShopOverlay(game: game),
        },
        initialActiveOverlays: const [Overlays.hud],
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Wait until onLoad finishes, then open the shop with some coins.
      while (!_game.isLoaded) {
        await Future<void>.delayed(const Duration(milliseconds: 16));
      }
      _game.addCoins(30);
      _game.floor = 2;
      _game.floorNotifier.value = 2;
      _game.pauseEngine();
      _game.overlays.add(Overlays.shop);
    });
  }
}
