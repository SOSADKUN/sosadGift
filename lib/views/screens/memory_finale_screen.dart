import 'package:audioplayers/audioplayers.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/memory_display_config.dart';
import '../../games/memory_album_game.dart';
export '../../games/memory_float_pose.dart';

class MemoryFinaleScreen extends StatefulWidget {
  const MemoryFinaleScreen({super.key, this.useMockPhotos = false});
  final bool useMockPhotos;
  @override
  State<MemoryFinaleScreen> createState() => _MemoryFinaleScreenState();
}

class _MemoryFinaleScreenState extends State<MemoryFinaleScreen>
    with WidgetsBindingObserver {
  final _music = AudioPlayer();
  final _progress = ValueNotifier<(int, double)>((0, 0));
  MemoryAlbumGame? _album;
  int _photoCount = 0;
  bool _loading = true;
  bool _active = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadPhotos();
    _playMusic();
  }

  Future<void> _loadPhotos() async {
    try {
      final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
      if (!mounted) return;
      final assets = manifest.listAssets();
      var photos = widget.useMockPhotos
          ? <String>[]
          : MemoryDisplayConfig.orderedPhotos(assets);
      if (photos.isEmpty) {
        photos =
            assets
                .where(
                  (path) => RegExp(
                    r'^assets/photos/story/202[2345]/[^/]+\.jpg$',
                  ).hasMatch(path),
                )
                .toList()
              ..sort();
      }
      final album = MemoryAlbumGame(
        photos: photos,
        onProgress: (index, progress) {
          if (mounted) _progress.value = (index, progress);
        },
      );
      if (!_active) album.pauseEngine();
      setState(() {
        _album = album;
        _photoCount = photos.length;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
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
      await _music.play(AssetSource(track), volume: .5);
      if (!_active) await _music.pause();
    } catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active) {
      _album?.resumeEngine();
      _music.resume().catchError((Object _) {});
    } else {
      _album?.pauseEngine();
      _music.pause().catchError((Object _) {});
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _music.dispose().catchError((Object _) {});
    _progress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _album?.reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF100D19),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFECD2A4)),
            )
          : _photoCount == 0
          ? const Center(
              child: Text(
                '属于我们的回忆 ♡',
                style: TextStyle(color: Color(0xFFECD2A4)),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                GameWidget(game: _album!),
                IgnorePointer(
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 24,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OUR INFINITE LITTLE UNIVERSE',
                            style: TextStyle(
                              color: Color(0xFFD3BBA9),
                              fontSize: 9,
                              letterSpacing: 2.8,
                            ),
                          ),
                          const SizedBox(height: 9),
                          const Text(
                            '属于我们的回忆',
                            style: TextStyle(
                              color: Color(0xFFF7E9DE),
                              fontSize: 19,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 3,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            '有些瞬间，值得一再停留。',
                            style: TextStyle(
                              color: Color(0xFFF7E9DE),
                              fontSize: 17,
                              letterSpacing: 1.5,
                              fontFamily: 'serif',
                            ),
                          ),
                          const SizedBox(height: 14),
                          ValueListenableBuilder<(int, double)>(
                            valueListenable: _progress,
                            builder: (context, progress, _) => Column(
                              children: [
                                Row(
                                  children: [
                                    const Expanded(
                                      child: Text(
                                        'WITH YOU, ALWAYS  /  无限循环',
                                        style: TextStyle(
                                          color: Color(0xFFB6A0AB),
                                          fontSize: 9,
                                          letterSpacing: 1.5,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '${(progress.$1 + 1).toString().padLeft(3, '0')} / ${_photoCount.toString().padLeft(3, '0')}',
                                      key: const ValueKey('finale-counter'),
                                      style: const TextStyle(
                                        color: Color(0xFFD3BBA9),
                                        fontSize: 10,
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                LinearProgressIndicator(
                                  value: progress.$2,
                                  minHeight: 1,
                                  color: const Color(0xFFE3B9C8),
                                  backgroundColor: const Color(0x33E3B9C8),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
