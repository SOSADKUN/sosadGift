import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/config/treasure_hunt_config.dart';
import 'package:gift/views/screens/digital_cake_screen.dart';

class BirthdayPlayer implements AudioPlayer {
  final completed = StreamController<void>.broadcast();
  String? playedAsset;
  bool fail = false;

  @override
  Stream<void> get onPlayerComplete => completed.stream;

  @override
  Future<void> setReleaseMode(ReleaseMode releaseMode) async {}

  @override
  Future<void> play(
    Source source, {
    double? volume,
    double? balance,
    AudioContext? ctx,
    Duration? position,
    PlayerMode? mode,
  }) async {
    if (fail) throw StateError('Audio unavailable');
    playedAsset = (source as AssetSource).path;
  }

  @override
  Future<void> dispose() => completed.close();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    if (Platform.environment['CAPTURE_CAKE_PREVIEW'] != '1') return;
    for (final font in {
      'preview': '/System/Library/Fonts/Supplemental/Arial Unicode.ttf',
      'serif': '/System/Library/Fonts/Supplemental/Georgia Italic.ttf',
      'monospace': '/System/Library/Fonts/Supplemental/Arial.ttf',
    }.entries) {
      if (!File(font.value).existsSync()) continue;
      final loader = FontLoader(font.key)
        ..addFont(
          Future.value(
            ByteData.sublistView(File(font.value).readAsBytesSync()),
          ),
        );
      await loader.load();
    }
  });
  testWidgets('birthday music starts immediately; taps never skip the song', (
    tester,
  ) async {
    final player = BirthdayPlayer();
    var advances = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DigitalCakeScreen(
          birthdayPlayer: player,
          onComplete: () => advances++,
        ),
      ),
    );
    await tester.pump();
    expect(player.playedAsset, TreasureHuntConfig.birthdaySong);
    await tester.tapAt(const Offset(50, 200));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 1700));
    await tester.tap(find.byKey(const ValueKey('birthday-candle')));
    await tester.pump();
    expect(find.text('愿你的每一年，都被温柔以待。'), findsOneWidget);
    await tester.pump(const Duration(seconds: 10));
    expect(advances, 0);
    player.completed.add(null);
    await tester.pump();
    expect(advances, 1);
    player.completed.add(null);
    await tester.pump();
    expect(advances, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('song completion advances without requiring a candle tap', (
    tester,
  ) async {
    final player = BirthdayPlayer();
    var advances = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DigitalCakeScreen(
          birthdayPlayer: player,
          onComplete: () => advances++,
        ),
      ),
    );
    await tester.pump();
    player.completed.add(null);
    await tester.pump();
    expect(advances, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('audio failure offers retry and never skips the cake', (
    tester,
  ) async {
    final player = BirthdayPlayer()..fail = true;
    var advances = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: DigitalCakeScreen(
          birthdayPlayer: player,
          onComplete: () => advances++,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('重新播放生日歌'), findsOneWidget);
    expect(advances, 0);
    player.fail = false;
    await tester.tap(find.text('重新播放生日歌'));
    await tester.pump();
    expect(player.playedAsset, TreasureHuntConfig.birthdaySong);
    expect(advances, 0);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('dream cake fits a small phone viewport', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'preview'),
          home: DigitalCakeScreen(birthdayPlayer: BirthdayPlayer()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4200));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1600));
    await tester.pump(const Duration(milliseconds: 1700));
    expect(tester.takeException(), isNull);
    if (Platform.environment['CAPTURE_CAKE_PREVIEW'] == '1') {
      await tester.pump(const Duration(milliseconds: 800));
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 2);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '/tmp/dream_cake_preview.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
  });
}
