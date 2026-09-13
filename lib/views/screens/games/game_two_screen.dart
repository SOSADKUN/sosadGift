import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../widgets/game_background.dart';
import '../../widgets/game_intro_overlay.dart';

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

class _GameTwoScreenState extends State<GameTwoScreen> {
  static const _startLength = 3;
  static const _winLength = 7;
  static const _showDuration = Duration(milliseconds: 500);
  static const _gapDuration = Duration(milliseconds: 250);

  final _rnd = Random();
  final List<int> _sequence = [];
  int _inputIndex = 0;
  int _activePad = -1;
  bool _showingSequence = true;
  String? _message;
  bool _finished = false;
  late bool _introDone;
  Timer? _playTimer;

  @override
  void initState() {
    super.initState();
    _introDone = !widget.showIntro;
    if (_introDone) _startLevel();
  }

  void _onIntroStart() {
    setState(() => _introDone = true);
    _startLevel();
  }

  void _startLevel() {
    _playTimer?.cancel();
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
      _playTimer = Timer(_showDuration, () {
        if (!mounted) return;
        setState(() => _activePad = -1);
        step++;
        _playTimer = Timer(_gapDuration, showNext);
      });
    }

    showNext();
  }

  void _tapPad(int index) {
    if (_showingSequence || _finished) return;
    HapticFeedback.selectionClick();
    if (_sequence[_inputIndex] != index) {
      _fail();
      return;
    }
    setState(() => _activePad = index);
    Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _activePad = -1);
    });
    _inputIndex++;
    if (_inputIndex == _sequence.length) {
      if (_sequence.length >= _winLength) {
        _levelClear();
      } else {
        setState(
          () => _sequence.add(_rnd.nextInt(_pads.length)),
        );
        Timer(const Duration(milliseconds: 500), _playSequence);
      }
    }
  }

  void _fail() {
    _finished = true;
    HapticFeedback.heavyImpact();
    setState(() => _message = '记错顺序啦，再试一次！');
    Timer(const Duration(milliseconds: 900), () {
      if (mounted) widget.onLose();
    });
  }

  void _levelClear() {
    _finished = true;
    HapticFeedback.mediumImpact();
    setState(() => _message = '获得一把钥匙！🔑');
    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _playTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                  '第 ${_sequence.length - _startLength + 1} 关 · 共 '
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
                const Spacer(),
                GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.45,
                  children: List.generate(_pads.length, (i) {
                    final pad = _pads[i];
                    final active = _activePad == i;
                    return GestureDetector(
                      onTap: () => _tapPad(i),
                      child: AnimatedScale(
                        scale: active ? 1.08 : 1.0,
                        duration: const Duration(milliseconds: 120),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2D223C),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: active
                                  ? pad.color
                                  : Colors.white.withValues(alpha: 0.3),
                              width: active ? 3 : 1.5,
                            ),
                            boxShadow: active
                                ? [
                                    BoxShadow(
                                      color: pad.color.withValues(alpha: 0.7),
                                      blurRadius: 20,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : const [],
                          ),
                          child: AnimatedOpacity(
                            opacity: active ? 1.0 : 0.55,
                            duration: const Duration(milliseconds: 120),
                            child: Image.asset(
                              pad.asset,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
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
