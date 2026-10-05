import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/config/treasure_hunt_config.dart';
import 'package:gift/views/app_flow.dart';
import 'package:gift/views/screens/surprise_countdown_screen.dart';

void main() {
  test('hunt and countdown must precede cake after opening the door', () {
    final door = kFlowOrder.indexOf(FlowStep.doorOpening);
    expect(kFlowOrder.sublist(door), [
      FlowStep.doorOpening,
      FlowStep.treasureHunt,
      FlowStep.surpriseCountdown,
      FlowStep.digitalCake,
      FlowStep.memoryFinale,
    ]);
  });

  test('only the printed final QR unlocks the countdown', () {
    expect(TreasureHuntConfig.acceptsQr('SOSAD-GIFT-FINALE'), isTrue);
    expect(TreasureHuntConfig.acceptsQr(null), isFalse);
    expect(TreasureHuntConfig.acceptsQr('https://example.com'), isFalse);
  });

  testWidgets('countdown completes once, only after thirty seconds', (
    tester,
  ) async {
    var now = DateTime(2026);
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SurpriseCountdownScreen(
          now: () => now,
          onComplete: () => completed++,
        ),
      ),
    );
    expect(find.text('30'), findsOneWidget);
    now = now.add(const Duration(seconds: 29));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('1'), findsOneWidget);
    expect(completed, 0);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(completed, 1);
    await tester.pump(const Duration(seconds: 5));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('leaving countdown cancels completion', (tester) async {
    var now = DateTime(2026);
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: SurpriseCountdownScreen(
          now: () => now,
          onComplete: () => completed++,
        ),
      ),
    );
    await tester.pumpWidget(const SizedBox());
    now = now.add(const Duration(seconds: 40));
    await tester.pump(const Duration(seconds: 40));
    expect(completed, 0);
  });
}
