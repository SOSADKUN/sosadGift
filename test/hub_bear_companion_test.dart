import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/widgets/hub_bear_companion.dart';

void main() {
  testWidgets('all three bear moods render and reduced motion stays still', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 280);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: RepaintBoundary(
          key: const ValueKey('bear-preview'),
          child: const ColoredBox(
            color: Color(0xFF49334E),
            child: Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  HubBearCompanion(mood: HubBearMood.idle, width: 220),
                  HubBearCompanion(mood: HubBearMood.sad, width: 220),
                  HubBearCompanion(mood: HubBearMood.happy, width: 220),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    expect(find.byType(HubBearCompanion), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    if (Platform.environment['CAPTURE_HUB_BEARS'] == '1') {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('bear-preview')),
      );
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2);
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        await Directory('tmp').create(recursive: true);
        await File(
          'tmp/hub_bears_preview.png',
        ).writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: HubBearCompanion(),
        ),
      ),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('inactive companion stops its animation ticker', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HubBearCompanion(active: false)),
    );
    expect(tester.hasRunningAnimations, isFalse);
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
}
