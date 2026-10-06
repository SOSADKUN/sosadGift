import 'package:flutter_test/flutter_test.dart';
import 'package:gift/games/game_timer.dart';

void main() {
  testWidgets('gameplay delays retain remaining time while the app is paused', (
    tester,
  ) async {
    var paused = false;
    var calls = 0;
    final timer = GameTimer(
      const Duration(seconds: 1),
      () => calls++,
      isPaused: () => paused,
    );
    await tester.pump(const Duration(milliseconds: 400));
    paused = true;
    await tester.pump(const Duration(seconds: 20));
    expect(calls, 0);
    paused = false;
    await tester.pump(const Duration(milliseconds: 500));
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 120));
    expect(calls, 1);
    expect(timer.isActive, isFalse);
  });
  testWidgets('cancelling a gameplay timer prevents subsequent callbacks', (
    tester,
  ) async {
    var calls = 0;
    final timer = GameTimer.periodic(
      const Duration(milliseconds: 100),
      (_) => calls++,
      isPaused: () => false,
    );
    await tester.pump(const Duration(milliseconds: 120));
    expect(calls, 1);
    timer.cancel();
    await tester.pump(const Duration(seconds: 1));
    expect(calls, 1);
  });
}
