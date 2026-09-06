import 'dart:async';
import 'package:flutter/material.dart';

/// Full-screen intro shown the first time a game is opened: the title and
/// each line of the instructions appear one at a time, stacking on screen,
/// then the screen fades to white before handing control to the game.
class GameIntroOverlay extends StatefulWidget {
  final String title;
  final String instructionText;
  final VoidCallback onStart;

  const GameIntroOverlay({
    super.key,
    required this.title,
    required this.instructionText,
    required this.onStart,
  });

  @override
  State<GameIntroOverlay> createState() => _GameIntroOverlayState();
}

class _GameIntroOverlayState extends State<GameIntroOverlay> {
  static const _lineDelay = Duration(milliseconds: 900);
  static const _holdBeforeWhiteOut = Duration(milliseconds: 1100);
  static const _whiteFade = Duration(milliseconds: 1100);

  late final List<String> _lines;
  int _visibleCount = 1;
  bool _whiteOut = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _lines = [
      widget.title,
      ...widget.instructionText.split('\n').where((l) => l.trim().isNotEmpty),
    ];
    if (_lines.length > 1) {
      _scheduleNextLine();
    } else {
      _scheduleWhiteOut();
    }
  }

  void _scheduleNextLine() {
    _timer = Timer(_lineDelay, () {
      if (!mounted) return;
      setState(() => _visibleCount++);
      if (_visibleCount < _lines.length) {
        _scheduleNextLine();
      } else {
        _scheduleWhiteOut();
      }
    });
  }

  void _scheduleWhiteOut() {
    _timer = Timer(_holdBeforeWhiteOut, () {
      if (!mounted) return;
      setState(() => _whiteOut = true);
      _timer = Timer(_whiteFade, () {
        if (mounted) widget.onStart();
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Stack(
        children: [
          Container(
            color: Colors.black.withValues(alpha: 0.85),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
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
            ),
          ),
          IgnorePointer(
            child: AnimatedOpacity(
              opacity: _whiteOut ? 1 : 0,
              duration: _whiteFade,
              curve: Curves.easeIn,
              child: Container(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
