import 'dart:ui' as ui;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/games/animated_game_assets.dart';

void main() {
  testWidgets(
    'Flame keeps every GIF frame, its timing and source proportions',
    (tester) async {
      await tester.runAsync(() async {
        final library = AnimatedGameAssets();
        const paths = [
          'assets/photos/game2_1.gif',
          'assets/photos/game4_1.gif',
        ];
        try {
          await library.load(paths);
          for (final path in paths) {
            final data = await rootBundle.load(path);
            final codec = await ui.instantiateImageCodec(
              data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
            );
            try {
              final frames = library.animation(path).frames;
              expect(frames.length, codec.frameCount);
              for (var i = 0; i < codec.frameCount; i++) {
                final frame = await codec.getNextFrame();
                final seconds = frame.duration > Duration.zero
                    ? frame.duration.inMicroseconds / 1000000
                    : .1;
                expect(frames[i].stepTime, seconds);
                expect(
                  frames[i].sprite.srcSize.x / frames[i].sprite.srcSize.y,
                  closeTo(frame.image.width / frame.image.height, .02),
                );
                frame.image.dispose();
              }
            } finally {
              codec.dispose();
            }
          }
        } finally {
          library.dispose();
        }
      });
    },
  );
}
