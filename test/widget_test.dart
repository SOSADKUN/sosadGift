import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/main.dart';
import 'package:gift/views/screens/app_unlock_screen.dart';

void main() {
  testWidgets('app entry protects the birthday flow with its startup gate', (
    tester,
  ) async {
    late MaterialApp app;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          app = const MyApp().build(context) as MaterialApp;
          return const SizedBox.shrink();
        },
      ),
    );
    expect(app.home, isA<AppUnlockScreen>());
    expect(app.debugShowCheckedModeBanner, isFalse);
  });
}
