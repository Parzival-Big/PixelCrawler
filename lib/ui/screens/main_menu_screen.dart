import 'package:flutter/material.dart';

import '../../config/game_assets.dart';
import '../../services/save_service.dart';
import '../theme.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/pixel_widgets.dart';
import 'character_select_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  Future<void> _open(Widget screen) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final save = SaveService.instance;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.4,
            colors: [PixelColors.surface, PixelColors.bg],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      PixelSpriteAnimation(spec: GameAssets.firePot, scale: 3),
                      SizedBox(width: 12),
                      Column(
                        children: [
                          Text(
                            'PIXEL',
                            style: TextStyle(
                              fontFamily: pixelFont,
                              fontSize: 34,
                              color: PixelColors.text,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF68A08A),
                                  offset: Offset(3, 3),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'CRAWLER',
                            style: TextStyle(
                              fontFamily: pixelFont,
                              fontSize: 34,
                              color: PixelColors.textDim,
                              shadows: [
                                Shadow(
                                  color: Color(0xFF15323D),
                                  offset: Offset(3, 3),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(width: 12),
                      PixelSpriteAnimation(spec: GameAssets.firePot, scale: 3),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Un dungeon infinito ti aspetta',
                    style: TextStyle(
                      fontFamily: pixelFont,
                      fontSize: 8,
                      color: PixelColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 28),
                  PixelButton(
                    label: 'GIOCA',
                    color: PixelColors.red,
                    fontSize: 14,
                    onPressed: () => _open(const CharacterSelectScreen()),
                  ),
                  const SizedBox(height: 24),
                  PixelPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Text(
                      'RECORD: PIANO ${save.bestFloor}'
                      '   MONETE: ${save.totalCoins}',
                      style: const TextStyle(
                        fontFamily: pixelFont,
                        fontSize: 8,
                        color: PixelColors.gold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
