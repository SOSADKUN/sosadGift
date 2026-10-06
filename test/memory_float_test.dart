import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/screens/memory_finale_screen.dart';

void main() {
  const size = Size(390, 844);
  test('each photograph arrives, holds in the center, then leaves', () {
    for (var i = 0; i < 6; i++) {
      final start = MemoryFloatPose.at(0, i, size);
      expect(start.opacity, 0);
      expect(start.offset.distance, greaterThan(390));
      for (final t in [.2, .4, .6, .8]) {
        final hold = MemoryFloatPose.at(t, i, size);
        expect(hold.offset, Offset.zero);
        expect(hold.angle, 0);
        expect(hold.scale, 1);
        expect(hold.opacity, 1);
      }
      final end = MemoryFloatPose.at(1, i, size);
      expect(end.opacity, 0);
      expect(end.offset.dx * start.offset.dx, lessThan(0));
    }
  });
  test(
    'reduced motion keeps the photo centered and fades between memories',
    () {
      for (final t in [0.0, .2, .5, .9, 1.0]) {
        final pose = MemoryFloatPose.at(t, 3, size, reducedMotion: true);
        expect(pose.offset, Offset.zero);
        expect(pose.angle, 0);
        expect(pose.scale, 1);
      }
    },
  );
}
