import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gift/models/story_entry.dart';
import 'package:gift/views/widgets/memory_journey.dart';

const entries = [
  StoryEntry(
    year: '2024',
    title: 'Us',
    steps: [
      StoryStep(sentence: 'Our first little memory.'),
      StoryStep(sentence: 'Another day together.'),
      StoryStep(sentence: 'And many more to come.'),
    ],
  ),
];

Future<void> advance(WidgetTester tester, int frames) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 40));
  }
}

void main() {
  testWidgets(
    'year titles separate each chapter and reverse navigation restores them',
    (tester) async {
      const chapters = [
        StoryEntry(
          year: '2022',
          title: '原神开端',
          steps: [StoryStep(sentence: 'First photo')],
        ),
        StoryEntry(
          year: '2023',
          title: '香水味～',
          steps: [StoryStep(sentence: 'Second photo')],
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: MemoryJourney(entries: chapters, onComplete: () {}),
        ),
      );
      expect(find.text('2022年'), findsOneWidget);
      expect(find.text('原神开端'), findsOneWidget);
      expect(find.byKey(const ValueKey('memory-photo-1')), findsNothing);
      await tester.tap(find.byTooltip('下一段回忆'));
      await tester.pump();
      expect(find.text('First photo'), findsOneWidget);
      expect(find.text('2022年'), findsNothing);
      await tester.tap(find.byTooltip('下一段回忆'));
      await tester.pump();
      expect(find.text('2023年'), findsOneWidget);
      expect(find.text('香水味～'), findsOneWidget);
      expect(find.byKey(const ValueKey('memory-photo-3')), findsNothing);
      await tester.tap(find.byTooltip('下一段回忆'));
      await tester.pump();
      expect(find.text('Second photo'), findsOneWidget);
      await tester.tap(find.byTooltip('上一段回忆'));
      await tester.pump();
      expect(find.text('2023年'), findsOneWidget);
    },
  );

  testWidgets('hold advances, release stops, and left hold reverses', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MemoryJourney(entries: entries, onComplete: () {}),
      ),
    );
    final area = tester.getRect(find.byKey(const ValueKey('memory-hold-area')));
    var gesture = await tester.startGesture(
      Offset(area.right - 10, area.center.dy),
    );
    await advance(tester, 125);
    expect(find.text('03 / 04'), findsOneWidget);
    await gesture.up();
    await advance(tester, 60);
    expect(find.text('03 / 04'), findsOneWidget);
    gesture = await tester.startGesture(Offset(area.left + 10, area.center.dy));
    await advance(tester, 95);
    await gesture.up();
    expect(find.text('01 / 04'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancel stops motion and navigation stays within bounds', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MemoryJourney(entries: entries, onComplete: () {}),
      ),
    );
    await tester.tap(find.byTooltip('上一段回忆'));
    expect(find.text('01 / 04'), findsOneWidget);
    for (var i = 0; i < 5; i++) {
      await tester.tap(find.byTooltip('下一段回忆'));
      await tester.pump();
    }
    expect(find.text('04 / 04'), findsOneWidget);
    final area = tester.getRect(find.byKey(const ValueKey('memory-hold-area')));
    final gesture = await tester.startGesture(
      Offset(area.left + 10, area.center.dy),
    );
    await advance(tester, 25);
    await gesture.cancel();
    final counter = tester
        .widget<Text>(find.byKey(const ValueKey('memory-counter')))
        .data;
    await advance(tester, 80);
    expect(find.text(counter!), findsOneWidget);
  });

  testWidgets(
    'compact screen supports large text, reduced motion and completion',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      var completions = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              textScaler: TextScaler.linear(1.6),
              disableAnimations: true,
            ),
            child: MemoryJourney(
              entries: entries,
              onComplete: () => completions++,
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('下一段回忆'));
      await tester.pump();
      expect(find.text('Our first little memory.'), findsOneWidget);
      await tester.tap(find.text('下一页  ↗'));
      await tester.tap(find.text('下一页  ↗'));
      expect(completions, 1);
      expect(tester.takeException(), isNull);
    },
  );
}
