import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/story_entry.dart';
import '../widgets/diary_page_background.dart';
import '../widgets/curved_photo_carousel.dart';

/// Replaces the old page-by-page diary flow: a full-screen photo slideshow
/// split top-to-bottom into 30% (reserved for captions, added later) / 60%
/// (the curved auto-playing carousel) / 10% (a single "next page" button).
class StoryRecapScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const StoryRecapScreen({super.key, required this.onComplete});

  @override
  State<StoryRecapScreen> createState() => _StoryRecapScreenState();
}

class _StoryRecapScreenState extends State<StoryRecapScreen> {
  final _player = AudioPlayer();

  late final List<String?> _photos = [
    for (final entry in kStoryEntries)
      for (final step in entry.steps) step.imageAsset,
  ];

  @override
  void initState() {
    super.initState();
    _playMusic();
  }

  Future<void> _playMusic() async {
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      // Drop your track at assets/audio/story_recap_bgm.mp3 and register it
      // under pubspec.yaml's `assets:` list — playback picks it up as-is.
      await _player.play(AssetSource('audio/story_recap_bgm.mp3'), volume: 0.5);
    } catch (_) {
      // No track yet — screen still works silently without music.
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DiaryPageBackground(
      child: SafeArea(
        child: Column(
          children: [
            // Reserved for subtitles/captions — left blank for now.
            const Expanded(flex: 30, child: SizedBox.expand()),
            Expanded(
              flex: 60,
              child: CurvedPhotoCarousel(imageAssets: _photos),
            ),
            Expanded(
              flex: 10,
              child: Center(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.pinkAccent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 14),
                  ),
                  onPressed: widget.onComplete,
                  child: const Text('下一页'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
