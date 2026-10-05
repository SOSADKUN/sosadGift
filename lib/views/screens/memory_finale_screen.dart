import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/memory_display_config.dart';

/// An endless photo film, discovered from the installed asset manifest.
class MemoryFinaleScreen extends StatefulWidget {
  const MemoryFinaleScreen({super.key});

  @override
  State<MemoryFinaleScreen> createState() => _MemoryFinaleScreenState();
}

class _MemoryFinaleScreenState extends State<MemoryFinaleScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _film;
  final _music = AudioPlayer();
  List<String> _photos = [];
  int _index = 0;
  bool _loading = true;
  bool _active = true;
  String? _error;
  String? _cachedNext;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _film =
        AnimationController(
          vsync: this,
          duration: MemoryDisplayConfig.photoDuration,
        )..addStatusListener((status) {
          if (status != AnimationStatus.completed || !mounted) return;
          setState(
            () =>
                _index = MemoryDisplayConfig.nextIndex(_index, _photos.length),
          );
          _preloadNext();
          if (_active) _film.forward(from: 0);
        });
    _loadPhotos();
    _playMusic();
  }

  Future<void> _loadPhotos() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!mounted) return;
      setState(() {
        _photos = MemoryDisplayConfig.orderedPhotos(manifest.listAssets());
        _loading = false;
      });
      _preloadNext();
      if (_photos.isNotEmpty && _active) _film.forward();
    } catch (_) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = '回忆暂时无法加载';
        });
      }
    }
  }

  Future<void> _playMusic() async {
    var track = MemoryDisplayConfig.musicAsset;
    try {
      await rootBundle.load('assets/$track');
    } catch (_) {
      track = MemoryDisplayConfig.fallbackMusic;
    }
    try {
      await _music.setReleaseMode(ReleaseMode.loop);
      if (!mounted) return;
      await _music.play(AssetSource(track), volume: .55);
      if (!_active) await _music.pause();
    } catch (error) {
      debugPrint('Memory music unavailable: $error');
    }
  }

  void _preloadNext() {
    if (_photos.isEmpty) return;
    final next = _photos[MemoryDisplayConfig.nextIndex(_index, _photos.length)];
    if (next == _cachedNext) return;
    _cachedNext = next;
    // Decode only the next image, rather than keeping the entire album in RAM.
    precacheImage(
      ResizeImage(AssetImage(next), width: 1400),
      context,
      onError: (_, _) {},
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      if (_photos.isNotEmpty) _film.forward();
      _music.resume();
    } else {
      _film.stop();
      _music.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _film.dispose();
    _music.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF151113),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFECD2A4)),
            )
          : _photos.isEmpty
          ? Center(
              child: Text(
                _error ?? '属于我们的回忆，等你放进来 ♡',
                style: const TextStyle(color: Color(0xFFECD2A4), fontSize: 20),
              ),
            )
          : AnimatedBuilder(
              animation: _film,
              builder: (context, _) {
                final t = _film.value;
                final dissolve = Curves.easeInOut.transform(
                  ((t - .72) / .28).clamp(0.0, 1.0),
                );
                final next = MemoryDisplayConfig.nextIndex(
                  _index,
                  _photos.length,
                );
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _photo(_index, .2 + .8 * t, reducedMotion),
                    if (_photos.length > 1)
                      Opacity(
                        opacity: dissolve,
                        child: _photo(
                          next,
                          .2 * ((t - .72) / .28).clamp(0.0, 1.0),
                          reducedMotion,
                        ),
                      ),
                    const IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x55151113),
                              Colors.transparent,
                              Color(0xBB151113),
                            ],
                            stops: [0, .55, 1],
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 28,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'THE LITTLE THINGS, WITH YOU',
                              style: TextStyle(
                                color: Color(0xFFD8C3AB),
                                fontSize: 10,
                                letterSpacing: 3,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              '每一帧，都是我们。',
                              style: TextStyle(
                                color: Color(0xFFF8EEE2),
                                fontSize: 25,
                                letterSpacing: 2,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Expanded(
                                  child: Text(
                                    '故事还在继续  ♡',
                                    style: TextStyle(
                                      color: Color(0xFFBEAEA0),
                                      fontSize: 12,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(_index + 1).toString().padLeft(3, '0')} / ${_photos.length.toString().padLeft(3, '0')}',
                                  style: const TextStyle(
                                    color: Color(0xFFBEAEA0),
                                    fontSize: 10,
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _photo(int index, double progress, bool reducedMotion) {
    final path = _photos[index];
    final direction = index.isEven ? 1.0 : -1.0;
    final zoom = reducedMotion ? 1.0 : 1.015 + progress * .045;
    final drift = reducedMotion ? 0.0 : direction * (progress - .5) * 12;
    final image = Image.asset(
      path,
      fit: BoxFit.contain,
      cacheWidth: 1400,
      errorBuilder: (_, _, _) => const Center(
        child: Icon(Icons.photo_outlined, color: Colors.white38, size: 60),
      ),
    );
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
            child: Image.asset(
              path,
              fit: BoxFit.cover,
              cacheWidth: 400,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: Color(0xFF241B20)),
            ),
          ),
          const ColoredBox(color: Color(0x88151113)),
          Center(
            child: Transform.translate(
              offset: Offset(drift, -drift * .4),
              child: Transform.scale(
                scale: zoom,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 70, 20, 145),
                  child: image,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
