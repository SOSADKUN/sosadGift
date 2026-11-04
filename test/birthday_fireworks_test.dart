import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/widgets/birthday_fireworks.dart';

void main() {
  testWidgets(
    'layered fireworks render on a phone and respect reduced motion',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        const MaterialApp(
          home: RepaintBoundary(
            key: ValueKey('fireworks-preview'),
            child: ColoredBox(
              color: Color(0xFF180F20),
              child: BirthdayFireworks(animation: AlwaysStoppedAnimation(.65)),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      if (Platform.environment['CAPTURE_FIREWORKS'] == '1') {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(const ValueKey('fireworks-preview')),
        );
        await tester.runAsync(() async {
          final img = await boundary.toImage(pixelRatio: 2);
          final png = await img.toByteData(format: ui.ImageByteFormat.png);
          await File(
            'tmp/fireworks_preview.png',
          ).writeAsBytes(png!.buffer.asUint8List());
          img.dispose();
        });
      }
      await tester.pumpWidget(
        const MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: BirthdayFireworks(animation: AlwaysStoppedAnimation(.65)),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
