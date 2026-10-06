import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'package:gift/games/maze_game.dart';
import 'package:gift/games/maze_layouts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/screens/games/game_three_screen.dart';
import 'package:gift/views/widgets/game_failure_overlay.dart';
import 'package:gift/views/widgets/explosion_overlay.dart';

Offset stick(WidgetTester tester) =>
    tester.getCenter(find.byKey(const ValueKey('maze-joystick')));

Future<void> finishTour(WidgetTester tester) async {
  for (var i = 0; i < 310; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets(
    'maze previews escaped goal and returns while clock and input pause',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      late MazeGame game;
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: GameThreeScreen(onComplete: () {}, onLose: () {}),
          ),
        );
        game = tester
            .widget<GameWidget<MazeGame>>(find.byType(GameWidget<MazeGame>))
            .game!;
        await game.loaded;
      });
      await tester.pump();
      await finishTour(tester);
      const arrows = {
        'R': Offset(36, 0),
        'L': Offset(-36, 0),
        'U': Offset(0, -36),
        'D': Offset(0, 36),
      };
      for (final step in pathToGoal(kMazeVariants.first)..removeLast()) {
        await tester.tapAt(stick(tester) + arrows[step]!);
        await tester.pump(const Duration(milliseconds: 160));
      }
      expect(find.text('它跑回起点啦！跟着镜头看看～'), findsOneWidget);
      final clockBefore = tester
          .widgetList<Text>(find.byType(Text))
          .firstWhere((t) => t.data!.startsWith('⏱'))
          .data;
      await tester.pump(const Duration(milliseconds: 220));
      expect(game.lookAtStart, isTrue);
      final playerBefore = game.playerPosition;
      await tester.tapAt(stick(tester) + const Offset(-36, 0));
      await tester.pump(const Duration(milliseconds: 1400));
      expect(game.lookAtStart, isTrue);
      expect(game.playerPosition, playerBefore);
      await tester.pump(const Duration(milliseconds: 1250));
      expect(game.lookAtStart, isFalse);
      expect(find.text(clockBefore!), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 1850));
      expect(find.text('回到你这里，出发追回它吧！'), findsNothing);
      await tester.pump(const Duration(seconds: 1));
      expect(find.text(clockBefore), findsNothing);
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

List<String> pathToGoal(List<String> maze) {
  final queue = <(int, int, List<String>)>[(1, 1, [])];
  final visited = <(int, int)>{(1, 1)};
  for (var cursor = 0; cursor < queue.length; cursor++) {
    final (row, col, path) = queue[cursor];
    if (maze[row][col] == 'G') return path;
    for (final (dr, dc, step) in [
      (0, 1, 'R'),
      (1, 0, 'D'),
      (0, -1, 'L'),
      (-1, 0, 'U'),
    ]) {
      final r = row + dr, c = col + dc;
      if (r < 0 ||
          c < 0 ||
          r >= maze.length ||
          c >= maze[0].length ||
          maze[r][c] == '#' ||
          !visited.add((r, c))) {
        continue;
      }
      queue.add((r, c, [...path, step]));
    }
  }
  throw StateError('Maze goal is unreachable');
}
