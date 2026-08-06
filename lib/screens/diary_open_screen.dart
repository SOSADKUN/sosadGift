import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';

class DiaryOpenScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const DiaryOpenScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return VideoPlayerWidget(
      assetPath: 'assets/videos/diaryOpen.mp4',
      loop: false,
      showTapToSkip: false,
      onComplete: onComplete, 
    );
  }
}