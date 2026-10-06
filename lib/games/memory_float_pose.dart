import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Six alternating flight paths. The middle portion holds the photograph still.
class MemoryFloatPose {
  const MemoryFloatPose(this.offset, this.angle, this.scale, this.opacity);
  final Offset offset;
  final double angle;
  final double scale;
  final double opacity;

  static MemoryFloatPose at(
    double t,
    int index,
    Size size, {
    bool reducedMotion = false,
  }) {
    if (reducedMotion) {
      return MemoryFloatPose(
        Offset.zero,
        0,
        1,
        math.min((t / .12).clamp(0.0, 1.0), ((1 - t) / .12).clamp(0.0, 1.0)),
      );
    }
    final directions = [
      const Offset(-1, -.55),
      const Offset(1, .45),
      const Offset(.4, -1),
      const Offset(-1, .6),
      const Offset(1, -.6),
      const Offset(-.4, 1),
    ];
    final direction = directions[index % directions.length];
    final start = Offset(
      direction.dx * size.width * 1.2,
      direction.dy * size.height * 1.1,
    );
    final end = Offset(
      -direction.dx * size.width * 1.2,
      -direction.dy * size.height * 1.1,
    );
    final sign = index.isEven ? -1.0 : 1.0;
    if (t < .2) {
      final p = Curves.easeOutCubic.transform((t / .2).clamp(0.0, 1.0));
      return MemoryFloatPose(
        Offset.lerp(start, Offset.zero, p)!,
        sign * .24 * (1 - p),
        .72 + .28 * p,
        (t / .14).clamp(0.0, 1.0),
      );
    }
    if (t <= .8) return const MemoryFloatPose(Offset.zero, 0, 1, 1);
    final p = Curves.easeInCubic.transform(((t - .8) / .2).clamp(0.0, 1.0));
    return MemoryFloatPose(
      Offset.lerp(Offset.zero, end, p)!,
      -sign * .18 * p,
      1 - .15 * p,
      ((1 - t) / .17).clamp(0.0, 1.0),
    );
  }
}
