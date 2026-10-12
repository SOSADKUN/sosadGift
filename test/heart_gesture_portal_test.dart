import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/widgets/heart_gesture_portal.dart';
import 'package:gift/views/screens/video_memory_screen.dart';

List<Offset> heart({int shift = 0, bool reverse = false}) =>
    List.generate(129, (i) {
      final t = ((reverse ? -i : i) + shift) * math.pi * 2 / 128;
      return Offset(
        220 + 128 * math.pow(math.sin(t), 3).toDouble(),
        250 -
            .5 *
                (13 * math.cos(t) -
                    5 * math.cos(2 * t) -
                    2 * math.cos(3 * t) -
                    math.cos(4 * t)) *
                16,
      );
    });
void main() {
  test(
    'recognizes a closed heart from either direction and arbitrary start',
    () {
      expect(isHeartStroke(heart()), isTrue);
      expect(isHeartStroke(heart(reverse: true)), isTrue);
      expect(isHeartStroke(heart(shift: 40)), isTrue);
      expect(
        isHeartStroke(
          heart().map((p) => p * .6 + const Offset(100, 100)).toList(),
        ),
        isTrue,
      );
    },
  );
  test('rejects circles, swipes, tiny marks and incomplete hearts', () {
    expect(
      isHeartStroke(
        List.generate(
          129,
          (i) => Offset(
            200 + 100 * math.cos(i * math.pi / 64),
            250 + 100 * math.sin(i * math.pi / 64),
          ),
        ),
      ),
      isFalse,
    );
    expect(
      isHeartStroke(List.generate(60, (i) => Offset(i * 4, 100))),
      isFalse,
    );
    expect(isHeartStroke(heart().map((p) => p * .1).toList()), isFalse);
    expect(isHeartStroke(heart().take(64).toList()), isFalse);
  });
  testWidgets('drawn heart opens once and clears the trail', (tester) async {
    var opened = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HeartGesturePortal(
          onHeart: () => opened++,
          child: const ColoredBox(color: Colors.black),
        ),
      ),
    );
    final points = heart();
    final touch = await tester.startGesture(points.first);
    for (final point in points.skip(1)) {
      await touch.moveTo(point);
    }
    await touch.up();
    await tester.pump();
    expect(opened, 1);
    await tester.tapAt(const Offset(200, 200));
    expect(opened, 1);
  });
  test('video assets sort numerically and ignore unrelated files', () {
    expect(
      orderedMemoryVideos([
        'assets/memory_videos/video10.mp4',
        'assets/memory_videos/README.md',
        'assets/memory_videos/video2.mp4',
        'assets/memory_videos/video1.mp4',
      ]),
      [
        'assets/memory_videos/video1.mp4',
        'assets/memory_videos/video2.mp4',
        'assets/memory_videos/video10.mp4',
      ],
    );
  });
}
