import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import '../../models/story_entry.dart';
import '../widgets/memory_journey.dart';

/// Music accompanies the reversible photo journey.
class StoryRecapScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const StoryRecapScreen({super.key, required this.onComplete});

  @override
  State<StoryRecapScreen> createState() => _StoryRecapScreenState();
}

class _StoryRecapScreenState extends State<StoryRecapScreen> {
  final _player = AudioPlayer();

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
  Widget build(BuildContext context) =>
      MemoryJourney(entries: kStoryEntries, onComplete: widget.onComplete);
}
