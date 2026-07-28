import 'package:flutter/material.dart';

import '../../game/pixel_crawler_game.dart';
import '../../game/store_catalog.dart';
import '../../game/components/player.dart';
import '../adaptive.dart';
import '../theme.dart';
import '../widgets/pixel_widgets.dart';

/// Between-floor merchant: spends run coins on bonuses that last until death.
class ShopOverlay extends StatefulWidget {
  const ShopOverlay({super.key, required this.game});

  final PixelCrawlerGame game;

  @override
  State<ShopOverlay> createState() => _ShopOverlayState();
}

class _ShopOverlayState extends State<ShopOverlay> {
  String? _toast;

  Future<void> _buy(StoreUpgrade upgrade) async {
    final ok = widget.game.buyShopUpgrade(upgrade);
    setState(() {
      _toast = ok
          ? '${upgrade.name}!'
          : (SessionBonus.levelOf(upgrade) >= upgrade.maxLevel
              ? 'ESAURITO'
              : 'MONETE INSUFFICIENTI');
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _toast = null);
  }

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return Container(
      color: const Color(0xDD0E222B),
      child: AdaptiveSafeArea(
        child: Column(
          children: [
            const SizedBox(height: 10),
            Text(
              'MERCANTE  ·  PIANO ${game.floor}',
              style: const TextStyle(
                fontFamily: pixelFont,
                fontSize: 12,
                color: PixelColors.gold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Apparizione casuale tra i piani · solo questa run',
              style: TextStyle(
                fontFamily: pixelFont,
                fontSize: 7,
                color: PixelColors.textDim,
              ),
            ),
            const SizedBox(height: 6),
            ValueListenableBuilder<int>(
              valueListenable: game.coinsNotifier,
              builder: (_, coins, _) => Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/objects/coin.png',
                    width: 16,
                    height: 16,
                    filterQuality: FilterQuality.none,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '$coins',
                    style: const TextStyle(
                      fontFamily: pixelFont,
                      fontSize: 12,
                      color: PixelColors.gold,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: StoreCatalog.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final upgrade = StoreCatalog.all[i];
                  return ValueListenableBuilder<int>(
                    valueListenable: game.coinsNotifier,
                    builder: (_, coins, _) => _ShopCard(
                      upgrade: upgrade,
                      level: SessionBonus.levelOf(upgrade),
                      coins: coins,
                      onBuy: () => _buy(upgrade),
                    ),
                  );
                },
              ),
            ),
            if (_toast != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _toast!,
                  style: const TextStyle(
                    fontFamily: pixelFont,
                    fontSize: 9,
                    color: PixelColors.gold,
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: PixelButton(
                label: 'AVANTI  >',
                color: PixelColors.green,
                textColor: PixelColors.bg,
                fontSize: 11,
                onPressed: () => game.finishShopAndEnterFloor(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  const _ShopCard({
    required this.upgrade,
    required this.level,
    required this.coins,
    required this.onBuy,
  });

  final StoreUpgrade upgrade;
  final int level;
  final int coins;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final maxed = level >= upgrade.maxLevel;
    final cost = maxed ? 0 : upgrade.costForLevel(level);
    final canBuy = !maxed && coins >= cost;
    final isHeal = upgrade.unit == StoreUnit.heal;

    return PixelPanel(
      padding: const EdgeInsets.all(12),
      child: SizedBox(
        width: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              upgrade.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: pixelFont,
                fontSize: 8,
                color: PixelColors.gold,
              ),
            ),
            const SizedBox(height: 8),
            Transform.scale(
              scale: 2.5,
              child: Image.asset(
                upgrade.iconAsset,
                width: 16,
                height: 16,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              upgrade.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: pixelFont,
                fontSize: 6,
                height: 1.7,
                color: PixelColors.textDim,
              ),
            ),
            const SizedBox(height: 8),
            if (!isHeal)
              Text(
                maxed ? 'MAX' : 'LVL $level/${upgrade.maxLevel}',
                style: const TextStyle(
                  fontFamily: pixelFont,
                  fontSize: 6,
                  color: PixelColors.textDim,
                ),
              )
            else
              Text(
                'x$level comprate',
                style: const TextStyle(
                  fontFamily: pixelFont,
                  fontSize: 6,
                  color: PixelColors.textDim,
                ),
              ),
            const SizedBox(height: 10),
            PixelButton(
              label: maxed ? 'ESAURITO' : 'COMPRA  $cost',
              enabled: canBuy,
              color: canBuy ? PixelColors.green : PixelColors.surface,
              textColor: canBuy ? PixelColors.bg : PixelColors.textDim,
              fontSize: 7,
              onPressed: onBuy,
            ),
          ],
        ),
      ),
    );
  }
}
