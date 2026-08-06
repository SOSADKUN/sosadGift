import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';

class OldGiftVideoScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const OldGiftVideoScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    return VideoPlayerWidget(
      assetPath: 'assets/videos/old_gift.mp4',
      onComplete: onComplete,
    );
  }
}