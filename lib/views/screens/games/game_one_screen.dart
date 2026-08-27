import 'package:flutter/material.dart';

/// TODO: you said you forgot what game 1 was — decide and build it here.
/// Left as a stub so the flow is testable end-to-end right away.
class GameOneScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const GameOneScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ElevatedButton(
        onPressed: onComplete,
        child: const Text('Game 1 — TODO (tap to test flow)'),
      ),
    );
  }
}