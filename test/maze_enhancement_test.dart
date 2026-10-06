import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/games/maze_game.dart';
import 'package:gift/games/maze_layouts.dart';

void main() {
  test('every enlarged maze remains connected and reasonably completable', () {
    for (final maze in kMazeVariants) {
      expect(maze.length, 19);
      expect(maze.every((row) => row.length == 23), isTrue);
      final queue = <(int, int, int)>[(1, 1, 0)];
      final visited = <(int, int)>{(1, 1)};
      int? distance;
      for (var cursor = 0; cursor < queue.length; cursor++) {
        final (r, c, d) = queue[cursor];
        if (maze[r][c] == 'G') distance = d;
        for (final (dr, dc) in [(0, 1), (1, 0), (0, -1), (-1, 0)]) {
          final next = (r + dr, c + dc);
          if (next.$1 < 0 ||
              next.$2 < 0 ||
              next.$1 >= 19 ||
              next.$2 >= 23 ||
              maze[next.$1][next.$2] == '#' ||
              !visited.add(next)) {
            continue;
          }
          queue.add((next.$1, next.$2, d + 1));
        }
      }
      expect(distance, isNotNull);
      expect(distance!, lessThanOrEqualTo(106));
      final open = maze.fold<int>(
        0,
        (n, row) => n + row.split('').where((cell) => cell != '#').length,
      );
      expect(visited.length, open);
    }
  });

  test(
    'camera travels through intermediate positions both ways without resize jumps',
    () {
      final game = MazeGame(
        rows: kMazeVariants.first,
        player: const Offset(21, 17),
        goal: const Offset(1, 1),
      );
      game.onGameResize(Vector2(350, 450));
      expect(game.backgroundColor(), Colors.white);
      final origin = game.cameraOffset;
      game.cameraTour = true;
      game.lookAtStart = true;
      game.update(.016);
      expect(game.cameraOffset.dx, greaterThan(0));
      expect(game.cameraOffset.dx, closeTo(origin.dx, 1));
      for (var i = 0; i < 45; i++) {
        game.update(.016);
      }
      final halfway = game.cameraOffset;
      expect(halfway.dx, greaterThan(0));
      expect(halfway.dx, lessThan(origin.dx));
      game.onGameResize(Vector2(350, 420));
      expect(game.cameraOffset.dx, closeTo(halfway.dx, 1));
      for (var i = 0; i < 110; i++) {
        game.update(.016);
      }
      expect(game.cameraOffset.distance, closeTo(0, .001));
      game.lookAtStart = false;
      game.update(.016);
      expect(game.cameraOffset.dx, lessThan(1));
      for (var i = 0; i < 45; i++) {
        game.update(.016);
      }
      expect(game.cameraOffset.dx, greaterThan(0));
      expect(game.cameraOffset.dx, lessThan(origin.dx));
      for (var i = 0; i < 65; i++) {
        game.update(.016);
      }
      expect(game.cameraOffset.dx, closeTo(origin.dx, .001));
    },
  );
}
