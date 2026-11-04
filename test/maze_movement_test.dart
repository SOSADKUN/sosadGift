import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:gift/games/maze_game.dart';

void main() {
  const rows = ['#####', '#   #', '#   #', '#   #', '#####'];
  MazeGame createGame() =>
      MazeGame(rows: rows, player: const Offset(2, 2), goal: const Offset(3, 3))
        ..onGameResize(Vector2(350, 450));

  test(
    'escaping target runs through corridors and settles at the new goal',
    () {
      const maze = ['#######', '#     #', '##### #', '#     #', '#######'];
      final game = MazeGame(
        rows: maze,
        player: const Offset(5, 3),
        goal: const Offset(1, 1),
      )..onGameResize(Vector2(200, 200));
      game.fleeTarget(const Offset(1, 3));
      expect(game.targetPosition, const Offset(1, 3));
      expect(game.targetEscaping, isTrue);
      var previous = game.targetPosition;
      for (var i = 0; i < 260; i++) {
        game.update(.01);
        final position = game.targetPosition;
        expect((position - previous).distance, lessThan(.1));
        expect(maze[position.dy.round()][position.dx.round()], isNot('#'));
        previous = position;
      }
      game.update(.01);
      expect(game.targetEscaping, isFalse);
      expect(game.targetPosition, const Offset(1, 1));
    },
  );

  test('all directions travel at the same steady speed and settle on cell', () {
    for (final direction in [
      const Offset(1, 0),
      const Offset(-1, 0),
      const Offset(0, 1),
      const Offset(0, -1),
    ]) {
      final game = createGame();
      game.setScene(
        rows: rows,
        player: const Offset(2, 2) + direction,
        goal: const Offset(3, 3),
      );
      for (var frame = 1; frame <= 10; frame++) {
        game.update(.016);
        final travelled = game.playerPosition - const Offset(2, 2);
        expect(travelled.dx, closeTo(direction.dx * frame / 10, .00001));
        expect(travelled.dy, closeTo(direction.dy * frame / 10, .00001));
      }
      game.update(.001);
      expect(game.moving, isFalse);
      expect(game.playerBob, 0);
      final end = game.playerPosition;
      game.update(.1);
      expect(game.playerPosition, end);
    }
  });

  test(
    'vertical travel uses front and back views with the same gentle step',
    () {
      final game = createGame();
      game.facingCol = 1;
      game.update(.01);
      expect(game.playerFacesRight, isTrue);
      game.facingCol = 0;
      for (final row in [-1, 1]) {
        game.facingRow = row;
        expect(
          game.characterView,
          row < 0 ? MazeCharacterView.back : MazeCharacterView.front,
        );
        game.setScene(
          rows: rows,
          player: Offset(2, (2 + row).toDouble()),
          goal: const Offset(3, 3),
        );
        game.update(.08);
        expect(game.playerFacesRight, isTrue);
        expect(game.playerBob, closeTo(game.cellSize * .02, .00001));
        game.update(.1);
        expect(game.playerBob, 0);
        game.setScene(
          rows: rows,
          player: const Offset(2, 2),
          goal: const Offset(3, 3),
        );
        game.update(.18);
      }
      game.facingCol = -1;
      game.update(.01);
      expect(game.playerFacesRight, isFalse);
    },
  );
}
