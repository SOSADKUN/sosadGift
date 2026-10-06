import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/games/maze_game.dart';
import 'package:gift/views/screens/games/game_three_screen.dart';

Offset stick(WidgetTester tester) =>
    tester.getCenter(find.byKey(const ValueKey('maze-joystick')));

Future<void> finishTour(WidgetTester tester) async {
  for (var i = 0; i < 310; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

void main() {
  testWidgets(
    'Flame maze camera follows movement and stays within world bounds',
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
      expect(game.worldWidth, greaterThan(game.size.x * 2));
      expect(game.cameraOffset.dx, closeTo(0, .1));
      for (var i = 0; i < 4; i++) {
        await tester.tapAt(stick(tester) + const Offset(36, 0));
        await tester.pump(const Duration(milliseconds: 180));
      }
      for (var i = 0; i < 20; i++) {
        game.update(.016);
      }
      expect(game.playerPosition.dx, 5);
      expect(game.cameraOffset.dx, greaterThan(0));
      expect(
        game.cameraOffset.dx,
        lessThanOrEqualTo(game.worldWidth - game.size.x),
      );
      final before = game.playerPosition;
      await tester.tapAt(stick(tester) + const Offset(0, -36));
      await tester.pump(const Duration(milliseconds: 180));
      expect(game.playerPosition, before); // The adjacent cell is a wall.
      final left = stick(tester) + const Offset(-36, 0);
      final right = stick(tester) + const Offset(36, 0);
      expect(right.dx - left.dx, greaterThan(60));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );

  testWidgets('holding a direction moves continuously and releasing stops it', (
    tester,
  ) async {
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
    final touch = await tester.startGesture(
      stick(tester) + const Offset(36, 0),
    );
    for (var i = 0; i < 45; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await touch.up();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(game.playerPosition.dx, 5);
    final stopped = game.playerPosition;
    await tester.pump(const Duration(milliseconds: 400));
    expect(game.playerPosition, stopped);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
