import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_background.dart';

class _LevelConfig {
  final int colors;
  const _LevelConfig({required this.colors});
}

/// Water sort puzzle: tap a tube to pick up its top color, tap another to
/// pour it in. Sort every color into its own tube.
class GameFourScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const GameFourScreen({super.key, required this.onComplete});

  @override
  State<GameFourScreen> createState() => _GameFourScreenState();
}

class _GameFourScreenState extends State<GameFourScreen> {
  static const _capacity = 4;
  static const _levels = [
    _LevelConfig(colors: 4),
    _LevelConfig(colors: 5),
    _LevelConfig(colors: 6),
  ];
  static const _palette = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.green,
    Colors.orange,
    Colors.purpleAccent,
    Colors.teal,
    Colors.pinkAccent,
    Colors.brown,
  ];

  final _rnd = Random();
  int _levelIndex = 0;
  late List<List<Color>> _tubes;
  int? _selected;
  String? _message;
  bool _finished = false;

  _LevelConfig get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    final colorCount = _level.colors;
    final blocks = <Color>[];
    for (int i = 0; i < colorCount; i++) {
      for (int j = 0; j < _capacity; j++) {
        blocks.add(_palette[i]);
      }
    }
    blocks.shuffle(_rnd);

    _tubes = List.generate(
      colorCount,
      (i) => List<Color>.from(blocks.sublist(i * _capacity, (i + 1) * _capacity)),
    );
    _tubes.addAll(List.generate(2, (_) => <Color>[]));
    _selected = null;
    _message = null;
    _finished = false;
  }

  void _selectTube(int index) {
    if (_finished) return;
    if (_selected == null) {
      if (_tubes[index].isEmpty) return;
      setState(() => _selected = index);
    } else if (_selected == index) {
      setState(() => _selected = null);
    } else {
      _pour(_selected!, index);
    }
  }

  void _pour(int from, int to) {
    final src = _tubes[from];
    final dst = _tubes[to];
    if (src.isEmpty || dst.length >= _capacity) {
      setState(() => _selected = null);
      return;
    }
    final color = src.last;
    if (dst.isNotEmpty && dst.last != color) {
      setState(() => _selected = null);
      return;
    }

    int count = 0;
    for (int i = src.length - 1; i >= 0 && src[i] == color; i--) {
      count++;
    }
    final moveCount = min(count, _capacity - dst.length);

    setState(() {
      for (int i = 0; i < moveCount; i++) {
        dst.add(src.removeLast());
      }
      _selected = null;
    });

    _checkWin();
  }

  void _checkWin() {
    final solved = _tubes.every(
      (t) => t.isEmpty || (t.length == _capacity && t.toSet().length == 1),
    );
    if (!solved) return;

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
      title: '彩虹分类',
      level: _levelIndex + 1,
      levelCount: _levels.length,
      backgroundImage: 'assets/photos/game4.png',
      child: Column(
        children: [
          const SizedBox(height: 4),
          const Text(
            '点击试管拿起，再点另一个倒入',
            style: TextStyle(color: Colors.white70, fontSize: 13),
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
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 16,
            children: List.generate(_tubes.length, (i) {
              final tube = _tubes[i];
              final selected = _selected == i;
              return GestureDetector(
                onTap: () => _selectTube(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 42,
                  height: _capacity * 28 + 12,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.vertical(
                        bottom: const Radius.circular(16),
                        top: const Radius.circular(6)),
                    border: Border.all(
                      color: selected ? Colors.white : Colors.white38,
                      width: selected ? 3 : 1.5,
                    ),
                    boxShadow: selected
                        ? [
                            BoxShadow(
                                color: Colors.white.withValues(alpha: 0.4),
                                blurRadius: 10)
                          ]
                        : const [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      for (final color in tube)
                        Container(
                          width: double.infinity,
                          height: 26,
                          margin: const EdgeInsets.only(top: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(4),
                          ),
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
