import 'package:flutter/material.dart';
import 'game_one_screen.dart';
import 'game_two_screen.dart';
import 'game_three_screen.dart';
// import 'game_four_screen.dart'; // swap in when your new game is ready

class GameHubScreen extends StatefulWidget {
  final VoidCallback onAllGamesComplete;

  const GameHubScreen({super.key, required this.onAllGamesComplete});

  @override
  State<GameHubScreen> createState() => _GameHubScreenState();
}

class _GameHubScreenState extends State<GameHubScreen> {
  int _gameIndex = 0;

  // Add/remove/reorder games here. Each entry takes an onComplete callback,
  // same pattern as the rest of the app.
  late final List<Widget Function(VoidCallback onComplete)> _games = [
    (onComplete) => GameOneScreen(onComplete: onComplete),
    (onComplete) => GameTwoScreen(onComplete: onComplete),
    (onComplete) => GameThreeScreen(onComplete: onComplete),
    // (onComplete) => GameFourScreen(onComplete: onComplete),
  ];

  void _nextGame() {
    if (_gameIndex < _games.length - 1) {
      setState(() => _gameIndex++);
    } else {
      widget.onAllGamesComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            '游戏 ${_gameIndex + 1} / ${_games.length}',
            style: const TextStyle(color: Colors.white70),
          ),
        ),
        Expanded(
          child: _games[_gameIndex](_nextGame),
        ),
      ],
    );
  }
}