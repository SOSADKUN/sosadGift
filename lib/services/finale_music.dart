import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'fading_music.dart';

/// Owned by AppFlow so fireworks and the album share one uninterrupted playlist.
class FinaleMusic {
  FinaleMusic({FadingMusic? music}) : _provided = music;
  final FadingMusic? _provided;
  static final audioContext = AudioContext(
    android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    iOS: AudioContextIOS(options: {AVAudioSessionOptions.mixWithOthers}),
  );
  late final _music = _provided ?? FadingMusic(audioContext: audioContext);
  Future<void>? _starting;
  StreamSubscription<void>? _completion;
  StreamSubscription<Duration>? _position;
  static const photoStart = Duration(seconds: 13);
  final photosReady = ValueNotifier(false);
  bool _hasPlaybackPosition = false;
  bool get hasPlaybackPosition => _hasPlaybackPosition;
  List<String> _tracks = [];
  int _index = 0;
  bool _disposed = false;

  Future<void> start() => _starting ??= _start();
  Future<void> _start() async {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    if (_disposed) return;
    _tracks =
        manifest
            .listAssets()
            .where(
              (p) => RegExp(
                r'^assets/music/last_display_music[1-9][0-9]*\.mp3$',
              ).hasMatch(p),
            )
            .toList()
          ..sort();
    if (_tracks.isEmpty) return;
    _position = _music.onPositionChanged.listen((position) {
      if (_disposed) return;
      if (position > Duration.zero) _hasPlaybackPosition = true;
      if (_index == 0 && position >= photoStart) photosReady.value = true;
    });
    _completion = _music.onComplete.listen((_) {
      if (_disposed) return;
      _index = (_index + 1) % _tracks.length;
      unawaited(_music.play(_tracks[_index].substring(7), loop: false));
    });
    await _music.play(_tracks.first.substring(7), loop: false);
  }

  void setPaused(bool paused) {
    if (!_disposed && _starting != null) _music.setPaused(paused);
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _completion?.cancel();
    _position?.cancel();
    photosReady.dispose();
    if (_starting != null) _music.dispose();
  }
}
