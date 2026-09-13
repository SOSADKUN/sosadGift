import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/game_background.dart';
import '../../widgets/game_intro_overlay.dart';

/// One friendly round: catch 30 feathers in 30 seconds to earn one key.
class GameOneScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onLose;
  final bool showIntro;
  const GameOneScreen({
    super.key,
    required this.onComplete,
    required this.onLose,
    this.showIntro = false,
  });

  @override
  State<GameOneScreen> createState() => _GameOneScreenState();
}

class _GameOneScreenState extends State<GameOneScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _goal = 30;
  final _random = Random();
  final _elapsed = Stopwatch();
  late final AnimationController _float;
  Timer? _clock;
  Timer? _respawn;
  late bool _introDone;
  int _count = 0;
  int _seconds = 30;
  int _ready = 3;
  bool _visible = false;
  bool _finished = false;
  bool _claimed = false;
  bool _paused = false;
  Offset _position = const Offset(0.5, 0.5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _float = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
    _introDone = !widget.showIntro;
    if (_introDone) _start();
  }

  void _onIntroStart() {
    setState(() => _introDone = true);
    // The intro overlay already played its own 3-2-1 countdown.
    _start(withReadyCountdown: false);
  }

  void _start({bool withReadyCountdown = true}) {
    _clock?.cancel();
    _respawn?.cancel();
    _elapsed
      ..reset()
      ..stop();
    setState(() {
      _count = 0;
      _seconds = 30;
      _ready = withReadyCountdown ? 3 : 0;
      _finished = false;
      _visible = false;
      _claimed = false;
    });
    if (!withReadyCountdown) {
      _elapsed.start();
      _spawn();
      _clock = Timer.periodic(
        const Duration(milliseconds: 100),
        (_) => _tick(),
      );
      return;
    }
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_paused) return;
      setState(() => _ready--);
      if (_ready == 0) {
        _clock?.cancel();
        _elapsed.start();
        _spawn();
        _clock = Timer.periodic(
          const Duration(milliseconds: 100),
          (_) => _tick(),
        );
      }
    });
  }

  void _tick() {
    if (_paused || _finished) return;
    final remaining = max(0, 30 - _elapsed.elapsed.inSeconds);
    if (remaining != _seconds) setState(() => _seconds = remaining);
    if (_elapsed.elapsedMilliseconds >= 30000) _finish(false);
  }

  void _spawn() {
    if (!mounted || _finished) return;
    setState(() {
      _position = Offset(_random.nextDouble(), _random.nextDouble());
      _visible = true;
    });
  }

  void _hit() {
    if (!_visible || _finished || _paused || _ready > 0) return;
    if (_elapsed.elapsedMilliseconds >= 30000) {
      _finish(false);
      return;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _count++;
      _visible = false;
    });
    if (_count == _goal) {
      _finish(true);
    } else {
      _respawn = Timer(const Duration(milliseconds: 100), _spawn);
    }
  }

  void _finish(bool won) {
    if (_finished) return;
    _clock?.cancel();
    _respawn?.cancel();
    _elapsed.stop();
    setState(() {
      _finished = true;
      _visible = false;
    });
    if (won) HapticFeedback.mediumImpact();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _elapsed.stop();
    } else if (_introDone && _ready == 0 && !_finished) {
      _elapsed.start();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock?.cancel();
    _respawn?.cancel();
    _elapsed.stop();
    _float.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pink = Color(0xFFFFBBD0);
    return Stack(
      children: [
        GameBackground(
          title: '小鸡毛大作战',
          level: 1,
          levelCount: 1,
          backgroundImage: 'assets/photos/game1.png',
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xE62D223C),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: pink.withValues(alpha: 0.4)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '抓住小鸡毛',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '⏱ ${_seconds}s',
                          style: TextStyle(
                            color: _seconds <= 5 ? pink : Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: Text(
                            '$_count',
                            key: ValueKey(_count),
                            style: const TextStyle(
                              fontSize: 42,
                              fontWeight: FontWeight.w800,
                              color: pink,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: Text(
                            ' / 30',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _count == 0
                              ? '30 秒 · 一把钥匙'
                              : '真棒！还差 ${30 - _count} 个',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: _count / _goal,
                        minHeight: 8,
                        color: pink,
                        backgroundColor: Colors.white12,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, box) {
                    final targetSize = min(
                      112.0,
                      min(box.maxWidth, box.maxHeight),
                    );
                    return Stack(
                      children: [
                        if (!_finished && _ready == 0)
                          const Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding: EdgeInsets.only(bottom: 18),
                              child: Text(
                                '点一下，抓住它 ♡',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        if (_visible)
                          AnimatedBuilder(
                            animation: _float,
                            builder: (context, _) {
                              final reducedMotion =
                                  MediaQuery.disableAnimationsOf(context);
                              final phase = _float.value * pi * 2;
                              // A continuous flying loop, safely inside the play area.
                              final x =
                                  0.20 +
                                  _position.dx * 0.60 +
                                  (reducedMotion ? 0.0 : sin(phase) * 0.18);
                              final y =
                                  0.16 +
                                  _position.dy * 0.68 +
                                  (reducedMotion ? 0.0 : cos(phase) * 0.14);
                              return Positioned(
                                left: x * max(0, box.maxWidth - targetSize),
                                top:
                                    y * max(0, box.maxHeight - targetSize - 44),
                                child: Semantics(
                                  button: true,
                                  label: '抓住小鸡毛',
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _hit,
                                    child: Container(
                                      width: targetSize,
                                      height: targetSize,
                                      padding: const EdgeInsets.all(12),
                                      child: Image.asset(
                                        'assets/photos/jimao.gif',
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        if (_ready > 0 && !_finished)
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text(
                                  '准备好了吗？',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                  ),
                                ),
                                Text(
                                  '$_ready',
                                  style: const TextStyle(
                                    color: pink,
                                    fontSize: 88,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (_finished)
                          Center(
                            child: Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: const Color(0xF22D223C),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _count == _goal
                                        ? Icons.vpn_key_rounded
                                        : Icons.favorite_rounded,
                                    size: 52,
                                    color: pink,
                                  ),
                                  const SizedBox(height: 14),
                                  Text(
                                    _count == _goal
                                        ? '钥匙到手啦！'
                                        : '已经抓到 $_count 个！',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _count == _goal
                                        ? '30 / 30 · 太厉害了 ♡'
                                        : '差一点点，再来一次吧 ♡',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  FilledButton(
                                    onPressed: () {
                                      if (_count == _goal) {
                                        if (_claimed) return;
                                        _claimed = true;
                                        widget.onComplete();
                                      } else {
                                        _start();
                                      }
                                    },
                                    style: FilledButton.styleFrom(
                                      backgroundColor: pink,
                                      foregroundColor: const Color(0xFF392239),
                                    ),
                                    child: Text(
                                      _count == _goal ? '领取钥匙，回到小屋' : '再试一次',
                                    ),
                                  ),
                                  if (_count != _goal)
                                    TextButton(
                                      onPressed: widget.onLose,
                                      child: const Text(
                                        '先回小屋',
                                        style: TextStyle(color: Colors.white70),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        if (!_introDone)
          GameIntroOverlay(
            title: '小鸡毛大作战',
            instructionText:
                '30 秒内，点到 30 个小鸡毛！\n小鸡毛会飞来飞去，点中会轻轻震动～\n完成就能拿到一把钥匙 ♡',
            onStart: _onIntroStart,
          ),
      ],
    );
  }
}
