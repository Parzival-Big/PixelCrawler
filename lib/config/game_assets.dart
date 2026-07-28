import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';

/// Central registry of every sprite used by the game.
///
/// This is the ONLY place that knows about file names and frame layouts.
/// The PNGs in `assets/images/` are composed from the original asset pack
/// (`assets/raw_pack/`) by `tools/prepare_pack.py`.
class GameAssets {
  GameAssets._();

  // ------------------------------------------------------------ tiles
  static const floorTiles = SpriteSheetSpec('tiles/floor.png', 16, 16, 4);
  static const stairs = SpriteSpec('tiles/stairs.png');

  /// Directional wall tiles, 5 texture variants each. The suffix tells on
  /// which side(s) of the wall tile the floor lies.
  static const wallTiles = <String, SpriteSheetSpec>{
    'top': SpriteSheetSpec('tiles/wall_top.png', 16, 16, 5),
    'bottom': SpriteSheetSpec('tiles/wall_bottom.png', 16, 16, 5),
    'left': SpriteSheetSpec('tiles/wall_left.png', 16, 16, 5),
    'right': SpriteSheetSpec('tiles/wall_right.png', 16, 16, 5),
    'inner_tl': SpriteSheetSpec('tiles/wall_inner_tl.png', 16, 16, 5),
    'inner_tr': SpriteSheetSpec('tiles/wall_inner_tr.png', 16, 16, 5),
    'inner_bl': SpriteSheetSpec('tiles/wall_inner_bl.png', 16, 16, 5),
    'inner_br': SpriteSheetSpec('tiles/wall_inner_br.png', 16, 16, 5),
    'outer_tl': SpriteSheetSpec('tiles/wall_outer_tl.png', 16, 16, 5),
    'outer_tr': SpriteSheetSpec('tiles/wall_outer_tr.png', 16, 16, 5),
    'outer_bl': SpriteSheetSpec('tiles/wall_outer_bl.png', 16, 16, 5),
    'outer_br': SpriteSheetSpec('tiles/wall_outer_br.png', 16, 16, 5),
  };

  /// Animated wall torches — pack sides match wall tiles (top/bottom/left/right).
  static const torchWallTop =
      AnimSpec('tiles/torch_wall_top.png', 16, 16, 4, 0.15);
  static const torchWallBottom =
      AnimSpec('tiles/torch_wall_bottom.png', 16, 16, 4, 0.15);
  static const torchWallLeft =
      AnimSpec('tiles/torch_wall_left.png', 16, 16, 4, 0.15);
  static const torchWallRight =
      AnimSpec('tiles/torch_wall_right.png', 16, 16, 4, 0.15);

  static AnimSpec torchWallFor(String side) => switch (side) {
        'top' => torchWallTop,
        'bottom' => torchWallBottom,
        'left' => torchWallLeft,
        'right' => torchWallRight,
        _ => torchWallBottom,
      };

  // ---------------------------------------------------------- objects
  static const chest = SpriteSheetSpec('objects/chest.png', 16, 16, 2);
  static const potionRed = SpriteSpec('objects/potion_red.png');
  static const potionBlue = SpriteSpec('objects/potion_blue.png');
  static const coin = AnimSpec('objects/coin.png', 16, 16, 1, 1);
  static const firePot = AnimSpec('objects/torch.png', 16, 16, 6, 0.12);
  static const key = SpriteSpec('objects/key.png');
  static const keyBoss = SpriteSpec('objects/key_boss.png');
  static const shield = SpriteSpec('objects/shield.png');
  static const boot = SpriteSpec('objects/boot.png');
  static const sword = SpriteSpec('objects/sword.png');

  /// Purely decorative props scattered in rooms.
  static const decor = <SpriteSpec>[
    SpriteSpec('objects/barrel.png'),
    SpriteSpec('objects/crate.png'),
    SpriteSpec('objects/table.png'),
    SpriteSpec('objects/skull.png'),
    SpriteSpec('objects/bone.png'),
  ];

  // Pits + spike traps (off / charging / on).
  static const pit = SpriteSpec('tiles/pit.png');
  static const trapSmall = SpriteSheetSpec('tiles/trap_small.png', 16, 16, 3);
  static const trapBig = SpriteSheetSpec('tiles/trap_big.png', 16, 16, 3);

  // Doors: one sprite per wall side (n/s/e/w match pack top/bottom/right/left).
  static const doorOpenN = SpriteSpec('tiles/door_open_n.png');
  static const doorOpenS = SpriteSpec('tiles/door_open_s.png');
  static const doorOpenE = SpriteSpec('tiles/door_open_e.png');
  static const doorOpenW = SpriteSpec('tiles/door_open_w.png');
  static const doorClosedN = SpriteSpec('tiles/door_closed_n.png');
  static const doorClosedS = SpriteSpec('tiles/door_closed_s.png');
  static const doorClosedE = SpriteSpec('tiles/door_closed_e.png');
  static const doorClosedW = SpriteSpec('tiles/door_closed_w.png');
  static const doorLockedN = SpriteSpec('tiles/door_locked_n.png');
  static const doorLockedS = SpriteSpec('tiles/door_locked_s.png');
  static const doorLockedE = SpriteSpec('tiles/door_locked_e.png');
  static const doorLockedW = SpriteSpec('tiles/door_locked_w.png');
  static const doorBossN = SpriteSpec('tiles/door_boss_n.png');
  static const doorBossS = SpriteSpec('tiles/door_boss_s.png');
  static const doorBossE = SpriteSpec('tiles/door_boss_e.png');
  static const doorBossW = SpriteSpec('tiles/door_boss_w.png');

  // --------------------------------------------------------- monsters
  // Idle strips are 16×17 (1px headroom so the bob-up frame never clips).
  static const slime = AnimSpec('monsters/slime.png', 16, 17, 2, 0.3);
  static const bat = AnimSpec('monsters/bat.png', 16, 17, 2, 0.14);
  static const rat = AnimSpec('monsters/rat.png', 16, 17, 2, 0.18);
  static const skeleton = AnimSpec('monsters/skeleton.png', 16, 17, 2, 0.25);
  static const skeletonArcher =
      AnimSpec('monsters/skeleton_archer.png', 16, 17, 2, 0.25);
  static const skeletonNecromancer =
      AnimSpec('monsters/skeleton_necromancer.png', 16, 17, 2, 0.28);
  static const spider = AnimSpec('monsters/spider.png', 16, 17, 2, 0.16);
  static const ghost = AnimSpec('monsters/ghost.png', 16, 17, 2, 0.3);
  static const flyingEye = AnimSpec('monsters/flying_eye.png', 16, 17, 2, 0.14);
  static const devil = AnimSpec('monsters/devil.png', 16, 17, 2, 0.22);

  // ----------------------------------------------------------- heroes
  static const knight = AnimSpec('heroes/knight.png', 16, 17, 2, 0.25);
  static const mage = AnimSpec('heroes/mage.png', 16, 17, 2, 0.25);
  static const hunter = AnimSpec('heroes/hunter.png', 16, 17, 2, 0.25);
  static const rogue = AnimSpec('heroes/rogue.png', 16, 17, 2, 0.25);
  static const slimeHero = AnimSpec('heroes/slime_hero.png', 16, 17, 2, 0.3);
  static const mummy = AnimSpec('heroes/mummy.png', 16, 17, 2, 0.28);
  static const mushroom = AnimSpec('heroes/mushroom.png', 16, 17, 2, 0.26);
  static const witch = AnimSpec('heroes/witch.png', 16, 17, 2, 0.25);
  static const dragon = AnimSpec('heroes/dragon.png', 16, 17, 2, 0.22);

  // Bomb: idle + lit fuse (2 frames).
  static const bomb = AnimSpec('objects/bomb.png', 16, 16, 2, 0.2);

  // ---------------------------------------------------------- effects
  static const slash = AnimSpec('effects/slash.png', 16, 16, 3, 0.05);
  static const fireball = AnimSpec('effects/fireball.png', 16, 16, 4, 0.08);
  static const arrow = SpriteSpec('effects/arrow.png');
  static const bone = SpriteSpec('effects/bone.png');

  // --------------------------------------------------------------- ui
  static const heartFull = SpriteSpec('ui/heart_full.png');
  static const heartHalf = SpriteSpec('ui/heart_half.png');
  static const heartEmpty = SpriteSpec('ui/heart_empty.png');

  static List<String> get allImages => [
        'tiles/floor.png',
        'tiles/stairs.png',
        ...wallTiles.values.map((s) => s.path),
        'tiles/torch_wall_top.png',
        'tiles/torch_wall_bottom.png',
        'tiles/torch_wall_left.png',
        'tiles/torch_wall_right.png',
        'tiles/torch_wall.png',
        'objects/chest.png',
        'objects/potion_red.png',
        'objects/potion_blue.png',
        'objects/coin.png',
        'objects/torch.png',
        ...decor.map((s) => s.path),
        'objects/key.png',
        'objects/key_boss.png',
        'objects/shield.png',
        'objects/boot.png',
        'objects/sword.png',
        'tiles/pit.png',
        'tiles/trap_small.png',
        'tiles/trap_big.png',
        'tiles/door_open_n.png',
        'tiles/door_open_s.png',
        'tiles/door_open_e.png',
        'tiles/door_open_w.png',
        'tiles/door_closed_n.png',
        'tiles/door_closed_s.png',
        'tiles/door_closed_e.png',
        'tiles/door_closed_w.png',
        'tiles/door_locked_n.png',
        'tiles/door_locked_s.png',
        'tiles/door_locked_e.png',
        'tiles/door_locked_w.png',
        'tiles/door_boss_n.png',
        'tiles/door_boss_s.png',
        'tiles/door_boss_e.png',
        'tiles/door_boss_w.png',
        'monsters/slime.png',
        'monsters/bat.png',
        'monsters/rat.png',
        'monsters/skeleton.png',
        'monsters/skeleton_archer.png',
        'monsters/skeleton_necromancer.png',
        'monsters/spider.png',
        'monsters/ghost.png',
        'monsters/flying_eye.png',
        'monsters/devil.png',
        'heroes/knight.png',
        'heroes/mage.png',
        'heroes/hunter.png',
        'heroes/rogue.png',
        'heroes/slime_hero.png',
        'heroes/mummy.png',
        'heroes/mushroom.png',
        'heroes/witch.png',
        'heroes/dragon.png',
        'objects/bomb.png',
        'effects/slash.png',
        'effects/fireball.png',
        'effects/arrow.png',
        'effects/bone.png',
        'ui/heart_full.png',
        'ui/heart_half.png',
        'ui/heart_empty.png',
      ];
}

/// A single-frame sprite (whole image).
class SpriteSpec {
  const SpriteSpec(this.path);
  final String path;

  Sprite sprite() => Sprite(Flame.images.fromCache(path));
}

/// A horizontal strip of same-sized frames, addressed individually.
class SpriteSheetSpec {
  const SpriteSheetSpec(this.path, this.frameWidth, this.frameHeight, this.frames);
  final String path;
  final int frameWidth;
  final int frameHeight;
  final int frames;

  Sprite frame(int index) {
    final sheet = SpriteSheet(
      image: Flame.images.fromCache(path),
      srcSize: Vector2(frameWidth.toDouble(), frameHeight.toDouble()),
    );
    return sheet.getSprite(0, index);
  }
}

/// A horizontal strip played as a looping animation.
class AnimSpec {
  const AnimSpec(this.path, this.frameWidth, this.frameHeight, this.frames, this.stepTime);
  final String path;
  final int frameWidth;
  final int frameHeight;
  final int frames;
  final double stepTime;

  Vector2 get size => Vector2(frameWidth.toDouble(), frameHeight.toDouble());

  SpriteAnimation animation({double? stepTimeOverride, bool loop = true}) {
    return SpriteAnimation.fromFrameData(
      Flame.images.fromCache(path),
      SpriteAnimationData.sequenced(
        amount: frames,
        stepTime: stepTimeOverride ?? stepTime,
        textureSize: size,
        loop: loop,
      ),
    );
  }
}
