import 'package:flutter_test/flutter_test.dart';
import 'package:gift/controllers/app_flow_progress.dart';
import 'package:gift/views/app_flow.dart';

void main() {
  test('late intro callbacks cannot skip the four-game hub', () {
    final flow = AppFlowProgress(kFlowOrder);
    while (flow.current != FlowStep.giftIntro) {
      expect(flow.complete(flow.current), isTrue);
    }
    expect(flow.complete(FlowStep.giftIntro), isTrue);
    expect(flow.current, FlowStep.gameHub);
    for (final oldPage in [
      FlowStep.giftIntro,
      FlowStep.storyRecap,
      FlowStep.diaryOpen,
      FlowStep.splash,
    ]) {
      expect(flow.complete(oldPage), isFalse);
      expect(flow.current, FlowStep.gameHub);
    }
    // Only the hub's own all-games-complete event may unlock the door screen.
    expect(flow.complete(FlowStep.gameHub), isTrue);
    expect(flow.current, FlowStep.fourKeyDoor);
    expect(flow.complete(FlowStep.gameHub), isFalse);
    expect(flow.current, FlowStep.fourKeyDoor);
  });

  test('every step advances once and the final page stays in place', () {
    final flow = AppFlowProgress(kFlowOrder);
    for (var i = 0; i < kFlowOrder.length - 1; i++) {
      expect(flow.current, kFlowOrder[i]);
      expect(flow.complete(kFlowOrder[i]), isTrue);
      expect(flow.complete(kFlowOrder[i]), isFalse);
    }
    expect(flow.current, FlowStep.memoryFinale);
    expect(flow.complete(FlowStep.memoryFinale), isFalse);
  });
}
