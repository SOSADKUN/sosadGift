import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../../widgets/game_background.dart';
import '../../widgets/game_intro_overlay.dart';

/// A platform, in fractional world coordinates (0..1 of the play area).
class _Platform {
  final double x;
  final double y;
  final double width;
  const _Platform(this.x, this.y, this.width);
  static const height = 0.035;
}

class _LevelConfig {
  final List<_Platform> platforms;
  final List<Offset> stars;
  final Offset start;
  const _LevelConfig({
    required this.platforms,
    required this.stars,
    required this.start,
  });
}

/// 2D side-scroller: move with on-screen left/right/jump controls and
/// collect every star without falling into a pit.
class GameThreeScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onLose;
  final bool showIntro;

  const GameThreeScreen({
    super.key,
    required this.onComplete,
    required this.onLose,
    this.showIntro = false,
  });

  @override
  State<GameThreeScreen> createState() => _GameThreeScreenState();
}

class _GameThreeScreenState extends State<GameThreeScreen>
    with SingleTickerProviderStateMixin {
  static const _playerW = 0.09;
  static const _playerH = 0.09;
  static const _gravity = 2.6;
  static const _jumpVelocity = -1.35;
  static const _moveSpeed = 0.55;
  static const _fallLimit = 1.15;
  static const _starRadius = 0.06;

  static final _levels = [
    _LevelConfig(
      start: const Offset(0.05, 0.78),
      platforms: const [
        _Platform(0, 0.92, 1.0),
        _Platform(0.12, 0.68, 0.24),
        _Platform(0.64, 0.55, 0.26),
      ],
      stars: const [
        Offset(0.22, 0.635),
        Offset(0.76, 0.505),
        Offset(0.5, 0.87),
      ],
    ),
    _LevelConfig(
      start: const Offset(0.05, 0.78),
      platforms: const [
        _Platform(0, 0.92, 0.34),
        _Platform(0.55, 0.92, 0.45),
        _Platform(0.37, 0.74, 0.2),
        _Platform(0.12, 0.58, 0.2),
      ],
      stars: const [
        Offset(0.47, 0.695),
        Offset(0.22, 0.535),
        Offset(0.82, 0.875),
      ],
    ),
    _LevelConfig(
      start: const Offset(0.03, 0.78),
      platforms: const [
        _Platform(0, 0.92, 0.24),
        _Platform(0.4, 0.92, 0.2),
        _Platform(0.75, 0.92, 0.25),
        _Platform(0.21, 0.72, 0.18),
        _Platform(0.57, 0.72, 0.18),
        _Platform(0.38, 0.5, 0.2),
      ],
      stars: const [
        Offset(0.30, 0.675),
        Offset(0.66, 0.675),
        Offset(0.48, 0.455),
        Offset(0.86, 0.875),
      ],
    ),
  ];

  late Ticker _ticker;
  Duration _lastElapsed = Duration.zero;
  double _worldW = 320;
  double _worldH = 520;

  int _levelIndex = 0;
  double _px = 0;
  double _py = 0;
  double _vy = 0;
  bool _grounded = false;
  bool _movingLeft = false;
  bool _movingRight = false;
  late List<bool> _starCollected;
  int _collectedCount = 0;
  String? _message;
  bool _finished = false;
  late bool _introDone;

  _LevelConfig get _level => _levels[_levelIndex];

  @override
  void initState() {
    super.initState();
    _introDone = !widget.showIntro;
    _ticker = createTicker(_onTick);
    _resetLevelState();
    if (_introDone) _ticker.start();
  }

  void _onIntroStart() {
    setState(() => _introDone = true);
    _ticker.start();
  }

  void _resetLevelState() {
    _px = _level.start.dx;
    _py = _level.start.dy;
    _vy = 0;
    _grounded = false;
    _movingLeft = false;
    _movingRight = false;
    _starCollected = List.filled(_level.stars.length, false);
    _collectedCount = 0;
    _message = null;
    _finished = false;
    _lastElapsed = Duration.zero;
  }

  void _onTick(Duration elapsed) {
    if (_finished || !_introDone) {
      _lastElapsed = elapsed;
      return;
    }
    if (_lastElapsed == Duration.zero) {
      _lastElapsed = elapsed;
      return;
    }
    final dt = ((elapsed - _lastElapsed).inMicroseconds / 1e6).clamp(0.0, 0.032);
    _lastElapsed = elapsed;
    if (dt > 0) _update(dt);
  }

  void _update(double dt) {
    final vx = _movingLeft && !_movingRight
        ? -_moveSpeed
        : (_movingRight && !_movingLeft ? _moveSpeed : 0.0);
    final newX = (_px + vx * dt).clamp(0.0, 1.0 - _playerW);

    var vy = _vy + _gravity * dt;
    final newY = _py + vy * dt;

    final playerLeft = newX;
    final playerRight = newX + _playerW;
    final bottomPrev = _py + _playerH;
    final bottomNew = newY + _playerH;

    bool grounded = false;
    double resolvedY = newY;
    if (vy >= 0) {
      for (final p in _level.platforms) {
        final platLeft = p.x;
        final platRight = p.x + p.width;
        final platTop = p.y;
        final overlaps = playerRight > platLeft && playerLeft < platRight;
        if (overlaps && bottomPrev <= platTop + 0.01 && bottomNew >= platTop) {
          resolvedY = platTop - _playerH;
          vy = 0;
          grounded = true;
          break;
        }
      }
    }

    for (int i = 0; i < _level.stars.length; i++) {
      if (_starCollected[i]) continue;
      final s = _level.stars[i];
      final dx = (s.dx - (newX + _playerW / 2)).abs();
      final dy = (s.dy - (resolvedY + _playerH / 2)).abs();
      if (dx < _starRadius && dy < _starRadius) {
        _starCollected[i] = true;
        _collectedCount++;
      }
    }

    setState(() {
      _px = newX;
      _py = resolvedY;
      _vy = vy;
      _grounded = grounded;
    });

    if (_collectedCount >= _level.stars.length) {
      _levelClear();
      return;
    }
    if (resolvedY > _fallLimit) {
      _fail();
    }
  }

  void _jump() {
    if (!_grounded || _finished) return;
    setState(() {
      _vy = _jumpVelocity;
      _grounded = false;
    });
  }

  void _fail() {
    _finished = true;
    setState(() => _message = '掉下去了，再试一次！');
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
        setState(() {
          _levelIndex++;
          _resetLevelState();
        });
      });
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Widget _controlButton(IconData icon,
      {required VoidCallback onPress, VoidCallback? onDown, VoidCallback? onUp}) {
    return GestureDetector(
      onTapDown: onDown == null ? null : (_) => onDown(),
      onTapUp: onUp == null ? null : (_) => onUp(),
      onTapCancel: onUp,
      onTap: onDown == null ? onPress : null,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.25),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white38),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameBackground(
          title: '星星大冒险',
          level: _levelIndex + 1,
          levelCount: _levels.length,
          backgroundImage: 'assets/photos/game3.png',
          child: LayoutBuilder(
            builder: (context, constraints) {
              _worldW = constraints.maxWidth;
              _worldH = constraints.maxHeight;
              return Stack(
                children: [
                  Positioned(
                    top: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Text(
                        '⭐ $_collectedCount / ${_level.stars.length}',
                        style: const TextStyle(color: Colors.white, fontSize: 18),
                      ),
                    ),
                  ),
                  if (_message != null)
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Text(
                          _message!,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  for (final p in _level.platforms)
                    Positioned(
                      left: p.x * _worldW,
                      top: p.y * _worldH,
                      width: p.width * _worldW,
                      height: _Platform.height * _worldH,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: const Color(0xFF8D6748),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.white24),
                        ),
                      ),
                    ),
                  for (int i = 0; i < _level.stars.length; i++)
                    if (!_starCollected[i])
                      Positioned(
                        left: _level.stars[i].dx * _worldW - 12,
                        top: _level.stars[i].dy * _worldH - 12,
                        child: const Text('⭐', style: TextStyle(fontSize: 24)),
                      ),
                  Positioned(
                    left: _px * _worldW,
                    top: _py * _worldH,
                    width: _playerW * _worldW,
                    height: _playerH * _worldH,
                    child: const Center(
                      child: Text('🐥', style: TextStyle(fontSize: 32)),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 16,
                    child: Row(
                      children: [
                        _controlButton(
                          Icons.arrow_back,
                          onPress: () {},
                          onDown: () => _movingLeft = true,
                          onUp: () => _movingLeft = false,
                        ),
                        const SizedBox(width: 12),
                        _controlButton(
                          Icons.arrow_forward,
                          onPress: () {},
                          onDown: () => _movingRight = true,
                          onUp: () => _movingRight = false,
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: _controlButton(
                      Icons.arrow_upward,
                      onPress: _jump,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (!_introDone)
          GameIntroOverlay(
            title: '星星大冒险',
            instructionText:
                '星星大冒险～ 用左右按钮移动，跳跃按钮起跳\n收集地图上所有星星就过关\n小心别掉进坑里哦～',
            onStart: _onIntroStart,
          ),
      ],
    );
  }
}
