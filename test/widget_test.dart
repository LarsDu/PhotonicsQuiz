import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:photonics_quiz/content.dart';
import 'package:photonics_quiz/main.dart';
import 'package:photonics_quiz/quiz_screen.dart';
import 'package:photonics_quiz/study_store.dart';
import 'package:photonics_quiz/style.dart';

void main() {
  final content = Curriculum(
    jsonDecode(File('assets/curriculum.json').readAsStringSync()),
  );
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  testWidgets(
    'mobile home, topic filters, review and employer guide work without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final store = StudyStore(content);
      await tester.pumpWidget(LumenApp(store: store));
      await tester.pumpAndSettle();
      expect(find.text('A little light. Every day.'), findsOneWidget);
      await tester.tap(find.text('Topics'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'germanium');
      await tester.pumpAndSettle();
      expect(find.text('Detectors & receivers'), findsOneWidget);
      expect(find.text('The silicon platform'), findsNothing);
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(find.text('0 questions ready'), findsOneWidget);
      await tester.tap(find.text('Explore'));
      await tester.pumpAndSettle();
      expect(find.text('Xscape Photonics'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final kind in [
    'choice',
    'cloze',
    'calculate',
    'multi',
    'order',
    'recall',
  ]) {
    testWidgets('$kind can be answered on a phone and records exactly once', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final q = content.questions.firstWhere((q) => q.kind == kind);
      final store = StudyStore(content);
      store.start([q], 'Practice');
      await tester.pumpWidget(
        MaterialApp(
          theme: appTheme(),
          home: QuizScreen(store: store, questions: [q], title: 'Practice'),
        ),
      );
      await tester.pumpAndSettle();
      if (kind == 'recall') {
        await tester.tap(find.text('Reveal answer'));
        await tester.pumpAndSettle();
        expect(store.answered, 0);
        await tester.tap(find.text('Got it'));
      } else {
        for (final answer in q.answers) {
          final option = find.widgetWithText(InkWell, answer).last;
          await tester.ensureVisible(option);
          await tester.pumpAndSettle();
          await tester.tap(option);
          await tester.pumpAndSettle();
        }
        await tester.tap(find.text('Check answer'));
      }
      await tester.pumpAndSettle();
      expect(store.records[q.id]!.correct, 1);
      expect(store.records[q.id]!.attempts, 1);
      expect(store.active, isNull);
      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();
      expect(find.text('Session complete'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('320px screen with large text can use recall controls', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final q = content.questions.firstWhere((q) => q.kind == 'recall');
    final store = StudyStore(content);
    store.start([q], 'Practice');
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(),
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(1.5)),
          child: child!,
        ),
        home: QuizScreen(store: store, questions: [q], title: 'Practice'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reveal answer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Almost'));
    await tester.pumpAndSettle();
    expect(store.records[q.id]!.interval, 1);
    expect(tester.takeException(), isNull);
  });
}
