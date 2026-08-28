import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'game_one_screen.dart';
import 'game_two_screen.dart';
import 'game_three_screen.dart';
import 'game_four_screen.dart';

enum _Mood { none, sad, celebrate }

class GameHubScreen extends StatefulWidget {
  final VoidCallback onAllGamesComplete;

  const GameHubScreen({super.key, required this.onAllGamesComplete});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  // Add/remove games here — one door per entry, in door order
  // [top-left, top-right, bottom-left, bottom-right].
  late final List<Widget Function(VoidCallback onComplete, VoidCallback onLose)>
      _games = [
    (onComplete, onLose) =>
        GameOneScreen(onComplete: onComplete, onLose: onLose),
    (onComplete, onLose) => GameTwoScreen(onComplete: onComplete),
    (onComplete, onLose) =>
        GameThreeScreen(onComplete: onComplete, onLose: onLose),
    (onComplete, onLose) =>
        GameFourScreen(onComplete: onComplete, onLose: onLose),
  ];

  final Set<int> _solved = {};
  _Mood _mood = _Mood.none;
  Timer? _moodTimer;

  void _openGame(int index) async {
    if (_solved.contains(index)) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _games[index](
          () => _completeGame(index),
          () => _loseGame(index),
        ),
      ),
    );
  }

  void _completeGame(int index) {
    Navigator.of(context).pop();
    setState(() {
      _solved.add(index);
      _mood = _Mood.celebrate;
    });
    _resetMoodAfter(const Duration(seconds: 2));

    if (_solved.length == _games.length) {
      Future.delayed(const Duration(milliseconds: 1200), widget.onAllGamesComplete);
    }
  }

  void _loseGame(int index) {
    Navigator.of(context).pop();
    setState(() => _mood = _Mood.sad);
    _resetMoodAfter(const Duration(seconds: 2));
  }

  void _resetMoodAfter(Duration duration) {
    _moodTimer?.cancel();
    _moodTimer = Timer(duration, () {
      if (mounted) setState(() => _mood = _Mood.none);
    });
  }

  @override
  void dispose() {
    _moodTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E1A3C), Color(0xFF4B2354), Color(0xFF6B2D5C)],
        ),
      ),
      child: Stack(
        children: [
          const Positioned(top: 40, left: 24, child: _Sparkle('⭐', 18)),
          const Positioned(top: 90, right: 30, child: _Sparkle('✨', 16)),
          const Positioned(bottom: 90, left: 36, child: _Sparkle('⭐', 14)),
          const Positioned(bottom: 140, right: 24, child: _Sparkle('✨', 20)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '🔑 ${_solved.length} / ${_games.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      Center(
                        child: _HubCharacter(
                            winCount: _solved.length, mood: _mood),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _GameDoor(
                          number: 1,
                          solved: _solved.contains(0),
                          onTap: () => _openGame(0),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: _GameDoor(
                          number: 2,
                          solved: _solved.contains(1),
                          onTap: () => _openGame(1),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        left: 12,
                        child: _GameDoor(
                          number: 3,
                          solved: _solved.contains(2),
                          onTap: () => _openGame(2),
                        ),
                      ),
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: _GameDoor(
                          number: 4,
                          solved: _solved.contains(3),
                          onTap: () => _openGame(3),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sparkle extends StatelessWidget {
  final String emoji;
  final double size;
  const _Sparkle(this.emoji, this.size);

  @override
  Widget build(BuildContext context) {
    return Text(emoji, style: TextStyle(fontSize: size));
  }
}

/// Placeholder character portrait — swap the emoji for a GIF asset later.
/// Gets happier as more doors are solved; flashes sad/celebrate on lose/win.
class _HubCharacter extends StatelessWidget {
  final int winCount;
  final _Mood mood;
  const _HubCharacter({required this.winCount, required this.mood});

  static const _faces = ['😐', '🙂', '😊', '😄', '🥳'];

  String get _face {
    switch (mood) {
      case _Mood.sad:
        return '😢';
      case _Mood.celebrate:
        return '🥳';
      case _Mood.none:
        return _faces[winCount.clamp(0, _faces.length - 1)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.white.withValues(alpha: 0.04),
          ],
        ),
        border: Border.all(color: Colors.white38, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.pinkAccent.withValues(alpha: 0.25),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: Text(
          _face,
          key: ValueKey(_face),
          style: const TextStyle(fontSize: 68),
        ),
      ),
    );
  }
}

/// Placeholder door — swap for the real door art later.
class _GameDoor extends StatelessWidget {
  final int number;
  final bool solved;
  final VoidCallback onTap;

  const _GameDoor({
    required this.number,
    required this.solved,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: solved ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 92,
        height: 108,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: solved
                ? [Colors.amber[200]!, Colors.amber[400]!]
                : [Colors.brown[300]!, Colors.brown[500]!],
          ),
          border: Border.all(
            color: solved ? Colors.amber[700]! : Colors.brown[700]!,
            width: 3,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(solved ? '🔑' : '🚪', style: const TextStyle(fontSize: 34)),
                  const SizedBox(height: 4),
                  Text(
                    'Game $number',
                    style: TextStyle(
                      color: solved ? Colors.brown[900] : Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (solved)
              Positioned(
                top: 10,
                right: -30,
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: 110,
                    color: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    alignment: Alignment.center,
                    child: const Text(
                      'PASSED',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
