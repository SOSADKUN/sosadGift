import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/screens/surprise_countdown_screen.dart';

class CountdownAudio implements AudioPlayer {
  String? asset;
  int plays = 0;
  bool stopped = false;
  final seeks = <Duration>[];
  @override
  Future<void> setAudioContext(AudioContext ctx) async {}
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSource(Source source) async =>
      asset = (source as AssetSource).path;
  @override
  Future<void> seek(Duration position) async => seeks.add(position);
  @override
  Future<void> resume() async {
    plays++;
  }

  @override
  Future<void> pause() async {}
  @override
  Future<void> stop() async {
    stopped = true;
  }

  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('60 seconds beep until eleven then speak English ten to one', (
    tester,
  ) async {
    var now = DateTime(2026, 11, 3);
    var advances = 0;
    final players = <CountdownAudio>[];
    await tester.pumpWidget(
      MaterialApp(
        home: SurpriseCountdownScreen(
          now: () => now,
          onComplete: () => advances++,
          audioPlayerFactory: () {
            final player = CountdownAudio();
            players.add(player);
            return player;
          },
        ),
      ),
    );
    await tester.pump();
    for (var n = 59; n >= 1; n--) {
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(find.text('$n'), findsOneWidget);
      if (n <= 10) {
        final voice = players.singleWhere(
          (p) => p.asset == 'audio/countdown_$n.wav',
        );
        expect(voice.plays, 1);
        await tester.pump(const Duration(milliseconds: 200));
        expect(voice.plays, 1);
      }
    }
    expect(players.first.asset, 'audio/countdown_tick.wav');
    expect(players.first.plays, 50);
    expect(players.length, 11);
    expect(players.every((p) => !p.asset!.endsWith('.mp3')), isTrue);
    now = now.add(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 200));
    expect(advances, 1);
    expect(players.skip(1).every((p) => p.stopped), isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(advances, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
