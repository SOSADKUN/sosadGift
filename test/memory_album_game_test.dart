import 'dart:math';
import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/games/memory_album_game.dart';

void main() {
  testWidgets(
    'six randomized backdrops change offscreen and cover all 50 photos',
    (tester) async {
      final game = MemoryAlbumGame(
        photos: List.filled(50, 'assets/photos/game4.png'),
        random: Random(42),
        onProgress: (_, _) {},
      );
      game.onGameResize(Vector2(390, 844));
      await tester.runAsync(() async {
        await game.onLoad();
        await game.waitForPreload();
        expect(game.backgroundIndices.length, 6);
        expect(game.backgroundIndices, isNot([0, 1, 2, 3, 4, 5]));
        final seen = <int>{...game.backgroundIndices};
        for (var second = 0; second < 480; second++) {
          final previous = game.backgroundIndices;
          game.update(1);
          await game.waitForPreload();
          final current = game.backgroundIndices;
          expect(current.length, 6);
          expect(current.toSet().length, 6);
          expect(
            List.generate(
              6,
              (i) => current[i] != previous[i],
            ).where((changed) => changed).length,
            lessThanOrEqualTo(1),
          );
          seen.addAll(current);
          expect(game.decodedBackgroundCount, lessThanOrEqualTo(12));
          expect(game.decodedPhotoCount, lessThanOrEqualTo(3));
        }
        expect(seen.length, 50);
        game.onRemove();
        expect(game.decodedBackgroundCount, 0);
      });
    },
  );

  testWidgets(
    '100 memories loop without resetting atmosphere or retaining the album in RAM',
    (tester) async {
      final game = MemoryAlbumGame(
        photos: List.filled(100, 'assets/photos/game4.png'),
        onProgress: (_, _) {},
      );
      game.onGameResize(Vector2(390, 844));
      await tester.runAsync(() async {
        await game.onLoad();
        await game.waitForPreload();
        expect(game.decodedPhotoCount, 3);
        for (var i = 0; i < 100; i++) {
          game.update(5);
          await game.waitForPreload();
          expect(game.currentIndex, (i + 1) % 100);
          expect(game.decodedPhotoCount, lessThanOrEqualTo(3));
        }
        expect(game.elapsedAtmosphere, 500);
        game.onRemove();
        expect(game.decodedPhotoCount, 0);
      });
    },
  );
}
