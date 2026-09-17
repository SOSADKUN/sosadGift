import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/screens/games/game_three_screen.dart';
import 'package:gift/views/widgets/game_failure_overlay.dart';
import 'package:gift/views/widgets/explosion_overlay.dart';

void main() {
  testWidgets(
    'maze previews escaped goal and returns while clock and input pause',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: GameThreeScreen(onComplete: () {}, onLose: () {}),
        ),
      );
      const arrows = {
        'R': Icons.keyboard_arrow_right,
        'L': Icons.keyboard_arrow_left,
        'U': Icons.keyboard_arrow_up,
        'D': Icons.keyboard_arrow_down,
      };
      for (final step in 'RRRRDDLLLLDDDDRRDDDDRRUURRUURRDDRRDDR'.split('')) {
        await tester.tap(find.byIcon(arrows[step]!));
        await tester.pump(const Duration(milliseconds: 160));
      }
      expect(find.text('它跑回起点啦！跟着镜头看看～'), findsOneWidget);
      final clockBefore = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => t.data!.startsWith('⏱'))
          .data;
      final camera = find.byWidgetPredicate(
        (w) => w is TweenAnimationBuilder<Offset>,
      );
      Offset destination() =>
          (tester.widget(camera) as TweenAnimationBuilder<Offset>).tween.end!;
      await tester.pump(const Duration(milliseconds: 220));
      expect(destination(), Offset.zero);
      await tester.tap(find.byIcon(Icons.keyboard_arrow_left));
      await tester.pump(const Duration(milliseconds: 1400));
      expect(destination(), Offset.zero);
      await tester.pump(const Duration(milliseconds: 850));
      expect(destination().dx, greaterThan(0));
      await tester.pump(const Duration(milliseconds: 1450));
      expect(find.text('回到你这里，出发追回它吧！'), findsNothing);
      expect(find.text(clockBefore!), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets(
    'failure card uses fail animation and retry is invoked only once',
    (tester) async {
      var retries = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameFailureOverlay(
                  title: '时间到啦！',
                  onRetry: () => retries++,
                  onExit: () {},
                ),
              ],
            ),
          ),
        ),
      );
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Image &&
              w.image is AssetImage &&
              (w.image as AssetImage).assetName == 'assets/photos/fail.gif',
        ),
        findsOneWidget,
      );
      await tester.tap(find.text('再试一次'));
      await tester.tap(find.text('再试一次'));
      expect(retries, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('explosion zoom builds without rendering exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              ColoredBox(color: Colors.pink),
              ExplosionOverlay(asset: 'assets/photos/game4_booooom.gif'),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 550));
    expect(tester.takeException(), isNull);
    await tester.pump(const Duration(milliseconds: 600));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
