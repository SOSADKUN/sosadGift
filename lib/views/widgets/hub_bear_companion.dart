import 'dart:math' as math;
import 'package:flutter/material.dart';

enum HubBearMood { idle, sad, happy }

/// Vector-drawn bears with independent faces, paws and idle motion.
class HubBearCompanion extends StatefulWidget {
  const HubBearCompanion({
    super.key,
    this.mood = HubBearMood.idle,
    this.active = true,
    this.width = 190,
  });
  final HubBearMood mood;
  final bool active;
  final double width;

  @override
  State<HubBearCompanion> createState() => _HubBearCompanionState();
}

class _HubBearCompanionState extends State<HubBearCompanion>
    with SingleTickerProviderStateMixin {
  late final _motion = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  void _sync() {
    final animate =
        widget.active &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (animate && !_motion.isAnimating) _motion.repeat();
    if (!animate) _motion.stop();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sync();
  }

  @override
  void didUpdateWidget(HubBearCompanion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: switch (widget.mood) {
      HubBearMood.idle => '一二和布布：眨眼、呼吸、张望和挥手',
      HubBearMood.sad => '一二和布布伤心地互相鼓励',
      HubBearMood.happy => '一二和布布开心地蹦跳庆祝',
    },
    image: true,
    child: RepaintBoundary(
      child: SizedBox(
        width: widget.width,
        height: widget.width * .9,
        child: AnimatedBuilder(
          animation: _motion,
          builder: (context, _) => CustomPaint(
            painter: _BearsPainter(
              widget.mood,
              MediaQuery.disableAnimationsOf(context) ? 0 : _motion.value * 8,
            ),
          ),
        ),
      ),
    ),
  );
}

class _BearsPainter extends CustomPainter {
  _BearsPainter(this.mood, this.time);
  final HubBearMood mood;
  final double time;
  static const ink = Color(0xFF613D30);

  Paint get line => Paint()
    ..color = ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.8
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;
  void oval(Canvas c, Rect rect, Color color) {
    c.drawOval(rect, Paint()..color = color);
    c.drawOval(rect, line);
  }

  void rounded(Canvas c, Rect rect, double radius, Color color) {
    final r = RRect.fromRectAndRadius(rect, Radius.circular(radius));
    c.drawRRect(r, Paint()..color = color);
    c.drawRRect(r, line);
  }

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / 200, size.height / 180);
    canvas.drawOval(
      const Rect.fromLTWH(30, 151, 140, 14),
      Paint()
        ..color = const Color(0x334D283E)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );
    _bear(canvas, const Offset(130, 77), const Color(0xFFDDA17D), false, .35);
    _bear(canvas, const Offset(72, 76), const Color(0xFFFFFCF5), true, 0);
    _heart(
      canvas,
      Offset(102, 23 + math.sin(time * 2) * 2),
      mood == HubBearMood.happy ? 10 : 7,
    );
    if (mood == HubBearMood.happy) {
      for (var i = 0; i < 5; i++) {
        final x = 22.0 + i * 39;
        final y = 25 + math.sin(time * 4 + i) * 7;
        final p = Paint()
          ..color = (i.isEven
              ? const Color(0xFFFFD48F)
              : const Color(0xFFFF99B8))
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(Offset(x - 3, y), Offset(x + 3, y), p);
        canvas.drawLine(Offset(x, y - 3), Offset(x, y + 3), p);
      }
    }
    canvas.restore();
  }

  void _bear(Canvas c, Offset center, Color fur, bool white, double phase) {
    final t = time + phase;
    final happy = mood == HubBearMood.happy;
    final sad = mood == HubBearMood.sad;
    final hop = happy ? math.pow(math.sin(t * 5), 2).toDouble() * 6 : 0.0;
    final breathe = math.sin(t * 2) * 1.4;
    final sway = sad ? math.sin(t * 2) * .025 : math.sin(t * 1.4) * .035;
    c.save();
    c.translate(center.dx, center.dy + breathe - hop);
    c.rotate(sway);
    // Body and grounded feet retain their silhouette as the head breathes.
    oval(c, const Rect.fromLTWH(-24, 22, 48, 48), fur);
    if (!white) {
      c.drawOval(
        const Rect.fromLTWH(-14, 33, 28, 29),
        Paint()..color = const Color(0xFFEEC2A4),
      );
    }
    oval(c, const Rect.fromLTWH(-24, 61, 23, 14), fur);
    oval(c, const Rect.fromLTWH(2, 61, 23, 14), fur);
    // Independent arms: a little idle wave, drooped sadness, or raised cheers.
    final waving = !sad && !happy && t % 8 > 4.8 && t % 8 < 6.7;
    final wave = waving ? math.sin(t * 12) * 6 : 0.0;
    for (final side in [-1.0, 1.0]) {
      final raised = happy || (waving && (white ? side < 0 : side > 0));
      final start = Offset(side * 20, 34);
      final end = Offset(
        side * (raised ? 34 : 29),
        raised ? 8 + wave : (sad ? 52 : 42),
      );
      final arm = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(side * 38, 32, end.dx, end.dy);
      c.drawPath(
        arm,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 16
          ..strokeCap = StrokeCap.round,
      );
      c.drawPath(
        arm,
        Paint()
          ..color = fur
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11
          ..strokeCap = StrokeCap.round,
      );
    }
    c.save();
    c.rotate(sad ? (white ? -.06 : .06) : 0);
    oval(
      c,
      const Rect.fromLTWH(-38, -35, 23, 24),
      white ? ink : const Color(0xFFB67B58),
    );
    oval(
      c,
      const Rect.fromLTWH(15, -35, 23, 24),
      white ? ink : const Color(0xFFB67B58),
    );
    rounded(c, const Rect.fromLTWH(-40, -27, 80, 68), 27, fur);
    c.drawOval(
      const Rect.fromLTWH(-33, 14, 18, 13),
      Paint()..color = const Color(0xFFFFB4B3),
    );
    c.drawOval(
      const Rect.fromLTWH(15, 14, 18, 13),
      Paint()..color = const Color(0xFFFFB4B3),
    );
    final blink = (t % 4.3) > 3.95 && (t % 4.3) < 4.10;
    final look = mood == HubBearMood.idle ? math.sin(t * .9) * 2.0 : 0.0;
    for (final side in [-1.0, 1.0]) {
      final x = side * 14 + look;
      if (happy) {
        c.drawPath(
          Path()
            ..moveTo(x - 5, 7)
            ..quadraticBezierTo(x, -2, x + 5, 7),
          line,
        );
      } else if (blink) {
        c.drawLine(Offset(x - 4, 6), Offset(x + 4, 6), line);
      } else {
        c.drawOval(
          Rect.fromCenter(center: Offset(x, 6), width: 7, height: sad ? 8 : 9),
          Paint()..color = ink,
        );
      }
      if (sad) {
        c.drawLine(
          Offset(x - 5, -6 + (side < 0 ? 2 : 0)),
          Offset(x + 5, -6 + (side > 0 ? 2 : 0)),
          line,
        );
        final tearY = 16 + (t * 20 % 16);
        final tear = Path()
          ..moveTo(x, tearY - 5)
          ..quadraticBezierTo(x - 6, tearY + 4, x, tearY + 5)
          ..quadraticBezierTo(x + 6, tearY + 4, x, tearY - 5);
        c.drawPath(
          tear,
          Paint()
            ..color = const Color(
              0xFF8ACCEB,
            ).withValues(alpha: .85 - (tearY - 16) / 28),
        );
      }
    }
    if (happy) {
      final mouth = Path()
        ..moveTo(-6, 15)
        ..quadraticBezierTo(0, 18, 6, 15)
        ..quadraticBezierTo(6, 30, 0, 30)
        ..quadraticBezierTo(-6, 30, -6, 15);
      c.drawPath(mouth, Paint()..color = ink);
      c.drawOval(
        const Rect.fromLTWH(-4, 23, 8, 5),
        Paint()..color = const Color(0xFFEF8D9B),
      );
    } else if (sad) {
      c.drawPath(
        Path()
          ..moveTo(-5, 24)
          ..quadraticBezierTo(0, 18, 5, 24),
        line,
      );
    } else {
      c.drawPath(
        Path()
          ..moveTo(-7, 18)
          ..quadraticBezierTo(-6, 25, 0, 20)
          ..quadraticBezierTo(6, 25, 7, 18),
        line,
      );
    }
    c.restore();
    c.restore();
  }

  void _heart(Canvas c, Offset p, double r) {
    final path = Path()
      ..moveTo(p.dx, p.dy + r)
      ..cubicTo(
        p.dx - r * 2,
        p.dy - r * .2,
        p.dx - r,
        p.dy - r * 1.5,
        p.dx,
        p.dy - r * .5,
      )
      ..cubicTo(
        p.dx + r,
        p.dy - r * 1.5,
        p.dx + r * 2,
        p.dy - r * .2,
        p.dx,
        p.dy + r,
      );
    c.drawPath(path, Paint()..color = const Color(0xFFFF9DB8));
  }

  @override
  bool shouldRepaint(_BearsPainter oldDelegate) =>
      mood != oldDelegate.mood || time != oldDelegate.time;
}
