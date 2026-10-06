import 'package:flutter/material.dart';

/// Place the pickup before a barricade on a valid route out of the corner.
({Offset bomb, Offset board}) mazeBombPuzzle(
  List<String> rows,
  Offset start,
  Offset goal,
) {
  final queue = <Offset>[start];
  final parents = <Offset, Offset?>{start: null};
  for (var i = 0; i < queue.length; i++) {
    final cell = queue[i];
    if (cell == goal) break;
    for (final direction in const [
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
    ]) {
      final next = cell + direction;
      final x = next.dx.toInt(), y = next.dy.toInt();
      if (y < 0 ||
          y >= rows.length ||
          x < 0 ||
          x >= rows[y].length ||
          rows[y][x] == '#' ||
          parents.containsKey(next)) {
        continue;
      }
      parents[next] = cell;
      queue.add(next);
    }
  }
  if (!parents.containsKey(goal)) throw StateError('Maze goal is unreachable');
  final path = <Offset>[];
  Offset? cell = goal;
  while (cell != null) {
    path.add(cell);
    cell = parents[cell];
  }
  final route = path.reversed.toList();
  if (route.length < 4) throw StateError('Maze route is too short');
  return (bomb: route[1], board: route[2]);
}
