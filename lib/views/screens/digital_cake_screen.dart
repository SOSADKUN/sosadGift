import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:audioplayers/audioplayers.dart';
import '../../config/treasure_hunt_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

/// A dreamlike cake reveal; only the end of the birthday song advances it.
class DigitalCakeScreen extends StatefulWidget {
  const DigitalCakeScreen({super.key, this.onComplete, this.birthdayPlayer});
  final VoidCallback? onComplete;

  /// Optional player for testing audio completion independently of native audio.
  final AudioPlayer? birthdayPlayer;

  @override
  State<DigitalCakeScreen> createState() => _DigitalCakeScreenState();
}

class _DigitalCakeScreenState extends State<DigitalCakeScreen>
    with TickerProviderStateMixin {
  late final _birthdayPlayer = widget.birthdayPlayer ?? AudioPlayer();
  bool _completed = false;
  bool _musicError = false;
  StreamSubscription<void>? _birthdayComplete;
  bool _songFinished = false;
  bool _blownOut = false;
  bool _micActive = false;

  AudioRecorder? _recorder;
  Timer? _introTimer;
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

    _flyController =
        AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 4200),
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed) {
            _crossfadeController.forward();
          }
        });

    _crossfadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _digits = List.generate(100, (i) => _DigitParticle(seed: i));

    // Brief black screen before the digits start flying in.
    _introTimer = Timer(const Duration(milliseconds: 400), () {
      if (mounted) _flyController.forward();
    });

    _birthdayComplete = _birthdayPlayer.onPlayerComplete.listen((_) {
      _songFinished = true;
      _scheduleFinale();
    });
    _playBirthdaySong();
  }

  Future<void> _playBirthdaySong() async {
    if (mounted) setState(() => _musicError = false);
    try {
      await _birthdayPlayer.setReleaseMode(ReleaseMode.release);
      if (!mounted) return;
      await _birthdayPlayer.play(
        AssetSource(TreasureHuntConfig.birthdaySong),
        volume: 0.65,
      );
    } catch (error) {
      debugPrint('Birthday music unavailable: $error');
      if (mounted) setState(() => _musicError = true);
    }
  }

  Future<void> _initMic() async {
    final status = await Permission.microphone.request();
    if (!mounted || !status.isGranted || _blownOut) return;

    try {
      final recorder = _recorder ??= AudioRecorder();
      if (!await recorder.hasPermission() || !mounted) return;
      final stream = await recorder.startStream(
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
    _recorder?.stop();
    _scheduleFinale();
  }

  void _scheduleFinale() {
    if (!mounted || !_songFinished || _completed) return;
    _completed = true;
    widget.onComplete?.call();
  }

  @override
  void dispose() {
    _introTimer?.cancel();
    _birthdayComplete?.cancel();
    _birthdayPlayer.dispose();
    _flameController.dispose();
    _blowController.dispose();
    _glowController.dispose();
    _flyController.dispose();
    _crossfadeController.dispose();
    _audioSub?.cancel();
    _recorder?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF191329),
      body: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment(0, -.15),
                radius: 1.1,
                colors: [
                  Color(0xFF594061),
                  Color(0xFF2B203D),
                  Color(0xFF120F20),
                ],
                stops: [0, .5, 1],
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _glowController,
            builder: (_, _) =>
                CustomPaint(painter: _DreamSkyPainter(_glowController.value)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const Text(
                    'A LITTLE MAGIC, JUST FOR YOU',
                    style: TextStyle(
                      color: Color(0xFFD9BDD0),
                      fontSize: 9,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Happy Birthday',
                    style: TextStyle(
                      color: Color(0xFFFFF0E2),
                      fontSize: 34,
                      fontFamily: 'serif',
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: SizedBox(
                          width: 340,
                          height: 420,
                          child: _buildCakeScene(),
                        ),
                      ),
                    ),
                  ),
                  AnimatedBuilder(
                    animation: _crossfadeController,
                    builder: (_, child) => Opacity(
                      opacity: _crossfadeController.value,
                      child: child,
                    ),
                    child: Column(
                      children: [
                        Text(
                          _blownOut ? '愿你的每一年，都被温柔以待。' : '闭上眼睛，许一个愿。',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFF7E5DF),
                            fontSize: 17,
                            letterSpacing: 2,
                            height: 1.7,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _blownOut ? '生日快乐，我会一直在。' : '轻点烛光，让心愿闪闪发亮',
                          style: const TextStyle(
                            color: Color(0xFFBBA3BE),
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_musicError)
                    TextButton.icon(
                      onPressed: _playBirthdaySong,
                      icon: const Icon(
                        Icons.music_note,
                        color: Color(0xFFECD2A4),
                      ),
                      label: const Text(
                        '重新播放生日歌',
                        style: TextStyle(color: Color(0xFFECD2A4)),
                      ),
                    )
                  else
                    IconButton(
                      tooltip: _micActive ? '可以对着麦克风吹熄蜡烛' : '开启吹蜡烛',
                      onPressed: _micActive || _blownOut ? null : _initMic,
                      icon: Icon(
                        _micActive ? Icons.mic : Icons.mic_none,
                        size: 18,
                        color: const Color(0xFFBBA3BE),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDigit(_DigitParticle d, Size size, double progress) {
    final localProgress = ((progress - d.delay) / (1 - d.delay)).clamp(
      0.0,
      1.0,
    );
    final eased = Curves.easeOutCubic.transform(localProgress);

    final center = Offset(size.width / 2, size.height / 2);
    final halfDiagonal =
        sqrt(size.width * size.width + size.height * size.height) / 2;
    final start =
        center +
        Offset(cos(d.startAngle), sin(d.startAngle)) *
            (d.startRadius * halfDiagonal);
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

  Widget _buildCakeScene() => AnimatedBuilder(
    animation: Listenable.merge([
      _flyController,
      _crossfadeController,
      _flameController,
      _blowController,
    ]),
    builder: (context, _) {
      final reveal = Curves.easeInOutCubic.transform(
        _crossfadeController.value,
      );
      return Stack(
        fit: StackFit.expand,
        children: [
          Opacity(
            opacity: reveal,
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - reveal)),
              child: CustomPaint(painter: _CakePainter()),
            ),
          ),
          if (reveal < 1)
            Opacity(
              opacity: 1 - reveal,
              child: Stack(
                children: [
                  for (final digit in _digits)
                    _buildDigit(
                      digit,
                      const Size(340, 420),
                      _flyController.value,
                    ),
                ],
              ),
            ),
          Positioned(
            top: 70,
            left: 142,
            width: 56,
            height: 64,
            child: GestureDetector(
              key: const ValueKey('birthday-candle'),
              onTap: reveal == 1 ? _blowOutCandle : null,
              behavior: HitTestBehavior.opaque,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 700),
                opacity: _blownOut ? 0 : reveal,
                child: Center(
                  child: Transform.scale(
                    scale: .9 + _flameController.value * .12,
                    child: CustomPaint(
                      size: const Size(18, 32),
                      painter: _FlamePainter(),
                    ),
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: CustomPaint(
              painter: _ParticlePainter(
                particles: _particles,
                progress: _blowController.value,
                active: _blownOut,
              ),
            ),
          ),
        ],
      );
    },
  );
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
        (Random(seed + 3).nextDouble() - 0.5) *
            (seed % 3 == 0
                ? 240
                : seed % 3 == 1
                ? 180
                : 120),
        (seed % 3 == 0
                ? 80
                : seed % 3 == 1
                ? 15
                : -45) +
            Random(seed + 4).nextDouble() * 35,
      ),
      fontSize = 14 + Random(seed + 5).nextDouble() * 14,
      color = const [
        Color(0xFFE5B6CE),
        Color(0xFFFFF0DF),
        Color(0xFFCAB8E6),
        Color(0xFFECD2A4),
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
        Color(0xFFECD2A4),
        Color(0xFFE5B6CE),
        Color(0xFFCAB8E6),
        Color(0xFFFFF0DF),
        Color(0xFFD9BDD0),
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

    final origin = Offset(size.width / 2, 100);
    for (final p in particles) {
      final t = progress;
      final dx = cos(p.angle) * p.speed * t;
      final dy = sin(p.angle) * p.speed * t - 90 * t * t; // upward arc
      final opacity = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.drawCircle(origin + Offset(dx, dy), p.size * (1 - t * 0.4), paint);
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
      ..cubicTo(
        size.width * 1.1,
        size.height * 0.4,
        size.width * 0.8,
        size.height * 0.7,
        size.width / 2,
        size.height,
      )
      ..cubicTo(
        size.width * 0.2,
        size.height * 0.7,
        -size.width * 0.1,
        size.height * 0.4,
        size.width / 2,
        0,
      );

    final outerPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFFFF176), Color(0xFFFF7043), Color(0xFFE64A19)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(outerPath, outerPaint);

    final innerPath = Path()
      ..moveTo(size.width / 2, size.height * 0.3)
      ..cubicTo(
        size.width * 0.75,
        size.height * 0.55,
        size.width * 0.65,
        size.height * 0.8,
        size.width / 2,
        size.height * 0.95,
      )
      ..cubicTo(
        size.width * 0.35,
        size.height * 0.8,
        size.width * 0.25,
        size.height * 0.55,
        size.width / 2,
        size.height * 0.3,
      );
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
    canvas.save();
    canvas.scale(size.width / 340, size.height / 420);
    final glow = Rect.fromLTWH(15, 75, 310, 310);
    canvas.drawOval(
      glow,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x55F6BDCF), Color(0x00F6BDCF)],
        ).createShader(glow),
    );
    canvas.drawOval(
      const Rect.fromLTWH(25, 348, 290, 42),
      Paint()
        ..color = const Color(0x554A2C59)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );
    final plate = const Rect.fromLTWH(28, 345, 284, 32);
    canvas.drawOval(
      plate,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFF6E7D0), Color(0xFFB79379), Color(0xFFF6E7D0)],
        ).createShader(plate),
    );
    canvas.drawOval(
      const Rect.fromLTWH(36, 346, 268, 19),
      Paint()..color = const Color(0xFFFFF1E5),
    );
    _tier(
      canvas,
      const Rect.fromLTWH(50, 265, 240, 86),
      const Color(0xFFE2B6D2),
      const Color(0xFF9E79AC),
    );
    _tier(
      canvas,
      const Rect.fromLTWH(80, 201, 180, 72),
      const Color(0xFFF4D8DF),
      const Color(0xFFC28EA8),
    );
    _tier(
      canvas,
      const Rect.fromLTWH(110, 150, 120, 59),
      const Color(0xFFFFEBDC),
      const Color(0xFFD1AEBB),
    );
    for (final position in [
      const Offset(78, 280),
      const Offset(92, 291),
      const Offset(250, 211),
      const Offset(235, 220),
      const Offset(121, 160),
    ]) {
      _rose(canvas, position);
    }
    final candle = RRect.fromRectAndRadius(
      const Rect.fromLTWH(165, 117, 10, 38),
      const Radius.circular(3),
    );
    canvas.drawRRect(
      candle,
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFFFFF7E9), Color(0xFFD6B386), Color(0xFFFFECD3)],
        ).createShader(candle.outerRect),
    );
    canvas.drawLine(
      const Offset(170, 112),
      const Offset(170, 117),
      Paint()
        ..color = const Color(0xFF6D4F56)
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  void _tier(Canvas canvas, Rect rect, Color light, Color dark) {
    final body = RRect.fromRectAndRadius(rect, const Radius.circular(14));
    canvas.drawRRect(
      body,
      Paint()
        ..shader = LinearGradient(
          colors: [dark, light, light, dark],
          stops: const [0, .3, .6, 1],
        ).createShader(rect),
    );
    canvas.save();
    canvas.clipRRect(body);
    for (double x = rect.left + 8; x < rect.right; x += 10) {
      canvas.drawLine(
        Offset(x, rect.top + 15),
        Offset(x, rect.bottom - 8),
        Paint()
          ..color = Colors.white.withValues(alpha: .12)
          ..strokeWidth = 1,
      );
    }
    final icing = Path()
      ..moveTo(rect.left, rect.top + 6)
      ..lineTo(rect.right, rect.top + 6)
      ..lineTo(rect.right, rect.top + 16);
    for (double x = rect.right; x > rect.left; x -= 20) {
      icing.quadraticBezierTo(
        x - 10,
        rect.top + 38,
        max(rect.left, x - 20),
        rect.top + 16,
      );
    }
    icing.close();
    canvas.drawPath(icing, Paint()..color = const Color(0xFFFBECE5));
    canvas.restore();
    final top = Rect.fromLTWH(rect.left, rect.top - 8, rect.width, 24);
    canvas.drawOval(
      top,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFFF5EA), Color(0xFFECD1DB)],
        ).createShader(top),
    );
    for (double x = rect.left + 6; x < rect.right - 4; x += 11) {
      canvas.drawCircle(
        Offset(x, rect.bottom - 5),
        3,
        Paint()..color = const Color(0xFFFFE8CE),
      );
      canvas.drawCircle(
        Offset(x - .7, rect.bottom - 6),
        .9,
        Paint()..color = Colors.white,
      );
    }
    canvas.drawLine(
      Offset(rect.left + 8, rect.bottom - 13),
      Offset(rect.right - 8, rect.bottom - 13),
      Paint()
        ..color = const Color(0x88E8C59C)
        ..strokeWidth = 1,
    );
  }

  void _rose(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.drawOval(
      const Rect.fromLTWH(-12, 0, 17, 6),
      Paint()..color = const Color(0xFF9EAA9A),
    );
    for (int i = 0; i < 5; i++) {
      final angle = i * 2 * pi / 5;
      canvas.drawCircle(
        Offset(cos(angle) * 4, sin(angle) * 4),
        5.5,
        Paint()..color = const Color(0xFFE9B3C8),
      );
    }
    canvas.drawCircle(Offset.zero, 4, Paint()..color = const Color(0xFFBE809C));
    canvas.drawArc(
      const Rect.fromLTWH(-3, -3, 6, 6),
      -.8,
      4.5,
      false,
      Paint()
        ..color = const Color(0xFFF6D2DB)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CakePainter oldDelegate) => false;
}

class _DreamSkyPainter extends CustomPainter {
  final double phase;
  _DreamSkyPainter(this.phase);

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random(17);
    for (int i = 0; i < 70; i++) {
      final position = Offset(
        random.nextDouble() * size.width,
        random.nextDouble() * size.height,
      );
      final radius = .6 + random.nextDouble() * 1.6;
      final shimmer = .2 + .55 * (.5 + .5 * sin(phase * pi * 2 + i));
      final paint = Paint()
        ..color = const Color(0xFFF5DCD1).withValues(alpha: shimmer);
      canvas.drawCircle(position, radius, paint);
      if (i % 9 == 0) {
        paint.strokeWidth = .6;
        canvas.drawLine(
          position - const Offset(0, 5),
          position + const Offset(0, 5),
          paint,
        );
        canvas.drawLine(
          position - const Offset(5, 0),
          position + const Offset(5, 0),
          paint,
        );
      }
    }
    for (int i = 0; i < 8; i++) {
      final position = Offset(
        (.5 + .48 * sin(i * 2.3 + phase * .15)) * size.width,
        (.5 + .46 * cos(i * 1.7 + phase * .12)) * size.height,
      );
      canvas.drawCircle(
        position,
        20 + i * 4.0,
        Paint()
          ..color = const Color(0xFFDFB5D9).withValues(alpha: .035)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _DreamSkyPainter oldDelegate) =>
      phase != oldDelegate.phase;
}
