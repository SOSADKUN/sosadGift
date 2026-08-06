import 'package:flutter/material.dart';

/// TODO: your new "better game" idea goes here. Once it's built,
/// add it to the `_games` list in game_hub_screen.dart.
class GameFourScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const GameFourScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onComplete,
        child: const Text('Game 4 — TODO (tap to test flow)'),
      ),
    );
  }
}