import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pixel_crawler/game/components/pickups.dart';
import 'package:pixel_crawler/game/components/traps.dart';
import 'package:pixel_crawler/game/dungeon/dungeon_map.dart';
import 'package:pixel_crawler/game/monsters.dart';

void main() {
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
}
