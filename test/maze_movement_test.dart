import 'package:flutter_test/flutter_test.dart';
import 'package:flame/game.dart';
import 'package:gift/games/maze_game.dart';

void main() {
  const rows = ['#####', '#   #', '#   #', '#   #', '#####'];
  MazeGame createGame() =>
      MazeGame(rows: rows, player: const Offset(2, 2), goal: const Offset(3, 3))
        ..onGameResize(Vector2(350, 450));

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

  test('vertical travel keeps horizontal facing and the same gentle step', () {
    final game = createGame();
    game.facingCol = 1;
    game.update(.01);
    expect(game.playerFacesRight, isTrue);
    game.facingCol = 0;
    for (final row in [-1, 1]) {
      game.facingRow = row;
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
  });
}
