import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flutter/services.dart';

/// GIF frames are decoded once per playfield, shared by its components.
class AnimatedGameAssets {
  final Map<String, SpriteAnimation> _animations = {};
  final List<ui.Image> _images = [];

  Future<void> load(Iterable<String> paths, {int width = 140}) async {
    for (final path in paths.toSet()) {
      final data = await rootBundle.load(path);
      final codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: width,
      );
      final frames = <SpriteAnimationFrame>[];
      try {
        for (var i = 0; i < codec.frameCount; i++) {
          final frame = await codec.getNextFrame();
          _images.add(frame.image);
          frames.add(
            SpriteAnimationFrame(
              Sprite(frame.image),
              frame.duration > Duration.zero
                  ? frame.duration.inMicroseconds /
                        Duration.microsecondsPerSecond
                  : .1,
            ),
          );
        }
        _animations[path] = SpriteAnimation(frames);
      } finally {
        codec.dispose();
      }
    }
  }

  SpriteAnimation animation(String path) => _animations[path]!.clone();

  void dispose() {
    for (final image in _images) {
      image.dispose();
    }
    _images.clear();
    _animations.clear();
  }
}
