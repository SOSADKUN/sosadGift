import 'dart:async';
import 'package:flutter/material.dart';
import '../../widgets/video_player_widget.dart';
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
    return Stack(
      children: [
        // Background + door art both come from the video.
        const Positioned.fill(
          child: VideoPlayerWidget(
            assetPath: 'assets/videos/gameHub.mp4',
            loop: true,
            showTapToSkip: false,
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.vpn_key_rounded,
                          color: Colors.amberAccent, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${_solved.length} / ${_games.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final cellWidth = constraints.maxWidth * 0.48;
                    final cellHeight = constraints.maxHeight * 0.46;
                    return Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _HubCharacter(
                                  winCount: _solved.length, mood: _mood),
                              const _SpeechBubble(text: '点击门口进入游戏哦～'),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 0,
                          left: 0,
                          width: cellWidth,
                          height: cellHeight,
                          child: _GameDoorHotspot(
                            solved: _solved.contains(0),
                            onTap: () => _openGame(0),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 0,
                          width: cellWidth,
                          height: cellHeight,
                          child: _GameDoorHotspot(
                            solved: _solved.contains(1),
                            onTap: () => _openGame(1),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          width: cellWidth,
                          height: cellHeight,
                          child: _GameDoorHotspot(
                            solved: _solved.contains(2),
                            onTap: () => _openGame(2),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          width: cellWidth,
                          height: cellHeight,
                          child: _GameDoorHotspot(
                            solved: _solved.contains(3),
                            onTap: () => _openGame(3),
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
      ],
    );
  }
}

/// Character portrait, with a small reaction badge that pops in on
/// win/lose. Swap assets/photos/character.gif for a different animation
/// whenever you like — no code changes needed.
class _HubCharacter extends StatelessWidget {
  final int winCount;
  final _Mood mood;
  const _HubCharacter({required this.winCount, required this.mood});

  String? get _reactionEmoji {
    switch (mood) {
      case _Mood.sad:
        return '😢';
      case _Mood.celebrate:
        return '🥳';
      case _Mood.none:
        return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      height: 170,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            clipBehavior: Clip.antiAlias,
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
            child: Image.asset(
              'assets/photos/character.gif',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: -4,
            right: -4,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: _reactionEmoji == null
                  ? const SizedBox.shrink(key: ValueKey('none'))
                  : Container(
                      key: ValueKey(_reactionEmoji),
                      padding: const EdgeInsets.all(6),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Text(_reactionEmoji!,
                          style: const TextStyle(fontSize: 26)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Little hint bubble under the character, pointing up at it.
class _SpeechBubble extends StatelessWidget {
  final String text;
  const _SpeechBubble({required this.text});

  static const _bubbleColor = Color(0xE6FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      clipBehavior: Clip.none,
      children: [
        Transform.rotate(
          angle: 0.7853981634, // 45deg
          child: Container(width: 14, height: 14, color: _bubbleColor),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 7),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: _bubbleColor,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                    color: Colors.black26, blurRadius: 8, offset: Offset(0, 3)),
              ],
            ),
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFF6B4A3A),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Tap zone over a door drawn into the background video. Invisible until
/// solved, when it drops a key/passed badge on top.
class _GameDoorHotspot extends StatelessWidget {
  final bool solved;
  final VoidCallback onTap;

  const _GameDoorHotspot({required this.solved, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: solved ? null : onTap,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          if (solved)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber[400],
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                        color: Colors.black45,
                        blurRadius: 6,
                        offset: Offset(0, 2)),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.vpn_key_rounded, color: Colors.brown, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'PASSED',
                      style: TextStyle(
                        color: Colors.brown,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
