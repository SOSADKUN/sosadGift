import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/games/maze_bomb_puzzle.dart';
import 'package:gift/games/maze_game.dart';
import 'package:gift/games/maze_layouts.dart';
import 'package:gift/views/screens/games/game_three_screen.dart';

List<Offset> route(
  List<String> rows,
  Offset start,
  Offset goal, {
  Offset? blocked,
}) {
  final queue = <Offset>[start];
  final parents = <Offset, Offset?>{start: null};
  for (var i = 0; i < queue.length; i++) {
    if (queue[i] == goal) break;
    for (final d in const [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
    ]) {
      final p = queue[i] + d;
      if (p == blocked ||
          parents.containsKey(p) ||
          p.dy < 0 ||
          p.dy >= rows.length ||
          p.dx < 0 ||
          p.dx >= rows.first.length ||
          rows[p.dy.toInt()][p.dx.toInt()] == '#') {
        continue;
      }
      parents[p] = queue[i];
      queue.add(p);
    }
  }
  if (!parents.containsKey(goal)) return [];
  final path = <Offset>[];
  Offset? p = goal;
  while (p != null) {
    path.add(p);
    p = parents[p];
  }
  return path.reversed.toList();
}

Future<void> advance(WidgetTester tester, int milliseconds) async {
  for (var elapsed = 0; elapsed < milliseconds; elapsed += 10) {
    await tester.pump(const Duration(milliseconds: 10));
  }
}

void main() {
  test('all variants have a reachable bomb before the blocking board', () {
    for (final rows in kMazeVariants) {
      const start = Offset(21, 17), goal = Offset(1, 1);
      final puzzle = mazeBombPuzzle(rows, start, goal);
      expect(
        route(rows, start, puzzle.bomb, blocked: puzzle.board),
        isNotEmpty,
      );
      expect(route(rows, start, goal, blocked: puzzle.board), isEmpty);
      expect((puzzle.bomb - puzzle.board).distance, 1);
      expect(route(rows, start, goal), isNotEmpty);
    }
  });

  testWidgets(
    'return tour drops board; pickup and planted bomb clear it only after 3 seconds',
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
      await advance(tester, 5000);
      Future<void> move(Offset direction) async {
        final stick = tester.getCenter(
          find.byKey(const ValueKey('maze-joystick')),
        );
        await tester.tapAt(stick + direction * 36);
        await advance(tester, 200);
      }

      final path = route(
        kMazeVariants.first,
        const Offset(1, 1),
        const Offset(21, 17),
      );
      for (var i = 1; i < path.length - 1; i++) {
        await move(path[i] - path[i - 1]);
      }
      await advance(tester, 10000);
      expect(game.boardPosition, isNotNull);
      expect(game.bombPickup, isNotNull);
      final board = game.boardPosition!;
      final bomb = game.bombPickup!;
      await tester.tap(find.text('拿起炸弹'));
      await tester.pump();
      expect(game.bombPickup, isNull);
      await move(bomb - game.playerPosition);
      await move(board - bomb);
      expect(game.playerPosition, bomb); // The board prevents movement.
      await tester.tap(find.text('放下炸弹'));
      await tester.pump();
      expect(game.plantedBomb, bomb);
      expect(game.bombSeconds, 3);
      await advance(tester, 2990);
      expect(game.boardPosition, board);
      await advance(tester, 20);
      expect(game.boardPosition, isNull);
      expect(game.plantedBomb, isNull);
      await move(board - bomb);
      expect(game.playerPosition, board);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
