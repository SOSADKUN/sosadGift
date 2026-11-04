import 'dart:math' as math;
import 'dart:async';
import '../../config/game_hub_music_config.dart';
import '../../services/game_audio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// A single cinematic invitation, with four accumulating lines of copy.
class GiftIntroScreen extends StatefulWidget {
  final VoidCallback onComplete;
  final GameAudio? audio;
  final Duration? chorusStart;

  const GiftIntroScreen({
    super.key,
    required this.onComplete,
    this.audio,
    this.chorusStart,
  });

  @override
  State<GiftIntroScreen> createState() => _GiftIntroScreenState();
}

class _GiftIntroScreenState extends State<GiftIntroScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _sentences = [
    '前年我的生日app的game不是很完美',
    '今年我又回来了！！噗哈哈哈',
    '然后这次也有30秒点30个小鸡毛哟OwO',
    'Lezz go 展示',
  ];
  static const _gold = Color(0xFFECD2A4);
  late final AnimationController _timeline;
  bool _active = true;
  bool _audioReady = false;
  late final _audio =
      widget.audio ??
      GameAudio(
        GameHubMusicConfig.asset,
        musicVolume: GameHubMusicConfig.volume,
      );
  StreamSubscription<Duration>? _musicPosition;
  Duration get _introDuration =>
      widget.chorusStart ?? GameHubMusicConfig.fallbackIntroDuration;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _timeline =
        AnimationController(
          vsync: this,
          duration: _introDuration,
          animationBehavior: AnimationBehavior.preserve,
        )..addStatusListener((status) {
          if (status == AnimationStatus.completed &&
              !_completed &&
              widget.chorusStart == null) {
            _completed = true;
            widget.onComplete();
          }
        });
    unawaited(_prepareAudio());
  }

  Future<void> _prepareAudio() async {
    _musicPosition = _audio.positions.listen(_checkChorus);
    await _audio.start();
    if (!mounted) return;
    _audioReady = true;
    if (_active) {
      _checkChorus(_audio.musicPosition);
      _timeline.forward();
    }
  }

  void _checkChorus(Duration position) {
    if (!mounted || !_active || _completed || widget.chorusStart == null) {
      return;
    }
    if (position >= widget.chorusStart!) {
      _completed = true;
      widget.onComplete();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    _audio.setForeground(_active);
    if (!_active) {
      _timeline.stop();
    } else if (_audioReady && !_completed) {
      _checkChorus(_audio.musicPosition);
      _timeline.forward();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timeline.dispose();
    _musicPosition?.cancel();
    if (widget.audio == null) unawaited(_audio.dispose());
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
                                    '游戏upgradee！！',
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
                                    opacity: _reveal(.72),
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
                                          '今年的生日 APP卷土重来',
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
    final reveal = _reveal([.07, .24, .41, .58][index]);
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
