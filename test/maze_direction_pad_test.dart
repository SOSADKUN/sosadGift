import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/widgets/maze_direction_pad.dart';

void main() {
  testWidgets('direction buttons emit exact axes and release/cancel stops', (
    tester,
  ) async {
    final directions = <Offset>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: MazeDirectionPad(enabled: true, onChanged: directions.add),
        ),
      ),
    );
    for (final entry in {
      'up': const Offset(0, -1),
      'down': const Offset(0, 1),
      'left': const Offset(-1, 0),
      'right': const Offset(1, 0),
    }.entries) {
      final finger = await tester.startGesture(
        tester.getCenter(find.byKey(ValueKey('maze-${entry.key}'))),
      );
      expect(directions.last, entry.value);
      await tester.pump(const Duration(milliseconds: 400));
      await finger.up();
      expect(directions.last, Offset.zero);
    }
    final finger = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('maze-up'))),
    );
    await finger.cancel();
    expect(directions.last, Offset.zero);
    await tester.pumpWidget(const SizedBox());
  });
  testWidgets('disabled pad ignores presses during camera tours', (
    tester,
  ) async {
    final directions = <Offset>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Center(
          child: MazeDirectionPad(enabled: false, onChanged: directions.add),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('maze-right')));
    expect(directions, isEmpty);
  });
}
