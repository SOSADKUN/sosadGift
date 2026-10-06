import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Procedural geometry only: orbiting digits assemble two cylindrical tiers.
class BirthdayCinematicScene extends StatefulWidget {
  const BirthdayCinematicScene({
    super.key,
    required this.blownOut,
    required this.onReady,
    required this.onCandleTap,
  });
  final bool blownOut;
  final VoidCallback onReady, onCandleTap;
  @override
  State<BirthdayCinematicScene> createState() => _BirthdayCinematicSceneState();
}

class _BirthdayCinematicSceneState extends State<BirthdayCinematicScene>
    with TickerProviderStateMixin {
  late final AnimationController _formation = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 10),
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 24),
  )..repeat();
  @override
  void initState() {
    super.initState();
    _formation.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onReady();
    });
    _formation.forward();
  }

  @override
  void dispose() {
    _formation.dispose();
    _ambient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
    child: AnimatedBuilder(
      animation: Listenable.merge([_formation, _ambient]),
      builder: (context, _) => GestureDetector(
        key: const ValueKey('birthday-candle'),
        behavior: HitTestBehavior.opaque,
        onTap: _formation.isCompleted ? widget.onCandleTap : null,
        child: CustomPaint(
          size: Size.infinite,
          painter: _CakePainter(
            _formation.value,
            _ambient.value * 24,
            widget.blownOut,
            MediaQuery.disableAnimationsOf(context),
          ),
        ),
      ),
    ),
  );
}

class _Point {
  const _Point(this.x, this.y, this.z);
  final double x, y, z;
}

class _Face {
  _Face(this.points, this.color);
  final List<_Point> points;
  final Color color;
  double get depth =>
      points.fold<double>(0, (sum, p) => sum + p.z) / points.length;
}

class _CakePainter extends CustomPainter {
  _CakePainter(this.progress, this.time, this.blownOut, this.reduced);
  final double progress, time;
  final bool blownOut, reduced;
  late double angle, scale;
  late Offset center;
  double phase(double start, double end) => Curves.easeInOutCubic.transform(
    ((progress - start) / (end - start)).clamp(0.0, 1.0),
  );
  _Point rotate(double x, double y, double z) {
    final rx = x * math.cos(angle) - z * math.sin(angle);
    final rz = x * math.sin(angle) + z * math.cos(angle);
    // Elevated camera exposes the tops and preserves actual depth in rotation.
    return _Point(rx, y * .82 + rz * .57, -y * .57 + rz * .82);
  }

  Offset project(_Point p) {
    final perspective = 700 / (700 - p.z);
    return center + Offset(p.x, p.y) * (scale * perspective);
  }

  Color alpha(Color c, double a) => c.withValues(alpha: a.clamp(0.0, 1.0));
  void cylinder(
    List<_Face> faces,
    double radius,
    double top,
    double bottom,
    Color color,
    double opacity,
  ) {
    const segments = 64;
    final rim = <_Point>[];
    for (var i = 0; i < segments; i++) {
      final a = i * math.pi * 2 / segments;
      final b = (i + 1) * math.pi * 2 / segments;
      _Point at(double theta, double y) =>
          rotate(radius * math.cos(theta), y, radius * math.sin(theta));
      rim.add(at(a, top));
      final light = .92 + .07 * math.cos(a + angle + .7);
      final shade = Color.fromARGB(
        255,
        (color.r * 255 * light).round(),
        (color.g * 255 * light).round(),
        (color.b * 255 * light).round(),
      );
      faces.add(
        _Face([
          at(a, top),
          at(b, top),
          at(b, bottom),
          at(a, bottom),
        ], alpha(shade, opacity)),
      );
    }
    faces.add(
      _Face(rim, alpha(Color.lerp(color, Colors.white, .48)!, opacity)),
    );
  }

  void drawFaces(Canvas canvas, List<_Face> faces) {
    faces.sort((a, b) => a.depth.compareTo(b.depth));
    for (final face in faces) {
      final points = face.points.map(project).toList();
      final path = Path()..addPolygon(points, true);
      canvas.drawPath(
        path,
        Paint()
          ..isAntiAlias = false
          ..color = face.color,
      );
    }
  }

  void flower(
    Canvas canvas,
    _Point p,
    double radius,
    double opacity,
    int index,
  ) {
    final o = project(p);
    final r = radius * scale * 700 / (700 - p.z);
    canvas.save();
    canvas.translate(o.dx, o.dy);
    canvas.rotate(index * .7 + angle * .15);
    final pink = index.isEven
        ? const Color(0xFFFFA7CD)
        : const Color(0xFFD7B7FF);
    for (var petal = 0; petal < 5; petal++) {
      canvas.save();
      canvas.rotate(petal * math.pi * 2 / 5);
      final rect = Rect.fromCenter(
        center: Offset(0, -r * .65),
        width: r,
        height: r * 1.45,
      );
      canvas.drawOval(
        rect,
        Paint()
          ..shader = RadialGradient(
            colors: [alpha(Colors.white, opacity), alpha(pink, opacity)],
          ).createShader(rect),
      );
      canvas.restore();
    }
    canvas.drawCircle(
      Offset.zero,
      r * .3,
      Paint()..color = alpha(const Color(0xFFFFD880), opacity),
    );
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final bounds = Offset.zero & size;
    canvas.drawRect(
      bounds,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(0, .05),
          radius: .85,
          colors: [Color(0xFF492D59), Color(0xFF171126), Color(0xFF090715)],
        ).createShader(bounds),
    );
    final orbit = phase(0, .65);
    angle = reduced
        ? -.3
        : -1.4 + orbit * math.pi * 2.3 + .12 * math.sin(time * .22);
    scale =
        math.min(size.width / 365, size.height / 510) *
        (.74 + .16 * phase(.15, .8));
    center = Offset(size.width / 2, size.height * .53);
    // Stable star field; nothing is reseeded between animation frames.
    for (var i = 0; i < 70; i++) {
      final o = Offset(
        (i * .61803398875 % 1) * size.width,
        (i * .41421356237 % 1) * size.height,
      );
      canvas.drawCircle(
        o,
        i % 7 == 0 ? 2 : .8,
        Paint()
          ..color = alpha(
            const Color(0xFFFFDAEF),
            .12 + .18 * (1 + math.sin(time + i)) / 2,
          ),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, 105 * scale),
        width: 280 * scale,
        height: 60 * scale,
      ),
      Paint()
        ..color = alpha(const Color(0xFFE8AAFF), .25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24),
    );
    final material = phase(.52, .91);

    final faces = <_Face>[];
    cylinder(faces, 137, 85, 91, const Color(0xFFEED4F2), material);
    cylinder(faces, 118, -5, 82, const Color(0xFFFAD2E4), material);
    cylinder(faces, 78, -91, -7, const Color(0xFFFFE4EC), material);
    cylinder(faces, 120, -9, -2, const Color(0xFFFFF8F1), material);
    cylinder(faces, 80, -95, -88, const Color(0xFFFFF8F1), material);
    drawFaces(canvas, faces);
    // Hundreds of deterministic particles converge from helices to cake surfaces.
    final particles = <(_Point, int)>[];
    for (var i = 0; i < 760; i++) {
      final upper = i.isEven;
      final r = upper ? 78.0 : 118.0;
      final a = i * 2.399963;
      final targetY =
          (upper ? -91.0 : -5.0) + (i * .618 % 1) * (upper ? 84 : 87);
      final converge = phase(.12 + (i % 19) * .007, .56 + (i % 19) * .009);
      final spin =
          a + (reduced ? 0 : time * .8 + progress * 8) * (1 - converge);
      final radius = r + (210 + i % 71 - r) * (1 - converge);
      final y =
          targetY +
          (math.sin(i * 1.7 + time * .5) * 185 - targetY) * (1 - converge);
      particles.add((
        rotate(radius * math.cos(spin), y, radius * math.sin(spin)),
        i,
      ));
    }
    particles.sort((a, b) => a.$1.z.compareTo(b.$1.z));
    for (final entry in particles) {
      final p = entry.$1;
      final i = entry.$2;
      final opacity =
          (1 - phase(.62, .92)) *
          (.35 + .45 * ((p.z + 280) / 560).clamp(0.0, 1.0));
      final color = alpha(
        i % 3 == 0 ? const Color(0xFFFFD99D) : const Color(0xFFF5C5F5),
        opacity,
      );
      final o = project(p);
      if (i % 7 == 0) {
        final text = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: i.isEven ? '0' : '1',
            style: TextStyle(
              color: color,
              fontSize: 10 * scale * 700 / (700 - p.z),
              fontFamily: 'monospace',
            ),
          ),
        )..layout();
        text.paint(canvas, o);
      } else {
        canvas.drawCircle(
          o,
          (i % 5 == 0 ? 2 : .9) * scale,
          Paint()..color = color,
        );
      }
    }
    final decoration = phase(.7, 1);
    // Piped cream beads and flowers attach to the rotating geometry.
    final flowers = <(_Point, int)>[];
    for (final tier in [(118.0, -5.0, 82.0), (78.0, -91.0, -7.0)]) {
      for (var i = 0; i < 44; i++) {
        final a = i * math.pi * 2 / 44;
        final p = rotate(
          tier.$1 * math.cos(a),
          tier.$2 - 2,
          tier.$1 * math.sin(a),
        );
        if (math.sin(a + angle) < -.1) continue;
        canvas.drawCircle(
          project(p),
          4.2 * scale,
          Paint()..color = alpha(Colors.white, decoration),
        );
        if (i % 4 == 0) {
          final drip = rotate(
            tier.$1 * math.cos(a),
            tier.$2 + 10 + i % 3 * 4,
            tier.$1 * math.sin(a),
          );
          canvas.drawLine(
            project(p),
            project(drip),
            Paint()
              ..strokeWidth = 7 * scale
              ..strokeCap = StrokeCap.round
              ..color = alpha(Colors.white, decoration),
          );
        }
      }
      for (var i = 0; i < 9; i++) {
        final a = i * math.pi * 2 / 9;
        if (math.sin(a + angle) < 0) continue;
        flowers.add((
          rotate(
            (tier.$1 + 3) * math.cos(a),
            tier.$2 + 40,
            (tier.$1 + 3) * math.sin(a),
          ),
          i,
        ));
      }
    }
    flowers.sort((a, b) => a.$1.z.compareTo(b.$1.z));
    for (final f in flowers) {
      final o = project(f.$1);
      canvas.drawOval(
        Rect.fromCenter(
          center: o + Offset(9 * scale, 7 * scale),
          width: 18 * scale,
          height: 7 * scale,
        ),
        Paint()..color = alpha(const Color(0xFF9CD9BD), decoration),
      );
      flower(canvas, f.$1, 10, decoration, f.$2);
    }
    for (var i = 0; i < 6; i++) {
      final a = i * math.pi * 2 / 6;
      flower(
        canvas,
        rotate(50 * math.cos(a), -94, 50 * math.sin(a)),
        9,
        decoration,
        i,
      );
    }
    final candle = project(rotate(0, -96, 0));
    final tip = project(rotate(0, -144, 0));
    canvas.drawLine(
      candle,
      tip,
      Paint()
        ..strokeWidth = 9 * scale
        ..strokeCap = StrokeCap.round
        ..color = alpha(const Color(0xFFFFB5D7), decoration),
    );
    if (!blownOut) {
      final flicker = reduced ? 1.0 : 1 + .09 * math.sin(time * 15);
      canvas.drawCircle(
        tip - Offset(0, 9 * scale),
        15 * scale,
        Paint()
          ..color = alpha(const Color(0xFFFFCA71), decoration * .55)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
      );
      final flame = Path()
        ..moveTo(tip.dx, tip.dy - 23 * scale * flicker)
        ..cubicTo(
          tip.dx - 13 * scale,
          tip.dy - 8 * scale,
          tip.dx - 7 * scale,
          tip.dy + 2 * scale,
          tip.dx,
          tip.dy,
        )
        ..cubicTo(
          tip.dx + 9 * scale,
          tip.dy,
          tip.dx + 9 * scale,
          tip.dy - 10 * scale,
          tip.dx,
          tip.dy - 23 * scale * flicker,
        );
      canvas.drawPath(
        flame,
        Paint()..color = alpha(const Color(0xFFFFE7A6), decoration),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CakePainter old) =>
      old.progress != progress ||
      old.time != time ||
      old.blownOut != blownOut ||
      old.reduced != reduced;
}
