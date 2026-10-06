import 'dart:async';
import '../../../games/game_timer.dart';
import 'package:flame/game.dart';
import '../../../games/mole_game.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/game_background.dart';
import '../../widgets/game_failure_overlay.dart';
import '../../widgets/explosion_overlay.dart';
import '../../widgets/game_intro_overlay.dart';

enum _HoleKind { clickable, bomb }

class _HoleItem {
  final _HoleKind kind;
  final String asset;
  const _HoleItem(this.kind, this.asset);
}

const _clickableAssets = [
  'assets/photos/game4_1.gif',
  'assets/photos/game4_2.gif',
  'assets/photos/game4_3.gif',
];
const _bombAsset = 'assets/photos/game4_boom.gif';
const _boomAsset = 'assets/photos/game4_booooom.gif';

/// Whack-a-mole: 布布 pop up at random holes, tap them fast to collect a
/// key. Tapping the bomb ends the round immediately — a big boom plays,
/// then a fail card offers a retry.
class GameFourScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onLose;
  final bool showIntro;

  const GameFourScreen({
    super.key,
    required this.onComplete,
    required this.onLose,
    this.showIntro = false,
  });

  @override
  State<GameFourScreen> createState() => _GameFourScreenState();
}

class _GameFourScreenState extends State<GameFourScreen>
    with WidgetsBindingObserver {
  static const _holeCount = 9;
  static const _goal = 30;
  static const _timeLimit = 30;
  static const _popDuration = Duration(milliseconds: 850);
  static const _spawnInterval = Duration(milliseconds: 650);
  static const _bombChance = 0.22;
  static const _boomDuration = Duration(milliseconds: 1200);

  late final MoleGame _field;
  bool _paused = false;
  bool _fieldReady = false;
  final _rnd = Random();
  late List<_HoleItem?> _holes;
  late List<Timer?> _hideTimers;
  int _score = 0;
  int _secondsLeft = _timeLimit;
  Timer? _spawnTimer;
  Timer? _clock;
  Timer? _boomTimer;
  Timer? _impactTimer;
  String? _message;
  bool _finished = false;
  bool _won = false;
  bool _exploding = false;
  bool _failedByBomb = false;
  bool _claimed = false;
  late bool _introDone;

  Timer _delay(Duration duration, void Function() callback) =>
      GameTimer(duration, callback, isPaused: () => _paused);
  Timer _repeat(Duration duration, void Function(Timer) callback) =>
      GameTimer.periodic(duration, callback, isPaused: () => _paused);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
    if (_paused) {
      _field.pauseEngine();
    } else {
      _field.resumeEngine();
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _field = MoleGame(
      spriteAssets: [..._clickableAssets, _bombAsset],
      onTap: _tapHole,
      onReady: _onFieldReady,
    );
    _introDone = !widget.showIntro;
    _holes = List.filled(_holeCount, null);
    _hideTimers = List.filled(_holeCount, null);
  }

  void _onIntroStart() {
    setState(() => _introDone = true);
    if (_fieldReady) _startLevel();
  }

  void _onFieldReady() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _fieldReady = true;
      if (_introDone) _startLevel();
    });
  }

  void _startLevel() {
    _spawnTimer?.cancel();
    _clock?.cancel();
    _boomTimer?.cancel();
    _impactTimer?.cancel();
    for (final t in _hideTimers) {
      t?.cancel();
    }
    setState(() {
      _holes = List.filled(_holeCount, null);
      _hideTimers = List.filled(_holeCount, null);
      _score = 0;
      _secondsLeft = _timeLimit;
      _message = null;
      _finished = false;
      _won = false;
      _exploding = false;
      _failedByBomb = false;
      _claimed = false;
    });
    _spawnTimer = _repeat(_spawnInterval, (_) => _spawn());
    _clock = _repeat(const Duration(seconds: 1), (_) {
      if (_finished) return;
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) _fail();
    });
  }

  void _spawn() {
    if (_finished) return;
    final empty = [
      for (int i = 0; i < _holeCount; i++)
        if (_holes[i] == null) i,
    ];
    if (empty.isEmpty) return;
    final index = empty[_rnd.nextInt(empty.length)];
    final item = _rnd.nextDouble() < _bombChance
        ? const _HoleItem(_HoleKind.bomb, _bombAsset)
        : _HoleItem(
            _HoleKind.clickable,
            _clickableAssets[_rnd.nextInt(_clickableAssets.length)],
          );
    setState(() => _holes[index] = item);
    _hideTimers[index] = _delay(_popDuration, () {
      if (!mounted) return;
      setState(() => _holes[index] = null);
    });
  }

  void _tapHole(int index) {
    if (!_fieldReady || _paused || _finished) return;
    final item = _holes[index];
    if (item == null) return;
    _hideTimers[index]?.cancel();
    setState(() => _holes[index] = null);

    if (item.kind == _HoleKind.clickable) {
      HapticFeedback.lightImpact();
      setState(() => _score++);
      if (_score >= _goal) _levelClear();
    } else {
      _hitBomb();
    }
  }

  void _hitBomb() {
    _finished = true;
    _spawnTimer?.cancel();
    _clock?.cancel();
    HapticFeedback.vibrate();
    _impactTimer = _delay(const Duration(milliseconds: 180), () {
      if (mounted && _exploding) HapticFeedback.heavyImpact();
    });
    for (final timer in _hideTimers) {
      timer?.cancel();
    }
    setState(() => _exploding = true);
    _boomTimer = _delay(_boomDuration, () {
      if (!mounted) return;
      setState(() {
        _exploding = false;
        _failedByBomb = true;
      });
    });
  }

  void _fail() {
    _finished = true;
    _spawnTimer?.cancel();
    _clock?.cancel();
    for (final timer in _hideTimers) {
      timer?.cancel();
    }
    setState(() {
      _failedByBomb = true;
      _message = '时间到啦！';
    });
  }

  void _levelClear() {
    _finished = true;
    _won = true;
    _spawnTimer?.cancel();
    _clock?.cancel();
    HapticFeedback.mediumImpact();
    setState(() => _message = null);
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    _clock?.cancel();
    _boomTimer?.cancel();
    _impactTimer?.cancel();
    for (final t in _hideTimers) {
      t?.cancel();
    }
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _field.items = _holes.map((item) => item?.asset).toList();
    _field.inputEnabled = _introDone && !_finished;
    _field.reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        GameBackground(
          title: '点击布布',
          level: 1,
          levelCount: 1,
          backgroundImage: 'assets/photos/game4.png',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '💗 $_score / $_goal',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '⏱ ${_secondsLeft}s',
                      style: TextStyle(
                        color: _secondsLeft <= 8
                            ? Colors.pinkAccent
                            : Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '点击布布',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  '不要点到炸弹哦～',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Expanded(
                  child: GameWidget(
                    game: _field,
                    loadingBuilder: (_) => const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFFBBD0),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
              ],
            ),
          ),
        ),
        if (_exploding) ExplosionOverlay(asset: _boomAsset),
        if (_failedByBomb)
          GameFailureOverlay(
            title: _message ?? '呀，点到炸弹啦！',
            onRetry: _startLevel,
            onExit: widget.onLose,
          ),
        if (_won)
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
                  const Icon(
                    Icons.vpn_key_rounded,
                    size: 52,
                    color: Color(0xFFFFBBD0),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    '钥匙到手啦！',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '成功集满布布 ♡',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: () {
                      if (_claimed) return;
                      _claimed = true;
                      widget.onComplete();
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFBBD0),
                      foregroundColor: const Color(0xFF392239),
                    ),
                    child: const Text('领取钥匙，回到小屋'),
                  ),
                ],
              ),
            ),
          ),
        if (!_introDone)
          GameIntroOverlay(
            title: '点击布布',
            instructionText:
                '布布会从格子里探出头来，快点点它们攒钥匙\n千万别点到炸弹，一点到就会失败哦\n$_timeLimit 秒内集满 $_goal 个布布就能拿到钥匙～',
            onStart: _onIntroStart,
          ),
      ],
    );
  }
}
