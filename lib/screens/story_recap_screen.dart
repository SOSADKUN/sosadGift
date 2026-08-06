import 'package:flutter/material.dart';
import '../models/story_entry.dart';

class StoryRecapScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const StoryRecapScreen({super.key, required this.onComplete});

  @override
  State<StoryRecapScreen> createState() => _StoryRecapScreenState();
}

class _StoryRecapScreenState extends State<StoryRecapScreen> {
  final _pageController = PageController();
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final isLast = _page == kStoryEntries.length - 1;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: kStoryEntries.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) {
                final entry = kStoryEntries[i];
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.year,
                          style: const TextStyle(
                              color: Colors.pinkAccent, fontSize: 18)),
                      const SizedBox(height: 8),
                      Text(entry.title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (entry.imageAsset != null)
                        Image.asset(entry.imageAsset!),
                      const SizedBox(height: 16),
                      Text(entry.body,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: isLast
                  ? widget.onComplete
                  : () => _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut),
              child: Text(isLast ? '继续' : '下一页'),
            ),
          ),
        ],
      ),
    );
  }
}