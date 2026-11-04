import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/services/app_unlock_policy.dart';
import 'package:gift/views/screens/app_unlock_screen.dart';

void main() {
  test('opens exactly at 23:30 Malaysia time regardless of local timezone', () {
    expect(
      AppUnlockPolicy.isOpen(DateTime.parse('2026-11-07T23:29:59.999+08:00')),
      isFalse,
    );
    expect(
      AppUnlockPolicy.isOpen(DateTime.parse('2026-11-07T23:30:00+08:00')),
      isTrue,
    );
    expect(AppUnlockPolicy.isOpen(DateTime.utc(2026, 11, 7, 15, 30)), isTrue);
  });

  test('PBKDF2 matches independently generated SHA256 reference vectors', () {
    String hex(List<int> bytes) =>
        bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    expect(
      hex(AppUnlockPolicy.deriveKey('password', 'salt'.codeUnits, 1)),
      '120fb6cffcf8b32c43e7225256c4f837a86548c92ccc35480805987cb70be17b',
    );
    expect(
      hex(AppUnlockPolicy.deriveKey('password', 'salt'.codeUnits, 2)),
      'ae4d0c95af6b46d32d0adff928f06dd02a303f8ef3c251dfd6e2d85a95474c43',
    );
  });

  final configuredPassword = Platform.environment['APP_UNLOCK_TEST_PASSWORD'];
  if (configuredPassword != null) {
    test(
      'configured admin hash accepts correct password and rejects incorrect password',
      () async {
        expect(
          await AppUnlockPolicy.verifyAdminPassword(configuredPassword),
          isTrue,
        );
        expect(
          await AppUnlockPolicy.verifyAdminPassword('incorrect-password'),
          isFalse,
        );
      },
    );
  }

  testWidgets(
    'locked app never builds flow and automatically opens at deadline',
    (tester) async {
      var now = AppUnlockPolicy.unlockAt.subtract(const Duration(seconds: 1));
      var builds = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: AppUnlockScreen(
            now: () => now,
            builder: (_) {
              builds++;
              return const Text('birthday flow');
            },
          ),
        ),
      );
      expect(builds, 0);
      expect(find.text('此 App 已锁定'), findsOneWidget);
      now = AppUnlockPolicy.unlockAt;
      await tester.pump(const Duration(seconds: 1));
      expect(find.text('birthday flow'), findsOneWidget);
      expect(builds, 1);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'admin bypass stays locked on failure and starts flow on success',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: AppUnlockScreen(
            now: () => DateTime.utc(2026, 11, 4),
            verifyPassword: (value) async => value == 'test-pass',
            builder: (_) => const Text('birthday flow'),
          ),
        ),
      );
      await tester.tap(find.text('管理员入口'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'wrong');
      await tester.ensureVisible(find.text('解锁'));
      await tester.tap(find.text('解锁'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));
      expect(find.text('密码不正确，请再试一次'), findsOneWidget);
      expect(find.text('birthday flow'), findsNothing);
      await tester.enterText(find.byType(TextField), 'test-pass');
      await tester.ensureVisible(find.text('解锁'));
      await tester.tap(find.text('解锁'));
      await tester.pumpAndSettle();
      expect(find.text('birthday flow'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
