import 'dart:async';
import '../../../games/game_timer.dart';
import 'package:flame/game.dart';
import '../../../games/memory_pad_game.dart';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/game_background.dart';
import '../../widgets/game_failure_overlay.dart';
import '../../widgets/game_intro_overlay.dart';
import '../../widgets/game_key_reward_overlay.dart';

class _Pad {
  final Color color;
  final String asset;
  const _Pad(this.color, this.asset);
}

const _pads = [
  _Pad(Color(0xFFFF6FA5), 'assets/photos/game2_1.gif'),
  _Pad(Color(0xFFFFC857), 'assets/photos/game2_2.gif'),
  _Pad(Color(0xFF8E7CFF), 'assets/photos/game2_3.gif'),
  _Pad(Color(0xFF5FD3A6), 'assets/photos/game2_4.gif'),
  _Pad(Color(0xFF5AC8FA), 'assets/photos/game2_5.gif'),
  _Pad(Color(0xFFFF8A5B), 'assets/photos/game2_6.gif'),
];

/// Simon-style memory game: watch the pattern light up, then repeat it by
/// tapping the pads in the same order. Each round adds one more step.
class GameTwoScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final VoidCallback onLose;
  final bool showIntro;

  const GameTwoScreen({
    super.key,
    required this.onComplete,
    required this.onLose,
    this.showIntro = false,
  });

  @override
  State<GameTwoScreen> createState() => _GameTwoScreenState();
}

class _GameTwoScreenState extends State<GameTwoScreen>
    with WidgetsBindingObserver {
  static const _startLength = 3;
  static const _winLength = 7;
  static const _showDuration = Duration(milliseconds: 500);
  static const _gapDuration = Duration(milliseconds: 250);

  late final MemoryPadGame _field;
  bool _paused = false;
  bool _fieldReady = false;
  final _rnd = Random();
  final List<int> _sequence = [];
  int _inputIndex = 0;
  int _activePad = -1;
  bool _showingSequence = true;
  String? _message;
  bool _finished = false;
  bool _failed = false;
  Timer? _nextRoundTimer;
  Timer? _padTimer;
  late bool _introDone;
  Timer? _playTimer;
  bool _won = false;
  bool _claimed = false;

  Timer _delay(Duration duration, void Function() callback) =>
      GameTimer(duration, callback, isPaused: () => _paused);

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
    _field = MemoryPadGame(
      spriteAssets: _pads.map((p) => p.asset).toList(),
      colors: _pads.map((p) => p.color).toList(),
      onTap: _tapPad,
      onReady: _onFieldReady,
    );
    _introDone = !widget.showIntro;
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
    _playTimer?.cancel();
    _nextRoundTimer?.cancel();
    _padTimer?.cancel();
    _failed = false;
    _won = false;
    _claimed = false;
    _sequence
      ..clear()
      ..addAll(List.generate(_startLength, (_) => _rnd.nextInt(_pads.length)));
    _inputIndex = 0;
    _finished = false;
    _message = null;
    _playSequence();
  }

  void _playSequence() {
    setState(() {
      _showingSequence = true;
      _inputIndex = 0;
      _message = null;
    });
    int step = 0;
    void showNext() {
      if (!mounted) return;
      if (step >= _sequence.length) {
        setState(() {
          _activePad = -1;
          _showingSequence = false;
        });
        return;
      }
      setState(() => _activePad = _sequence[step]);
      _playTimer = _delay(_showDuration, () {
        if (!mounted) return;
        setState(() => _activePad = -1);
        step++;
        _playTimer = _delay(_gapDuration, showNext);
      });
    }

    showNext();
  }

  void _tapPad(int index) {
    if (!_fieldReady || _paused || _showingSequence || _finished) return;
    HapticFeedback.selectionClick();
    if (_sequence[_inputIndex] != index) {
      _fail();
      return;
    }
    setState(() => _activePad = index);
    _padTimer?.cancel();
    _padTimer = _delay(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _activePad = -1);
    });
    _inputIndex++;
    if (_inputIndex == _sequence.length) {
      if (_sequence.length >= _winLength) {
        _levelClear();
      } else {
        setState(() => _sequence.add(_rnd.nextInt(_pads.length)));
        _showingSequence = true;
        _nextRoundTimer = _delay(const Duration(milliseconds: 500), () {
          if (mounted && !_finished) _playSequence();
        });
      }
    }
  }

  void _fail() {
    _playTimer?.cancel();
    _nextRoundTimer?.cancel();
    _padTimer?.cancel();
    HapticFeedback.heavyImpact();
    setState(() {
      _finished = true;
      _failed = true;
    });
  }

  void _levelClear() {
    _playTimer?.cancel();
    _nextRoundTimer?.cancel();
    _padTimer?.cancel();
    HapticFeedback.mediumImpact();
    setState(() {
      _finished = true;
      _won = true;
      _activePad = -1;
      _message = null;
    });
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    _nextRoundTimer?.cancel();
    _padTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _field.activePad = _activePad;
    _field.inputEnabled = _introDone && !_showingSequence && !_finished;
    _field.reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Stack(
      children: [
        GameBackground(
          title: '心动记忆',
          level: 1,
          levelCount: 1,
          backgroundImage: 'assets/photos/game2.png',
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Text(
                  _showingSequence ? '仔细看好顺序～' : '轮到你啦，跟着点一遍',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '第 ${max(1, _sequence.length - _startLength + 1)} 关 · 共 '
                  '${_winLength - _startLength + 1} 关',
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                if (_message != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _message!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
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
        if (_won)
          GameKeyRewardOverlay(
            message: '5 / 5 关 · 全部记对了，太厉害了 ♡',
            onClaim: () {
              if (_claimed) return;
              _claimed = true;
              widget.onComplete();
            },
          ),
        if (_failed)
          GameFailureOverlay(
            title: '记错顺序啦！',
            onRetry: _startLevel,
            onExit: widget.onLose,
          ),
        if (!_introDone)
          GameIntroOverlay(
            title: '心动记忆',
            instructionText:
                '看好卡片亮起的顺序\n轮到你时，按同样的顺序点一遍\n每过一关顺序会变长一点，坚持到第 5 关就赢啦～',
            onStart: _onIntroStart,
          ),
      ],
    );
  }
}
