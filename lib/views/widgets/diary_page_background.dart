import 'dart:math' as math;
import 'package:flutter/material.dart';

/// A cream scrapbook sheet on blush gingham, held with translucent washi tape.
class DiaryPageBackground extends StatelessWidget {
  final Widget? child;
  const DiaryPageBackground({super.key, this.child});

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFFF4DFDC),
    child: Stack(
      fit: StackFit.expand,
      children: [
        const CustomPaint(painter: _ScrapbookPainter()),
        ?child,
      ],
    ),
  );
}

class _ScrapbookPainter extends CustomPainter {
  const _ScrapbookPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final gingham = Paint()
      ..color = const Color(0xFFD39DA4).withValues(alpha: 0.14);
    for (double x = 0; x < size.width; x += 28) {
      canvas.drawRect(Rect.fromLTWH(x, 0, 14, size.height), gingham);
    }
    for (double y = 0; y < size.height; y += 28) {
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, 14), gingham);
    }
    final page = Rect.fromLTRB(22, 24, size.width - 18, size.height - 22);
    final paper = RRect.fromRectAndRadius(page, const Radius.circular(5));
    canvas.drawShadow(
      Path()..addRRect(paper),
      const Color(0xFF956D67),
      7,
      false,
    );
    canvas.drawRRect(
      paper.shift(const Offset(3, 4)),
      Paint()..color = const Color(0xFFE9D9C6),
    );
    canvas.drawRRect(
      paper,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFFFCF3), Color(0xFFF9F0DE)],
        ).createShader(page),
    );
    canvas.save();
    canvas.clipRRect(paper);
    // Faint dotted stationery leaves plenty of quiet space for handwriting.
    final dot = Paint()
      ..color = const Color(0xFFBDA69D).withValues(alpha: 0.23);
    for (double x = 38; x < page.right; x += 20) {
      for (double y = 42; y < page.bottom; y += 20) {
        canvas.drawCircle(Offset(x, y), 0.65, dot);
      }
    }
    final random = math.Random(917);
    final grain = Paint()
      ..color = const Color(0xFF9C816C).withValues(alpha: 0.045);
    for (var i = 0; i < 1500; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        0.6,
        grain,
      );
    }
    canvas.restore();
    _tape(canvas, Offset(55, 29), -0.28, const Color(0xFFE8B8BD));
    _tape(
      canvas,
      Offset(size.width - 48, size.height - 29),
      -0.30,
      const Color(0xFFC5CEB4),
    );
    // A pressed flower at the edge, away from the writing and photographs.
    final stem = Paint()
      ..color = const Color(0xFF9DAE8C)
      ..strokeWidth = 1.4;
    final base = Offset(size.width - 29, 155);
    canvas.drawLine(base, base.translate(-5, -42), stem);
    canvas.drawOval(
      Rect.fromCenter(center: base.translate(-6, -12), width: 10, height: 5),
      Paint()..color = const Color(0xFFBCC8A6),
    );
    final center = base.translate(-5, -45);
    for (var i = 0; i < 5; i++) {
      final angle = i * math.pi * 2 / 5;
      canvas.drawCircle(
        center + Offset(math.cos(angle), math.sin(angle)) * 5,
        4,
        Paint()..color = const Color(0xFFE8B8BD),
      );
    }
    canvas.drawCircle(center, 2.5, Paint()..color = const Color(0xFFEACB8F));
  }

  void _tape(Canvas canvas, Offset center, double angle, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    const rect = Rect.fromLTWH(-30, -9, 60, 18);
    canvas.drawRect(rect, Paint()..color = color.withValues(alpha: 0.75));
    canvas.clipRect(rect);
    final stripe = Paint()
      ..color = Colors.white.withValues(alpha: 0.35)
      ..strokeWidth = 2;
    for (double x = -45; x < 45; x += 8) {
      canvas.drawLine(Offset(x, -9), Offset(x + 18, 9), stripe);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ScrapbookPainter oldDelegate) => false;
}
