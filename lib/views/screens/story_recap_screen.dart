import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/typewriter_text.dart';
import '../../models/story_entry.dart';
import '../widgets/diary_page_background.dart';
import '../widgets/curved_photo_carousel.dart';

/// Handwritten memories above the auto-playing photo carousel.
class StoryRecapScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const StoryRecapScreen({super.key, required this.onComplete});

  @override
  State<StoryRecapScreen> createState() => _StoryRecapScreenState();
}

class _StoryRecapScreenState extends State<StoryRecapScreen> {
  final _player = AudioPlayer();

  // Replace these samples with your diary sentences later.
  static const _sentences = [
    'xxxxxxx',
    'xxxxxxx，xxxxxxx。',
    'xxxxxxx……\nxxxxxxx。',
    'xxxxxxx ♡',
  ];
  int _sentenceIndex = 0;

  void _nextSentence() {
    setState(() => _sentenceIndex = (_sentenceIndex + 1) % _sentences.length);
  }

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
    const ink = Color(0xFF795551);
    return DiaryPageBackground(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _nextSentence,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final textScale = MediaQuery.textScalerOf(context).scale(1);
              final pageHeight =
                  (constraints.maxHeight < 720
                      ? 720.0
                      : constraints.maxHeight) +
                  (textScale > 1 ? (textScale - 1) * 220 : 0);
              return SingleChildScrollView(
                child: SizedBox(
                  height: pageHeight,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(48, 22, 58, 0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                'Dear diary ♡',
                                style: GoogleFonts.caveat(
                                  fontSize: 34,
                                  color: ink,
                                ),
                              ),
                            ),
                            Text(
                              'OUR LITTLE STORY',
                              style: GoogleFonts.cormorantGaramond(
                                fontSize: 10,
                                letterSpacing: 1.5,
                                color: const Color(0xFFA17D75),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        flex: 32,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(48, 20, 36, 8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Semantics(
                                    button: true,
                                    label: '下一句日记',
                                    onTap: _nextSentence,
                                    child: TypewriterText(
                                      key: ValueKey(_sentenceIndex),
                                      text: _sentences[_sentenceIndex],
                                      charDuration: const Duration(
                                        milliseconds: 120,
                                      ),
                                      style: GoogleFonts.longCang(
                                        fontSize: 32,
                                        height: 1.65,
                                        color: ink,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  const Icon(
                                    Icons.touch_app_outlined,
                                    size: 14,
                                    color: Color(0xFFA17D75),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '轻触纸页，继续写下去',
                                    style: GoogleFonts.notoSerifSc(
                                      fontSize: 11,
                                      color: const Color(0xFFA17D75),
                                    ),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '${_sentenceIndex + 1} / ${_sentences.length}',
                                    style: GoogleFonts.caveat(
                                      fontSize: 18,
                                      color: const Color(0xFFA17D75),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 58,
                        child: CurvedPhotoCarousel(imageAssets: _photos),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(40, 6, 28, 18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'little moments, kept forever.',
                                style: GoogleFonts.caveat(
                                  fontSize: 19,
                                  color: const Color(0xFFA17D75),
                                ),
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                foregroundColor: ink,
                                backgroundColor: const Color(0xFFF0D4CF),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              onPressed: widget.onComplete,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '下一页',
                                    style: GoogleFonts.longCang(fontSize: 22),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 17,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
