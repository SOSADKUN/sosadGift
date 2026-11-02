import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/services/fading_music.dart';

class RecordingPlayer implements AudioPlayer {
  final events = <String>[];
  final releaseModes = <ReleaseMode>[];
  final startPositions = <Duration?>[];
  @override
  Future<void> setVolume(double volume) async => events.add('volume:$volume');
  @override
  Future<void> stop() async => events.add('stop');
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async => releaseModes.add(mode);
  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    startPositions.add(position);
    events.add('play:${(source as AssetSource).path}:$volume');
  }

  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('story4 starts at fifteen seconds with its fade-in preserved', () async {
    final player = RecordingPlayer();
    final music = FadingMusic(player: player);
    await music.play(
      'music/story4.mp3',
      startPosition: const Duration(seconds: 15),
    );
    expect(player.startPositions, [const Duration(seconds: 15)]);
    expect(player.events, contains('play:music/story4.mp3:0.0'));
    expect(player.events.last, 'volume:0.5');
    music.dispose();
  });

  test('chapter transition fades to silence before changing song', () async {
    final player = RecordingPlayer();
    final music = FadingMusic(player: player);
    await music.play('music/story1.mp3');
    expect(player.releaseModes.last, ReleaseMode.loop);
    expect(player.events.last, 'volume:0.5');
    player.events.clear();
    await music.play('music/story2.mp3');
    expect(player.releaseModes.last, ReleaseMode.loop);
    final stop = player.events.indexOf('stop');
    expect(player.events[stop - 1], 'volume:0.0');
    expect(player.events[stop + 1], 'play:music/story2.mp3:0.0');
    expect(player.events.last, 'volume:0.5');
    await music.stop();
    expect(player.events.last, 'stop');
    expect(player.events[player.events.length - 2], 'volume:0.0');
    music.dispose();
  });

  test('rapid chapter requests play only the latest requested song', () async {
    final player = RecordingPlayer();
    final music = FadingMusic(player: player);
    music.play('music/story1.mp3');
    music.play('music/story2.mp3');
    await music.play('music/story4.mp3');
    expect(player.events.where((event) => event.startsWith('play:')), [
      'play:music/story4.mp3:0.0',
    ]);
    player.events.clear();
    await music.play('music/story4.mp3');
    expect(player.events, isEmpty);
    music.dispose();
  });
}
