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
                    for (final def in save.visibleHeroes)
                      _HeroCard(
                        def: def,
                        locked: !save.isUnlocked(def.type),
                      ),
                  ];

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
                  final cardHeight = constraints.maxHeight - 8;
                  return Center(
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 4,
                      ),
                      itemCount: cards.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 16),
                      itemBuilder: (_, i) => SizedBox(
                        height: cardHeight,
                        child: cards[i],
                      ),
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
      padding: const EdgeInsets.all(10),
      child: SizedBox(
        width: 190,
        height: 320,
        child: Column(
          children: [
            Text(
              locked ? '???' : def.name.toUpperCase(),
              style: TextStyle(
                fontFamily: pixelFont,
                fontSize: 12,
                color: locked ? PixelColors.textDim : PixelColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 64,
              child: locked
                  ? const Icon(
                      Icons.lock,
                      size: 40,
                      color: PixelColors.textDim,
                    )
                  : PixelSpriteAnimation(spec: def.anim, scale: 4),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: SingleChildScrollView(
                child: locked
                    ? _UnlockProgress(def: def, save: save)
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            def.description,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: pixelFont,
                              fontSize: 6,
                              height: 1.6,
                              color: PixelColors.textDim,
                            ),
                          ),
                          const SizedBox(height: 8),
                          StatPips(
                            label: 'VITA',
                            value: def.hpPips,
                            color: PixelColors.red,
                          ),
                          const SizedBox(height: 3),
                          StatPips(
                            label: 'ATK',
                            value: def.atkPips,
                            color: PixelColors.gold,
                          ),
                          const SizedBox(height: 3),
                          StatPips(
                            label: 'VEL',
                            value: def.spdPips,
                            color: PixelColors.green,
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 10),
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

class _UnlockProgress extends StatelessWidget {
  const _UnlockProgress({required this.def, required this.save});

  final HeroDef def;
  final SaveService save;

  @override
  Widget build(BuildContext context) {
    final rule = def.unlock!;
    final names = rule.requiredHeroes.map((h) => heroes[h]!.name).join(', ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Raggiungi il piano ${rule.floor}\ncon: $names',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: pixelFont,
            fontSize: 6,
            height: 1.6,
            color: PixelColors.textDim,
          ),
        ),
        const SizedBox(height: 6),
        for (final hero in rule.requiredHeroes)
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              '${heroes[hero]!.name.toUpperCase()}  '
              '${save.bestFloorFor(hero)}/${rule.floor}'
              '${save.bestFloorFor(hero) >= rule.floor ? '  OK' : ''}',
              style: TextStyle(
                fontFamily: pixelFont,
                fontSize: 6,
                color: save.bestFloorFor(hero) >= rule.floor
                    ? PixelColors.gold
                    : PixelColors.textDim,
              ),
            ),
          ),
      ],
    );
  }
}
