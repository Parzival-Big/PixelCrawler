import 'dart:math' show Random;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/experimental.dart' show Rectangle;
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult;

import '../config/game_assets.dart';
import '../services/save_service.dart';
import 'components/dungeon_renderer.dart';
import 'components/effects.dart';
import 'components/monster.dart';
import 'components/pickups.dart';
import 'components/player.dart';
import 'dungeon/dungeon_generator.dart';
import 'dungeon/dungeon_map.dart';
import 'heroes.dart';
import 'monsters.dart';

/// Names of the Flutter overlays registered on the GameWidget.
class Overlays {
  static const hud = 'hud';
  static const pause = 'pause';
  static const gameOver = 'gameOver';
  static const unlock = 'unlock';
}

class PixelCrawlerGame extends FlameGame with KeyboardEvents {
  PixelCrawlerGame({required this.heroType})
      : super(
          camera: CameraComponent.withFixedResolution(width: 384, height: 216),
        ) {
    SessionBonus.extraHp = 0;
  }

  final HeroType heroType;
  final _rng = Random();

  late DungeonMap map;
  Player? player;

  int floor = 1;
  int coins = 0;
  int kills = 0;

  late final hpNotifier = ValueNotifier<int>(0);
  late final maxHpNotifier = ValueNotifier<int>(0);
  late final coinsNotifier = ValueNotifier<int>(0);
  late final floorNotifier = ValueNotifier<int>(1);

  late final JoystickComponent _joystick;
  bool _attackButtonHeld = false;
  final _keysDown = <LogicalKeyboardKey>{};

  bool get attackHeld =>
      _attackButtonHeld ||
      _keysDown.contains(LogicalKeyboardKey.space) ||
      _keysDown.contains(LogicalKeyboardKey.keyJ);

  @override
  Color backgroundColor() => const Color(0xFF14141c);

  @override
  Future<void> onLoad() async {
    await images.loadAll(GameAssets.allImages);

    _joystick = JoystickComponent(
      knob: CircleComponent(
        radius: 13,
        paint: Paint()..color = const Color(0x88E8E8DC),
      ),
      background: CircleComponent(
        radius: 30,
        paint: Paint()..color = const Color(0x33E8E8DC),
      ),
      margin: const EdgeInsets.only(left: 24, bottom: 20),
    );

    final attackButton = HudButtonComponent(
      button: CircleComponent(
        radius: 21,
        paint: Paint()..color = const Color(0x55E83C4C),
        children: [
          CircleComponent(
            radius: 16,
            position: Vector2.all(5),
            paint: Paint()..color = const Color(0x99E83C4C),
          ),
        ],
      ),
      buttonDown: CircleComponent(
        radius: 21,
        paint: Paint()..color = const Color(0xCCE83C4C),
      ),
      margin: const EdgeInsets.only(right: 24, bottom: 18),
      onPressed: () => _attackButtonHeld = true,
      onReleased: () => _attackButtonHeld = false,
      onCancelled: () => _attackButtonHeld = false,
    );

    camera.viewport.addAll([_joystick, attackButton]);

    final def = heroes[heroType]!;
    player = Player(def: def, position: Vector2.zero());
    hpNotifier.value = def.maxHp;
    maxHpNotifier.value = def.maxHp;

    await _loadFloor();
  }

  Future<void> _loadFloor() async {
    world.removeAll(world.children.toList());

    map = DungeonGenerator(floor: floor).generate();

    world.add(DungeonRenderer(map));

    for (final t in map.torchSpawns) {
      final px = t.x * tileSize;
      final py = t.y * tileSize;
      world.add(Torch(position: Vector2(px, py)));
      world.add(GlowComponent(center: Vector2(px + 8, py + 12)));
    }

    world.add(StairsTrigger(
      position: _tileCenter(map.stairsPos.x, map.stairsPos.y),
    ));

    for (final p in map.chestSpawns) {
      world.add(Chest(position: _tileBottom(p.x, p.y)));
    }
    for (final p in map.coinSpawns) {
      world.add(CoinPickup(position: _tileBottom(p.x, p.y)));
    }
    for (final p in map.potionSpawns) {
      world.add(PotionPickup.red(position: _tileBottom(p.x, p.y)));
    }

    final pool = spawnPoolForFloor(floor);
    for (final p in map.monsterSpawns) {
      final type = pool[_rng.nextInt(pool.length)];
      world.add(Monster(
        def: monsters[type]!,
        position: _tileBottom(p.x, p.y),
        floor: floor,
      ));
    }

    player!.position = _tileBottom(map.playerSpawn.x, map.playerSpawn.y);
    world.add(player!);

    camera.follow(player!, maxSpeed: 400, snap: true);
    camera.setBounds(
      Rectangle.fromLTRB(
        0,
        0,
        map.width * tileSize,
        map.height * tileSize,
      ),
      considerViewport: true,
    );
  }

  Vector2 _tileCenter(int x, int y) =>
      Vector2(x * tileSize + tileSize / 2, y * tileSize + tileSize / 2);

  Vector2 _tileBottom(int x, int y) =>
      Vector2(x * tileSize + tileSize / 2, y * tileSize + tileSize - 2);

  // ------------------------------------------------------------ input

  Vector2 moveInput() {
    if (_joystick.direction != JoystickDirection.idle) {
      return _joystick.relativeDelta.clone();
    }
    final v = Vector2.zero();
    if (_keysDown.contains(LogicalKeyboardKey.keyW) ||
        _keysDown.contains(LogicalKeyboardKey.arrowUp)) {
      v.y -= 1;
    }
    if (_keysDown.contains(LogicalKeyboardKey.keyS) ||
        _keysDown.contains(LogicalKeyboardKey.arrowDown)) {
      v.y += 1;
    }
    if (_keysDown.contains(LogicalKeyboardKey.keyA) ||
        _keysDown.contains(LogicalKeyboardKey.arrowLeft)) {
      v.x -= 1;
    }
    if (_keysDown.contains(LogicalKeyboardKey.keyD) ||
        _keysDown.contains(LogicalKeyboardKey.arrowRight)) {
      v.x += 1;
    }
    return v;
  }

  @override
  KeyEventResult onKeyEvent(
    KeyEvent event,
    Set<LogicalKeyboardKey> keysPressed,
  ) {
    _keysDown
      ..clear()
      ..addAll(keysPressed);
    return KeyEventResult.handled;
  }

  // ------------------------------------------------------------ events

  void addCoins(int n) {
    coins += n;
    coinsNotifier.value = coins;
  }

  void raiseMaxHp(int amount) {
    final p = player!;
    p.maxHp += amount;
    p.heal(amount);
    maxHpNotifier.value = p.maxHp;
  }

  void onMonsterKilled() => kills++;

  void spawnDamageText(int amount, Vector2 worldPos) {
    world.add(FloatingText(text: '$amount', position: worldPos));
  }

  Future<void> goToNextFloor() async {
    floor++;
    floorNotifier.value = floor;
    final justUnlocked = await SaveService.instance.reportFloorReached(floor);
    if (justUnlocked) {
      overlays.add(Overlays.unlock);
    }
    await _loadFloor();
  }

  Future<void> onPlayerDied() async {
    await SaveService.instance.reportRunEnded(coins: coins, kills: kills);
    overlays.add(Overlays.gameOver);
    pauseEngine();
  }

  void togglePause() {
    if (overlays.isActive(Overlays.pause)) {
      overlays.remove(Overlays.pause);
      resumeEngine();
    } else {
      overlays.add(Overlays.pause);
      pauseEngine();
    }
  }
}
