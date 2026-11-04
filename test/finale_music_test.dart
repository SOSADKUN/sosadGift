import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/services/fading_music.dart';
import 'package:gift/services/finale_music.dart';

class _UnusedPlayer implements AudioPlayer {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class PlaylistRecorder extends FadingMusic {
  PlaylistRecorder() : super(player: _UnusedPlayer());
  final done = StreamController<void>.broadcast();
  final position = StreamController<Duration>.broadcast();
  final tracks = <String>[];
  @override
  Stream<void> get onComplete => done.stream;
  @override
  Stream<Duration> get onPositionChanged => position.stream;
  @override
  Future<void> play(
    String asset, {
    bool loop = true,
    Duration startPosition = Duration.zero,
  }) async => tracks.add(asset);
  @override
  void dispose() {
    done.close();
    position.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'fireworks and album share track one without restarting; playlist loops',
    () async {
      final recorder = PlaylistRecorder();
      final music = FinaleMusic(music: recorder);
      await music.start();
      await music.start();
      expect(recorder.tracks, ['music/last_display_music1.mp3']);
      recorder.position.add(const Duration(milliseconds: 12999));
      await Future<void>.delayed(Duration.zero);
      expect(music.photosReady.value, isFalse);
      recorder.position.add(const Duration(seconds: 13));
      await Future<void>.delayed(Duration.zero);
      expect(music.photosReady.value, isTrue);
      for (var i = 0; i < 3; i++) {
        recorder.done.add(null);
        await Future<void>.delayed(Duration.zero);
      }
      expect(recorder.tracks, [
        'music/last_display_music1.mp3',
        'music/last_display_music2.mp3',
        'music/last_display_music3.mp3',
        'music/last_display_music1.mp3',
      ]);
      music.dispose();
    },
  );
}
