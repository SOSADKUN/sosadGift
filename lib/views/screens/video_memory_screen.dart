import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../widgets/story_video.dart';

List<String> orderedMemoryVideos(Iterable<String> assets) {
  final pattern = RegExp(
    r'^assets/memory_videos/video([1-9][0-9]*)\.mp4$',
    caseSensitive: false,
  );
  final videos = assets.where((path) => pattern.hasMatch(path)).toList();
  videos.sort(
    (a, b) => int.parse(
      pattern.firstMatch(a)!.group(1)!,
    ).compareTo(int.parse(pattern.firstMatch(b)!.group(1)!)),
  );
  return videos;
}

class VideoMemoryScreen extends StatefulWidget {
  const VideoMemoryScreen({super.key});
  @override
  State<VideoMemoryScreen> createState() => _VideoMemoryScreenState();
}

class _VideoMemoryScreenState extends State<VideoMemoryScreen> {
  final _pages = PageController(viewportFraction: .78);
  List<String> _videos = [];
  bool _loading = true;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!mounted) return;
      setState(() {
        _videos = orderedMemoryVideos(manifest.listAssets());
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF100D19),
    body: DecoratedBox(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF4A2D47), Color(0xFF100D19)],
          radius: 1.2,
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Row(
                children: [
                  IconButton(
                    tooltip: '返回照片回忆',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFFF4DDDD),
                    ),
                  ),
                  const Expanded(
                    child: Text(
                      '流动的回忆 ♡',
                      style: TextStyle(
                        color: Color(0xFFF4DDDD),
                        fontSize: 22,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _videos.isEmpty
                  ? const Center(
                      child: Text(
                        '视频回忆即将开始 ♡',
                        style: TextStyle(
                          color: Color(0xFFEACBDA),
                          fontSize: 18,
                        ),
                      ),
                    )
                  : PageView.builder(
                      controller: _pages,
                      itemCount: _videos.length,
                      itemBuilder: (context, index) => AnimatedBuilder(
                        animation: _pages,
                        builder: (context, _) {
                          final page =
                              _pages.hasClients &&
                                  _pages.position.hasContentDimensions
                              ? _pages.page ?? 0
                              : 0.0;
                          final distance = (index - page).clamp(-1.5, 1.5);
                          final reduced = MediaQuery.disableAnimationsOf(
                            context,
                          );
                          final transform = Matrix4.identity()
                            ..setEntry(3, 2, .0012);
                          if (!reduced) {
                            transform.translateByDouble(
                              0,
                              0,
                              -math.min(1, distance.abs()) * 130,
                              1,
                            );
                            transform.rotateY(-distance * .85);
                          }
                          return Center(
                            child: Transform(
                              alignment: Alignment.center,
                              transform: transform,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 22,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF211829),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: const Color(0x66E9B5CE),
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x55000000),
                                        blurRadius: 25,
                                        offset: Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8),
                                      child: StoryVideo(
                                        key: ValueKey(_videos[index]),
                                        asset: _videos[index],
                                        active: distance.abs() < .08,
                                        volume: 1,
                                        showControls: true,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            if (_videos.isNotEmpty)
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 26),
                child: Text(
                  '左右滑动，转动我们的回忆',
                  style: TextStyle(
                    color: Color(0xFFBCA0B4),
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
