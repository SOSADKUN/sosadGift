import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/memory_display_config.dart';
import 'memory_float_pose.dart';

class _Backdrop {
  _Backdrop(this.index, this.elapsed);
  int index;
  double elapsed;
  ui.Image? image;
  ui.Image? next;
  int? nextIndex;
  Future<void>? loading;
}

/// Continuous atmosphere, three foreground photos and six small backdrop photos.
class MemoryAlbumGame extends FlameGame {
  MemoryAlbumGame({
    required this.photos,
    required this.onProgress,
    math.Random? random,
  }) : _random = random ?? math.Random();
  final List<String> photos;
  final void Function(int index, double progress) onProgress;
  final Map<int, ui.Image> _images = {};
  final Set<int> _failed = {};
  final List<_Backdrop> _backgroundPhotos = [];
  final math.Random _random;
  final List<int> _backgroundBag = [];
  static const _backgroundDuration = 24.0;
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
  List<int> get backgroundIndices =>
      _backgroundPhotos.map((slot) => slot.index).toList();
  @visibleForTesting
  int get decodedBackgroundCount => _backgroundPhotos.fold(
    0,
    (count, slot) =>
        count + (slot.image == null ? 0 : 1) + (slot.next == null ? 0 : 1),
  );

  @visibleForTesting
  Future<void> waitForPreload() async {
    await Future.wait(_pending.values.toList());
    await Future.wait(
      _backgroundPhotos
          .map((slot) => slot.loading)
          .whereType<Future<void>>()
          .toList(),
    );
  }

  @override
  Color backgroundColor() => const Color(0xFF100D19);

  @override
  Future<void> onLoad() async {
    if (photos.isEmpty) return;
    await _load(0);
    final count = math.min(6, photos.length);
    for (var i = 0; i < count; i++) {
      _backgroundPhotos.add(
        _Backdrop(_pickBackground(), i * _backgroundDuration / count),
      );
    }
    await Future.wait(
      _backgroundPhotos.map((slot) async {
        slot.image = await _decodeBackdrop(slot.index);
      }),
    );
    _preload();
  }

  Future<ui.Image?> _decodeBackdrop(int index) async {
    ui.Codec? codec;
    try {
      final data = await rootBundle.load(photos[index]);
      codec = await ui.instantiateImageCodec(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        targetWidth: 220,
      );
      final image = (await codec.getNextFrame()).image;
      if (_disposed) {
        image.dispose();
        return null;
      }
      return image;
    } catch (_) {
      return null;
    } finally {
      codec?.dispose();
    }
  }

  int _pickBackground() {
    final occupied = <int>{
      for (final slot in _backgroundPhotos) slot.index,
      for (final slot in _backgroundPhotos)
        if (slot.nextIndex != null) slot.nextIndex!,
    };
    if (_backgroundBag.isEmpty || _backgroundBag.every(occupied.contains)) {
      _backgroundBag
        ..clear()
        ..addAll(List.generate(photos.length, (i) => i)..shuffle(_random));
    }
    final candidate = _backgroundBag.indexWhere((i) => !occupied.contains(i));
    // Small albums may already occupy every slot; reuse a photo gracefully.
    return _backgroundBag.removeAt(candidate < 0 ? 0 : candidate);
  }

  void _prepareBackdrop(_Backdrop slot) {
    if (slot.loading != null || slot.nextIndex != null) return;
    final index = _pickBackground();
    slot.nextIndex = index;
    slot.loading = _decodeBackdrop(index)
        .then((image) {
          if (_disposed) {
            image?.dispose();
            return;
          }
          slot.next = image;
        })
        .whenComplete(() => slot.loading = null);
  }

  void _updateBackdrops(double dt) {
    if (reducedMotion) return;
    for (final slot in _backgroundPhotos) {
      slot.elapsed += dt;
      // Decode the replacement while the current photo is still leaving.
      if (slot.elapsed >= _backgroundDuration * .7) _prepareBackdrop(slot);
      if (slot.elapsed >= _backgroundDuration &&
          slot.loading == null &&
          slot.nextIndex != null) {
        // Both endpoints are outside the viewport, including rotated corners.
        slot.image?.dispose();
        slot.image = slot.next;
        slot.index = slot.nextIndex!;
        slot.next = null;
        slot.nextIndex = null;
        slot.elapsed = 0;
      } else if (slot.elapsed > _backgroundDuration) {
        slot.elapsed = _backgroundDuration;
      }
    }
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
    _updateBackdrops(dt);
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
      final slot = _backgroundPhotos[i];
      final image = slot.image;
      if (image == null) continue;
      final t = slot.elapsed / _backgroundDuration;
      final x = size.x * (.5 + .38 * math.sin(t * math.pi * 1.2 + i * 2.1));
      final y = size.y * (1.35 - 1.7 * t);
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
        Paint()..color = const Color(0xFFF5EDE3).withValues(alpha: .14),
      );
      canvas.drawImageRect(
        image,
        Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
        rect,
        Paint()
          ..color = Colors.white.withValues(alpha: .14)
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
    for (final slot in _backgroundPhotos) {
      slot.image?.dispose();
      slot.next?.dispose();
    }
    _backgroundPhotos.clear();
    super.onRemove();
  }
}
