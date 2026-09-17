import 'package:flutter/material.dart';

/// Shared modal for every game's failure, including timeouts and bombs.
class GameFailureOverlay extends StatefulWidget {
  final String title;
  final VoidCallback onRetry;
  final VoidCallback onExit;
  const GameFailureOverlay({
    super.key,
    required this.title,
    required this.onRetry,
    required this.onExit,
  });

  @override
  State<GameFailureOverlay> createState() => _GameFailureOverlayState();
}

class _GameFailureOverlayState extends State<GameFailureOverlay> {
  bool _acted = false;
  void _choose(VoidCallback action) {
    if (_acted) return;
    _acted = true;
    action();
  }

  @override
  Widget build(BuildContext context) => Positioned.fill(
    child: Stack(
      children: [
        const ModalBarrier(dismissible: false, color: Colors.black54),
        Center(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Material(
                color: const Color(0xF22D223C),
                borderRadius: BorderRadius.circular(24),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.asset(
                          'assets/photos/fail.gif',
                          width: 130,
                          height: 130,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        widget.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '别灰心，再挑战一次吧～',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 20),
                      FilledButton(
                        onPressed: () => _choose(widget.onRetry),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFFFBBD0),
                          foregroundColor: const Color(0xFF392239),
                        ),
                        child: const Text('再试一次'),
                      ),
                      TextButton(
                        onPressed: () => _choose(widget.onExit),
                        child: const Text(
                          '先回小屋',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
