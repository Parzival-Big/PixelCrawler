import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flame/components.dart';

/// Central registry of every sprite used by the game.
///
/// This is the ONLY place that knows about file names and frame layouts:
/// to use your own asset pack, drop the PNGs into `assets/images/...` and
/// adjust the paths / frame data below.
class GameAssets {
  GameAssets._();

  // ------------------------------------------------------------ tiles
  static const floorTiles = SpriteSheetSpec('tiles/floor.png', 16, 16, 4);
  static const wallFront = SpriteSpec('tiles/wall_front.png');
  static const wallTop = SpriteSpec('tiles/wall_top.png');
  static const stairs = SpriteSpec('tiles/stairs.png');

  // ---------------------------------------------------------- objects
  static const chest = SpriteSheetSpec('objects/chest.png', 16, 16, 2);
  static const potionRed = SpriteSpec('objects/potion_red.png');
  static const potionBlue = SpriteSpec('objects/potion_blue.png');
  static const coin = AnimSpec('objects/coin.png', 16, 16, 4, 0.12);
  static const torch = AnimSpec('objects/torch.png', 16, 16, 4, 0.15);

  // --------------------------------------------------------- monsters
  static const slime = AnimSpec('monsters/slime.png', 16, 16, 4, 0.22);
  static const bat = AnimSpec('monsters/bat.png', 16, 16, 4, 0.12);
  static const skeleton = AnimSpec('monsters/skeleton.png', 16, 24, 4, 0.18);
  static const goblin = AnimSpec('monsters/goblin.png', 16, 24, 4, 0.15);

  // ----------------------------------------------------------- heroes
  static const knight = AnimSpec('heroes/knight.png', 16, 24, 4, 0.16);
  static const mage = AnimSpec('heroes/mage.png', 16, 24, 4, 0.16);
  static const hunter = AnimSpec('heroes/hunter.png', 16, 24, 4, 0.16);
  static const rogue = AnimSpec('heroes/rogue.png', 16, 24, 4, 0.16);
  static const slimeHero = AnimSpec('heroes/slime_hero.png', 16, 16, 4, 0.2);

  // ---------------------------------------------------------- effects
  static const slash = AnimSpec('effects/slash.png', 16, 16, 3, 0.05);
  static const fireball = AnimSpec('effects/fireball.png', 16, 16, 4, 0.08);
  static const arrow = SpriteSpec('effects/arrow.png');
  static const blob = SpriteSpec('effects/blob.png');

  // --------------------------------------------------------------- ui
  static const heartFull = SpriteSpec('ui/heart_full.png');
  static const heartHalf = SpriteSpec('ui/heart_half.png');
  static const heartEmpty = SpriteSpec('ui/heart_empty.png');

  static List<String> get allImages => const [
        'tiles/floor.png',
        'tiles/wall_front.png',
        'tiles/wall_top.png',
        'tiles/stairs.png',
        'objects/chest.png',
        'objects/potion_red.png',
        'objects/potion_blue.png',
        'objects/coin.png',
        'objects/torch.png',
        'monsters/slime.png',
        'monsters/bat.png',
        'monsters/skeleton.png',
        'monsters/goblin.png',
        'heroes/knight.png',
        'heroes/mage.png',
        'heroes/hunter.png',
        'heroes/rogue.png',
        'heroes/slime_hero.png',
        'effects/slash.png',
        'effects/fireball.png',
        'effects/arrow.png',
        'effects/blob.png',
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
