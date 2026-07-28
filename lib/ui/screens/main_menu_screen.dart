import 'package:flutter/material.dart';

import '../../config/game_assets.dart';
import '../adaptive.dart';
import '../theme.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/pixel_widgets.dart';
import 'character_select_screen.dart';
import 'stats_screen.dart';

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
    final titleSize = adaptiveFont(context, 34);
    final mq = MediaQuery.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.4),
            radius: 1.4,
            colors: [PixelColors.surface, PixelColors.bg],
          ),
        ),
        child: AdaptiveSafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: mq.isTablet ? 720 : double.infinity,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        PixelSpriteAnimation(
                          spec: GameAssets.firePot,
                          scale: mq.isTablet ? 4 : 3,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Text(
                              'PIXEL',
                              style: TextStyle(
                                fontFamily: pixelFont,
                                fontSize: titleSize,
                                color: PixelColors.text,
                                shadows: const [
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
                                fontSize: titleSize,
                                color: PixelColors.textDim,
                                shadows: const [
                                  Shadow(
                                    color: Color(0xFF15323D),
                                    offset: Offset(3, 3),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        PixelSpriteAnimation(
                          spec: GameAssets.firePot,
                          scale: mq.isTablet ? 4 : 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Un dungeon infinito ti aspetta',
                      style: TextStyle(
                        fontFamily: pixelFont,
                        fontSize: adaptiveFont(context, 8),
                        color: PixelColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 28),
                    PixelButton(
                      label: 'GIOCA',
                      color: PixelColors.red,
                      fontSize: adaptiveFont(context, 14),
                      onPressed: () => _open(const CharacterSelectScreen()),
                    ),
                    const SizedBox(height: 14),
                    PixelButton(
                      label: 'STATISTICHE',
                      color: PixelColors.surfaceLight,
                      textColor: PixelColors.text,
                      fontSize: adaptiveFont(context, 11),
                      onPressed: () => _open(const StatsScreen()),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
