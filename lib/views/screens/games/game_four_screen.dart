import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_background.dart';

class _LevelConfig {
  final int length;
  final Duration stepDuration;
  const _LevelConfig({required this.length, required this.stepDuration});
}

enum _Phase { showing, input }

/// Simon-says style: watch the sequence light up, then repeat it.
class GameFourScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onLose;

  const GameFourScreen({
    super.key,
    required this.onComplete,
    required this.onLose,
  });

  @override
  State<GameFourScreen> createState() => _GameFourScreenState();
}

class _GameFourScreenState extends State<GameFourScreen> {
  static const _levels = [
    _LevelConfig(length: 4, stepDuration: Duration(milliseconds: 600)),
    _LevelConfig(length: 6, stepDuration: Duration(milliseconds: 500)),
    _LevelConfig(length: 8, stepDuration: Duration(milliseconds: 420)),
  ];

  static const _icons = ['🌸', '💗', '⭐', '🎈'];
  static const _colors = [
    Colors.pinkAccent,
    Colors.redAccent,
    Colors.amber,
    Colors.deepPurpleAccent,
  ];

  final _rnd = Random();
  int _levelIndex = 0;
  List<int> _sequence = [];
  int _playerProgress = 0;
  int _highlighted = -1;
  _Phase _phase = _Phase.showing;
  String? _message;

  _LevelConfig get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    _sequence = List.generate(_level.length, (_) => _rnd.nextInt(4));
    _playerProgress = 0;
    _message = null;
    _playShowPhase();
  }

  Future<void> _playShowPhase() async {
    setState(() => _phase = _Phase.showing);
    await Future.delayed(const Duration(milliseconds: 400));
    for (final index in _sequence) {
      if (!mounted) return;
      setState(() => _highlighted = index);
      await Future.delayed(_level.stepDuration);
      if (!mounted) return;
      setState(() => _highlighted = -1);
      await Future.delayed(const Duration(milliseconds: 150));
    }
    if (!mounted) return;
    setState(() => _phase = _Phase.input);
  }

  void _onTapButton(int index) {
    if (_phase != _Phase.input) return;

    if (_sequence[_playerProgress] == index) {
      setState(() {
        _highlighted = index;
        _playerProgress++;
      });
      Timer(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _highlighted = -1);
      });
      if (_playerProgress == _sequence.length) {
        _levelClear();
      }
    } else {
      setState(() {
        _phase = _Phase.showing;
        _message = '再试一次！';
      });
      Timer(const Duration(milliseconds: 700), widget.onLose);
    }
  }

  void _levelClear() {
    if (_levelIndex >= _levels.length - 1) {
      setState(() {
        _message = '通关啦！🎉';
        _phase = _Phase.showing;
      });
      Timer(const Duration(milliseconds: 700), widget.onComplete);
    } else {
      setState(() {
        _message = 'Level ${_levelIndex + 1} 完成！';
        _phase = _Phase.showing;
      });
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
      title: '记忆序列',
      level: _levelIndex + 1,
      levelCount: _levels.length,
      child: Column(
        children: [
          const SizedBox(height: 12),
          Text(
            _phase == _Phase.showing ? '看好顺序…' : '轮到你了！',
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
          if (_message != null) ...[
            const SizedBox(height: 8),
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
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 20,
              crossAxisSpacing: 20,
              children: List.generate(4, (i) {
                final active = _highlighted == i;
                return GestureDetector(
                  onTap: () => _onTapButton(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color:
                          active ? _colors[i] : _colors[i].withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(_icons[i], style: const TextStyle(fontSize: 40)),
                  ),
                );
              }),
            ),
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
