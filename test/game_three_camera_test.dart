import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/screens/games/game_three_screen.dart';

void main() {
  testWidgets('maze is enlarged and camera follows movement within its bounds', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(MaterialApp(home: GameThreeScreen(onComplete: () {}, onLose: () {})));
    await tester.pump(const Duration(milliseconds: 300));
    expect(tester.takeException(), isNull);
    final cameraFinder = find.byWidgetPredicate((widget) => widget is TweenAnimationBuilder<Offset>);
    expect(cameraFinder, findsOneWidget);
    final cameraStackFinder = find.descendant(of: cameraFinder, matching: find.byType(Stack)).first;
    final viewport = tester.getSize(cameraStackFinder);
    Positioned world() => tester.widget<Stack>(cameraStackFinder).children.single as Positioned;
    expect(world().width!, greaterThan(viewport.width * 2));
    expect(world().left, 0);
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byIcon(Icons.keyboard_arrow_right));
      await tester.pump(const Duration(milliseconds: 200));
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(tester.takeException(), isNull);
    expect(world().left!, lessThan(0));
    expect(world().left!, greaterThanOrEqualTo(viewport.width - world().width!));
    final left = tester.getCenter(find.byIcon(Icons.keyboard_arrow_left));
    final right = tester.getCenter(find.byIcon(Icons.keyboard_arrow_right));
    expect(right.dx - left.dx, greaterThan(200));
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
