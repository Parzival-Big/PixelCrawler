import 'package:flutter/material.dart';

import '../../game/store_catalog.dart';
import '../../services/save_service.dart';
import '../theme.dart';
import '../widgets/pixel_widgets.dart';

/// Merchant screen: spend banked coins on permanent upgrades.
class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  String? _toast;

  Future<void> _buy(StoreUpgrade upgrade) async {
    final ok = await SaveService.instance.buyUpgrade(upgrade);
    if (!mounted) return;
    setState(() {
      _toast = ok
          ? '${upgrade.name} ACQUISTATO!'
          : (SaveService.instance.upgradeLevel(upgrade) >= upgrade.maxLevel
              ? 'GIA AL MASSIMO'
              : 'MONETE INSUFFICIENTI');
    });
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (mounted) setState(() => _toast = null);
  }

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
                    'NEGOZIO',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: pixelFont,
                      fontSize: 14,
                      color: PixelColors.gold,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/objects/coin.png',
                        width: 18,
                        height: 18,
                        filterQuality: FilterQuality.none,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${save.totalCoins}',
                        style: const TextStyle(
                          fontFamily: pixelFont,
                          fontSize: 10,
                          color: PixelColors.gold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Le monete raccolte nelle run finiscono qui',
              style: TextStyle(
                fontFamily: pixelFont,
                fontSize: 7,
                color: PixelColors.textDim,
              ),
            ),
            Expanded(
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: StoreCatalog.all.length,
                separatorBuilder: (_, _) => const SizedBox(width: 14),
                itemBuilder: (context, i) {
                  final upgrade = StoreCatalog.all[i];
                  return _UpgradeCard(
                    upgrade: upgrade,
                    level: save.upgradeLevel(upgrade),
                    coins: save.totalCoins,
                    onBuy: () => _buy(upgrade),
                  );
                },
              ),
            ),
            if (_toast != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PixelPanel(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  child: Text(
                    _toast!,
                    style: const TextStyle(
                      fontFamily: pixelFont,
                      fontSize: 9,
                      color: PixelColors.gold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({
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
    return PixelPanel(
      padding: const EdgeInsets.all(14),
      child: SizedBox(
        width: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              upgrade.name,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: pixelFont,
                fontSize: 9,
                height: 1.5,
                color: PixelColors.gold,
              ),
            ),
            const SizedBox(height: 10),
            Transform.scale(
              scale: 3,
              child: Image.asset(
                _iconFor(upgrade),
                width: 16,
                height: 16,
                filterQuality: FilterQuality.none,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              upgrade.description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: pixelFont,
                fontSize: 6,
                height: 1.8,
                color: PixelColors.textDim,
              ),
            ),
            const SizedBox(height: 12),
            StatPips(
              label: 'LVL',
              value: level.clamp(0, 5),
              color: PixelColors.gold,
            ),
            const SizedBox(height: 4),
            Text(
              maxed ? 'MAX' : 'LVL $level/${upgrade.maxLevel}',
              style: const TextStyle(
                fontFamily: pixelFont,
                fontSize: 7,
                color: PixelColors.textDim,
              ),
            ),
            const SizedBox(height: 14),
            PixelButton(
              label: maxed ? 'ESAURITO' : 'COMPRA  $cost',
              enabled: canBuy,
              color: canBuy ? PixelColors.green : PixelColors.surface,
              textColor: canBuy ? PixelColors.bg : PixelColors.textDim,
              fontSize: 8,
              onPressed: onBuy,
            ),
          ],
        ),
      ),
    );
  }

  String _iconFor(StoreUpgrade upgrade) {
    switch (upgrade.id) {
      case 'max_hp':
        return 'assets/images/ui/heart_full.png';
      case 'damage':
        return 'assets/images/objects/sword.png';
      case 'speed':
        return 'assets/images/objects/boot.png';
      case 'attack_speed':
        return 'assets/images/effects/arrow.png';
      default:
        return 'assets/images/objects/coin.png';
    }
  }
}
