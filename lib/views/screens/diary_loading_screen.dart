import 'package:flutter/material.dart';
import '../widgets/video_player_widget.dart';

class DiaryLoadingScreen extends StatelessWidget {
  final VoidCallback onComplete;

  const DiaryLoadingScreen({super.key, required this.onComplete});

  @override
  Widget build(BuildContext context) {
    // loop=true because you want the video idling until the user taps
    // "打开日记" — tapping fires onComplete, which app_flow.dart advances
    // into the white-flash transition.
    return Stack(
      children: [
        VideoPlayerWidget(
          assetPath: 'assets/videos/diaryLoading.mp4',
          loop: true,
          showTapToSkip: false,
          // no onComplete here — it loops forever until tapped below
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 60,
          child: Center(
            child: GestureDetector(
              onTap: onComplete,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white54),
                ),
                child: const Text(
                  '轻触打开日记',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}