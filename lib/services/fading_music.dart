import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Serializes track changes so quick chapter navigation cannot overlap songs.
class FadingMusic {
  FadingMusic({AudioPlayer? player, AudioContext? audioContext})
    : _player = player ?? AudioPlayer(),
      _audioContext = audioContext;

  final AudioPlayer _player;
  final AudioContext? _audioContext;
  Future<void> _queue = Future.value();
  String? _requested;
  int _revision = 0;
  bool _disposed = false;
  bool _paused = false;
  double _volume = 0;

  Stream<void> get onComplete => _player.onPlayerComplete;
  Stream<Duration> get onPositionChanged => _player.onPositionChanged;

  Future<void> play(
    String asset, {
    bool loop = true,
    Duration startPosition = Duration.zero,
  }) {
    if (_disposed || _requested == asset) return _queue;
    _requested = asset;
    final revision = ++_revision;
    _queue = _queue
        .then((_) async {
          if (_disposed || revision != _revision) return;
          await _fade(0);
          if (_disposed || revision != _revision) return;
          await _player.stop();
          await _player.setReleaseMode(
            loop ? ReleaseMode.loop : ReleaseMode.release,
          );
          if (_disposed || revision != _revision) return;
          await _player.play(
            AssetSource(asset),
            volume: 0,
            ctx: _audioContext,
            position: startPosition,
          );
          if (_paused) await _player.pause();
          await _fade(.5);
        })
        .catchError((Object error) {
          debugPrint('Music playback failed: $error');
        });
    return _queue;
  }

  Future<void> _fade(double target) async {
    final from = _volume;
    if (from == target) return;
    for (var i = 1; i <= 20; i++) {
      if (_disposed) return;
      _volume = from + (target - from) * i / 20;
      await _player.setVolume(_volume);
      await Future<void>.delayed(const Duration(milliseconds: 40));
    }
  }

  void setPaused(bool paused) {
    _paused = paused;
    if (_disposed) return;
    (paused ? _player.pause() : _player.resume()).catchError((Object error) {
      debugPrint('Music pause/resume failed: $error');
    });
  }

  Future<void> stop() {
    _requested = null;
    ++_revision;
    _queue = _queue
        .then((_) async {
          if (_disposed) return;
          await _fade(0);
          if (!_disposed) await _player.stop();
        })
        .catchError((Object error) {
          debugPrint('Music stop failed: $error');
        });
    return _queue;
  }

  void dispose() {
    _disposed = true;
    ++_revision;
    // Let pending platform operations finish before releasing the player.
    unawaited(_queue.whenComplete(() => _player.dispose()));
  }
}
