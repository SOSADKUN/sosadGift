import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_background.dart';

class _LevelConfig {
  final int targetTaps;
  final int seconds;
  final Duration visible;
  const _LevelConfig({
    required this.targetTaps,
    required this.seconds,
    required this.visible,
  });
}

/// Tap the feather before it vanishes — reach the target count before time's up.
class GameOneScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onLose;

  const GameOneScreen({
    super.key,
    required this.onComplete,
    required this.onLose,
  });

  @override
  State<GameOneScreen> createState() => _GameOneScreenState();
}

class _GameOneScreenState extends State<GameOneScreen> {
  static const _levels = [
    _LevelConfig(
        targetTaps: 30, seconds: 30, visible: Duration(milliseconds: 800)),
    _LevelConfig(
        targetTaps: 35, seconds: 28, visible: Duration(milliseconds: 600)),
    _LevelConfig(
        targetTaps: 40, seconds: 25, visible: Duration(milliseconds: 450)),
  ];

  final _rnd = Random();
  int _levelIndex = 0;
  int _tapped = 0;
  int _secondsLeft = 0;
  Offset _pos = const Offset(0.5, 0.5);
  bool _visible = true;
  String? _message;
  Timer? _clock;
  Timer? _spawnTimer;
  Timer? _loseTimer;

  _LevelConfig get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    _tapped = 0;
    _secondsLeft = _level.seconds;
    _message = null;
    _clock?.cancel();
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _timeUp();
    });
    _spawnTarget();
  }

  void _spawnTarget() {
    _spawnTimer?.cancel();
    setState(() {
      _pos =
          Offset(0.1 + _rnd.nextDouble() * 0.8, 0.12 + _rnd.nextDouble() * 0.7);
      _visible = true;
    });
    _spawnTimer = Timer(_level.visible, () {
      if (!mounted) return;
      setState(() => _visible = false);
      Timer(const Duration(milliseconds: 200), () {
        if (mounted && _secondsLeft > 0) _spawnTarget();
      });
    });
  }

  void _onTapTarget() {
    if (!_visible) return;
    _spawnTimer?.cancel();
    setState(() {
      _visible = false;
      _tapped++;
    });
    if (_tapped >= _level.targetTaps) {
      _levelClear();
    } else {
      Timer(const Duration(milliseconds: 120), _spawnTarget);
    }
  }

  void _timeUp() {
    if (_tapped >= _level.targetTaps) {
      _levelClear();
      return;
    }
    _clock?.cancel();
    _spawnTimer?.cancel();
    setState(() {
      _visible = false;
      _message = '再试一次！';
    });
    _loseTimer = Timer(const Duration(milliseconds: 900), widget.onLose);
  }

  void _levelClear() {
    _clock?.cancel();
    _spawnTimer?.cancel();
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
  void dispose() {
    _clock?.cancel();
    _spawnTimer?.cancel();
    _loseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      title: '小鸡毛大作战',
      level: _levelIndex + 1,
      levelCount: _levels.length,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Positioned(
                top: 12,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    '$_tapped / ${_level.targetTaps}   •   ⏱ $_secondsLeft s',
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                ),
              ),
              if (_message != null)
                Positioned(
                  top: 60,
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
              if (_visible)
                Positioned(
                  left: _pos.dx * constraints.maxWidth - 28,
                  top: _pos.dy * constraints.maxHeight,
                  child: GestureDetector(
                    onTap: _onTapTarget,
                    child: const Text('🪶', style: TextStyle(fontSize: 52)),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
