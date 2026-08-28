import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// Final screen: digital cake with a candle to blow out.
///
/// Two ways to extinguish the candle:
///   1. Tap it (always works, no permissions needed).
///   2. Actually blow into the microphone — uses `noise_meter` to watch
///      ambient decibel level and treats a sudden loud burst of noise
///      close to the mic as a "blow".
///
/// Setup required for real blow detection:
///   pubspec.yaml:
///     dependencies:
///       record: ^5.0.0
///       permission_handler: ^11.3.0
///
///   Android (android/app/src/main/AndroidManifest.xml):
///     <uses-permission android:name="android.permission.RECORD_AUDIO"/>
///
///   iOS (ios/Runner/Info.plist):
///     <key>NSMicrophoneUsageDescription</key>
///     <string>需要麦克风来检测吹蜡烛的动作</string>
class DigitalCakeScreen extends StatefulWidget {
  const DigitalCakeScreen({super.key});

  @override
  State<DigitalCakeScreen> createState() => _DigitalCakeScreenState();
}

class _DigitalCakeScreenState extends State<DigitalCakeScreen>
    with TickerProviderStateMixin {
  bool _blownOut = false;
  bool _micActive = false;

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _audioSub;

  // dBFS (decibels relative to full scale) — negative values, 0 is loudest
  // possible. Ambient room noise is typically around -50 to -35 dBFS; a
  // close blow spikes up sharply toward 0. Tune this if it's too
  // sensitive/insensitive for your mic setup.
  static const double _blowThresholdDb = -20.0;

  late final AnimationController _flameController; // idle flicker loop
  late final AnimationController _blowController; // particle burst / smoke
  late final AnimationController _glowController; // ambient light pulse

  late final AnimationController _flyController; // digits converge to center
  late final AnimationController _crossfadeController; // digits -> cake

  late final List<_Particle> _particles;
  late final List<_DigitParticle> _digits;

  @override
  void initState() {
    super.initState();

    _flameController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..repeat(reverse: true);

    _blowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _particles = List.generate(26, (i) => _Particle(seed: i));

    _flyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          _crossfadeController.forward();
        }
      });

    _crossfadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _digits = List.generate(40, (i) => _DigitParticle(seed: i));

    // Brief black screen before the digits start flying in.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _flyController.forward();
    });

    _initMic();
  }

  Future<void> _initMic() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    try {
      if (!await _recorder.hasPermission()) return;
      final stream = await _recorder.startStream(
        const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ),
      );
      _audioSub = stream.listen(_onAudioChunk, onError: (_) {});
      if (mounted) setState(() => _micActive = true);
    } catch (_) {
      // Simulator / unsupported platform — silently fall back to tap-only.
    }
  }

  void _onAudioChunk(Uint8List chunk) {
    if (_blownOut) return;
    if (_decibelsFromPcm16(chunk) >= _blowThresholdDb) {
      _blowOutCandle();
    }
  }

  /// Computes RMS-based dBFS from a chunk of little-endian 16-bit PCM audio.
  double _decibelsFromPcm16(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    if (sampleCount == 0) return -160.0;

    final byteData = ByteData.sublistView(bytes);
    double sumSquares = 0;
    for (int i = 0; i < sampleCount; i++) {
      final sample = byteData.getInt16(i * 2, Endian.little);
      sumSquares += sample * sample;
    }

    final rms = sqrt(sumSquares / sampleCount);
    if (rms <= 0) return -160.0;
    return 20 * log(rms / 32768) / ln10;
  }

  void _blowOutCandle() {
    if (_blownOut) return;
    setState(() => _blownOut = true);
    HapticFeedback.mediumImpact();
    _flameController.stop();
    _blowController.forward(from: 0);
    _audioSub?.cancel();
    _recorder.stop();
  }

  @override
  void dispose() {
    _flameController.dispose();
    _blowController.dispose();
    _glowController.dispose();
    _flyController.dispose();
    _crossfadeController.dispose();
    _audioSub?.cancel();
    _recorder.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Cake scene fades in as the digits converge and dissolve.
        AnimatedBuilder(
          animation: _crossfadeController,
          builder: (context, child) => Opacity(
            opacity: _crossfadeController.value,
            child: IgnorePointer(
              ignoring: _crossfadeController.value < 1,
              child: child,
            ),
          ),
          child: _buildCakeScene(),
        ),

        // Digits flying in from off-screen, converging to the center, then
        // dissolving away to reveal the cake underneath.
        AnimatedBuilder(
          animation: Listenable.merge([_flyController, _crossfadeController]),
          builder: (context, _) {
            final introOpacity = 1 - _crossfadeController.value;
            if (introOpacity <= 0) return const SizedBox.shrink();
            final flashOpacity = _crossfadeController.value < 0.3
                ? (1 - _crossfadeController.value / 0.3) * 0.6
                : 0.0;
            return Opacity(
              opacity: introOpacity,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final size = Size(constraints.maxWidth, constraints.maxHeight);
                  return Stack(
                    children: [
                      for (final d in _digits)
                        _buildDigit(d, size, _flyController.value),
                      Center(
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withValues(alpha: flashOpacity),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDigit(_DigitParticle d, Size size, double progress) {
    final localProgress =
        ((progress - d.delay) / (1 - d.delay)).clamp(0.0, 1.0);
    final eased = Curves.easeOutCubic.transform(localProgress);

    final center = Offset(size.width / 2, size.height / 2);
    final halfDiagonal = sqrt(size.width * size.width + size.height * size.height) / 2;
    final start = center +
        Offset(cos(d.startAngle), sin(d.startAngle)) * (d.startRadius * halfDiagonal);
    final target = center + d.targetJitter;
    final pos = Offset.lerp(start, target, eased)!;
    final scale = 1.0 - eased * 0.5;
    final opacity = localProgress < 0.08 ? localProgress / 0.08 : 1.0;

    return Positioned(
      left: pos.dx - d.fontSize / 2,
      top: pos.dy - d.fontSize / 2,
      child: Opacity(
        opacity: opacity,
        child: Transform.scale(
          scale: scale,
          child: Text(
            d.char,
            style: TextStyle(
              color: d.color,
              fontSize: d.fontSize,
              fontFamily: 'monospace',
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCakeScene() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Ambient candlelight glow behind the whole scene.
        AnimatedBuilder(
          animation: _glowController,
          builder: (context, _) {
            final t = _glowController.value;
            final opacity = _blownOut ? 0.0 : 0.22 + t * 0.08;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              width: 260 + t * 30,
              height: 260 + t * 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    Colors.orange.withOpacity(opacity),
                    Colors.transparent,
                  ],
                ),
              ),
            );
          },
        ),

        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 220,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Smoke / confetti particle burst.
                  AnimatedBuilder(
                    animation: _blowController,
                    builder: (context, _) => CustomPaint(
                      size: const Size(220, 260),
                      painter: _ParticlePainter(
                        particles: _particles,
                        progress: _blowController.value,
                        active: _blownOut,
                      ),
                    ),
                  ),

                  // The cake.
                  const Positioned(
                    bottom: 0,
                    child: CustomPaintCakeWrapper(),
                  ),

                  // The candle flame — tap fallback always available.
                  Positioned(
                    top: 4,
                    child: GestureDetector(
                      onTap: _blowOutCandle,
                      behavior: HitTestBehavior.translucent,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: AnimatedBuilder(
                          animation: _flameController,
                          builder: (context, _) {
                            final flicker =
                                0.85 + _flameController.value * 0.3;
                            return AnimatedOpacity(
                              duration: const Duration(milliseconds: 400),
                              opacity: _blownOut ? 0.0 : 1.0,
                              child: Transform.scale(
                                scale: _blownOut ? 1.0 : flicker,
                                child: CustomPaint(
                                  size: const Size(20, 34),
                                  painter: _FlamePainter(),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.15),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: _blownOut
                  ? const Padding(
                      key: ValueKey('after'),
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '今年、明年、未来的每一年，我也不会缺席。\n生日快乐 🎉',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          height: 1.6,
                        ),
                      ),
                    )
                  : Column(
                      key: const ValueKey('before'),
                      children: [
                        const Text(
                          '闭上眼睛，许个愿',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _micActive
                              ? '然后对着屏幕吹一口气，吹熄蜡烛'
                              : '然后点一下蜡烛，吹熄它吧',
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Small wrapper so the cake sits with a fixed footprint inside the Stack.
class CustomPaintCakeWrapper extends StatelessWidget {
  const CustomPaintCakeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: const Size(180, 170),
      painter: _CakePainter(),
    );
  }
}

// ---------------------------------------------------------------------------
// Digit intro (0/1 digits flying in from off-screen, converging to center)
// ---------------------------------------------------------------------------

class _DigitParticle {
  final String char;
  final double startAngle;
  final double startRadius; // multiple of the screen's half-diagonal
  final Offset targetJitter;
  final double fontSize;
  final Color color;
  final double delay; // staggers when this digit starts moving, 0..1

  _DigitParticle({required int seed})
      : char = Random(seed).nextBool() ? '0' : '1',
        startAngle = Random(seed + 1).nextDouble() * 2 * pi,
        startRadius = 1.0 + Random(seed + 2).nextDouble() * 0.6,
        targetJitter = Offset(
          (Random(seed + 3).nextDouble() - 0.5) * 40,
          (Random(seed + 4).nextDouble() - 0.5) * 40,
        ),
        fontSize = 14 + Random(seed + 5).nextDouble() * 14,
        color = const [
          Colors.pinkAccent,
          Colors.white,
          Color(0xFFB388FF),
          Color(0xFF80D8FF),
        ][seed % 4],
        delay = Random(seed + 6).nextDouble() * 0.35;
}

// ---------------------------------------------------------------------------
// Particles (smoke + confetti burst on blow-out)
// ---------------------------------------------------------------------------

class _Particle {
  final double angle;
  final double speed;
  final double size;
  final Color color;

  _Particle({required int seed})
      : angle = Random(seed).nextDouble() * pi + pi * 1.25,
        speed = 40 + Random(seed + 1).nextDouble() * 70,
        size = 3 + Random(seed + 2).nextDouble() * 5,
        color = const [
          Color(0xFFFFC107),
          Color(0xFFFF4081),
          Color(0xFF40C4FF),
          Color(0xFFFFFFFF),
          Color(0xFF69F0AE),
        ][seed % 5];
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;
  final bool active;

  _ParticlePainter({
    required this.particles,
    required this.progress,
    required this.active,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!active || progress == 0) return;

    final origin = Offset(size.width / 2, 46);
    for (final p in particles) {
      final t = progress;
      final dx = cos(p.angle) * p.speed * t;
      final dy = sin(p.angle) * p.speed * t - 90 * t * t; // upward arc
      final opacity = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withOpacity(opacity);
      canvas.drawCircle(
        origin + Offset(dx, dy),
        p.size * (1 - t * 0.4),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlePainter oldDelegate) => true;
}

// ---------------------------------------------------------------------------
// Flame
// ---------------------------------------------------------------------------

class _FlamePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final outerPath = Path()
      ..moveTo(size.width / 2, 0)
      ..cubicTo(size.width * 1.1, size.height * 0.4, size.width * 0.8,
          size.height * 0.7, size.width / 2, size.height)
      ..cubicTo(size.width * 0.2, size.height * 0.7, -size.width * 0.1,
          size.height * 0.4, size.width / 2, 0);

    final outerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF176), Color(0xFFFF7043), Color(0xFFE64A19)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(outerPath, outerPaint);

    final innerPath = Path()
      ..moveTo(size.width / 2, size.height * 0.3)
      ..cubicTo(size.width * 0.75, size.height * 0.55, size.width * 0.65,
          size.height * 0.8, size.width / 2, size.height * 0.95)
      ..cubicTo(size.width * 0.35, size.height * 0.8, size.width * 0.25,
          size.height * 0.55, size.width / 2, size.height * 0.3);
    canvas.drawPath(innerPath, Paint()..color = const Color(0xFFFFF9C4));
  }

  @override
  bool shouldRepaint(covariant _FlamePainter oldDelegate) => false;
}

// ---------------------------------------------------------------------------
// Cake
// ---------------------------------------------------------------------------

class _CakePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Plate shadow.
    canvas.drawOval(
      Rect.fromCenter(center: Offset(w / 2, h - 6), width: w * 0.95, height: 14),
      Paint()..color = Colors.black.withOpacity(0.25),
    );

    // Bottom tier.
    final bottomRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, h * 0.55, w, h * 0.4),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      bottomRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF8BBD0), Color(0xFFEC407A)],
        ).createShader(bottomRect.outerRect),
    );

    // Top tier.
    final topRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(w * 0.15, h * 0.28, w * 0.7, h * 0.32),
      const Radius.circular(10),
    );
    canvas.drawRRect(
      topRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF3E0), Color(0xFFFFCC80)],
        ).createShader(topRect.outerRect),
    );

    // Frosting drips along the top tier edge.
    final dripPaint = Paint()..color = Colors.white;
    for (int i = 0; i < 6; i++) {
      final x = w * 0.2 + i * (w * 0.6 / 5);
      canvas.drawCircle(Offset(x, h * 0.28), 6, dripPaint);
    }

    // Sprinkles scattered on the bottom tier.
    final sprinkleColors = [
      Colors.redAccent,
      Colors.lightGreen,
      Colors.lightBlue,
      Colors.purpleAccent,
    ];
    final rnd = Random(7);
    for (int i = 0; i < 18; i++) {
      final dx = rnd.nextDouble() * w * 0.8 + w * 0.1;
      final dy = h * 0.6 + rnd.nextDouble() * h * 0.3;
      canvas.drawCircle(
        Offset(dx, dy),
        1.6,
        Paint()..color = sprinkleColors[i % sprinkleColors.length],
      );
    }

    // Candle.
    final candleRect = Rect.fromLTWH(w / 2 - 5, h * 0.02, 10, h * 0.28);
    canvas.drawRect(
      candleRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFE0E0E0)],
        ).createShader(candleRect),
    );
    final stripePaint = Paint()..color = Colors.pinkAccent.withOpacity(0.6);
    for (double y = candleRect.top + 4; y < candleRect.bottom; y += 8) {
      canvas.drawRect(
        Rect.fromLTWH(candleRect.left, y, candleRect.width, 3),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CakePainter oldDelegate) => false;
}