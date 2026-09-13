import 'dart:math' as math;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single cinematic invitation, with four accumulating lines of copy.
class GiftIntroScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const GiftIntroScreen({super.key, required this.onComplete});

  @override
  State<GiftIntroScreen> createState() => _GiftIntroScreenState();
}

class _GiftIntroScreenState extends State<GiftIntroScreen>
    with SingleTickerProviderStateMixin {
  static const _sentences = [
    '前年我的生日app不是很完美',
    '今年我回来了！！噗哈哈哈',
    '这次也有30秒点30个小鸡毛哟OwO',
    'Lezz go 展示',
  ];
  static const _gold = Color(0xFFECD2A4);
  late final AnimationController _timeline;
  final _player = AudioPlayer();
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    _timeline =
        AnimationController(
          vsync: this,
          duration: const Duration(seconds: 12),
          animationBehavior: AnimationBehavior.preserve,
        )
          ..addStatusListener((status) {
            if (status == AnimationStatus.completed && !_completed) {
              _completed = true;
              widget.onComplete();
            }
          });
    _playMusic();
  }

  Future<void> _playMusic() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      if (!mounted) return;
      await _player.play(AssetSource('audio/gift_intro_bgm.mp3'), volume: 0.6);
    } catch (_) {
      // The optional soundtrack is not bundled yet; the intro works silently.
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preserve time to read, while respecting reduced-motion preferences.
    if (!_timeline.isAnimating && !_completed) _timeline.forward();
  }

  @override
  void dispose() {
    _timeline.dispose();
    _player.dispose();
    super.dispose();
  }

  double _reveal(double start) => Curves.easeOutCubic.transform(
    ((_timeline.value - start) / 0.09).clamp(0.0, 1.0),
  );

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Material(
      color: const Color(0xFF130F21),
      child: AnimatedBuilder(
        animation: _timeline,
        builder: (context, _) {
          return Stack(
            fit: StackFit.expand,
            children: [
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF30203E),
                      Color(0xFF171226),
                      Color(0xFF100F1D),
                    ],
                  ),
                ),
              ),
              ExcludeSemantics(
                child: CustomPaint(
                  painter: _NightPainter(
                    progress: reducedMotion ? 0 : _timeline.value,
                  ),
                ),
              ),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 520),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 28,
                                vertical: 36,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: _gold,
                                    size: 26,
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    'A LITTLE ADVENTURE',
                                    style: GoogleFonts.cormorantGaramond(
                                      fontSize: 15,
                                      letterSpacing: 3.5,
                                      color: _gold,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const SizedBox(
                                    width: 42,
                                    child: Divider(color: Color(0x667E658E)),
                                  ),
                                  const SizedBox(height: 32),
                                  for (var i = 0; i < _sentences.length; i++)
                                    _line(i, reducedMotion),
                                  const SizedBox(height: 32),
                                  Opacity(
                                    opacity: _reveal(0.72),
                                    child: Column(
                                      children: [
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: List.generate(
                                            4,
                                            (index) => Container(
                                              width: 5,
                                              height: 5,
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 5,
                                                  ),
                                              decoration: const BoxDecoration(
                                                color: _gold,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          '小小挑战，藏着大大惊喜',
                                          style: GoogleFonts.notoSansSc(
                                            fontSize: 12,
                                            letterSpacing: 2,
                                            color: const Color(0xFFB8A9C3),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _line(int index, bool reducedMotion) {
    final reveal = _reveal(0.07 + index * 0.17);
    final last = index == 3;
    return Padding(
      padding: EdgeInsets.only(bottom: last ? 0 : 25, top: last ? 15 : 0),
      child: ExcludeSemantics(
        excluding: reveal < 0.5,
        child: Opacity(
          opacity: reveal,
          child: Transform.translate(
            offset: Offset(0, reducedMotion ? 0 : 20 * (1 - reveal)),
            child: Text(
              _sentences[index],
              textAlign: TextAlign.center,
              style: last
                  ? GoogleFonts.maShanZheng(
                      fontSize: 43,
                      height: 1.3,
                      color: _gold,
                      shadows: [
                        Shadow(
                          color: _gold.withValues(alpha: 0.25),
                          blurRadius: 24,
                        ),
                      ],
                    )
                  : GoogleFonts.notoSerifSc(
                      fontSize: index == 2 ? 18 : 21,
                      height: 1.9,
                      fontWeight: index == 1
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: index == 1
                          ? const Color(0xFFFFE9DF)
                          : const Color(0xFFD6CADF),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NightPainter extends CustomPainter {
  final double progress;
  const _NightPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final glow = Offset(size.width * 0.5, size.height * 0.42);
    final radius = size.longestSide * 0.6;
    canvas.drawCircle(
      glow,
      radius,
      Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFF9A638E).withValues(alpha: 0.17),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: glow, radius: radius)),
    );

    final random = math.Random(917);
    for (var i = 0; i < 48; i++) {
      final x = random.nextDouble() * size.width;
      final y =
          (random.nextDouble() * size.height - progress * 35 + size.height) %
          size.height;
      final shimmer =
          0.2 + 0.35 * (0.5 + 0.5 * math.sin(progress * math.pi * 6 + i));
      canvas.drawCircle(
        Offset(x, y),
        0.6 + random.nextDouble() * 1.2,
        Paint()..color = const Color(0xFFECD2A4).withValues(alpha: shimmer),
      );
    }
    final border = Rect.fromLTWH(
      14,
      14,
      math.max(0, size.width - 28),
      math.max(0, size.height - 28),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(border, const Radius.circular(28)),
      Paint()
        ..color = const Color(0xFFECD2A4).withValues(alpha: 0.13)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7,
    );
  }

  @override
  bool shouldRepaint(_NightPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
