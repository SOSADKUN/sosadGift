import 'dart:io';
import 'dart:ui' as ui;
import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/games/memory_pad_game.dart';
import 'package:gift/games/mole_game.dart';
import 'package:gift/views/screens/games/game_two_screen.dart';
import 'package:gift/views/screens/games/game_three_screen.dart';
import 'package:gift/views/screens/games/game_four_screen.dart';

void main() {
  testWidgets('memory playfield accepts taps only during the player turn', (
    tester,
  ) async {
    final taps = <int>[];
    final game = MemoryPadGame(
      spriteAssets: ['assets/photos/game2_1.gif', 'assets/photos/game2_2.gif'],
      colors: [Colors.pink, Colors.amber],
      onTap: taps.add,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await game.loaded;
    });
    await tester.pump();
    final pad = game.children.whereType<PositionComponent>().first;
    final center = (pad.position + pad.size / 2).toOffset();
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    expect(taps, isEmpty);
    game.inputEnabled = true;
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    expect(taps, [0]);
    game.inputEnabled = false;
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    expect(taps, [0]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('mole playfield ignores empty holes and disabled input', (
    tester,
  ) async {
    final taps = <int>[];
    final game = MoleGame(
      spriteAssets: ['assets/photos/game4_1.gif'],
      onTap: taps.add,
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await game.loaded;
    });
    await tester.pump();
    final hole = game.children.whereType<PositionComponent>().first;
    final center = (hole.position + hole.size / 2).toOffset();
    game.inputEnabled = true;
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    expect(taps, isEmpty);
    game.items[0] = 'assets/photos/game4_1.gif';
    game.update(.1);
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    expect(taps, [0]);
    game.inputEnabled = false;
    await tester.tapAt(center);
    await tester.pump(const Duration(milliseconds: 50));
    expect(taps, [0]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  for (final number in [2, 3, 4]) {
    testWidgets('game $number loads and renders on a phone viewport', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final boundary = GlobalKey();
      final Widget screen = switch (number) {
        2 => GameTwoScreen(onComplete: () {}, onLose: () {}),
        3 => GameThreeScreen(onComplete: () {}, onLose: () {}),
        _ => GameFourScreen(onComplete: () {}, onLose: () {}),
      };
      await tester.runAsync(() async {
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(key: boundary, child: screen),
          ),
        );
        final field =
            tester.widget(find.byWidgetPredicate((w) => w is GameWidget))
                as GameWidget;
        await (field.game! as FlameGame).loaded;
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();
      for (var i = 0; i < 55; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(tester.takeException(), isNull);
      if (Platform.environment['CAPTURE_GAME_PREVIEWS'] == '1') {
        await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage();
          final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
          File(
            '/tmp/gift_game_$number.png',
          ).writeAsBytesSync(bytes!.buffer.asUint8List());
          image.dispose();
        });
      }
      await tester.pumpWidget(const SizedBox());
    });
  }
}
