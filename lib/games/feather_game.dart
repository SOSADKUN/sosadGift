import 'dart:math';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// The animated playfield is repainted by Flame independently of the HUD.
class FeatherGame extends FlameGame {
  FeatherGame({required this.onCatch, required this.onReady});

  final VoidCallback onCatch;
  final VoidCallback onReady;
  final _random = Random();
  final List<ui.Image> _images = [];
  final List<_Spark> _sparks = [];
  final _paint = Paint();
  _Feather? _feather;
  Offset _seed = const Offset(.5, .5);
  bool targetVisible = false;
  bool reducedMotion = false;
  double _phase = 0;
  double _period = 1.2;
  double _difficulty = 0;
  double _entrance = 0;
  double _feedback = 0;
  Offset _catchPosition = Offset.zero;
  final _label = TextPainter(
    text: const TextSpan(
      text: '+1 ♡',
      style: TextStyle(
        color: Color(0xFFFFE3A6),
        fontSize: 24,
        fontWeight: FontWeight.w800,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    final data = await rootBundle.load('assets/photos/jimao.gif');
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
      targetWidth: 180,
    );
    final frames = <SpriteAnimationFrame>[];
    try {
      for (var i = 0; i < codec.frameCount; i++) {
        final frame = await codec.getNextFrame();
        _images.add(frame.image);
        frames.add(
          SpriteAnimationFrame(
            Sprite(frame.image),
            max(.02, frame.duration.inMilliseconds / 1000),
          ),
        );
      }
    } finally {
      codec.dispose();
    }
    _feather = _Feather(this, SpriteAnimation(frames));
    await add(_feather!);
    _placeTarget();
    onReady();
  }

  void showTarget(Offset seed, {required bool fast, double difficulty = 0}) {
    _seed = seed;
    _difficulty = difficulty.clamp(0.0, 1.0);
    _period = (fast ? .85 : 1.25) - _difficulty * .2;
    _phase = _random.nextDouble() * pi * 2;
    _entrance = 0;
    targetVisible = true;
    _placeTarget();
  }

  void resetEffects() {
    _sparks.clear();
    _feedback = 0;
    targetVisible = false;
  }

  void catchTarget() {
    if (!targetVisible || paused) return;
    final target = _feather;
    if (target == null) return;
    _catchPosition = target.position.toOffset();
    _feedback = reducedMotion ? 0 : .65;
    if (!reducedMotion) {
      for (var i = 0; i < 14; i++) {
        final angle = _random.nextDouble() * pi * 2;
        final speed = 45 + _random.nextDouble() * 110;
        _sparks.add(
          _Spark(
            _catchPosition,
            Offset(cos(angle), sin(angle)) * speed,
            i.isEven ? const Color(0xFFFFBBD0) : const Color(0xFFFFE3A6),
          ),
        );
      }
    }
    onCatch();
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Limit visual jumps after a slow frame; the round clock remains independent.
    final step = min(dt, .05);
    if (!reducedMotion) _phase += step * pi * 2 / _period;
    _entrance = min(1, _entrance + step / .18);
    _feedback = max(0, _feedback - step);
    for (final spark in _sparks) {
      spark.life -= step;
      spark.position += spark.velocity * step;
      spark.velocity += Offset(0, 90 * step);
    }
    _sparks.removeWhere((spark) => spark.life <= 0);
    _placeTarget();
  }

  void _placeTarget() {
    final target = _feather;
    if (target == null || !hasLayout) return;
    final side = min(92.0 - _difficulty * 12, min(size.x, size.y));
    target.size.setValues(side, side);
    final x = .20 + _seed.dx * .60 + (reducedMotion ? 0 : sin(_phase) * .23);
    final y =
        .16 + _seed.dy * .68 + (reducedMotion ? 0 : cos(_phase * 1.3) * .18);
    target.position.setValues(
      side / 2 + x.clamp(0.0, 1.0) * max(0, size.x - side),
      side / 2 + y.clamp(0.0, 1.0) * max(0, size.y - side - 44),
    );
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    for (final spark in _sparks) {
      _paint.color = spark.color.withValues(
        alpha: (spark.life / .6).clamp(0, 1),
      );
      canvas.drawCircle(spark.position, 2 + spark.life * 3, _paint);
    }
    if (_feedback > 0) {
      _label.paint(
        canvas,
        _catchPosition +
            Offset(-_label.width / 2, -58 - (1 - _feedback / .65) * 28),
      );
    }
  }

  @override
  void onRemove() {
    for (final image in _images) {
      image.dispose();
    }
    _images.clear();
    _label.dispose();
    super.onRemove();
  }
}

class _Feather extends SpriteAnimationComponent with TapCallbacks {
  _Feather(this.field, SpriteAnimation animation)
    : super(animation: animation, anchor: Anchor.center);
  final FeatherGame field;
  final _glow = Paint()..color = const Color(0x25FFBBD0);

  @override
  void render(Canvas canvas) {
    if (!field.targetVisible) return;
    canvas.drawCircle(Offset(size.x / 2, size.y / 2), size.x * .44, _glow);
    canvas.save();
    final scale = field.reducedMotion ? 1.0 : .75 + .25 * field._entrance;
    canvas.translate(size.x / 2, size.y / 2);
    canvas.scale(scale * .8);
    canvas.translate(-size.x / 2, -size.y / 2);
    super.render(canvas);
    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) => field.catchTarget();
}

class _Spark {
  _Spark(this.position, this.velocity, this.color);
  Offset position;
  Offset velocity;
  final Color color;
  double life = .6;
}
