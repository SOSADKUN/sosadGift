import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/memory_display_config.dart';
import 'memory_float_pose.dart';

/// Continuous atmosphere, three foreground photos and three small backdrop photos.
class MemoryAlbumGame extends FlameGame {
  MemoryAlbumGame({required this.photos, required this.onProgress});
  final List<String> photos;
  final void Function(int index, double progress) onProgress;
  final Map<int, ui.Image> _images = {};
  final Set<int> _failed = {};
  final List<ui.Image> _backgroundPhotos = [];
  final Map<int, Future<void>> _pending = {};
  int _index = 0;
  double _cycle = 0;
  double _time = 0;
  double _notification = 0;
  bool _disposed = false;
  bool reducedMotion = false;

  int get currentIndex => _index;
  double get elapsedAtmosphere => _time;
  int get decodedPhotoCount => _images.length;

  @visibleForTesting
  Future<void> waitForPreload() async {
    await Future.wait(_pending.values.toList());
  }

  @override
  Color backgroundColor() => const Color(0xFF100D19);

  @override
  Future<void> onLoad() async {
    if (photos.isEmpty) return;
    await _load(0);
    for (var i = 0; i < math.min(3, photos.length); i++) {
      ui.Codec? codec;
      try {
        final path = photos[(i * photos.length ~/ 3) % photos.length];
        final data = await rootBundle.load(path);
        codec = await ui.instantiateImageCodec(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
          targetWidth: 220,
        );
        final frame = await codec.getNextFrame();
        if (_disposed) {
          frame.image.dispose();
          return;
        }
        _backgroundPhotos.add(frame.image);
      } catch (_) {
        // A missing background photo does not interrupt the foreground album.
      } finally {
        codec?.dispose();
      }
    }
    _preload();
  }

  Future<void> _load(int index) {
    if (_disposed || _images.containsKey(index) || _failed.contains(index)) {
      return Future.value();
    }
    return _pending.putIfAbsent(index, () async {
      ui.ImmutableBuffer? buffer;
      ui.ImageDescriptor? descriptor;
      ui.Codec? codec;
      try {
        final data = await rootBundle.load(photos[index]);
        buffer = await ui.ImmutableBuffer.fromUint8List(
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        );
        descriptor = await ui.ImageDescriptor.encoded(buffer);
        final scale = math.min(
          1.0,
          1200 / math.max(descriptor.width, descriptor.height),
        );
        codec = await descriptor.instantiateCodec(
          targetWidth: math.max(1, (descriptor.width * scale).round()),
          targetHeight: math.max(1, (descriptor.height * scale).round()),
        );
        final frame = await codec.getNextFrame();
        if (_disposed) {
          frame.image.dispose();
          return;
        }
        _images[index] = frame.image;
      } catch (_) {
        if (!_disposed) _failed.add(index);
      } finally {
        codec?.dispose();
        descriptor?.dispose();
        buffer?.dispose();
        _pending.remove(index);
      }
    });
  }

  void _preload() {
    if (photos.isEmpty || _disposed) return;
    final needed = {
      _index,
      (_index + 1) % photos.length,
      (_index + 2) % photos.length,
    };
    for (final index in _images.keys.toList()) {
      if (!needed.contains(index)) _images.remove(index)?.dispose();
    }
    for (final index in needed) {
      _load(index);
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (photos.isEmpty || _disposed) return;
    _time += dt;
    _cycle += dt;
    final duration = MemoryDisplayConfig.photoDuration.inMilliseconds / 1000;
    if (_cycle >= duration) {
      final next = (_index + 1) % photos.length;
      if (_images.containsKey(next) || _failed.contains(next)) {
        _index = next;
        _cycle %= duration;
        _preload();
      } else {
        _cycle = duration;
        _load(next);
      }
    }
    _notification += dt;
    if (_notification >= .1) {
      _notification = 0;
      onProgress(_index, (_cycle / duration).clamp(0.0, 1.0));
    }
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (size.x <= 0 || size.y <= 0) return;
    final bounds = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, -.2),
          radius: 1.2,
          colors: [Color(0xFF3F2945), Color(0xFF20192D), Color(0xFF100D19)],
        ).createShader(bounds),
    );
    // Time never resets at photo changes or at the end of the album.
    final phase = reducedMotion ? 0.0 : _time;
    final random = math.Random(42);
    for (var i = 0; i < 55; i++) {
      final x = random.nextDouble() * size.x;
      final y = (random.nextDouble() * size.y - phase * (2 + i % 4)) % size.y;
      final alpha = .12 + .28 * (.5 + .5 * math.sin(phase * .25 + i));
      canvas.drawCircle(
        Offset(x, y),
        .7 + random.nextDouble() * 1.7,
        Paint()..color = const Color(0xFFF5DCC0).withValues(alpha: alpha),
      );
    }
    for (var i = 0; i < 5; i++) {
      canvas.drawCircle(
        Offset(
          size.x * (.5 + .42 * math.sin(i * 2 + phase * .025)),
          size.y * (.5 + .4 * math.cos(i + phase * .02)),
        ),
        45 + i * 8.0,
        Paint()
          ..color = const Color(0xFFE7AAC4).withValues(alpha: .035)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 28),
      );
    }
    // Separate low-resolution photos keep drifting across foreground changes.
    for (var i = 0; i < _backgroundPhotos.length; i++) {
      final image = _backgroundPhotos[i];
      final x = size.x * (.5 + .44 * math.sin(phase * .055 + i * 2.1));
      final y = size.y * (.5 + .35 * math.cos(phase * .037 + i * 2.7));
      final fitted = applyBoxFit(
        BoxFit.contain,
        Size(image.width.toDouble(), image.height.toDouble()),
        Size(size.x * .34, size.y * .25),
      ).destination;
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: fitted.width,
        height: fitted.height,
      );
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(.18 * math.sin(phase * .04 + i));
      canvas.drawRect(
        rect.inflate(5),
        Paint()..color = const Color(0xFFF5EDE3).withValues(alpha: .18),
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        Paint()
          ..color = Colors.white.withValues(alpha: .18)
          ..filterQuality = FilterQuality.low,
      );
      canvas.restore();
    }
    if (photos.isEmpty) return;
    final duration = MemoryDisplayConfig.photoDuration.inMilliseconds / 1000;
    final t = (_cycle / duration).clamp(0.0, 1.0);
    final pose = MemoryFloatPose.at(
      t,
      _index,
      Size(size.x, size.y),
      reducedMotion: reducedMotion,
    );
    final image = _images[_index];
    if (image == null || pose.opacity <= 0) return;
    final fitted = applyBoxFit(
      BoxFit.contain,
      Size(image.width.toDouble(), image.height.toDouble()),
      Size(math.min(440, size.x * .78) - 18, math.min(520, size.y * .57) - 37),
    ).destination;
    final photoRect = Rect.fromCenter(
      center: const Offset(0, -9.5),
      width: fitted.width,
      height: fitted.height,
    );
    final cardRect = Rect.fromCenter(
      center: Offset.zero,
      width: fitted.width + 18,
      height: fitted.height + 37,
    );
    canvas.save();
    canvas.translate(size.x / 2 + pose.offset.dx, size.y / 2 + pose.offset.dy);
    canvas.rotate(pose.angle);
    canvas.scale(pose.scale);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        cardRect.shift(const Offset(0, 15)),
        const Radius.circular(3),
      ),
      Paint()
        ..color = const Color(0xFF000000).withValues(alpha: .4 * pose.opacity)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(cardRect, const Radius.circular(3)),
      Paint()..color = const Color(0xFFF5EDE3).withValues(alpha: pose.opacity),
    );
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      photoRect,
      Paint()
        ..color = Colors.white.withValues(alpha: pose.opacity)
        ..filterQuality = FilterQuality.medium,
    );
    canvas.restore();
  }

  @override
  void onRemove() {
    _disposed = true;
    for (final image in _images.values) {
      image.dispose();
    }
    _images.clear();
    for (final image in _backgroundPhotos) {
      image.dispose();
    }
    _backgroundPhotos.clear();
    super.onRemove();
  }
}
