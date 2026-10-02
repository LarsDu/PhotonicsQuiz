import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:photonics_quiz/content.dart';
import 'package:photonics_quiz/study_store.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final content = Curriculum(
    jsonDecode(File('assets/curriculum.json').readAsStringSync()),
  );
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );
  test('spacing increases after recall, lapses reset retention, partial recall returns tomorrow', () {
    final r = ReviewRecord();
    final now = DateTime(2026, 10, 1, 12);
    for (final days in [1, 3, 7]) {
      r.grade(Grade.good, now);
      expect(r.due.difference(now).inDays, days);
    }
    expect(r.mastered, isTrue);
    r.grade(Grade.again, now);
    expect(r.mastered, isFalse);
    expect(r.due, now.add(const Duration(minutes: 10)));
    expect(r.lapses, 1);
    r.grade(Grade.hard, now);
    expect(r.due, now.add(const Duration(days: 1)));
    expect(r.lastCorrect, isFalse);
  });
  test(
    'progress, bookmarks, portfolio and unfinished session survive a new store',
    () async {
      final store = StudyStore(content);
      final qs = content.questions.take(3).toList();
      store.start(qs, 'Test session');
      store.toggleBookmark(qs.first.id);
      store.toggleProject('layout');
      store.record(qs.first, Grade.good);
      await store.save();
      final loaded = StudyStore(content);
      await loaded.load();
      expect(loaded.active!['index'], 1);
      expect(loaded.active!['good'], 1);
      expect(loaded.records[qs.first.id]!.attempts, 1);
      expect(loaded.bookmarks, {qs.first.id});
      expect(loaded.projects, {'layout'});
      expect(loaded.todayCount, 1);
      loaded.record(qs[1], Grade.again);
      loaded.record(qs[2], Grade.good);
      expect(loaded.active, isNull);
      await loaded.save();
    },
  );
  test(
    'invalid restore is atomic and does not clear existing progress',
    () async {
      final store = StudyStore(content);
      store.toggleBookmark(content.questions.first.id);
      final before = store.export();
      final bad = jsonDecode(before) as Map<String, dynamic>;
      bad['active'] = {
        'ids': ['unknown'],
        'index': 0,
        'title': 'bad',
        'good': 0,
      };
      expect(() => store.restore(jsonEncode(bad)), throwsFormatException);
      expect(store.export(), before);
      await store.save();
    },
  );
  test('daily sessions prioritize overdue work and filters never include other topics or levels', () async {
    final store = StudyStore(content);
    final dueQuestion = content.questions[30];
    store.record(
      dueQuestion,
      Grade.again,
      now: DateTime.now().subtract(const Duration(hours: 1)),
    );
    expect(store.session(5, random: Random(1)).first.id, dueQuestion.id);
    final selected = store.session(20, topic: 'links', level: 3);
    expect(selected, isNotEmpty);
    expect(selected.every((q) => q.topic == 'links' && q.level == 3), isTrue);
    expect(store.session(20, mode: 'bookmarks'), isEmpty);
    expect(store.session(20, mode: 'weak').map((q) => q.id), [dueQuestion.id]);
    await store.save();
  });
}
