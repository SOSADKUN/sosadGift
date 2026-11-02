import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

enum GameSound {
  catchTarget('catch'),
  hit('hit'),
  pickup('pickup'),
  win('win'),
  fail('fail'),
  door('door'),
  plant('plant'),
  escape('escape'),
  step('step'),
  boom('boom'),
  pad0('pad0'),
  pad1('pad1'),
  pad2('pad2'),
  pad3('pad3'),
  pad4('pad4'),
  pad5('pad5');

  const GameSound(this.file);
  final String file;
  String get asset => 'audio/game_$file.wav';
  static GameSound pad(int index) => values[pad0.index + index];
}

class _Voice {
  _Voice(this.player);
  final AudioPlayer player;
  Future<void> queue = Future.value();
}

/// One music player and a small effect pool per route, never per game action.
class GameAudio {
  GameAudio(this.track, {AudioPlayer Function()? playerFactory})
    : _factory = playerFactory ?? AudioPlayer.new;
  final String track;
  final AudioPlayer Function() _factory;
  AudioPlayer? _music;
  final _voices = <_Voice>[];
  Future<void> _queue = Future.value();
  int _nextVoice = 0;
  bool _disposed = false;
  bool _routePaused = false;
  bool _foreground = true;
  bool get _paused => _routePaused || !_foreground;

  static final _context = AudioContext(
    android: const AudioContextAndroid(audioFocus: AndroidAudioFocus.none),
    iOS: AudioContextIOS(options: {AVAudioSessionOptions.mixWithOthers}),
  );

  Future<void> start() {
    _queue = _queue
        .then((_) async {
          if (_disposed || _music != null) return;
          final player = _music = _factory();
          await player.setReleaseMode(ReleaseMode.loop);
          if (_disposed) return;
          await player.play(AssetSource(track), volume: .23, ctx: _context);
          if (_paused) await player.pause();
        })
        .catchError(_report);
    return _queue;
  }

  Future<void> effect(GameSound sound) {
    if (_disposed || _paused) return Future.value();
    if (_voices.length < 4) _voices.add(_Voice(_factory()));
    final voice = _voices[_nextVoice++ % _voices.length];
    voice.queue = voice.queue
        .then((_) async {
          if (_disposed || _paused) return;
          await voice.player.stop();
          if (_disposed || _paused) return;
          await voice.player.play(
            AssetSource(sound.asset),
            volume: sound == GameSound.step ? .22 : .65,
            ctx: _context,
          );
        })
        .catchError(_report);
    return voice.queue;
  }

  void setPaused(bool paused) {
    _routePaused = paused;
    _sync();
  }

  void setForeground(bool foreground) {
    _foreground = foreground;
    _sync();
  }

  void _sync() {
    if (_disposed) return;
    _queue = _queue
        .then((_) async {
          if (_disposed) return;
          if (_paused) {
            await _music?.pause();
          } else {
            await _music?.resume();
          }
        })
        .catchError(_report);
    if (_paused) {
      for (final voice in _voices) {
        voice.queue = voice.queue
            .then((_) => voice.player.stop())
            .catchError(_report);
      }
    }
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    await _queue;
    await _music?.dispose();
    for (final voice in _voices) {
      await voice.queue;
      await voice.player.dispose();
    }
  }

  static void _report(Object error) =>
      debugPrint('Game audio unavailable: $error');
}
