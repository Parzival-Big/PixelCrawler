import 'package:flutter/material.dart';

import '../../game/heroes.dart';
import '../../services/save_service.dart';
import '../adaptive.dart';
import '../theme.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/pixel_widgets.dart';

/// Lifetime stats for unlocked heroes.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final save = SaveService.instance;
    final unlocked = heroes.values.where((d) => save.isUnlocked(d.type)).toList();

    return Scaffold(
      body: AdaptiveSafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 12),
                PixelButton(
                  label: '<',
                  fontSize: adaptiveFont(context, 12),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                Expanded(
                  child: Text(
                    'STATISTICHE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: pixelFont,
                      fontSize: adaptiveFont(context, 14),
                      color: PixelColors.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 54),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: PixelPanel(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Text(
                  'MIGLIOR PIANO ${save.bestFloor}'
                  '   MONETE ${save.totalCoins}'
                  '   KILL ${save.totalKills}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: pixelFont,
                    fontSize: adaptiveFont(context, 7),
                    color: PixelColors.textDim,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                itemCount: unlocked.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, i) {
                  final def = unlocked[i];
                  final best = save.bestFloorFor(def.type);
                  return PixelPanel(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 48,
                          height: 48,
                          child: PixelSpriteAnimation(spec: def.anim, scale: 3),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                def.name.toUpperCase(),
                                style: const TextStyle(
                                  fontFamily: pixelFont,
                                  fontSize: 10,
                                  color: PixelColors.gold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Miglior piano: $best',
                                style: const TextStyle(
                                  fontFamily: pixelFont,
                                  fontSize: 7,
                                  color: PixelColors.textDim,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
