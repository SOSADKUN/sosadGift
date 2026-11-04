import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/widgets/game_intro_overlay.dart';
import 'package:gift/views/widgets/game_audio_scope.dart';

Future<void> advance(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 16));
  }
}

class IntroAudioRecorder extends GameAudio {
  IntroAudioRecorder() : super('unused');
  final sounds = <GameSound>[];
  @override
  Future<void> start() async {}
  @override
  Future<void> effect(GameSound sound) async => sounds.add(sound);
  @override
  void setForeground(bool foreground) {}
  @override
  Future<void> dispose() async {}
}

void main() {
  testWidgets(
    'intro sentences stay silent while countdown voices remain available',
    (tester) async {
      final audio = IntroAudioRecorder();
      await tester.pumpWidget(
        MaterialApp(
          home: GameAudioScope(
            audio: audio,
            child: Scaffold(
              body: Stack(
                children: [
                  GameIntroOverlay(
                    title: 'Title',
                    instructionText: 'First line\nSecond line',
                    onStart: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(audio.sounds.where((s) => s == GameSound.introTitle), isEmpty);
      await advance(tester, 60);
      expect(audio.sounds.where((s) => s == GameSound.introLine), isEmpty);
      await advance(tester, 60);
      expect(audio.sounds.where((s) => s == GameSound.introLine), isEmpty);
      await tester.pump();
      expect(audio.sounds.where((s) => s == GameSound.introLine), isEmpty);
      expect(GameSound.introLine.asset, isNot(GameSound.hit.asset));
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('every game countdown displays THREE TWO ONE START before play', (
    tester,
  ) async {
    var starts = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              GameIntroOverlay(
                title: 'Game',
                instructionText: '',
                countdownOnly: true,
                onStart: () => starts++,
              ),
            ],
          ),
        ),
      ),
    );
    await advance(tester, 2);
    expect(find.text('THREE'), findsOneWidget);
    await advance(tester, 44);
    expect(find.text('TWO'), findsOneWidget);
    await advance(tester, 44);
    expect(find.text('ONE'), findsOneWidget);
    await advance(tester, 44);
    expect(find.text('START'), findsOneWidget);
    expect(starts, 0);
    await advance(tester, 60);
    expect(starts, 1);
    await tester.pumpWidget(const SizedBox());
  });
}
