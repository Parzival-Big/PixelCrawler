import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../config/game_assets.dart';

/// Renders an [AnimSpec] strip inside regular Flutter UI with crisp
/// nearest-neighbour scaling (used for hero previews in the menus).
class PixelSpriteAnimation extends StatefulWidget {
  const PixelSpriteAnimation({
    super.key,
    required this.spec,
    this.scale = 4,
    this.playing = true,
  });

  final AnimSpec spec;
  final double scale;
  final bool playing;

  @override
  State<PixelSpriteAnimation> createState() => _PixelSpriteAnimationState();
}

class _PixelSpriteAnimationState extends State<PixelSpriteAnimation>
    with SingleTickerProviderStateMixin {
  SpriteAnimation? _animation;
  SpriteAnimationTicker? _ticker;
  Ticker? _frameTicker;
  Duration _last = Duration.zero;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Flame.images.load(widget.spec.path);
    if (!mounted) return;
    setState(() {
      _animation = widget.spec.animation();
      _ticker = _animation!.createTicker();
    });
    _frameTicker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (widget.playing && _ticker != null) {
      _ticker!.update(dt);
      setState(() {});
    }
  }

  @override
  void dispose() {
    _frameTicker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.spec.frameWidth * widget.scale;
    final h = widget.spec.frameHeight * widget.scale;
    if (_ticker == null) {
      return SizedBox(width: w, height: h);
    }
    return CustomPaint(
      size: Size(w, h),
      painter: _SpritePainter(_ticker!.getSprite(), widget.scale),
    );
  }
}

class _SpritePainter extends CustomPainter {
  _SpritePainter(this.sprite, this.scale);

  final Sprite sprite;
  final double scale;

  static final _paint = Paint()..filterQuality = FilterQuality.none;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    sprite.render(
      canvas,
      position: Vector2.zero(),
      size: sprite.srcSize,
      overridePaint: _paint,
    );
  }

  @override
  bool shouldRepaint(_SpritePainter oldDelegate) =>
      oldDelegate.sprite != sprite;
}
