import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/services/game_audio.dart';

class FakePlayer implements AudioPlayer {
  final events = <String>[];
  ReleaseMode? configuredReleaseMode;
  AudioContext? context;
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async =>
      configuredReleaseMode = mode;
  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    context = ctx;
    events.add('play:${(source as AssetSource).path}');
  }

  @override
  Future<void> stop() async => events.add('stop');
  @override
  Future<void> pause() async => events.add('pause');
  @override
  Future<void> resume() async => events.add('resume');
  @override
  Future<void> dispose() async => events.add('dispose');
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('music loops; effect voices mix without replacing music', () async {
    final players = <FakePlayer>[];
    final audio = GameAudio(
      'audio/game_memory.wav',
      playerFactory: () {
        final player = FakePlayer();
        players.add(player);
        return player;
      },
    );
    await audio.start();
    expect(players.single.configuredReleaseMode, ReleaseMode.loop);
    for (var i = 0; i < 12; i++) {
      await audio.effect(GameSound.pad(i % 6));
    }
    expect(players.length, 5); // One music player plus four reusable voices.
    expect(players.first.events, ['play:audio/game_memory.wav']);
    expect(players.last.context!.android.audioFocus, AndroidAudioFocus.none);
    await audio.dispose();
    expect(players.every((p) => p.events.last == 'dispose'), isTrue);
    await audio.effect(GameSound.win);
    expect(players.length, 5);
  });

  test(
    'background/foreground cannot resume hub while a game covers it',
    () async {
      final player = FakePlayer();
      final audio = GameAudio(
        'audio/game_hub.wav',
        playerFactory: () => player,
      );
      await audio.start();
      audio.setPaused(true);
      await audio.start(); // Wait for serialized music operations.
      expect(player.events.last, 'pause');
      audio.setForeground(false);
      audio.setForeground(true);
      await audio.start();
      expect(player.events.last, 'pause');
      final before = player.events.length;
      await audio.effect(GameSound.hit);
      expect(player.events.length, before);
      audio.setPaused(false);
      await audio.start();
      expect(player.events.last, 'resume');
      await audio.dispose();
    },
  );

  test('all five music loops and every effect have playable WAV data', () {
    final assets = [
      for (final game in ['hub', 'feather', 'memory', 'maze', 'mole'])
        'audio/game_$game.wav',
      for (final sound in GameSound.values) sound.asset,
    ];
    for (final asset in assets) {
      final bytes = File('assets/$asset').readAsBytesSync();
      expect(String.fromCharCodes(bytes.take(4)), 'RIFF', reason: asset);
      expect(String.fromCharCodes(bytes.sublist(8, 12)), 'WAVE', reason: asset);
      expect(bytes.length, greaterThan(1000), reason: asset);
    }
    expect({for (var i = 0; i < 6; i++) GameSound.pad(i).asset}.length, 6);
  });
}
