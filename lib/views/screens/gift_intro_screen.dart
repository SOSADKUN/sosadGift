import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:audioplayers/audioplayers.dart';

/// Black screen with background music and a sequence of sentences that pop
/// in one at a time, then hands off into the game hub.
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
  static const _holdDuration = Duration(seconds: 2);

  final _player = AudioPlayer();
  late final AnimationController _glowController;
  int _index = 0;
  Timer? _advanceTimer;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _playMusic();
    _scheduleAdvance();
  }

  Future<void> _playMusic() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Drop your track at assets/audio/gift_intro_bgm.mp3 and register it
      // under pubspec.yaml's `assets:` list — playback picks it up as-is.
      await _player.play(AssetSource('audio/gift_intro_bgm.mp3'), volume: 0.6);
    } catch (_) {
      // No track yet — screen still works silently without music.
    }
  }

  void _scheduleAdvance() {
    _advanceTimer = Timer(_holdDuration, () {
      if (!mounted) return;
      if (_index >= _sentences.length - 1) {
        widget.onComplete();
      } else {
        setState(() => _index++);
        _scheduleAdvance();
      }
    });
  }

  @override
  void dispose() {
    _advanceTimer?.cancel();
    _glowController.dispose();
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      alignment: Alignment.center,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              final t = _glowController.value;
              return Container(
                width: 260 + t * 40,
                height: 260 + t * 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.pinkAccent.withValues(alpha: 0.12 + t * 0.06),
                      Colors.transparent,
                    ],
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (child, animation) => ScaleTransition(
                scale:
                    CurvedAnimation(parent: animation, curve: Curves.elasticOut),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: Text(
                _sentences[_index],
                key: ValueKey(_index),
                textAlign: TextAlign.center,
                style: GoogleFonts.zhiMangXing(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w600,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
