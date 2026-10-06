import 'package:flame/game.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/games/memory_album_game.dart';

void main() {
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
