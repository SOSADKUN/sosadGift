import 'package:flutter/material.dart';

/// Shared backdrop for the mini-games: a soft gradient, a few floating
/// sparkles, a back button, and a level pill — so every game looks
/// consistent instead of sitting on the raw scaffold background.
class GameBackground extends StatelessWidget {
  final Widget child;
  final String title;
  final int level;
  final int levelCount;

  const GameBackground({
    super.key,
    required this.child,
    required this.title,
    required this.level,
    required this.levelCount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E1A3C), Color(0xFF4B2354), Color(0xFF6B2D5C)],
          ),
        ),
        child: Stack(
          children: [
            const Positioned(top: 50, left: 26, child: _Sparkle('⭐', 18)),
            const Positioned(top: 100, right: 34, child: _Sparkle('✨', 16)),
            const Positioned(bottom: 70, left: 42, child: _Sparkle('⭐', 14)),
            const Positioned(bottom: 130, right: 26, child: _Sparkle('✨', 20)),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white70, size: 18),
                          onPressed: () => Navigator.of(context).maybePop(),
                        ),
                        Expanded(
                          child: Text(
                            title,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            'Lv $level/$levelCount',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: child),
                ],
              ),
            ),
          ],
        ),
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
