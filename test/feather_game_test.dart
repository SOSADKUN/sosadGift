import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/games/feather_game.dart';

void main() {
  testWidgets('feather stays in bounds and catches only once per spawn', (
    tester,
  ) async {
    var catches = 0;
    late FeatherGame game;
    game = FeatherGame(
      onReady: () {},
      onCatch: () {
        catches++;
        game.targetVisible = false;
      },
    );
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await game.loaded;
    });
    await tester.pump();
    game.showTarget(const Offset(1, 1), fast: true);
    for (var i = 0; i < 120; i++) {
      game.update(1 / 60);
      final feather = game.children
          .whereType<SpriteAnimationComponent>()
          .single;
      expect(feather.position.x - feather.size.x / 2, greaterThanOrEqualTo(0));
      expect(
        feather.position.x + feather.size.x / 2,
        lessThanOrEqualTo(game.size.x),
      );
      expect(
        feather.position.y + feather.size.y / 2,
        lessThanOrEqualTo(game.size.y),
      );
    }
    final feather = game.children.whereType<SpriteAnimationComponent>().single;
    await tester.tapAt(feather.position.toOffset());
    await tester.pump(const Duration(milliseconds: 50));
    expect(catches, 1);
    game.catchTarget();
    expect(catches, 1);
    game.showTarget(const Offset(.5, .5), fast: false);
    game.pauseEngine();
    game.catchTarget();
    expect(catches, 1);
    game.resumeEngine();
    game.catchTarget();
    expect(catches, 2);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion keeps the target stationary', (tester) async {
    final game = FeatherGame(onReady: () {}, onCatch: () {})
      ..reducedMotion = true;
    await tester.runAsync(() async {
      await tester.pumpWidget(MaterialApp(home: GameWidget(game: game)));
      await game.loaded;
    });
    await tester.pump();
    game.showTarget(const Offset(.2, .8), fast: true);
    final feather = game.children.whereType<SpriteAnimationComponent>().single;
    final start = feather.position.clone();
    for (var i = 0; i < 60; i++) {
      game.update(1 / 60);
    }
    expect(feather.position, start);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
