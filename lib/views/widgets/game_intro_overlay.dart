import 'dart:async';
import 'package:flutter/material.dart';
import '../../games/game_timer.dart';
import 'game_audio_scope.dart';

/// Full-screen intro shown the first time a game is opened: the title and
/// each line of the instructions appear one at a time, stacking on screen,
/// then a 3-2-1 countdown plays before handing control straight to the game
/// (a quick opacity fade, never a white flash).
class GameIntroOverlay extends StatefulWidget {
  final String title;
  final String instructionText;
  final VoidCallback onStart;
  final bool countdownOnly;

  const GameIntroOverlay({
    super.key,
    required this.title,
    required this.instructionText,
    required this.onStart,
    this.countdownOnly = false,
  });

  @override
  State<GameIntroOverlay> createState() => _GameIntroOverlayState();
}

class _GameIntroOverlayState extends State<GameIntroOverlay>
    with WidgetsBindingObserver {
  bool _paused = false;
  GameAudio? _audio;
  Timer _after(Duration duration, VoidCallback callback) =>
      GameTimer(duration, callback, isPaused: () => _paused);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _paused = state != AppLifecycleState.resumed;
  }

  void _sayCount() {
    GameAudioScope.effect(context, switch (_countdown) {
      3 => GameSound.ready3,
      2 => GameSound.ready2,
      1 => GameSound.ready1,
      _ => GameSound.start,
    });
  }

  static const _lineDelay = Duration(milliseconds: 900);
  static const _holdBeforeCountdown = Duration(milliseconds: 2000);
  static const _countdownStep = Duration(milliseconds: 700);
  static const _leaveFade = Duration(milliseconds: 220);

  late final List<String> _lines;
  int _visibleCount = 1;
  bool _counting = false;
  int _countdown = 3;
  bool _leaving = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _audio = GameAudioScope.of(context);
    _audio?.setIntroActive(true);
    WidgetsBinding.instance.addObserver(this);
    _lines = [
      widget.title,
      ...widget.instructionText.split('\n').where((l) => l.trim().isNotEmpty),
    ];
    if (widget.countdownOnly) {
      _timer = _after(Duration.zero, _beginCountdown);
    } else if (_lines.length > 1) {
      _scheduleNextLine();
    } else {
      _scheduleCountdown();
    }
  }

  void _scheduleNextLine() {
    _timer = _after(_lineDelay, () {
      if (!mounted) return;
      setState(() => _visibleCount++);
      if (_visibleCount < _lines.length) {
        _scheduleNextLine();
      } else {
        _scheduleCountdown();
      }
    });
  }

  void _beginCountdown() {
    if (!mounted) return;
    setState(() {
      _counting = true;
      _countdown = 3;
    });
    _sayCount();
    _tickCountdown();
  }

  void _scheduleCountdown() {
    _timer = _after(_holdBeforeCountdown, _beginCountdown);
  }

  void _tickCountdown() {
    _timer = _after(_countdownStep, () {
      if (!mounted) return;
      if (_countdown == 0) {
        setState(() => _leaving = true);
        _timer = _after(_leaveFade, () {
          if (mounted) widget.onStart();
        });
      } else {
        setState(() => _countdown--);
        _sayCount();
        _tickCountdown();
      }
    });
  }

  @override
  void dispose() {
    _audio?.setIntroActive(false);
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Material(
        type: MaterialType.transparency,
        child: AnimatedOpacity(
          opacity: _leaving ? 0 : 1,
          duration: _leaveFade,
          child: Container(
            color: Colors.black.withValues(alpha: 0.85),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: _counting ? _buildCountdown() : _buildLines(),
          ),
        ),
      ),
    );
  }

  Widget _buildLines() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < _visibleCount; i++)
          Padding(
            key: ValueKey(i),
            padding: const EdgeInsets.only(bottom: 14),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, child) =>
                  Opacity(opacity: value, child: child),
              child: Text(
                _lines[i],
                textAlign: TextAlign.center,
                style: i == 0
                    ? const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      )
                    : const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCountdown() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          '准备好了吗？',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          transitionBuilder: (child, anim) =>
              ScaleTransition(scale: anim, child: child),
          child: Text(
            switch (_countdown) {
              3 => 'THREE',
              2 => 'TWO',
              1 => 'ONE',
              _ => 'START',
            },
            key: ValueKey(_countdown),
            style: const TextStyle(
              color: Color(0xFFFFBBD0),
              fontSize: 60,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}
