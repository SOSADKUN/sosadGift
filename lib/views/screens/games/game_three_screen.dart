import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_background.dart';

class _LevelConfig {
  final int columns;
  final int maxHeight;
  final int targetTier;
  const _LevelConfig({
    required this.columns,
    required this.maxHeight,
    required this.targetTier,
  });
}

/// Merge-drop: tap a lane to drop the next piece in; matching tiers merge
/// into the next tier up. Reach the target tier before any lane overflows.
class GameThreeScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onLose;

  const GameThreeScreen({
    super.key,
    required this.onComplete,
    required this.onLose,
  });

  @override
  State<GameThreeScreen> createState() => _GameThreeScreenState();
}

class _GameThreeScreenState extends State<GameThreeScreen> {
  static const _tierEmoji = ['🍒', '🍓', '🍇', '🍊', '🍎', '🍉', '🎃', '⭐', '👑'];
  static const _levels = [
    _LevelConfig(columns: 5, maxHeight: 7, targetTier: 5),
    _LevelConfig(columns: 5, maxHeight: 6, targetTier: 6),
    _LevelConfig(columns: 4, maxHeight: 6, targetTier: 7),
  ];
  static const _cellSize = 34.0;

  final _rnd = Random();
  int _levelIndex = 0;
  late List<List<int>> _columns;
  int _currentTier = 1;
  String? _message;
  bool _finished = false;

  _LevelConfig get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    _columns = List.generate(_level.columns, (_) => <int>[]);
    _currentTier = _randomTier();
    _message = null;
    _finished = false;
  }

  int _randomTier() => 1 + _rnd.nextInt(2);

  void _mergeCascade(int col) {
    bool merged = true;
    while (merged) {
      merged = false;
      final list = _columns[col];
      for (int i = list.length - 1; i > 0; i--) {
        if (list[i] == list[i - 1]) {
          list[i - 1] = list[i - 1] + 1;
          list.removeAt(i);
          merged = true;
          break;
        }
      }
    }
  }

  void _drop(int col) {
    if (_finished) return;
    setState(() {
      _columns[col].add(_currentTier);
      _mergeCascade(col);
    });

    if (_columns.any((c) => c.length > _level.maxHeight)) {
      _fail();
      return;
    }
    if (_columns.any((c) => c.any((t) => t >= _level.targetTier))) {
      _levelClear();
      return;
    }
    setState(() => _currentTier = _randomTier());
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

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      title: '合成大作战',
      level: _levelIndex + 1,
      levelCount: _levels.length,
      backgroundImage: 'assets/photos/game3.png',
      child: Column(
        children: [
          const SizedBox(height: 4),
          Text(
            '目标: ${_tierEmoji[_level.targetTier - 1]}',
            style: const TextStyle(color: Colors.white, fontSize: 18),
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
          const SizedBox(height: 10),
          Text(_tierEmoji[_currentTier - 1],
              style: const TextStyle(fontSize: 36)),
          const Text('下一个', style: TextStyle(color: Colors.white70, fontSize: 12)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_level.columns, (col) {
              final stack = _columns[col];
              return GestureDetector(
                onTap: () => _drop(col),
                child: Container(
                  width: _cellSize + 8,
                  height: _cellSize * _level.maxHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.white24),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final tier in stack)
                        Container(
                          width: _cellSize,
                          height: _cellSize,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(vertical: 1),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: Text(_tierEmoji[tier - 1],
                              style: const TextStyle(fontSize: 18)),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
