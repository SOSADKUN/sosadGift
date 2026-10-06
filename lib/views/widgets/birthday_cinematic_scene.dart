import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Uses the approved concept frames for the exact cake and lighting artwork.
class BirthdayCinematicScene extends StatefulWidget {
  const BirthdayCinematicScene({
    super.key,
    required this.blownOut,
    required this.onReady,
    required this.onCandleTap,
  });
  final bool blownOut;
  final VoidCallback onReady;
  final VoidCallback onCandleTap;
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
  ui.Image? _digital;
  ui.Image? _floral;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _formation.addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onReady();
    });
    _load();
  }

  Future<ui.Image> _image(String path) async {
    final data = await rootBundle.load(path);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
    );
    try {
      return (await codec.getNextFrame()).image;
    } finally {
      codec.dispose();
    }
  }

  Future<void> _load() async {
    try {
      final digital = await _image('assets/cake/digital_formation.png');
      if (!mounted) {
        digital.dispose();
        return;
      }
      _digital = digital;
      final floral = await _image('assets/cake/floral_reveal.png');
      if (!mounted) {
        floral.dispose();
        return;
      }
      setState(() => _floral = floral);
      _formation.forward();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _formation.dispose();
    _ambient.dispose();
    _digital?.dispose();
    _floral?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_failed) {
      return const Center(
        child: Icon(Icons.cake_outlined, color: Color(0xFFE5B6CE), size: 64),
      );
    }
    if (_digital == null || _floral == null) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFE5B6CE)),
      );
    }
    return AnimatedBuilder(
      animation: Listenable.merge([_formation, _ambient]),
      builder: (context, _) => GestureDetector(
        key: const ValueKey('birthday-candle'),
        behavior: HitTestBehavior.opaque,
        onTap: _formation.isCompleted ? widget.onCandleTap : null,
        child: CustomPaint(
          painter: _CinematicPainter(
            _digital!,
            _floral!,
            _formation.value,
            _ambient.value,
            widget.blownOut,
            MediaQuery.disableAnimationsOf(context),
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _CinematicPainter extends CustomPainter {
  _CinematicPainter(
    this.digital,
    this.floral,
    this.progress,
    this.ambient,
    this.blownOut,
    this.reduced,
  );
  final ui.Image digital, floral;
  final double progress, ambient;
  final bool blownOut, reduced;

  // Four orbital/formation frames followed by three floral materialization frames.
  void _frame(Canvas canvas, Size size, int frame, double opacity) {
    if (opacity <= 0) return;
    final image = frame < 4 ? digital : floral;
    final count = frame < 4 ? 4 : 3;
    final index = frame < 4 ? frame : frame - 4;
    final panelWidth = image.width / count;
    final source = Rect.fromLTWH(
      index * panelWidth + 3,
      0,
      panelWidth - 6,
      image.height.toDouble(),
    );
    // Match the approved portrait composition. Fill with its own edge colors,
    // then fit the whole panel so flowers, candle and cake base remain visible.
    final fitted = applyBoxFit(BoxFit.contain, source.size, size).destination;
    final destination = Alignment.center.inscribe(fitted, Offset.zero & size);
    canvas.saveLayer(
      Offset.zero & size,
      Paint()..color = Colors.white.withValues(alpha: opacity),
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0xFF513044), Color(0xFF180F20)],
        ).createShader(Offset.zero & size),
    );
    canvas.save();
    if (!reduced) {
      final zoom = 1 + .035 * math.sin(progress * math.pi);
      canvas.translate(size.width / 2, size.height / 2);
      canvas.scale(zoom);
      canvas.translate(-size.width / 2, -size.height / 2);
    }
    canvas.drawImageRect(
      image,
      source,
      destination,
      Paint()..filterQuality = FilterQuality.high,
    );
    if (frame == 6 && blownOut) {
      // Cover only the painted flame with adjacent background from the same frame.
      final flame = Rect.fromLTWH(
        destination.left + destination.width * .47,
        destination.top + destination.height * .09,
        destination.width * .05,
        destination.height * .105,
      );
      final background = Rect.fromLTWH(
        source.left + source.width * .32,
        source.height * .09,
        source.width * .05,
        source.height * .105,
      );
      canvas.drawImageRect(
        image,
        background,
        flame,
        Paint()..filterQuality = FilterQuality.high,
      );
    }
    canvas.restore();
    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    final stage = (progress * 6).clamp(0.0, 6.0);
    final current = stage.floor();
    final blend = Curves.easeInOut.transform(stage - current);
    _frame(canvas, size, current, 1);
    if (current < 6) _frame(canvas, size, current + 1, blend);
    if (reduced) return;
    final time = progress * 10 + ambient * 24;
    final strength = (1 - progress).clamp(.08, 1.0);
    // Project a helix through depth, rather than rotating a flat cake picture.
    for (var i = 0; i < 85; i++) {
      final angle = i * 2.399 + time * .65;
      final z = math.sin(angle);
      final perspective = 1 / (1.4 - z * .3);
      final radius = size.width * (.3 + .14 * (1 - progress));
      final x = size.width / 2 + math.cos(angle) * radius * perspective;
      final y =
          size.height * (.35 + .38 * i / 85) +
          math.sin(angle) * size.height * .06 * perspective;
      final alpha = (.12 + .35 * (z + 1) / 2) * strength;
      final color = const Color(0xFFFFD8B0).withValues(alpha: alpha);
      canvas.drawCircle(
        Offset(x, y),
        (1 + perspective) * (i % 5 == 0 ? 1.8 : .6),
        Paint()..color = color,
      );
      if (i % 5 == 0 && progress < .75) {
        final text = TextPainter(
          textDirection: TextDirection.ltr,
          text: TextSpan(
            text: i.isEven ? '0' : '1',
            style: TextStyle(color: color, fontSize: 9 * perspective),
          ),
        )..layout();
        text.paint(canvas, Offset(x, y));
      }
    }
    for (var i = 0; i < 14; i++) {
      final x =
          (i * .618 * size.width + math.sin(time * .2 + i) * 20) % size.width;
      final y = (i * .217 * size.height - time * (3 + i % 3)) % size.height;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 4, height: 7),
        Paint()..color = const Color(0xFFF1C2D5).withValues(alpha: .2),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CinematicPainter old) =>
      progress != old.progress ||
      ambient != old.ambient ||
      blownOut != old.blownOut ||
      reduced != old.reduced;
}
