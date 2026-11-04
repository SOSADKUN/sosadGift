import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/widgets/video_player_widget.dart';

void main() {
  testWidgets(
    'diary stays full bleed in landscape even after contain threshold',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Center(
            child: SizedBox(
              width: 700,
              height: 300,
              child: VideoFrameLayout(
                videoSize: Size(1080, 1920),
                contain: true,
                containInLandscape: false,
                backgroundColor: Colors.white,
                child: ColoredBox(key: ValueKey('video'), color: Colors.pink),
              ),
            ),
          ),
        ),
      );
      expect(
        tester.widget<FittedBox>(find.byType(FittedBox)).fit,
        BoxFit.cover,
      );
      final video = tester.getRect(find.byKey(const ValueKey('video')));
      expect(video.width, closeTo(700, .001));
      expect(video.height, greaterThanOrEqualTo(300));
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('portrait retains full diary frame and white background', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Center(
          child: SizedBox(
            width: 300,
            height: 550,
            child: VideoFrameLayout(
              videoSize: Size(1080, 1920),
              contain: true,
              containInLandscape: false,
              backgroundColor: Colors.white,
              child: ColoredBox(key: ValueKey('video'), color: Colors.pink),
            ),
          ),
        ),
      ),
    );
    expect(
      tester.widget<FittedBox>(find.byType(FittedBox)).fit,
      BoxFit.contain,
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('video'))).width,
      lessThanOrEqualTo(300),
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('video'))).height,
      lessThanOrEqualTo(550),
    );
    expect(tester.takeException(), isNull);
  });
}
