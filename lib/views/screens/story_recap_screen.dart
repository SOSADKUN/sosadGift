import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/story_entry.dart';
import '../widgets/diary_page_background.dart';
import '../widgets/story_step_image.dart';
import '../widgets/typewriter_text.dart';

class StoryRecapScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const StoryRecapScreen({super.key, required this.onComplete});

  @override
  State<StoryRecapScreen> createState() => _StoryRecapScreenState();
}

class _StoryRecapScreenState extends State<StoryRecapScreen> {
  final _pageController = PageController();
  int _page = 0;
  int _step = 0;

  void _goBack() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _goNext() {
    final isLast = _page == kStoryEntries.length - 1;
    if (isLast) {
      widget.onComplete();
    } else {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _advanceStep() {
    final steps = kStoryEntries[_page].steps;
    if (_step < steps.length - 1) {
      setState(() => _step++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _page == kStoryEntries.length - 1;
    final isFirst = _page == 0;

    return DiaryPageBackground(
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: kStoryEntries.length,
                onPageChanged: (i) => setState(() {
                  _page = i;
                  _step = 0;
                }),
                itemBuilder: (context, i) {
                  final entry = kStoryEntries[i];
                  final step = entry.steps[_step];
                  final hasMore = _step < entry.steps.length - 1;

                  return GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _advanceStep,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 90, 32, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            entry.year,
                            style: GoogleFonts.zhiMangXing(
                              color: Colors.pinkAccent,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            entry.title,
                            style: GoogleFonts.zhiMangXing(
                              color: const Color(0xFF6B4A3A),
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 24),
                          TypewriterText(
                            key: ValueKey('$_page-$_step'),
                            text: step.sentence,
                            style: GoogleFonts.zcoolXiaoWei(
                              color: const Color(0xFF4A4A4A),
                              fontSize: 18,
                              height: 1.6,
                            ),
                          ),
                          const SizedBox(height: 20),
                          StoryStepImage(
                            imageAsset: step.imageAsset,
                            stepNumber: _step + 1,
                          ),
                          if (hasMore) ...[
                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                '点击继续',
                                style: GoogleFonts.zcoolXiaoWei(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavButton(
                    label: '上一页',
                    onPressed: isFirst ? null : _goBack,
                  ),
                  _NavButton(
                    label: isLast ? '继续' : '下一页',
                    onPressed: _goNext,
                    filled: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool filled;

  const _NavButton({
    required this.label,
    required this.onPressed,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    if (filled) {
      return ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.pinkAccent,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24)),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
        ),
        onPressed: onPressed,
        child: Text(label),
      );
    }
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.pinkAccent,
        disabledForegroundColor: Colors.grey,
        side: BorderSide(
            color: onPressed == null ? Colors.grey.shade300 : Colors.pinkAccent),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
