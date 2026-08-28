import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../../widgets/game_background.dart';

enum _ItemType { heart, bomb }

class _FallingItem {
  final _ItemType type;
  final double x; // 0..1
  double y = 0; // 0..1
  _FallingItem({required this.type, required this.x});
}

class _LevelConfig {
  final int heartsNeeded;
  final int lives;
  final double speed; // fraction of screen height per tick
  final Duration spawnInterval;
  const _LevelConfig({
    required this.heartsNeeded,
    required this.lives,
    required this.speed,
    required this.spawnInterval,
  });
}

/// Drag the basket to catch falling hearts and dodge the bombs.
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
  static const _levels = [
    _LevelConfig(
        heartsNeeded: 8,
        lives: 3,
        speed: 0.006,
        spawnInterval: Duration(milliseconds: 900)),
    _LevelConfig(
        heartsNeeded: 10,
        lives: 3,
        speed: 0.008,
        spawnInterval: Duration(milliseconds: 750)),
    _LevelConfig(
        heartsNeeded: 12,
        lives: 2,
        speed: 0.010,
        spawnInterval: Duration(milliseconds: 620)),
  ];

  static const _basketWidth = 0.22;
  static const _basketY = 0.86;
  static const _catchBandTop = 0.80;
  static const _catchBandBottom = 0.92;

  final _rnd = Random();
  int _levelIndex = 0;
  int _caught = 0;
  int _lives = 0;
  double _basketX = 0.5;
  final List<_FallingItem> _items = [];
  Timer? _ticker;
  Timer? _spawner;
  Timer? _loseTimer;
  String? _message;
  bool _busy = false;

  _LevelConfig get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _startLevel();
  }

  void _startLevel() {
    _items.clear();
    _caught = 0;
    _lives = _level.lives;
    _message = null;
    _busy = false;
    _ticker?.cancel();
    _spawner?.cancel();
    _ticker = Timer.periodic(const Duration(milliseconds: 16), _tick);
    _spawner = Timer.periodic(_level.spawnInterval, (_) => _spawnItem());
  }

  void _spawnItem() {
    if (_busy) return;
    final isBomb = _rnd.nextDouble() < 0.28;
    _items.add(_FallingItem(
      type: isBomb ? _ItemType.bomb : _ItemType.heart,
      x: 0.08 + _rnd.nextDouble() * 0.84,
    ));
  }

  void _tick(Timer timer) {
    if (_busy) return;
    setState(() {
      for (final item in _items) {
        item.y += _level.speed;
      }
      for (final item in List.of(_items)) {
        final inBand = item.y >= _catchBandTop && item.y <= _catchBandBottom;
        final inBasket = (item.x - _basketX).abs() <= _basketWidth / 2;
        if (inBand && inBasket) {
          _items.remove(item);
          if (item.type == _ItemType.heart) {
            _caught++;
            if (_caught >= _level.heartsNeeded) {
              _levelClear();
              return;
            }
          } else {
            _lives--;
            if (_lives <= 0) {
              _fail();
              return;
            }
          }
        }
      }
      _items.removeWhere((item) => item.y > 1.05);
    });
  }

  void _fail() {
    _busy = true;
    _ticker?.cancel();
    _spawner?.cancel();
    _message = '再试一次！';
    _loseTimer = Timer(const Duration(milliseconds: 900), widget.onLose);
  }

  void _levelClear() {
    _busy = true;
    _ticker?.cancel();
    _spawner?.cancel();
    if (_levelIndex >= _levels.length - 1) {
      _message = '通关啦！🎉';
      Timer(const Duration(milliseconds: 700), widget.onComplete);
    } else {
      _message = 'Level ${_levelIndex + 1} 完成！';
      Timer(const Duration(milliseconds: 900), () {
        if (!mounted) return;
        setState(() => _levelIndex++);
        _startLevel();
      });
    }
  }

  void _moveBasketTo(double fractionX) {
    setState(() => _basketX = fractionX.clamp(0.08, 0.92));
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _spawner?.cancel();
    _loseTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameBackground(
      title: '接爱心',
      level: _levelIndex + 1,
      levelCount: _levels.length,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (details) => _moveBasketTo(
                _basketX + details.delta.dx / constraints.maxWidth),
            onTapDown: (details) => _moveBasketTo(
                details.localPosition.dx / constraints.maxWidth),
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Text(
                      '💗 $_caught / ${_level.heartsNeeded}   •   ❤️‍🔥 $_lives',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
                if (_message != null)
                  Positioned(
                    top: 50,
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
                for (final item in _items)
                  Positioned(
                    left: item.x * constraints.maxWidth - 16,
                    top: item.y * constraints.maxHeight,
                    child: Text(
                      item.type == _ItemType.heart ? '💗' : '💣',
                      style: const TextStyle(fontSize: 30),
                    ),
                  ),
                Positioned(
                  left: _basketX * constraints.maxWidth - 28,
                  top: _basketY * constraints.maxHeight - 28,
                  child: const Text('🧺', style: TextStyle(fontSize: 56)),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
