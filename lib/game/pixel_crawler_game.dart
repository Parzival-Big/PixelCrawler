import 'dart:math' show Point, Random, min;

import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/input.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart' show KeyEventResult, MediaQuery;

import '../config/game_assets.dart';
import '../services/save_service.dart';
import '../ui/adaptive.dart';
import 'components/door.dart';
import 'components/dungeon_renderer.dart';
import 'components/effects.dart';
import 'components/monster.dart';
import 'components/pickups.dart';
import 'components/player.dart';
import 'components/shop_pedestal.dart';
import 'components/room_occluder.dart';
import 'components/solid_obstacle.dart';
import 'components/traps.dart';
import 'dungeon/dungeon_generator.dart';
import 'dungeon/dungeon_map.dart';
import 'heroes.dart';
import 'monsters.dart';
import 'store_catalog.dart';

/// Names of the Flutter overlays registered on the GameWidget.
class Overlays {
  static const hud = 'hud';
  static const pause = 'pause';
  static const gameOver = 'gameOver';
  static const unlock = 'unlock';
  static const shop = 'shop';
  static const floorTransition = 'floorTransition';
}

class PixelCrawlerGame extends FlameGame with KeyboardEvents {
  PixelCrawlerGame({required this.heroType}) : super() {
    SessionBonus.reset();
  }

  /// World size of one room including the wall ring (BoI single-room view),
  /// plus overhang so 1.5× tile sprites fit in frame.
  static const roomWorldWidth =
      (DungeonGenerator.interiorW + 2) * tileSize + tileSize * (tileVisualScale - 1);
  static const roomWorldHeight =
      (DungeonGenerator.interiorH + 2) * tileSize + tileSize * (tileVisualScale - 1);

  /// Used for HUD control scaling; matches the room height.
  static const designHeight = roomWorldHeight;

  final HeroType heroType;
  final _rng = Random();

  late DungeonMap map;
  Player? player;

  int floor = 1;
  int coins = 0;
  int kills = 0;
  int keys = 0;
  int bossKeys = 0;

  /// Floors since the last shop room (pity for shop placement).
  int floorsWithoutShop = 0;

  /// Heroes unlocked by the most recent floor report (for toast UI).
  Set<HeroType> lastUnlocked = {};

  /// Base shop-room chance; rises by [shopPityStep] each missed floor.
  static const shopChance = 0.05;
  static const shopPityStep = 0.05;

  late final hpNotifier = ValueNotifier<int>(0);
  late final maxHpNotifier = ValueNotifier<int>(0);
  late final coinsNotifier = ValueNotifier<int>(0);
  late final floorNotifier = ValueNotifier<int>(1);
  late final keysNotifier = ValueNotifier<int>(0);
  late final bossKeysNotifier = ValueNotifier<int>(0);
  late final roomMapNotifier = ValueNotifier<int>(0);

  RoomInfo? currentRoom;
  final discoveredRooms = <String>{};


  late JoystickComponent _joystick;
  late HudButtonComponent _attackButton;
  bool _hudReady = false;
  bool _mapReady = false;
  bool _attackButtonHeld = false;
  final _keysDown = <LogicalKeyboardKey>{};

  bool get attackHeld =>
      _attackButtonHeld ||
      _keysDown.contains(LogicalKeyboardKey.space) ||
      _keysDown.contains(LogicalKeyboardKey.keyJ);

  @override
  Color backgroundColor() => const Color(0xFF0E222B);

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    fitCameraToSize(size);
    layoutHudControls(size);
  }

  /// Fit the whole current room on screen (letterbox if aspect differs).
  /// Adjacent rooms are hidden by [RoomOccluder], not by zooming in.
  void fitCameraToSize(Vector2 size) {
    if (size.y <= 0 || size.x <= 0) return;
    final zoom = min(size.x / roomWorldWidth, size.y / roomWorldHeight);
    camera.viewfinder.zoom = zoom;
    focusCameraOnCurrentRoom();
  }

  /// Locks the camera on the active room centre (not the player).
  void focusCameraOnCurrentRoom() {
    final room = currentRoom;
    if (room == null) {
      snapCameraToPlayer();
      return;
    }
    final outer = room.outerBounds;
    camera.viewfinder.position = Vector2(
      (outer.left + outer.width / 2) * tileSize,
      (outer.top + outer.height / 2) * tileSize,
    );
  }

  /// Keeps the viewfinder locked on the player immediately.
  void snapCameraToPlayer() {
    final p = player;
    if (p == null || !p.isMounted) return;
    camera.viewfinder.position = p.position.clone();
  }

  /// Room-locked camera: no scroll bounds across the whole map.
  void refreshCameraBounds() {
    camera.setBounds(null);
  }

  void discoverRoom(RoomInfo room) {
    currentRoom = room;
    if (discoveredRooms.add(room.gridKey)) {
      roomMapNotifier.value++;
    }
    focusCameraOnCurrentRoom();
  }

  void _syncRoomFromPlayer() {
    final p = player;
    if (p == null || !_mapReady) return;
    final info = map.roomInfoContaining(
      p.position.x ~/ tileSize,
      p.position.y ~/ tileSize,
    );
    if (info == null) return;
    if (currentRoom?.gridKey != info.gridKey) {
      discoverRoom(info);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    _syncRoomFromPlayer();
  }

  /// Repositions virtual controls for the current canvas / hinge insets.
  void layoutHudControls(Vector2 size) {
    if (!_hudReady || size.x <= 0 || size.y <= 0) return;
    final shortest = min(size.x, size.y);
    final edge = (shortest * 0.045).clamp(16.0, 52.0);
    var left = edge;
    var right = edge;
    var bottom = edge;

    final ctx = buildContext;
    if (ctx != null && ctx.mounted) {
      final mq = MediaQuery.maybeOf(ctx);
      if (mq != null) {
        left += mq.hingePadding.left + mq.padding.left * 0.35;
        right += mq.hingePadding.right + mq.padding.right * 0.35;
        bottom += mq.hingePadding.bottom + mq.padding.bottom * 0.35;
      }
    }

    _joystick.margin = EdgeInsets.only(left: left, bottom: bottom);
    _attackButton.margin = EdgeInsets.only(right: right, bottom: bottom);
  }

  @override
  Future<void> onLoad() async {
    await images.loadAll(GameAssets.allImages);
    fitCameraToSize(size);

    final scale = (size.y / designHeight).clamp(0.9, 2.0);
    final stickR = 30.0 * scale;
    final knobR = 13.0 * scale;
    final btnR = 21.0 * scale;

    _joystick = JoystickComponent(
      knob: CircleComponent(
        radius: knobR,
        paint: Paint()..color = const Color(0x88B9DDA7),
      ),
      background: CircleComponent(
        radius: stickR,
        paint: Paint()..color = const Color(0x2EB9DDA7),
      ),
      margin: const EdgeInsets.only(left: 24, bottom: 20),
    );

    _attackButton = HudButtonComponent(
      button: CircleComponent(
        radius: btnR,
        paint: Paint()..color = const Color(0x4468A08A),
        children: [
          CircleComponent(
            radius: btnR * 0.75,
            position: Vector2.all(btnR * 0.25),
            paint: Paint()..color = const Color(0x99B9DDA7),
          ),
        ],
      ),
      buttonDown: CircleComponent(
        radius: btnR,
        paint: Paint()..color = const Color(0xCCB9DDA7),
      ),
      margin: const EdgeInsets.only(right: 24, bottom: 18),
      onPressed: () => _attackButtonHeld = true,
      onReleased: () => _attackButtonHeld = false,
      onCancelled: () => _attackButtonHeld = false,
    );

    camera.viewport.addAll([_joystick, _attackButton]);
    _hudReady = true;
    layoutHudControls(size);

    final def = heroes[heroType]!;
    player = Player(def: def, position: Vector2.zero());
    hpNotifier.value = def.maxHp;
    maxHpNotifier.value = def.maxHp;

    await _loadFloor();
  }

  Future<void> _loadFloor() async {
    world.removeAll(world.children.toList());

    map = DungeonGenerator(
      floor: floor,
      shopChance: currentShopChance,
    ).generate();
    if (map.hasShopRoom) {
      floorsWithoutShop = 0;
    } else {
      floorsWithoutShop++;
    }

    world.add(DungeonRenderer(map));
    world.add(RoomOccluder());

    // Spike trap overlays.
    for (var y = 0; y < map.height; y++) {
      for (var x = 0; x < map.width; x++) {
        final t = map.tileAt(x, y);
        if (t == TileType.trapSmall) {
          world.add(SpikeTrap(tile: Point(x, y), big: false));
        } else if (t == TileType.trapBig) {
          world.add(SpikeTrap(tile: Point(x, y), big: true));
        }
      }
    }

    for (final t in map.torchSpawns) {
      final px = t.pos.x * tileSize;
      final py = t.pos.y * tileSize;
      world.add(Torch(
        position: Vector2(px, py),
        side: t.side,
        tileX: t.pos.x,
        tileY: t.pos.y,
      ));
      // Glow spills into the room from the lit wall face.
      final d = t.side.floorDelta;
      world.add(
        GlowComponent(
          center: Vector2(px + 8 + d.x * 6, py + 8 + d.y * 6),
          radius: 28,
          tileX: t.pos.x,
          tileY: t.pos.y,
        ),
      );
    }

    for (final (p, kind) in map.decorSpawns) {
      final idx = kind % GameAssets.decor.length;
      world.add(Decor(
        position: _tileBottom(p.x, p.y),
        spec: GameAssets.decor[idx],
        kind: idx,
      ));
    }
    for (final p in map.firePotSpawns) {
      final pos = _tileBottom(p.x, p.y);
      world.add(FirePot(position: pos));
      world.add(GlowComponent(
        center: pos - Vector2(0, 6),
        radius: 30,
        tileX: p.x,
        tileY: p.y,
      ));
    }

    for (final d in map.doorSpawns) {
      world.add(Door(spawn: d));
    }

    for (final s in map.shopPedestals) {
      world.add(ShopPedestal(spawn: s));
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

    if (map.bossSpawn != null) {
      world.add(Monster(
        def: monsters[MonsterType.boss]!,
        position: _tileBottom(map.bossSpawn!.x, map.bossSpawn!.y),
        floor: floor,
      )..isBoss = true);
    }

    player!.position = _tileBottom(map.playerSpawn.x, map.playerSpawn.y);
    world.add(player!);

    _mapReady = true;
    discoveredRooms.clear();
    currentRoom = null;
    final startRoom = map.roomInfoContaining(
      map.playerSpawn.x,
      map.playerSpawn.y,
    );
    if (startRoom != null) {
      discoverRoom(startRoom);
    }
    refreshCameraBounds();
    focusCameraOnCurrentRoom();
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

  /// True when a closed door occupies this tile (blocks player and monsters).
  bool doorBlocksTile(int tx, int ty) {
    for (final d in world.children.query<Door>()) {
      if (d.spawn.pos.x == tx && d.spawn.pos.y == ty && d.blocksPassage) {
        return true;
      }
    }
    // Fallback for monsters: any door tile is blocked if no component match.
    return false;
  }

  /// No living monsters in the active room (doors may open).
  bool get currentRoomCleared {
    final room = currentRoom;
    if (room == null) return true;
    for (final m in world.children.query<Monster>()) {
      if (m.isDead) continue;
      final info = map.roomInfoContaining(
        m.position.x ~/ tileSize,
        m.position.y ~/ tileSize,
      );
      if (info?.gridKey == room.gridKey) return false;
    }
    return true;
  }

  /// True when a feet box centred at ([cx], [cy]) overlaps any solid prop.
  bool solidBlocksFeet(double cx, double cy, double w, double h) {
    for (final o in world.children.whereType<SolidObstacle>()) {
      if (o.overlapsFeet(cx, cy, w, h)) return true;
    }
    return false;
  }

  /// True when a world point sits inside a solid prop (for projectiles).
  bool solidBlocksPoint(Vector2 p) {
    for (final o in world.children.whereType<SolidObstacle>()) {
      if (o.containsWorldPoint(p)) return true;
    }
    return false;
  }

  /// True when the player's current room contains the given world position.
  bool playerSharesRoomWith(Vector2 worldPos) {
    final p = player;
    if (p == null) return false;
    final pr = map.roomContaining(
      p.position.x ~/ tileSize,
      p.position.y ~/ tileSize,
    );
    if (pr == null) return false;
    final or_ = map.roomContaining(
      worldPos.x ~/ tileSize,
      worldPos.y ~/ tileSize,
    );
    return identical(pr, or_);
  }

  void addCoins(int n) {
    coins += n;
    coinsNotifier.value = coins;
  }

  void addKey(int n) {
    keys += n;
    keysNotifier.value = keys;
  }

  void addBossKey(int n) {
    bossKeys += n;
    bossKeysNotifier.value = bossKeys;
  }

  /// Spends one normal key if available.
  bool tryUseKey() {
    if (keys <= 0) return false;
    keys--;
    keysNotifier.value = keys;
    return true;
  }

  /// Spends one boss key if available.
  bool tryUseBossKey() {
    if (bossKeys <= 0) return false;
    bossKeys--;
    bossKeysNotifier.value = bossKeys;
    return true;
  }

  bool spendCoins(int amount) {
    if (coins < amount) return false;
    coins -= amount;
    coinsNotifier.value = coins;
    return true;
  }

  void raiseMaxHp(int amount) {
    final p = player!;
    p.maxHp += amount;
    p.heal(amount);
    maxHpNotifier.value = p.maxHp;
  }

  /// Applies a shop-room pedestal purchase at a fixed [cost].
  bool buyShopPedestal(StoreUpgrade upgrade, int cost) {
    final level = SessionBonus.levelOf(upgrade);
    if (level >= upgrade.maxLevel) return false;
    if (!spendCoins(cost)) return false;
    SessionBonus.bumpLevel(upgrade);
    _applyUpgrade(upgrade);
    return true;
  }

  /// Legacy between-floor shop purchase (kept for screenshots / tests).
  bool buyShopUpgrade(StoreUpgrade upgrade) {
    final level = SessionBonus.levelOf(upgrade);
    if (level >= upgrade.maxLevel) return false;
    final cost = upgrade.costForLevel(level);
    if (!spendCoins(cost)) return false;
    SessionBonus.bumpLevel(upgrade);
    _applyUpgrade(upgrade);
    return true;
  }

  void _applyUpgrade(StoreUpgrade upgrade) {
    switch (upgrade.unit) {
      case StoreUnit.heal:
        player?.heal(upgrade.perLevel);
      case StoreUnit.halfHearts:
        SessionBonus.extraHp += upgrade.perLevel;
        raiseMaxHp(upgrade.perLevel);
      case StoreUnit.vitaQuarter:
        // +¼ cuore (1 HP when 4 HP = 1 cuore; here 2 HP = 1 cuore so +1
        // is half a half-heart ≈ quarter of a full heart display unit).
        SessionBonus.extraHp += upgrade.perLevel;
        raiseMaxHp(upgrade.perLevel);
        player?.heal(999);
      case StoreUnit.damage:
        SessionBonus.extraDamage += upgrade.perLevel;
      case StoreUnit.defense:
        SessionBonus.extraDefense += upgrade.perLevel;
      case StoreUnit.speed:
        SessionBonus.extraSpeed += upgrade.perLevel;
      case StoreUnit.cooldownHundredths:
        SessionBonus.extraCooldown += upgrade.perLevel / 100.0;
    }
  }

  void onMonsterKilled() => kills++;

  void spawnDamageText(int amount, Vector2 worldPos) {
    world.add(FloatingText(text: '$amount', position: worldPos));
  }

  /// Current shop-room spawn chance (base + pity).
  double get currentShopChance =>
      (shopChance + floorsWithoutShop * shopPityStep).clamp(0.0, 1.0);

  Future<void> goToNextFloor() async {
    floor++;
    floorNotifier.value = floor;
    lastUnlocked =
        await SaveService.instance.reportFloorReached(floor, heroType);
    if (lastUnlocked.isNotEmpty &&
        overlays.registeredOverlays.contains(Overlays.unlock)) {
      overlays.add(Overlays.unlock);
    }

    if (overlays.registeredOverlays.contains(Overlays.floorTransition)) {
      overlays.add(Overlays.floorTransition);
      await Future<void>.delayed(const Duration(milliseconds: 720));
    }

    await _loadFloor();

    if (overlays.isActive(Overlays.floorTransition)) {
      overlays.remove(Overlays.floorTransition);
    }
  }

  /// Kept for screenshot tooling that still opens the overlay shop.
  Future<void> finishShopAndEnterFloor() async {
    if (overlays.isActive(Overlays.shop)) {
      overlays.remove(Overlays.shop);
    }
    if (overlays.registeredOverlays.contains(Overlays.floorTransition)) {
      overlays.add(Overlays.floorTransition);
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
    await _loadFloor();
    if (overlays.isActive(Overlays.floorTransition)) {
      overlays.remove(Overlays.floorTransition);
    }
    resumeEngine();
  }

  Future<void> onPlayerDied() async {
    await SaveService.instance.reportRunEnded(coins: coins, kills: kills);
    coins = 0;
    overlays.add(Overlays.gameOver);
    pauseEngine();
  }

  /// Starts a fresh dungeon run with the same [heroType] (RIPROVA).
  Future<void> restartRun() async {
    SessionBonus.reset();

    for (final name in [
      Overlays.gameOver,
      Overlays.pause,
      Overlays.shop,
      Overlays.unlock,
      Overlays.floorTransition,
    ]) {
      if (overlays.isActive(name)) {
        overlays.remove(name);
      }
    }

    floor = 1;
    coins = 0;
    kills = 0;
    keys = 0;
    bossKeys = 0;
    floorsWithoutShop = 0;
    lastUnlocked = {};
    discoveredRooms.clear();
    currentRoom = null;

    floorNotifier.value = 1;
    coinsNotifier.value = 0;
    keysNotifier.value = 0;
    bossKeysNotifier.value = 0;

    final def = heroes[heroType]!;
    player = Player(def: def, position: Vector2.zero());
    hpNotifier.value = player!.maxHp;
    maxHpNotifier.value = player!.maxHp;

    await _loadFloor();
    resumeEngine();
  }

  /// Banks any run coins still held (used when quitting from pause).
  Future<void> bankAndQuit() async {
    await SaveService.instance.reportRunEnded(coins: coins, kills: kills);
    coins = 0;
  }

  void togglePause() {
    if (overlays.isActive(Overlays.shop)) return;
    if (overlays.isActive(Overlays.pause)) {
      overlays.remove(Overlays.pause);
      resumeEngine();
    } else {
      overlays.add(Overlays.pause);
      pauseEngine();
    }
  }
}
