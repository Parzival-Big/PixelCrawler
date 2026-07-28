import 'package:flutter/material.dart';

import '../../game/heroes.dart';
import '../../services/save_service.dart';
import '../theme.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/pixel_widgets.dart';
import 'game_screen.dart';

class CharacterSelectScreen extends StatelessWidget {
  const CharacterSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final save = SaveService.instance;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 12),
            Row(
              children: [
                const SizedBox(width: 12),
                PixelButton(
                  label: '<',
                  fontSize: 12,
                  onPressed: () => Navigator.of(context).pop(),
                ),
                const Expanded(
                  child: Text(
                    'SCEGLI IL TUO EROE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: pixelFont,
                      fontSize: 14,
                      color: PixelColors.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 54),
              ],
            ),
            Expanded(
              child: Center(
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  itemCount: heroes.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 16),
                  itemBuilder: (context, i) {
                    final def = heroes.values.elementAt(i);
                    final locked = def.unlockable && !save.slimeUnlocked;
                    return _HeroCard(def: def, locked: locked);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.def, required this.locked});

  final HeroDef def;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    return PixelPanel(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 190,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              locked ? '???' : def.name.toUpperCase(),
              style: TextStyle(
                fontFamily: pixelFont,
                fontSize: 12,
                color: locked ? PixelColors.textDim : PixelColors.gold,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 96,
              child: locked
                  ? const Icon(
                      Icons.lock,
                      size: 48,
                      color: PixelColors.textDim,
                    )
                  : PixelSpriteAnimation(spec: def.anim, scale: 4),
            ),
            const SizedBox(height: 10),
            if (locked)
              Text(
                'Raggiungi il piano '
                '${SaveService.slimeUnlockFloor}\nper sbloccare',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: pixelFont,
                  fontSize: 7,
                  height: 1.8,
                  color: PixelColors.textDim,
                ),
              )
            else ...[
              Text(
                def.description,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: pixelFont,
                  fontSize: 6,
                  height: 1.8,
                  color: PixelColors.textDim,
                ),
              ),
              const SizedBox(height: 10),
              StatPips(label: 'VITA', value: def.hpPips, color: PixelColors.red),
              const SizedBox(height: 4),
              StatPips(label: 'ATK', value: def.atkPips, color: PixelColors.gold),
              const SizedBox(height: 4),
              StatPips(label: 'VEL', value: def.spdPips, color: PixelColors.green),
            ],
            const SizedBox(height: 12),
            PixelButton(
              label: locked ? 'BLOCCATO' : 'GIOCA',
              enabled: !locked,
              color: locked ? PixelColors.surface : PixelColors.green,
              textColor: locked ? PixelColors.textDim : PixelColors.bg,
              fontSize: 9,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => GameScreen(heroType: def.type),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
