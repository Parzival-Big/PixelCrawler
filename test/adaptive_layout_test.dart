import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState, Rect;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/heroes.dart';
import 'package:pixel_crawler/game/pixel_crawler_game.dart';
import 'package:pixel_crawler/services/save_service.dart';
import 'package:pixel_crawler/ui/adaptive.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SaveService.resetForTest();
    await SaveService.load();
  });

  group('AdaptiveMediaQuery', () {
    testWidgets('detects tablet breakpoint', (tester) async {
      late MediaQueryData phone;
      late MediaQueryData tablet;
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(390, 844)),
          child: Builder(builder: (context) {
            phone = MediaQuery.of(context);
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(1024, 768)),
          child: Builder(builder: (context) {
            tablet = MediaQuery.of(context);
            return const SizedBox();
          }),
        ),
      );
      expect(phone.isTablet, isFalse);
      expect(phone.isPortrait, isTrue);
      expect(tablet.isTablet, isTrue);
      expect(tablet.isPortrait, isFalse);
    });

    testWidgets('hingePadding clears a vertical hinge', (tester) async {
      const size = Size(800, 400);
      final mq = MediaQueryData(
        size: size,
        displayFeatures: [
          DisplayFeature(
            bounds: const Rect.fromLTWH(390, 0, 20, 400),
            type: DisplayFeatureType.hinge,
            state: DisplayFeatureState.postureFlat,
          ),
        ],
      );
      expect(mq.hingePadding.left, greaterThan(0));
      expect(mq.hingePadding.right, 0);
    });
  });

  testWithGame<PixelCrawlerGame>(
    'camera zoom and HUD adapt when the canvas is resized (fold/unfold)',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);

      game.onGameResize(Vector2(384, 216));
      expect(game.camera.viewfinder.zoom, closeTo(1.0, 0.01));

      // Unfolded / tablet: taller canvas → higher zoom, more horizontal view
      // stays readable.
      game.onGameResize(Vector2(900, 432));
      expect(game.camera.viewfinder.zoom, closeTo(2.0, 0.01));

      // Folded portrait-like window.
      game.onGameResize(Vector2(300, 600));
      expect(game.camera.viewfinder.zoom, closeTo(600 / 216, 0.01));

      // Still playable after several resizes.
      expect(game.player!.isMounted, isTrue);
      for (var i = 0; i < 30; i++) {
        game.update(1 / 60);
      }
    },
  );
}
