// Dev-only entrypoint used to capture screenshots of individual screens:
//
//   flutter build web -t lib/dev/screenshot_main.dart
//   (serve build/web) http://localhost:8080/?screen=menu|select|game
import 'package:flutter/material.dart';

import '../game/heroes.dart';
import '../services/save_service.dart';
import '../ui/screens/character_select_screen.dart';
import '../ui/screens/game_screen.dart';
import '../ui/screens/main_menu_screen.dart';
import '../ui/screens/store_screen.dart';
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
        'store' => const StoreScreen(),
        'game' => GameScreen(heroType: hero),
        _ => const MainMenuScreen(),
      },
    ),
  );
}
