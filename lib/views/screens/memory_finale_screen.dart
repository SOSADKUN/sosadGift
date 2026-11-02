import 'dart:async';
import '../../services/fading_music.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/memory_display_config.dart';
import '../../games/memory_album_game.dart';
import '../widgets/heart_gesture_portal.dart';
import 'video_memory_screen.dart';
export '../../games/memory_float_pose.dart';

class MemoryFinaleScreen extends StatefulWidget {
  const MemoryFinaleScreen({super.key, this.useMockPhotos = false});
  final bool useMockPhotos;
  @override
  State<MemoryFinaleScreen> createState() => _MemoryFinaleScreenState();
}

class _MemoryFinaleScreenState extends State<MemoryFinaleScreen>
    with WidgetsBindingObserver {
  final _music = FadingMusic();
  StreamSubscription<void>? _completion;
  List<String> _tracks = [];
  int _trackIndex = 0;
  MemoryAlbumGame? _album;
  int _photoCount = 0;
  bool _loading = true;
  bool _active = true;
  bool _videoMenuOpen = false;

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
      photos.shuffle();
      final album = MemoryAlbumGame(photos: photos, onProgress: (_, _) {});
      if (!_active || _videoMenuOpen) album.pauseEngine();
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
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    if (!mounted) return;
    _tracks =
        manifest
            .listAssets()
            .where(
              (path) => RegExp(
                r'^assets/music/last_display_music[1-9][0-9]*\.mp3$',
              ).hasMatch(path),
            )
            .toList()
          ..sort();
    if (_tracks.isEmpty) return;
    _completion = _music.onComplete.listen((_) {
      if (!mounted) return;
      _trackIndex = (_trackIndex + 1) % _tracks.length;
      _music.play(_tracks[_trackIndex].substring(7), loop: false);
    });
    _music.setPaused(!_active || _videoMenuOpen);
    await _music.play(_tracks.first.substring(7), loop: false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _active = state == AppLifecycleState.resumed;
    if (_active && !_videoMenuOpen) {
      _album?.resumeEngine();
      _music.setPaused(false);
    } else {
      _album?.pauseEngine();
      _music.setPaused(true);
    }
  }

  Future<void> _openVideos() async {
    if (_videoMenuOpen || !_active) return;
    _videoMenuOpen = true;
    _album?.pauseEngine();
    HapticFeedback.mediumImpact();
    try {
      _music.setPaused(true);
    } catch (_) {}
    if (!mounted) return;
    try {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(builder: (_) => const VideoMemoryScreen()),
      );
    } finally {
      _videoMenuOpen = false;
      if (mounted && _active) {
        _album?.resumeEngine();
        _music.setPaused(false);
      }
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _completion?.cancel();
    _music.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _album?.reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: const Color(0xFF100D19),
      body: HeartGesturePortal(
        onHeart: _openVideos,
        child: _loading
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
                              '属于我们的每个瞬间',
                              style: TextStyle(
                                color: Color(0xFFF7E9DE),
                                fontSize: 17,
                                letterSpacing: 1.5,
                                fontFamily: 'serif',
                              ),
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'WITH YOU, ALWAYS',
                              style: TextStyle(
                                color: Color(0xFFB6A0AB),
                                fontSize: 9,
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
