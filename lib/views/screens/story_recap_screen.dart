import 'package:flutter/material.dart';
import '../../models/story_entry.dart';
import '../../services/fading_music.dart';
import '../widgets/memory_journey.dart';

/// Music follows the chapter in either direction through the photo journey.
class StoryRecapScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const StoryRecapScreen({super.key, required this.onComplete});

  @override
  State<StoryRecapScreen> createState() => _StoryRecapScreenState();
}

class _StoryRecapScreenState extends State<StoryRecapScreen>
    with WidgetsBindingObserver {
  final _music = FadingMusic();
  bool _completing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _changeChapter(kStoryEntries.first.year);
  }

  void _changeChapter(String year) {
    if (_completing) return;
    final index = kStoryEntries.indexWhere((entry) => entry.year == year);
    if (index >= 0) {
      _music.play(
        'music/story${index + 1}.mp3',
        startPosition: switch (index) {
          0 => Duration.zero,
          2 => const Duration(seconds: 1),
          3 => const Duration(seconds: 15),
          _ => Duration.zero,
        },
      );
    }
  }

  Future<void> _complete() async {
    if (_completing) return;
    _completing = true;
    await _music.stop();
    if (mounted) widget.onComplete();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _music.setPaused(state != AppLifecycleState.resumed);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _music.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MemoryJourney(
    entries: kStoryEntries,
    onChapterChanged: _changeChapter,
    onComplete: _complete,
  );
}
