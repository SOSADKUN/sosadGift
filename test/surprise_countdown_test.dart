import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/screens/surprise_countdown_screen.dart';

class CountdownVoice implements AudioPlayer {
  final done = StreamController<void>.broadcast();
  int plays = 0;
  String? asset;
  @override
  Stream<void> get onPlayerComplete => done.stream;
  @override
  Future<void> setReleaseMode(ReleaseMode mode) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setSource(Source source) async {
    asset = (source as AssetSource).path;
  }

  @override
  Future<void> resume() async {
    plays++;
  }

  @override
  Future<void> dispose() => done.close();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'last 10 seconds speak once each, greeting completes before cake',
    (tester) async {
      var now = DateTime(2026, 10, 12);
      var advances = 0;
      final voices = <CountdownVoice>[];
      await tester.pumpWidget(
        MaterialApp(
          home: SurpriseCountdownScreen(
            now: () => now,
            onComplete: () => advances++,
            audioPlayerFactory: () {
              final voice = CountdownVoice();
              voices.add(voice);
              return voice;
            },
          ),
        ),
      );
      await tester.pump();
      now = now.add(const Duration(seconds: 19));
      await tester.pump(const Duration(milliseconds: 200));
      expect(voices.every((voice) => voice.plays == 0), isTrue);
      for (var number = 10; number >= 1; number--) {
        now = now.add(const Duration(seconds: 1));
        await tester.pump(const Duration(milliseconds: 200));
        await tester.pump();
        expect(find.text('$number'), findsOneWidget);
        expect(voices[number].plays, 1);
        expect(voices[number].asset, 'audio/countdown_$number.wav');
        await tester.pump(const Duration(milliseconds: 400));
        expect(voices[number].plays, 1);
      }
      now = now.add(const Duration(seconds: 1));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump();
      expect(voices[0].plays, 1);
      expect(advances, 0);
      voices[0].done.add(null);
      await tester.pump();
      await tester.pump();
      expect(advances, 1);
      await tester.pump(const Duration(seconds: 3));
      expect(advances, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
