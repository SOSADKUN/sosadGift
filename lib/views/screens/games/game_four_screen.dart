import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/game_background.dart';
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
const _failAsset = 'assets/photos/fail.gif';

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

class _GameFourScreenState extends State<GameFourScreen> {
  static const _holeCount = 9;
  static const _goal = 15;
  static const _timeLimit = 30;
  static const _popDuration = Duration(milliseconds: 850);
  static const _spawnInterval = Duration(milliseconds: 650);
  static const _bombChance = 0.22;
  static const _boomDuration = Duration(milliseconds: 1200);

  final _rnd = Random();
  late List<_HoleItem?> _holes;
  late List<Timer?> _hideTimers;
  int _score = 0;
  int _secondsLeft = _timeLimit;
  Timer? _spawnTimer;
  Timer? _clock;
  String? _message;
  bool _finished = false;
  bool _won = false;
  bool _exploding = false;
  bool _failedByBomb = false;
  bool _claimed = false;
  late bool _introDone;

  @override
  void initState() {
    super.initState();
    _introDone = !widget.showIntro;
    _holes = List.filled(_holeCount, null);
    _hideTimers = List.filled(_holeCount, null);
    if (_introDone) _startLevel();
  }

  void _onIntroStart() {
    setState(() => _introDone = true);
    _startLevel();
  }

  void _startLevel() {
    _spawnTimer?.cancel();
    _clock?.cancel();
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
    _spawnTimer = Timer.periodic(_spawnInterval, (_) => _spawn());
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
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
    _hideTimers[index] = Timer(_popDuration, () {
      if (!mounted) return;
      setState(() => _holes[index] = null);
    });
  }

  void _tapHole(int index) {
    if (_finished) return;
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
    HapticFeedback.heavyImpact();
    setState(() => _exploding = true);
    Timer(_boomDuration, () {
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
    setState(() => _message = '时间到啦，再试一次！');
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) widget.onLose();
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
    for (final t in _hideTimers) {
      t?.cancel();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                const Spacer(),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 3,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1,
                  children: List.generate(_holeCount, (i) {
                    final item = _holes[i];
                    return GestureDetector(
                      onTap: () => _tapHole(i),
                      child: Container(
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: AnimatedScale(
                            scale: item == null ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 140),
                            curve: Curves.easeOutBack,
                            child: item == null
                                ? const SizedBox.shrink()
                                : Padding(
                                    padding: const EdgeInsets.all(6),
                                    child: Image.asset(
                                      item.asset,
                                      fit: BoxFit.contain,
                                      gaplessPlayback: true,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
        if (_exploding)
          Positioned.fill(
            child: ColoredBox(
              color: Colors.black.withValues(alpha: 0.55),
              child: Center(
                child: Image.asset(
                  _boomAsset,
                  width: 220,
                  height: 220,
                  fit: BoxFit.contain,
                  gaplessPlayback: true,
                ),
              ),
            ),
          ),
        if (_failedByBomb)
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      _failAsset,
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    '呀，点到炸弹啦！',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '别灰心，回去再挑战一次吧～',
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _startLevel,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFFBBD0),
                      foregroundColor: const Color(0xFF392239),
                    ),
                    child: const Text('再试一次'),
                  ),
                  TextButton(
                    onPressed: () {
                      if (_claimed) return;
                      _claimed = true;
                      widget.onLose();
                    },
                    child: const Text(
                      '先回小屋',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              ),
            ),
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
