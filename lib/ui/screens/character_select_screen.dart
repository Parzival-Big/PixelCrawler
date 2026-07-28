import 'package:flutter/material.dart';

import '../../game/heroes.dart';
import '../../services/save_service.dart';
import '../adaptive.dart';
import '../theme.dart';
import '../widgets/pixel_sprite.dart';
import '../widgets/pixel_widgets.dart';
import 'game_screen.dart';

class CharacterSelectScreen extends StatelessWidget {
  const CharacterSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final save = SaveService.instance;
    final mq = MediaQuery.of(context);
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
                    'SCEGLI IL TUO EROE',
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
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final cards = [
                    for (final def in heroes.values)
                      _HeroCard(
                        def: def,
                        locked: def.unlockable && !save.slimeUnlocked,
                      ),
                  ];

                  // Portrait / folded: vertical list. Wide tablet: wrap grid.
                  // Phone landscape: horizontal carousel.
                  if (mq.isPortrait) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount: cards.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => Center(child: cards[i]),
                    );
                  }
                  if (mq.isTablet && constraints.maxWidth >= 900) {
                    return SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      child: Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.center,
                        children: cards,
                      ),
                    );
                  }
                  return Center(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      itemCount: cards.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (_, i) => cards[i],
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

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.def, required this.locked});

  final HeroDef def;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final save = SaveService.instance;
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
                  : PixelSpriteAnimation(spec: def.anim, scale: 5),
            ),
            const SizedBox(height: 10),
            if (locked)
              _SlimeUnlockProgress(save: save)
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
              if (!def.unlockable) ...[
                const SizedBox(height: 8),
                Text(
                  'MAX P${save.bestFloorFor(def.type)}'
                  '/${SaveService.slimeUnlockFloor}',
                  style: const TextStyle(
                    fontFamily: pixelFont,
                    fontSize: 6,
                    color: PixelColors.textDim,
                  ),
                ),
              ],
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

class _SlimeUnlockProgress extends StatelessWidget {
  const _SlimeUnlockProgress({required this.save});

  final SaveService save;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text(
          'Raggiungi il piano '
          '${SaveService.slimeUnlockFloor}\n'
          'con TUTTI questi eroi:',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: pixelFont,
            fontSize: 6,
            height: 1.8,
            color: PixelColors.textDim,
          ),
        ),
        const SizedBox(height: 8),
        for (final hero in SaveService.slimeUnlockHeroes)
          Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              '${heroes[hero]!.name.toUpperCase()}  '
              '${save.bestFloorFor(hero)}'
              '/${SaveService.slimeUnlockFloor}'
              '${save.bestFloorFor(hero) >= SaveService.slimeUnlockFloor ? '  OK' : ''}',
              style: TextStyle(
                fontFamily: pixelFont,
                fontSize: 6,
                color: save.bestFloorFor(hero) >= SaveService.slimeUnlockFloor
                    ? PixelColors.gold
                    : PixelColors.textDim,
              ),
            ),
          ),
      ],
    );
  }
}
