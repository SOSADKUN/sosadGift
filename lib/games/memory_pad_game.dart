import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'animated_game_assets.dart';

class MemoryPadGame extends FlameGame {
  MemoryPadGame({
    required this.spriteAssets,
    required this.colors,
    required this.onTap,
    this.onReady,
  });
  final List<String> spriteAssets;
  final List<Color> colors;
  final ValueChanged<int> onTap;
  final VoidCallback? onReady;
  final _library = AnimatedGameAssets();
  final List<_MemoryPad> _pads = [];
  int activePad = -1;
  bool inputEnabled = false;
  bool reducedMotion = false;

  @override
  Color backgroundColor() => Colors.transparent;

  @override
  Future<void> onLoad() async {
    await _library.load(spriteAssets);
    for (var i = 0; i < spriteAssets.length; i++) {
      final pad = _MemoryPad(this, i, _library.animation(spriteAssets[i]));
      _pads.add(pad);
      await add(pad);
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
    const gap = 16.0;
    final width = max(0.0, (size.x - gap) / 2);
    final height = min(width / 1.25, max(0.0, (size.y - gap * 2) / 3));
    final top = (size.y - height * 3 - gap * 2) / 2;
    for (var i = 0; i < _pads.length; i++) {
      _pads[i].position.setValues(
        (i % 2) * (width + gap),
        top + (i ~/ 2) * (height + gap),
      );
      _pads[i].size.setValues(width, height);
    }
  }

  @override
  void onRemove() {
    _library.dispose();
    super.onRemove();
  }
}

class _MemoryPad extends PositionComponent with TapCallbacks {
  _MemoryPad(this.field, this.index, SpriteAnimation animation)
    : _sprite = SpriteAnimationComponent(animation: animation);
  final MemoryPadGame field;
  final int index;
  final SpriteAnimationComponent _sprite;
  double _light = 0;

  @override
  void update(double dt) {
    super.update(dt);
    _sprite.update(dt);
    final target = field.activePad == index ? 1.0 : 0.0;
    _light += (target - _light) * (1 - exp(-dt * 20));
    final source = _sprite.animationTicker!.getSprite().srcSize;
    final scale = min(size.x * .84 / source.x, size.y * .84 / source.y);
    _sprite.size.setValues(source.x * scale, source.y * scale);
    _sprite.position.setValues(
      (size.x - _sprite.size.x) / 2,
      (size.y - _sprite.size.y) / 2,
    );
    _sprite.opacity = .5 + _light * .5;
  }

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Offset.zero & size.toSize(),
      const Radius.circular(22),
    );
    final color = field.colors[index];
    if (_light > .01) {
      canvas.drawRRect(
        rect,
        Paint()
          ..color = color.withValues(alpha: _light * .32)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
    }
    canvas.drawRRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(const Color(0xFF40304E), color, _light * .35)!,
            const Color(0xFF211A2D),
          ],
        ).createShader(rect.outerRect),
    );
    canvas.drawRRect(
      rect.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5 + _light * 1.5
        ..color = Color.lerp(const Color(0x667F6C8C), color, _light)!,
    );
    canvas.save();
    canvas.clipRRect(rect);
    if (!field.reducedMotion) {
      canvas.translate(size.x / 2, size.y / 2);
      canvas.scale(1 + _light * .06);
      canvas.translate(-size.x / 2, -size.y / 2);
    }
    canvas.translate(_sprite.position.x, _sprite.position.y);
    _sprite.render(canvas);
    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    if (field.inputEnabled) field.onTap(index);
  }
}
