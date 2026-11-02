import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/screens/splash_screen.dart';

void main() {
  testWidgets('birthday splash shows selected icon and advances once', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: SplashScreen(onComplete: () => completed++)),
    );
    expect(find.text('今年的生日，依旧是我'), findsOneWidget);
    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as AssetImage).assetName, 'assets/icon/app_icon.png');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    expect(completed, 0);
      for (var i = 0; i < 12; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
    expect(completed, 1);
    await tester.pump(const Duration(seconds: 2));
    expect(completed, 1);
  });

  testWidgets('compact splash supports large text and reduced motion', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 480),
            textScaler: TextScaler.linear(2),
            disableAnimations: true,
          ),
          child: SplashScreen(onComplete: () {}),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });
}
