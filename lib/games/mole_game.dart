import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'animated_game_assets.dart';

class MoleGame extends FlameGame {
  MoleGame({required this.spriteAssets, required this.onTap, this.onReady});
  final List<String> spriteAssets;
  final ValueChanged<int> onTap;
  final VoidCallback? onReady;
  final _library = AnimatedGameAssets();
  final List<_MoleHole> _holes = [];
  List<String?> items = List.filled(9, null);
  bool inputEnabled = false;
  bool reducedMotion = false;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await _library.load(spriteAssets);
    for (var i = 0; i < 9; i++) {
      final hole = _MoleHole(this, i);
      _holes.add(hole);
      await add(hole);
    }
    _layout();
    onReady?.call();
  }

  @override
  void onGameResize(Vector2 size) {
    super.onGameResize(size);
    _layout();
  }

  void _layout() {
    if (!hasLayout) return;
    const gap = 14.0;
    final side = max(0.0, min((size.x - 2 * gap) / 3, (size.y - 2 * gap) / 3));
    final left = (size.x - side * 3 - gap * 2) / 2;
    final top = (size.y - side * 3 - gap * 2) / 2;
    for (var i = 0; i < _holes.length; i++) {
      _holes[i].position.setValues(
        left + (i % 3) * (side + gap),
        top + (i ~/ 3) * (side + gap),
      );
      _holes[i].size.setAll(side);
    }
  }

  @override
  void onRemove() {
    _library.dispose();
    super.onRemove();
  }
}

class _MoleHole extends PositionComponent with TapCallbacks {
  _MoleHole(this.field, this.index);
  final MoleGame field;
  final int index;
  SpriteAnimationComponent? _sprite;
  String? _path;
  double _rise = 0;
  double _ring = 0;

  @override
  void update(double dt) {
    super.update(dt);
    final path = field.items[index];
    if (path != null && path != _path) {
      _sprite = SpriteAnimationComponent(
        animation: field._library.animation(path),
      );
      _path = path;
      _rise = 0;
    }
    final target = path == null ? 0.0 : 1.0;
    _rise += (target - _rise) * (1 - exp(-dt * (target == 0 ? 24 : 18)));
    if (path == null && _rise < .01) _path = null;
    _ring = max(0, _ring - dt * 2.5);
    final sprite = _sprite;
    if (sprite != null) {
      sprite.update(dt);
      final source = sprite.animationTicker!.getSprite().srcSize;
      final scale = min(size.x * .8 / source.x, size.y * .8 / source.y);
      sprite.size.setValues(source.x * scale, source.y * scale);
      sprite.position.setValues(
        (size.x - sprite.size.x) / 2,
        (size.y - sprite.size.y) / 2 +
            (field.reducedMotion ? 0 : size.y * (1 - _rise) * .65),
      );
      sprite.opacity = _rise;
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    final radius = size.x * .48;
    canvas.drawCircle(
      center + const Offset(0, 4),
      radius,
      Paint()..color = const Color(0x66000000),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF181222), Color(0xFF493348)],
        ).createShader(Rect.fromCircle(center: center, radius: radius)),
    );
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = const Color(0xAAAB8392),
    );
    canvas.save();
    canvas.clipPath(
      Path()..addOval(Rect.fromCircle(center: center, radius: radius - 2)),
    );
    final sprite = _sprite;
    if (sprite != null) {
      canvas.translate(sprite.position.x, sprite.position.y);
      sprite.render(canvas);
    }
    canvas.restore();
    if (_ring > 0) {
      canvas.drawCircle(
        center,
        radius * (1 + (1 - _ring) * .2),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..color = const Color(0xFFFFD6A5).withValues(alpha: _ring),
      );
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (!field.inputEnabled || field.items[index] == null) return;
    _ring = 1;
    field.onTap(index);
  }
}
