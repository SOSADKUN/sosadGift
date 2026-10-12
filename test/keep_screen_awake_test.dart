import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/widgets/keep_screen_awake.dart';

void main() {
  testWidgets(
    'reapplies wake lock, retries failures, and releases in background',
    (tester) async {
      final calls = <bool>[];
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpWidget(
        KeepScreenAwake(
          child: const SizedBox(),
          setAwake: (enabled) async {
            calls.add(enabled);
            if (calls.length == 1) throw StateError('Temporary native failure');
          },
        ),
      );
      await tester.pump();
      expect(calls.every((enabled) => enabled), isTrue);
      final initialCount = calls.length;
      await tester.pump(const Duration(seconds: 10));
      expect(calls.length, greaterThan(initialCount));
      expect(calls.last, true);
      await tester.pump(const Duration(seconds: 10));
      expect(calls.last, true);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      expect(calls.last, false);
      final count = calls.length;
      await tester.pump(const Duration(seconds: 30));
      expect(calls.length, count);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(calls.last, true);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      expect(calls.last, false);
      final disposedCount = calls.length;
      await tester.pump(const Duration(seconds: 20));
      expect(calls.length, disposedCount);
    },
  );
}
