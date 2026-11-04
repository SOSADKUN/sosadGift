import 'dart:io';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/services/game_audio.dart';

class FakePlayer implements AudioPlayer {
  final events = <String>[];
  @override
  Stream<Duration> get onPositionChanged => positionEvents.stream;
  final positionEvents = StreamController<Duration>.broadcast();
  final playVolumes = <double?>[];
  ReleaseMode? configuredReleaseMode;
  AudioContext? context;
  @override
  Future<void> setAudioContext(AudioContext ctx) async => context = ctx;
  @override
  Future<void> setSource(Source source) async =>
      events.add('source:${(source as AssetSource).path}');
  @override
  Future<void> seek(Duration position) async =>
      events.add('seek:${position.inMilliseconds}');
  @override
  Future<void> setVolume(double volume) async => events.add('volume:$volume');
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
    playVolumes.add(volume);
    events.add('play:${(source as AssetSource).path}');
  }

  @override
  Future<void> stop() async => events.add('stop');
  @override
  Future<void> pause() async => events.add('pause');
  @override
  Future<void> resume() async => events.add('resume');
  @override
  Future<void> dispose() async {
    events.add('dispose');
    await positionEvents.close();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test(
    'intro and hub share low-volume playback without restart, with music position updates',
    () async {
      final player = FakePlayer();
      final audio = GameAudio(
        'music/GameMusic.mp3',
        musicVolume: .12,
        playerFactory: () => player,
      );
      final positions = <Duration>[];
      final subscription = audio.positions.listen(positions.add);
      await audio.start();
      player.positionEvents.add(const Duration(seconds: 10));
      await Future<void>.delayed(Duration.zero);
      await audio.start(); // The hub reuses the same controller.
      expect(player.events.where((e) => e.startsWith('play:')).length, 1);
      expect(player.playVolumes, [.12]);
      expect(audio.musicPosition, const Duration(seconds: 10));
      expect(positions, [const Duration(seconds: 10)]);
      await subscription.cancel();
      await audio.dispose();
    },
  );

  test(
    'intro impacts preload on dedicated players and duck the backing music',
    () async {
      final players = <FakePlayer>[];
      final audio = GameAudio(
        'audio/game_maze.wav',
        playerFactory: () {
          final player = FakePlayer();
          players.add(player);
          return player;
        },
      );
      await audio.prepareIntro();
      await audio.start();
      final title = players.singleWhere(
        (p) => p.events.contains('source:audio/game_intro_title.wav'),
      );
      final line = players.singleWhere(
        (p) => p.events.contains('source:audio/game_intro_line.wav'),
      );
      final music = players.last;
      audio.setIntroActive(true);
      await audio.start();
      expect(music.events.last, 'volume:0.08');
      await audio.effect(GameSound.introTitle);
      await audio.effect(GameSound.introLine);
      await audio.effect(GameSound.introLine);
      expect(title.events.last, 'resume');
      expect(line.events.where((e) => e == 'resume').length, 2);
      expect(line.events.where((e) => e.startsWith('source:')).length, 1);
      expect(players.length, 3);
      audio.setIntroActive(false);
      await audio.start();
      expect(music.events.last, 'volume:0.23');
      await audio.dispose();
      expect(players.every((p) => p.events.last == 'dispose'), isTrue);
    },
  );
  test('music loops; effect voices mix without replacing music', () async {
    final players = <FakePlayer>[];
    final audio = GameAudio(
      'music/game2_sneaky_snitch.mp3',
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
    expect(players.first.events, ['play:music/game2_sneaky_snitch.mp3']);
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
