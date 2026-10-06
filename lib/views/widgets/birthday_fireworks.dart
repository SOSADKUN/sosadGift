import 'dart:math' as math;
import 'package:flutter/material.dart';

class BirthdayFireworks extends StatelessWidget {
  const BirthdayFireworks({super.key, required this.animation});
  final Animation<double> animation;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: AnimatedBuilder(
      animation: animation,
      builder: (context, _) => CustomPaint(
        size: Size.infinite,
        painter: _FireworksPainter(animation.value),
      ),
    ),
  );
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    final time = progress * 6;
    const colors = [
      Color(0xFFFFD38C),
      Color(0xFFFF9ECC),
      Color(0xFFCCAEFF),
      Color(0xFFA7F0DE),
    ];
    for (var burst = 0; burst < 9; burst++) {
      final age = time - burst * .48;
      if (age < 0 || age > 1.7) continue;
      final center = Offset(
        size.width * (.18 + (burst * .317 % .64)),
        size.height * (.15 + (burst * .173 % .4)),
      );
      final alpha = (1 - age / 1.7).clamp(0.0, 1.0);
      for (var i = 0; i < 64; i++) {
        final a = i * math.pi * 2 / 64 + burst;
        final speed = 55 + i % 5 * 13;
        Offset at(double t) =>
            center +
            Offset(
              math.cos(a) * speed * t,
              math.sin(a) * speed * t + 30 * t * t,
            );
        canvas.drawLine(
          at(math.max(0, age - .13)),
          at(age),
          Paint()
            ..color = colors[burst % colors.length].withValues(alpha: alpha)
            ..strokeWidth = 1.8
            ..strokeCap = StrokeCap.round,
        );
        canvas.drawCircle(
          at(age),
          2,
          Paint()..color = Colors.white.withValues(alpha: alpha),
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FireworksPainter old) =>
      old.progress != progress;
}
