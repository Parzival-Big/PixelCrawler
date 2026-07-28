import 'package:flame/components.dart';
import 'package:flame_test/flame_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/components/monster.dart';
import 'package:pixel_crawler/game/components/pickups.dart';
import 'package:pixel_crawler/game/components/traps.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_map.dart';
import 'package:pixel_crawler/game/heroes.dart';
import 'package:pixel_crawler/game/monsters.dart';
import 'package:pixel_crawler/game/pixel_crawler_game.dart';
import 'package:pixel_crawler/services/save_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    SaveService.resetForTest();
    await SaveService.load();
  });

  group('pits', () {
    late DungeonMap map;

    setUp(() {
      map = DungeonMap(8, 8);
      map.setTile(2, 2, TileType.floor);
      map.setTile(3, 2, TileType.pit);
      map.setTile(4, 2, TileType.wall);
      map.setTile(5, 2, TileType.trapSmall);
    });

    test('ground units cannot walk pits; flyers and shots can', () {
      expect(map.isWalkable(3, 2), isFalse);
      expect(map.isFlyable(3, 2), isTrue);
      expect(map.blocksProjectile(3, 2), isFalse);

      expect(map.isWalkable(2, 2), isTrue);
      expect(map.isFlyable(2, 2), isTrue);
      expect(map.blocksProjectile(2, 2), isFalse);

      expect(map.blocksProjectile(4, 2), isTrue);
      expect(map.isFlyable(4, 2), isFalse);

      expect(map.isWalkable(5, 2), isTrue);
      expect(map.blocksProjectile(5, 2), isFalse);
    });

    test('bat, ghost and flying eye are marked as flying', () {
      expect(monsters[MonsterType.bat]!.flies, isTrue);
      expect(monsters[MonsterType.ghost]!.flies, isTrue);
      expect(monsters[MonsterType.flyingEye]!.flies, isTrue);
      expect(monsters[MonsterType.slime]!.flies, isFalse);
      expect(monsters[MonsterType.skeleton]!.flies, isFalse);
    });
  });

  test('bomb fuse defaults to 1.3 seconds', () {
    final bomb = BombPickup(position: Vector2.zero());
    expect(bomb.fuse, closeTo(1.3, 0.001));
  });

  test('spike phases cycle off → charging → on', () {
    expect(SpikePhase.values, [
      SpikePhase.off,
      SpikePhase.charging,
      SpikePhase.on,
    ]);
  });

  test('boss render size is 1.5x the base sprite', () {
    expect(Monster.bossScale, closeTo(1.5, 0.001));
    final base = monsters[MonsterType.boss]!.anim.size;
    expect(base.x * Monster.bossScale, closeTo(base.x * 1.5, 0.001));
  });

  testWithGame<PixelCrawlerGame>(
    'only monsters in the current room are activated',
    () => PixelCrawlerGame(heroType: HeroType.knight),
    (game) async {
      game.update(0);
      final room = game.currentRoom!;
      final monsters = game.world.children.query<Monster>().toList();
      expect(monsters, isNotEmpty);

      for (final m in monsters) {
        final info = game.map.roomInfoContaining(
          m.position.x ~/ 16,
          m.position.y ~/ 16,
        );
        final sameRoom = info?.gridKey == room.gridKey;
        expect(m.isActivated, sameRoom);
        if (sameRoom) {
          expect(m.opacity, greaterThan(0));
        } else {
          expect(m.opacity, 0);
        }
      }

      for (final b in monsters.where((m) => m.isBoss)) {
        final base = b.def.anim.size;
        expect(b.size.x, closeTo(base.x * Monster.bossScale, 0.01));
        expect(b.size.y, closeTo(base.y * Monster.bossScale, 0.01));
      }
    },
  );
}
