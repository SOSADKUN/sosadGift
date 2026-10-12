import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Translation/size/start-point independent matching, in both stroke directions.
bool isHeartStroke(List<Offset> points) {
  if (points.length < 20) return false;
  final minX = points.map((p) => p.dx).reduce(math.min);
  final maxX = points.map((p) => p.dx).reduce(math.max);
  final minY = points.map((p) => p.dy).reduce(math.min);
  final maxY = points.map((p) => p.dy).reduce(math.max);
  final width = maxX - minX, height = maxY - minY;
  if (width < 55 || height < 55 || width / height < .55 || width / height > 1.7) {
    return false;
  }
  if ((points.first - points.last).distance > math.max(width, height) * .35) {
    return false;
  }
  final normalized = points
      .map((p) => Offset((p.dx - minX) / width, (p.dy - minY) / height))
      .toList();
  // A heart has a central notch and two higher lobes; a circle does not.
  final center = normalized.where((p) => p.dx > .42 && p.dx < .58).toList();
  if (center.isEmpty || center.map((p) => p.dy).reduce(math.min) < .07) {
    return false;
  }
  if (!normalized.any((p) => p.dx < .4 && p.dy < .15) ||
      !normalized.any((p) => p.dx > .6 && p.dy < .15)) {
    return false;
  }
  List<Offset> resample(List<Offset> path) {
    final lengths = <double>[0];
    for (var i = 1; i < path.length; i++) {
      lengths.add(lengths.last + (path[i] - path[i - 1]).distance);
    }
    if (lengths.last == 0) return [];
    var segment = 1;
    return List.generate(64, (i) {
      final target = lengths.last * i / 63;
      while (segment < path.length - 1 && lengths[segment] < target) {
        segment++;
      }
      final span = lengths[segment] - lengths[segment - 1];
      return Offset.lerp(
        path[segment - 1],
        path[segment],
        span == 0 ? 0 : (target - lengths[segment - 1]) / span,
      )!;
    });
  }

  final template = List.generate(129, (i) {
    final t = i * math.pi * 2 / 128;
    return Offset(
      16 * math.pow(math.sin(t), 3).toDouble(),
      -(13 * math.cos(t) -
          5 * math.cos(2 * t) -
          2 * math.cos(3 * t) -
          math.cos(4 * t)),
    );
  });
  final tx = template.map((p) => p.dx).reduce(math.min);
  final ty = template.map((p) => p.dy).reduce(math.min);
  final tw = template.map((p) => p.dx).reduce(math.max) - tx;
  final th = template.map((p) => p.dy).reduce(math.max) - ty;
  final reference = resample(
    template.map((p) => Offset((p.dx - tx) / tw, (p.dy - ty) / th)).toList(),
  );
  final stroke = resample(normalized);
  var best = double.infinity;
  for (var shift = 0; shift < 64; shift++) {
    for (final direction in [-1, 1]) {
      var error = 0.0;
      for (var i = 0; i < 64; i++) {
        error += (stroke[i] - reference[(shift + direction * i) % 64])
            .distanceSquared;
      }
      best = math.min(best, math.sqrt(error / 64));
    }
  }
  return best < .18;
}

class HeartGesturePortal extends StatefulWidget {
  const HeartGesturePortal({
    super.key,
    required this.child,
    required this.onHeart,
  });
  final Widget child;
  final VoidCallback onHeart;
  @override
  State<HeartGesturePortal> createState() => _HeartGesturePortalState();
}

class _HeartGesturePortalState extends State<HeartGesturePortal> {
  final List<Offset> _points = [];
  int? _pointer;
  @override
  Widget build(BuildContext context) => Listener(
    behavior: HitTestBehavior.opaque,
    onPointerDown: (event) {
      if (_pointer != null) return;
      _pointer = event.pointer;
      setState(() {
        _points.clear();
        _points.add(event.localPosition);
      });
    },
    onPointerMove: (event) {
      if (event.pointer != _pointer || _points.length >= 2000) return;
      if ((event.localPosition - _points.last).distance < 2) return;
      setState(() => _points.add(event.localPosition));
    },
    onPointerUp: (event) {
      if (event.pointer != _pointer) return;
      _points.add(event.localPosition);
      final matched = isHeartStroke(_points);
      _pointer = null;
      setState(_points.clear);
      if (matched) {
        widget.onHeart();
      }
    },
    onPointerCancel: (event) {
      if (event.pointer != _pointer) return;
      _pointer = null;
      setState(_points.clear);
    },
    child: Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: CustomPaint(painter: _HeartTrail(List.of(_points))),
        ),
      ],
    ),
  );
}

class _HeartTrail extends CustomPainter {
  _HeartTrail(this.points);
  final List<Offset> points;
  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;
    final path = Path()..addPolygon(points, false);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = const Color(0xBBFFD1E5),
    );
  }

  @override
  bool shouldRepaint(covariant _HeartTrail old) => true;
}
