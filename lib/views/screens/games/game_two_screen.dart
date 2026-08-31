import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_background.dart';

class _LevelConfig {
  final int pairs;
  final int crossAxisCount;
  const _LevelConfig({required this.pairs, required this.crossAxisCount});
}

/// Flip two cards at a time, find all pairs. Swap the emoji list for photo
/// assets later if you want it more personal.
class GameTwoScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const GameTwoScreen({super.key, required this.onComplete});

  @override
  State<GameTwoScreen> createState() => _GameTwoScreenState();
}

class _GameTwoScreenState extends State<GameTwoScreen> {
  static const _symbols = ['🎂', '🎁', '💌', '⭐', '🎮', '🧸', '🍰', '🎈'];
  static const _levels = [
    _LevelConfig(pairs: 5, crossAxisCount: 5),
    _LevelConfig(pairs: 6, crossAxisCount: 4),
    _LevelConfig(pairs: 8, crossAxisCount: 4),
  ];

  int _levelIndex = 0;
  late List<String> _cards;
  final Set<int> _flipped = {};
  final Set<int> _matched = {};
  int? _firstIndex;
  bool _busy = false;
  String? _message;

  _LevelConfig get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    final symbols = _symbols.sublist(0, _level.pairs);
    setState(() {
      _cards = [...symbols, ...symbols]..shuffle(Random());
      _flipped.clear();
      _matched.clear();
      _firstIndex = null;
      _busy = false;
      _message = null;
    });
  }

  void _onTap(int index) {
    if (_busy || _flipped.contains(index) || _matched.contains(index)) return;

    setState(() => _flipped.add(index));

    if (_firstIndex == null) {
      _firstIndex = index;
      return;
    }

    final first = _firstIndex!;
    _firstIndex = null;

    if (_cards[first] == _cards[index]) {
      setState(() => _matched.addAll([first, index]));
      if (_matched.length == _cards.length) {
        _levelClear();
      }
    } else {
      _busy = true;
      Timer(const Duration(milliseconds: 700), () {
        if (!mounted) return;
        setState(() {
          _flipped.remove(first);
          _flipped.remove(index);
          _busy = false;
        });
      });
    }
  }

  void _levelClear() {
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
      title: '记忆配对',
      level: _levelIndex + 1,
      levelCount: _levels.length,
      backgroundImage: 'assets/photos/game2.png',
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _level.crossAxisCount,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
              ),
              itemCount: _cards.length,
              itemBuilder: (context, i) {
                final revealed = _flipped.contains(i) || _matched.contains(i);
                return GestureDetector(
                  onTap: () => _onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: revealed ? Colors.pink[100] : Colors.deepPurple,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _matched.contains(i)
                            ? Colors.amber
                            : Colors.white24,
                        width: 2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      revealed ? _cards[i] : '?',
                      style: const TextStyle(fontSize: 26, color: Colors.white),
                    ),
                  ),
                );
              },
            ),
          ),
          if (_message != null)
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  _message!,
                  style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
