import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/views/screens/door_opening_screen.dart';
import 'package:gift/views/screens/treasure_hunt_screen.dart';
import 'package:gift/views/widgets/found_phone_frame.dart';
import 'package:gift/views/widgets/found_phone_lock_screen.dart';
import 'package:gift/views/widgets/phone_floor_scene.dart';

Widget phone(VoidCallback unlocked) => MaterialApp(
  home: Scaffold(
    backgroundColor: const Color(0xFF211B28),
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: FoundPhoneFrame(
          dark: true,
          child: FoundPhoneLockScreen(onUnlocked: unlocked),
        ),
      ),
    ),
  ),
);

void main() {
  testWidgets('pickup requires PIN before chat and incoming voice are shown', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final boundary = GlobalKey();
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundary,
        child: MaterialApp(home: TreasureHuntScreen(onComplete: () {})),
      ),
    );
    await tester.pump();
    final veil = find
        .ancestor(
          of: find.byKey(const ValueKey('room-white-veil')),
          matching: find.byType(Opacity),
        )
        .first;
    expect(tester.widget<Opacity>(veil).opacity, 1);
    await tester.pump(const Duration(milliseconds: 3700));
    expect(find.text('那是什么？'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('floor-phone')));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('你捡起了一部手机。\n屏幕里，似乎藏着一段未读的故事。'), findsOneWidget);
    expect(find.text('输入密码'), findsNothing);
    await tester.tap(find.text('打开手机'));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('输入密码'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('神秘联系人'), findsNothing);
    expect(find.byKey(const ValueKey('hunt-voice-0')), findsNothing);
    for (final digit in ['0', '9', '1', '7']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('神秘联系人'), findsOneWidget);
    expect(find.byType(FoundPhoneFrame), findsOneWidget);
    expect(find.byKey(const ValueKey('hunt-voice-0')), findsNothing);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byKey(const ValueKey('hunt-voice-0')), findsOneWidget);
    expect(tester.takeException(), isNull);
    if (Platform.environment['CAPTURE_PHONE_PREVIEWS'] == '1') {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '/tmp/gift_phone_chat.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('only PIN 0917 unlocks, wrong PIN resets and deletion works', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var unlocked = 0;
    await tester.pumpWidget(phone(() => unlocked++));
    for (final digit in ['0', '9', '1', '4']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    expect(unlocked, 0);
    expect(find.text('密码不对，再试一次'), findsOneWidget);
    await tester.tap(find.text('2'));
    await tester.tap(find.byTooltip('删除一位'));
    for (final digit in ['0', '9', '1', '7']) {
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    expect(unlocked, 1);
    await tester.tap(find.text('4'));
    expect(unlocked, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('phone keypad remains usable on a small iPhone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var unlocked = 0;
    await tester.pumpWidget(phone(() => unlocked++));
    for (final digit in ['0', '9', '1', '7']) {
      await tester.ensureVisible(find.text(digit));
      await tester.tap(find.text(digit));
      await tester.pump();
    }
    expect(unlocked, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('door reaches pure white before advancing exactly once', (
    tester,
  ) async {
    var completed = 0;
    await tester.pumpWidget(
      MaterialApp(home: DoorOpeningScreen(onComplete: () => completed++)),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 4700));
    final veil = find
        .ancestor(
          of: find.byKey(const ValueKey('door-whiteout')),
          matching: find.byType(Opacity),
        )
        .first;
    expect(tester.widget<Opacity>(veil).opacity, 1);
    expect(completed, 0);
    await tester.pump(const Duration(milliseconds: 1000));
    expect(completed, 1);
    await tester.pump(const Duration(seconds: 1));
    expect(completed, 1);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('floor phone is tappable and phone scenes fit a phone viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var pickedUp = 0;
    final boundary = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: boundary,
            child: PhoneFloorScene(onPickUp: () => pickedUp++),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 3700));
    await tester.tap(find.byKey(const ValueKey('floor-phone')));
    await tester.pump(const Duration(milliseconds: 700));
    expect(pickedUp, 0);
    await tester.tap(find.text('打开手机'));
    expect(pickedUp, 1);
    expect(tester.takeException(), isNull);
    if (Platform.environment['CAPTURE_PHONE_PREVIEWS'] == '1') {
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '/tmp/gift_phone_floor.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(
        RepaintBoundary(key: boundary, child: phone(() {})),
      );
      await tester.pump();
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        File(
          '/tmp/gift_phone_lock.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
    }
    await tester.pumpWidget(const SizedBox());
  });
}
