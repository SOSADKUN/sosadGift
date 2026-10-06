import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';

class DiaryOpenScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const DiaryOpenScreen({super.key, required this.onComplete});

  @override
  State<DiaryOpenScreen> createState() => _DiaryOpenScreenState();
}

class _DiaryOpenScreenState extends State<DiaryOpenScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _whiteFade = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  late final CurvedAnimation _opacity = CurvedAnimation(
    parent: _whiteFade,
    curve: Curves.easeInOutCubic,
  );
  bool _finished = false;

  Future<void> _finishVideo() async {
    if (_finished) return;
    _finished = true;
    await _whiteFade.forward();
    if (mounted) widget.onComplete();
  }

  @override
  void dispose() {
    _opacity.dispose();
    _whiteFade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        VideoPlayerWidget(
          assetPath: 'assets/videos/diaryOpen.mp4',
          loop: false,
          showTapToSkip: false,
          containFrom: const Duration(seconds: 10),
          containedBackgroundColor: Colors.white,
          onComplete: _finishVideo,
        ),
        AbsorbPointer(
          child: FadeTransition(
            opacity: _opacity,
            child: const ColoredBox(color: Colors.white),
          ),
        ),
      ],
    );
  }
}
