import 'package:flutter/material.dart';
import '../../games/maze_game.dart';

/// The route overview lives beside the controls, outside Flame's viewport.
class MazeMiniMap extends StatelessWidget {
  const MazeMiniMap({super.key, required this.game});
  final MazeGame game;
  @override
  Widget build(BuildContext context) => Semantics(
    label: '迷宫路线图：显示人物、目标、炸弹和路障',
    image: true,
    child: RepaintBoundary(
      child: SizedBox(
        key: const ValueKey('maze-mini-map'),
        width: 128,
        height: 110,
        child: CustomPaint(painter: _MapPainter(game)),
      ),
    ),
  );
}

class _MapPainter extends CustomPainter {
  _MapPainter(this.game) : super(repaint: game.minimapRevision);
  final MazeGame game;
  @override
  void paint(Canvas canvas, Size size) => game.renderMinimap(canvas, size);
  @override
  bool shouldRepaint(_MapPainter oldDelegate) => game != oldDelegate.game;
}
