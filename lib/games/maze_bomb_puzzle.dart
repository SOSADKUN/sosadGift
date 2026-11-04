import 'package:flutter/material.dart';

const _directions = [Offset(1, 0), Offset(-1, 0), Offset(0, 1), Offset(0, -1)];

Map<Offset, Offset?> _reachable(
  List<String> rows,
  Offset start, {
  Offset? blocked,
}) {
  final queue = <Offset>[start];
  final parents = <Offset, Offset?>{start: null};
  for (var i = 0; i < queue.length; i++) {
    for (final direction in _directions) {
      final next = queue[i] + direction;
      final x = next.dx.toInt(), y = next.dy.toInt();
      if (next == blocked ||
          y < 0 ||
          y >= rows.length ||
          x < 0 ||
          x >= rows[y].length ||
          rows[y][x] == '#' ||
          parents.containsKey(next)) {
        continue;
      }
      parents[next] = queue[i];
      queue.add(next);
    }
  }
  return parents;
}

/// The bomb is at the upper-right; the barricade guards the distant goal.
/// Validate reachability so the pickup never gets trapped behind the barricade.
({Offset bomb, Offset board}) mazeBombPuzzle(
  List<String> rows,
  Offset start,
  Offset goal,
) {
  final parents = _reachable(rows, start);
  if (!parents.containsKey(goal)) throw StateError('Maze goal is unreachable');
  final route = <Offset>[];
  for (Offset? p = goal; p != null; p = parents[p]) {
    route.add(p);
  }
  final path = route.reversed.toList();
  if (path.length < 4) throw StateError('Maze route is too short');
  final corner = Offset(rows.first.length - 2.0, 1);
  // Prefer a chokepoint a few tiles before the goal, rather than beside the player.
  final indices = List.generate(path.length - 2, (i) => i + 1)
    ..sort(
      (a, b) => ((path.length - 1 - a) - 4).abs().compareTo(
        ((path.length - 1 - b) - 4).abs(),
      ),
    );
  for (final index in indices) {
    final board = path[index];
    final accessible = _reachable(rows, start, blocked: board);
    if (accessible.containsKey(goal)) continue;
    final pickups =
        accessible.keys.where((p) => p != start && p != goal).toList()..sort(
          (a, b) => ((a.dx - corner.dx).abs() + (a.dy - corner.dy).abs())
              .compareTo((b.dx - corner.dx).abs() + (b.dy - corner.dy).abs()),
        );
    if (pickups.isNotEmpty) return (bomb: pickups.first, board: board);
  }
  throw StateError('Maze has no blocking barricade with an accessible bomb');
}
