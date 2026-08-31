import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_background.dart';

class _LevelConfig {
  final int targetTaps;
  final int seconds;
  final Duration moveDuration;
  const _LevelConfig({
    required this.targetTaps,
    required this.seconds,
    required this.moveDuration,
  });
}

/// Tap the feather while it's flying past — reach the target count before time's up.
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

class _GameOneScreenState extends State<GameOneScreen>
    with SingleTickerProviderStateMixin {
  static const _levels = [
    _LevelConfig(
        targetTaps: 10, seconds: 30, moveDuration: Duration(milliseconds: 1400)),
    _LevelConfig(
        targetTaps: 20, seconds: 30, moveDuration: Duration(milliseconds: 1000)),
    _LevelConfig(
        targetTaps: 30, seconds: 30, moveDuration: Duration(milliseconds: 700)),
  ];

  final _rnd = Random();
  late final AnimationController _moveController;

  int _levelIndex = 0;
  int _tapped = 0;
  int _secondsLeft = 0;
  Offset _startPos = const Offset(0.5, 0.5);
  Offset _endPos = const Offset(0.5, 0.5);
  bool _visible = true;
  String? _message;
  bool _showComplete = false;
  Timer? _clock;
  Timer? _respawnTimer;
  Timer? _loseTimer;

  _LevelConfig get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController(vsync: this)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && _visible) {
          // Wasn't tapped in time — vanish and try again, no penalty.
          setState(() => _visible = false);
          _respawnTimer = Timer(const Duration(milliseconds: 150), () {
            if (mounted && _secondsLeft > 0) _spawnTarget();
          });
        }
      });
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
    _respawnTimer?.cancel();
    final angle = _rnd.nextDouble() * 2 * pi;
    final distance = 0.25 + _rnd.nextDouble() * 0.3;
    final start = Offset(
      0.12 + _rnd.nextDouble() * 0.76,
      0.15 + _rnd.nextDouble() * 0.6,
    );
    final end = Offset(
      (start.dx + cos(angle) * distance).clamp(0.08, 0.92),
      (start.dy + sin(angle) * distance).clamp(0.12, 0.8),
    );
    setState(() {
      _startPos = start;
      _endPos = end;
      _visible = true;
    });
    _moveController
      ..duration = _level.moveDuration
      ..forward(from: 0);
  }

  void _onTapTarget() {
    if (!_visible) return;
    _moveController.stop();
    setState(() {
      _visible = false;
      _tapped++;
    });
    if (_tapped >= _level.targetTaps) {
      _levelClear();
    } else {
      _respawnTimer = Timer(const Duration(milliseconds: 120), _spawnTarget);
    }
  }

  void _timeUp() {
    if (_tapped >= _level.targetTaps) {
      _levelClear();
      return;
    }
    _clock?.cancel();
    _moveController.stop();
    _respawnTimer?.cancel();
    setState(() {
      _visible = false;
      _message = '再试一次！';
    });
    _loseTimer = Timer(const Duration(milliseconds: 900), widget.onLose);
  }

  void _levelClear() {
    _clock?.cancel();
    _moveController.stop();
    _respawnTimer?.cancel();
    if (_levelIndex >= _levels.length - 1) {
      setState(() {
        _visible = false;
        _showComplete = true;
      });
      Timer(const Duration(milliseconds: 2200), widget.onComplete);
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
    _respawnTimer?.cancel();
    _loseTimer?.cancel();
    _moveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      title: '小鸡毛大作战',
      level: _levelIndex + 1,
      levelCount: _levels.length,
      backgroundImage: 'assets/photos/game1.png',
      child: Stack(
        children: [
          LayoutBuilder(
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
                    AnimatedBuilder(
                      animation: _moveController,
                      builder: (context, _) {
                        final t = Curves.easeInOut.transform(_moveController.value);
                        final pos = Offset.lerp(_startPos, _endPos, t)!;
                        final popT =
                            Curves.easeOutBack.transform(t.clamp(0.0, 0.2) / 0.2);
                        return Positioned(
                          left: pos.dx * constraints.maxWidth - 28,
                          top: pos.dy * constraints.maxHeight - 28,
                          child: GestureDetector(
                            onTap: _onTapTarget,
                            child: Transform.scale(
                              scale: popT,
                              child: Image.asset(
                                'assets/photos/jimao.gif',
                                width: 56,
                                height: 56,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                ],
              );
            },
          ),
          if (_showComplete)
            Positioned.fill(
              child: Container(
                color: Colors.black87,
                alignment: Alignment.center,
                child: Image.asset('assets/photos/complete.gif', width: 240),
              ),
            ),
        ],
      ),
    );
  }
}
