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

  /// Animated torch baked into a south-facing wall tile.
  static const torchWall = AnimSpec('tiles/torch_wall.png', 16, 16, 4, 0.15);

  // ---------------------------------------------------------- objects
  static const chest = SpriteSheetSpec('objects/chest.png', 16, 16, 2);
  static const potionRed = SpriteSpec('objects/potion_red.png');
  static const potionBlue = SpriteSpec('objects/potion_blue.png');
  static const coin = AnimSpec('objects/coin.png', 16, 16, 1, 1);
  static const firePot = AnimSpec('objects/torch.png', 16, 16, 6, 0.12);

  /// Purely decorative props scattered in rooms.
  static const decor = <SpriteSpec>[
    SpriteSpec('objects/barrel.png'),
    SpriteSpec('objects/crate.png'),
    SpriteSpec('objects/table.png'),
    SpriteSpec('objects/skull.png'),
    SpriteSpec('objects/bone.png'),
  ];

  // --------------------------------------------------------- monsters
  static const slime = AnimSpec('monsters/slime.png', 16, 16, 2, 0.3);
  static const bat = AnimSpec('monsters/bat.png', 16, 16, 2, 0.14);
  static const rat = AnimSpec('monsters/rat.png', 16, 16, 2, 0.18);
  static const skeleton = AnimSpec('monsters/skeleton.png', 16, 16, 2, 0.25);
  static const spider = AnimSpec('monsters/spider.png', 16, 16, 2, 0.16);
  static const ghost = AnimSpec('monsters/ghost.png', 16, 16, 2, 0.3);

  // ----------------------------------------------------------- heroes
  static const knight = AnimSpec('heroes/knight.png', 16, 16, 2, 0.25);
  static const mage = AnimSpec('heroes/mage.png', 16, 16, 2, 0.25);
  static const hunter = AnimSpec('heroes/hunter.png', 16, 16, 2, 0.25);
  static const rogue = AnimSpec('heroes/rogue.png', 16, 16, 2, 0.25);
  static const slimeHero = AnimSpec('heroes/slime_hero.png', 16, 16, 2, 0.3);

  // ---------------------------------------------------------- effects
  static const slash = AnimSpec('effects/slash.png', 16, 16, 3, 0.05);
  static const fireball = AnimSpec('effects/fireball.png', 16, 16, 4, 0.08);
  static const arrow = SpriteSpec('effects/arrow.png');

  // --------------------------------------------------------------- ui
  static const heartFull = SpriteSpec('ui/heart_full.png');
  static const heartHalf = SpriteSpec('ui/heart_half.png');
  static const heartEmpty = SpriteSpec('ui/heart_empty.png');

  static List<String> get allImages => [
        'tiles/floor.png',
        'tiles/stairs.png',
        ...wallTiles.values.map((s) => s.path),
        'tiles/torch_wall.png',
        'objects/chest.png',
        'objects/potion_red.png',
        'objects/potion_blue.png',
        'objects/coin.png',
        'objects/torch.png',
        ...decor.map((s) => s.path),
        'monsters/slime.png',
        'monsters/bat.png',
        'monsters/rat.png',
        'monsters/skeleton.png',
        'monsters/spider.png',
        'monsters/ghost.png',
        'heroes/knight.png',
        'heroes/mage.png',
        'heroes/hunter.png',
        'heroes/rogue.png',
        'heroes/slime_hero.png',
        'effects/slash.png',
        'effects/fireball.png',
        'effects/arrow.png',
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
