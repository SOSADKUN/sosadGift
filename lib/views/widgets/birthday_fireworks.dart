import 'dart:math' as math;
import 'package:flutter/material.dart';

/// One timeline shared by the visuals and the rendered fireworks audio.
class BirthdayFireworks extends StatelessWidget {
  const BirthdayFireworks({super.key, required this.animation});
  static const duration = Duration(milliseconds: 13600);
  static const burstTimes = [
    0.5955,
    1.0634,
    1.6164,
    2.1269,
    2.5948,
    3.0627,
    3.5731,
    3.956,
    4.3388,
    4.7216,
    5.1045,
    5.4873,
    5.8701,
    6.0828,
    6.2955,
    6.806,
    7.3164,
    7.8269,
    8.3373,
    8.8478,
    9.3582,
    9.8687,
    10.209,
    10.5493,
    10.8896,
    11.1873,
    11.4,
  ];
  final Animation<double> animation;
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, _) => CustomPaint(
          size: Size.infinite,
          painter: _FireworksPainter(
            animation.value,
            MediaQuery.disableAnimationsOf(context),
          ),
        ),
      ),
    ),
  );
}

class _FireworksPainter extends CustomPainter {
  _FireworksPainter(this.progress, this.reduced);
  final double progress;
  final bool reduced;
  static const colors = [
    Color(0xFFFFD38C),
    Color(0xFFFF9ECC),
    Color(0xFFCBB6FF),
    Color(0xFF92DFE6),
    Color(0xFFFFECBC),
  ];
  @override
  void paint(Canvas c, Size size) {
    c.save();
    c.clipRect(Offset.zero & size);
    final time = progress * (BirthdayFireworks.duration.inMilliseconds / 1000);
    for (var b = 0; b < BirthdayFireworks.burstTimes.length; b++) {
      final age = time - BirthdayFireworks.burstTimes[b];
      if (age < -.65 || age > 2.15) continue;
      final center = Offset(
        size.width * (.22 + (b * .293 % .56)),
        size.height * (.14 + (b * .137 % .38)),
      );
      final color = colors[b % colors.length];
      if (age < 0) {
        if (reduced) continue;
        final launch = (age + .65) / .65;
        final from = Offset(
          center.dx + (b.isEven ? -30 : 30),
          size.height * .92,
        );
        final p = Offset.lerp(
          from,
          center,
          1 - math.pow(1 - launch, 1.5).toDouble(),
        )!;
        c.drawLine(
          p + const Offset(0, 22),
          p,
          Paint()
            ..color = color.withValues(alpha: .65)
            ..strokeWidth = 2
            ..strokeCap = StrokeCap.round,
        );
        c.drawCircle(p, 2.5, Paint()..color = Colors.white);
        continue;
      }
      final alpha = (1 - age / 2.15).clamp(0.0, 1.0);
      final radius =
          math.min(size.width * .38, 155.0) * (1 - math.exp(-age * 2.5));
      if (age < .25 && !reduced) {
        c.drawCircle(
          center,
          20 + age * 90,
          Paint()
            ..shader = RadialGradient(
              colors: [
                Colors.white.withValues(alpha: (1 - age / .25) * .45),
                color.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: center, radius: 45)),
        );
      }
      final count = reduced ? 24 : 112;
      for (var i = 0; i < count; i++) {
        final seed = math.sin(i * 127.1 + b * 311.7) * 43758.5453;
        final random = seed - seed.floor();
        final angle = i * math.pi * 2 / count + b * .41 + random * .035;
        final variation = .18 + math.sqrt(random) * .82;
        final heart = b % 5 == 2;
        Offset at(double t) {
          final r =
              math.min(size.width * .38, 155.0) *
              (1 - math.exp(-t * 2.5)) *
              variation;
          if (heart) {
            return center +
                Offset(
                  math.pow(math.sin(angle), 3).toDouble() * r,
                  -(13 * math.cos(angle) -
                              5 * math.cos(2 * angle) -
                              2 * math.cos(3 * angle) -
                              math.cos(4 * angle)) /
                          16 *
                          r +
                      22 * t * t,
                );
          }
          return center +
              Offset(math.cos(angle) * r, math.sin(angle) * r + 22 * t * t);
        }

        final p = at(age);
        final tail = at(math.max(0, age - .13));
        c.drawLine(
          tail,
          p,
          Paint()
            ..color = color.withValues(alpha: alpha * .2)
            ..strokeWidth = 3.5
            ..strokeCap = StrokeCap.round,
        );
        c.drawLine(
          tail,
          p,
          Paint()
            ..color = color.withValues(alpha: alpha)
            ..strokeWidth = 1.1
            ..strokeCap = StrokeCap.round,
        );
        final glitter = (.55 + .45 * math.sin(age * 25 + i).abs()) * alpha;
        c.drawCircle(
          p,
          1.25,
          Paint()..color = Colors.white.withValues(alpha: glitter),
        );
        if (!reduced && i % 13 == 0 && age < 1.4) {
          final star = Paint()
            ..color = Colors.white.withValues(alpha: glitter * .8)
            ..strokeWidth = .7;
          c.drawLine(p - const Offset(2.8, 0), p + const Offset(2.8, 0), star);
          c.drawLine(p - const Offset(0, 2.8), p + const Offset(0, 2.8), star);
        }
        if (!reduced && i % 4 == 0 && age > .35) {
          c.drawCircle(
            p + Offset(math.sin(i) * 8, age * 12),
            .9,
            Paint()
              ..color = const Color(0xFFFFD78B).withValues(alpha: glitter * .7),
          );
        }
      }
      if (age < .8 && !reduced) {
        final glowRadius = radius * .6 + 10;
        c.drawCircle(
          center,
          glowRadius,
          Paint()
            ..shader = RadialGradient(
              colors: [
                color.withValues(alpha: (1 - age / .8) * .14),
                color.withValues(alpha: 0),
              ],
            ).createShader(Rect.fromCircle(center: center, radius: glowRadius)),
        );
      }
    }
    c.restore();
  }

  @override
  bool shouldRepaint(_FireworksPainter old) =>
      old.progress != progress || old.reduced != reduced;
}
