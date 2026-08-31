import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_background.dart';

class _LevelConfig {
  final int targetValue;
  const _LevelConfig({required this.targetValue});
}

/// Classic 2048: swipe to slide tiles, merge equal numbers, reach the target.
class GameTwoScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onLose;

  const GameTwoScreen({
    super.key,
    required this.onComplete,
    required this.onLose,
  });

  @override
  State<GameTwoScreen> createState() => _GameTwoScreenState();
}

class _GameTwoScreenState extends State<GameTwoScreen> {
  static const _size = 4;
  static const _levels = [
    _LevelConfig(targetValue: 64),
    _LevelConfig(targetValue: 128),
    _LevelConfig(targetValue: 256),
  ];

  final _rnd = Random();
  int _levelIndex = 0;
  late List<List<int>> _board;
  Offset _dragAccum = Offset.zero;
  String? _message;
  bool _finished = false;

  _LevelConfig get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    _board = List.generate(_size, (_) => List.filled(_size, 0));
    _message = null;
    _finished = false;
    _spawnRandomTile();
    _spawnRandomTile();
  }

  void _spawnRandomTile() {
    final empty = <Point<int>>[];
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_board[r][c] == 0) empty.add(Point(r, c));
      }
    }
    if (empty.isEmpty) return;
    final cell = empty[_rnd.nextInt(empty.length)];
    _board[cell.x][cell.y] = _rnd.nextDouble() < 0.9 ? 2 : 4;
  }

  List<int> _mergeRowLeft(List<int> row) {
    final nonZero = row.where((v) => v != 0).toList();
    final result = <int>[];
    int i = 0;
    while (i < nonZero.length) {
      if (i + 1 < nonZero.length && nonZero[i] == nonZero[i + 1]) {
        result.add(nonZero[i] * 2);
        i += 2;
      } else {
        result.add(nonZero[i]);
        i += 1;
      }
    }
    while (result.length < _size) {
      result.add(0);
    }
    return result;
  }

  List<List<int>> _transpose(List<List<int>> b) =>
      List.generate(_size, (i) => List.generate(_size, (j) => b[j][i]));

  List<List<int>> _reverseRows(List<List<int>> b) =>
      b.map((r) => r.reversed.toList()).toList();

  List<List<int>> _mergeLeft(List<List<int>> b) =>
      b.map(_mergeRowLeft).toList();

  List<List<int>> _applyMove(List<List<int>> board, String dir) {
    switch (dir) {
      case 'left':
        return _mergeLeft(board);
      case 'right':
        return _reverseRows(_mergeLeft(_reverseRows(board)));
      case 'up':
        return _transpose(_mergeLeft(_transpose(board)));
      case 'down':
        return _transpose(_reverseRows(_mergeLeft(_reverseRows(_transpose(board)))));
      default:
        return board;
    }
  }

  bool _boardsEqual(List<List<int>> a, List<List<int>> b) {
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (a[r][c] != b[r][c]) return false;
      }
    }
    return true;
  }

  bool _isStuck() {
    for (int r = 0; r < _size; r++) {
      for (int c = 0; c < _size; c++) {
        if (_board[r][c] == 0) return false;
        if (c + 1 < _size && _board[r][c] == _board[r][c + 1]) return false;
        if (r + 1 < _size && _board[r][c] == _board[r + 1][c]) return false;
      }
    }
    return true;
  }

  void _swipe(String dir) {
    if (_finished) return;
    final newBoard = _applyMove(_board, dir);
    if (_boardsEqual(_board, newBoard)) return;

    setState(() {
      _board = newBoard;
      _spawnRandomTile();
    });

    final maxTile = _board.expand((r) => r).reduce(max);
    if (maxTile >= _level.targetValue) {
      _levelClear();
    } else if (_isStuck()) {
      _fail();
    }
  }

  void _fail() {
    _finished = true;
    setState(() => _message = '再试一次！');
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) widget.onLose();
    });
  }

  void _levelClear() {
    _finished = true;
    if (_levelIndex >= _levels.length - 1) {
      setState(() => _message = '通关啦！🎉');
      Timer(const Duration(milliseconds: 700), widget.onComplete);
    } else {
      setState(() => _message = 'Level ${_levelIndex + 1} 完成！');
      Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _levelIndex++);
        _startLevel();
      });
    }
  }

  Color _tileColor(int value) {
    switch (value) {
      case 0:
        return Colors.white.withValues(alpha: 0.08);
      case 2:
        return const Color(0xFFEEE4DA);
      case 4:
        return const Color(0xFFEDE0C8);
      case 8:
        return const Color(0xFFF2B179);
      case 16:
        return const Color(0xFFF59563);
      case 32:
        return const Color(0xFFF67C5F);
      case 64:
        return const Color(0xFFF65E3B);
      case 128:
        return const Color(0xFFEDCF72);
      case 256:
        return const Color(0xFFEDCC61);
      case 512:
        return const Color(0xFFEDC850);
      default:
        return const Color(0xFFEDC22E);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      title: '2048',
      level: _levelIndex + 1,
      levelCount: _levels.length,
      backgroundImage: 'assets/photos/game2.png',
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            '目标: ${_level.targetValue}',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          if (_message != null) ...[
            const SizedBox(height: 6),
            Text(
              _message!,
              style: const TextStyle(
                  color: Colors.amberAccent,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
          ],
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GestureDetector(
              onPanUpdate: (d) => _dragAccum += d.delta,
              onPanEnd: (d) {
                final dx = _dragAccum.dx;
                final dy = _dragAccum.dy;
                _dragAccum = Offset.zero;
                if (dx.abs() < 20 && dy.abs() < 20) return;
                if (dx.abs() > dy.abs()) {
                  _swipe(dx > 0 ? 'right' : 'left');
                } else {
                  _swipe(dy > 0 ? 'down' : 'up');
                }
              },
              child: AspectRatio(
                aspectRatio: 1,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _size,
                      mainAxisSpacing: 6,
                      crossAxisSpacing: 6,
                    ),
                    itemCount: _size * _size,
                    itemBuilder: (context, index) {
                      final r = index ~/ _size;
                      final c = index % _size;
                      final value = _board[r][c];
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        decoration: BoxDecoration(
                          color: _tileColor(value),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: value == 0
                            ? null
                            : Text(
                                '$value',
                                style: TextStyle(
                                  fontSize: value >= 100 ? 20 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: value <= 4
                                      ? const Color(0xFF6B5B4F)
                                      : Colors.white,
                                ),
                              ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
