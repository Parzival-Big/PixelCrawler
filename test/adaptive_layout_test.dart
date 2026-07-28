import 'dart:ui' show DisplayFeature, DisplayFeatureType, DisplayFeatureState, Offset, Rect;

import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_generator.dart';
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
    'camera zoom fits a single room on screen',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      expect(PixelCrawlerGame.roomWorldWidth, 240);
      expect(PixelCrawlerGame.roomWorldHeight, 176);

      // Exact room aspect → zoom 1.
      game.onGameResize(Vector2(
        PixelCrawlerGame.roomWorldWidth,
        PixelCrawlerGame.roomWorldHeight,
      ));
      expect(game.camera.viewfinder.zoom, closeTo(1.0, 0.01));

      // Double size, same aspect.
      game.onGameResize(Vector2(
        PixelCrawlerGame.roomWorldWidth * 2,
        PixelCrawlerGame.roomWorldHeight * 2,
      ));
      expect(game.camera.viewfinder.zoom, closeTo(2.0, 0.01));

      // Tall phone: limited by width.
      game.onGameResize(Vector2(300, 600));
      expect(
        game.camera.viewfinder.zoom,
        closeTo(300 / PixelCrawlerGame.roomWorldWidth, 0.01),
      );

      expect(game.player!.isMounted, isTrue);
      expect(game.currentRoom, isNotNull);
      expect(game.discoveredRooms, isNotEmpty);
    },
  );

  testWithGame<PixelCrawlerGame>(
    'camera stays locked on the current room after movement and resize',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      game.onGameResize(Vector2(800, 400));

      final player = game.player!;
      final room = game.currentRoom!;
      final outer = room.outerBounds;
      final roomCenter = Vector2(
        (outer.left + outer.width / 2) * 16,
        (outer.top + outer.height / 2) * 16,
      );

      for (var i = 0; i < 40; i++) {
        player.moveAndCollide(Vector2(2, 1));
        game.update(1 / 60);
      }
      expect(
        game.camera.viewfinder.position.x,
        closeTo(roomCenter.x, 1.0),
      );
      expect(
        game.camera.viewfinder.position.y,
        closeTo(roomCenter.y, 1.0),
      );

      final visible = game.camera.visibleWorldRect;
      expect(
        visible.contains(Offset(player.position.x, player.position.y)),
        isTrue,
        reason: 'player left the room view while moving',
      );

      game.onGameResize(Vector2(400, 800));
      game.update(0);
      expect(
        game.camera.visibleWorldRect
            .contains(Offset(player.position.x, player.position.y)),
        isTrue,
      );
    },
  );
}
