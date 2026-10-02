import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'content.dart';

enum Grade { again, hard, good }

class ReviewRecord {
  int attempts = 0, correct = 0, streak = 0, lapses = 0, interval = 0;
  DateTime due = DateTime.fromMillisecondsSinceEpoch(0);
  bool lastCorrect = false;
  ReviewRecord();
  ReviewRecord.fromJson(Map<String, dynamic> j)
    : attempts = j['attempts'] as int,
      correct = j['correct'] as int,
      streak = j['streak'] as int,
      lapses = j['lapses'] as int,
      interval = j['interval'] as int,
      due = DateTime.parse(j['due'] as String),
      lastCorrect = j['lastCorrect'] as bool {
    if ([attempts, correct, streak, lapses, interval].any((v) => v < 0) ||
        correct > attempts) {
      throw const FormatException('Invalid review record');
    }
  }
  bool get mastered => streak >= 3;
  void grade(Grade grade, DateTime now) {
    attempts++;
    lastCorrect = grade == Grade.good;
    if (lastCorrect) correct++;
    switch (grade) {
      case Grade.again:
        lapses++;
        streak = 0;
        interval = 0;
        due = now.add(const Duration(minutes: 10));
      case Grade.hard:
        streak = 0;
        interval = 1;
        due = now.add(const Duration(days: 1));
      case Grade.good:
        streak++;
        const days = [1, 3, 7, 14, 30, 60];
        interval = days[min(streak - 1, days.length - 1)];
        due = now.add(Duration(days: interval));
    }
  }

  Map<String, dynamic> toJson() => {
    'attempts': attempts,
    'correct': correct,
    'streak': streak,
    'lapses': lapses,
    'interval': interval,
    'due': due.toIso8601String(),
    'lastCorrect': lastCorrect,
  };
}

class StudyStore extends ChangeNotifier {
  static const key = 'lumen.study.v1';
  final Curriculum content;
  final SharedPreferencesAsync preferences = SharedPreferencesAsync();
  Map<String, ReviewRecord> records = {};
  Set<String> bookmarks = {};
  Set<String> projects = {};
  Map<String, int> daily = {};
  Map<String, dynamic>? active;
  String? storageError;
  Future<void> _writes = Future.value();
  StudyStore(this.content);
  Future<void> load() async {
    try {
      final raw = await preferences.getString(key);
      if (raw != null) restore(raw);
    } catch (_) {
      storageError = 'Saved progress could not be loaded. Export a backup before replacing it.';
    }
  }

  String export() => jsonEncode({
    'version': 1,
    'records': records.map((k, v) => MapEntry(k, v.toJson())),
    'bookmarks': bookmarks.toList(),
    'projects': projects.toList(),
    'daily': daily,
    'active': active,
  });
  void restore(String raw) {
    final j = jsonDecode(raw) as Map<String, dynamic>;
    if (j['version'] != 1) {
      throw const FormatException('Unsupported backup version');
    }
    final ids = content.questions.map((q) => q.id).toSet();
    final newRecords = (j['records'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, ReviewRecord.fromJson(v)),
    );
    if (!newRecords.keys.every(ids.contains)) {
      throw const FormatException('Unknown question');
    }
    final newBookmarks = (j['bookmarks'] as List).cast<String>().toSet();
    if (!newBookmarks.every(ids.contains)) {
      throw const FormatException('Unknown bookmark');
    }
    final newProjects = (j['projects'] as List? ?? []).cast<String>().toSet();
    final newDaily = (j['daily'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, v as int),
    );
    if (newDaily.values.any((v) => v < 0)) {
      throw const FormatException('Invalid daily count');
    }
    final newActive = j['active'] as Map<String, dynamic>?;
    if (newActive != null) {
      final sessionIds = (newActive['ids'] as List).cast<String>();
      final index = newActive['index'] as int;
      if (sessionIds.isEmpty ||
          !sessionIds.every(ids.contains) ||
          index < 0 ||
          index >= sessionIds.length ||
          newActive['title'] is! String ||
          newActive['good'] is! int) {
        throw const FormatException('Invalid session');
      }
    }
    records = newRecords;
    bookmarks = newBookmarks;
    projects = newProjects;
    daily = newDaily;
    active = newActive;
    notifyListeners();
  }

  Future<void> save() {
    final snapshot = export();
    _writes = _writes.then((_) async {
      try {
        await preferences.setString(key, snapshot);
        storageError = null;
      } catch (_) {
        storageError = 'Progress is in memory, but saving failed. Export a backup from Progress.';
      }
      notifyListeners();
    });
    return _writes;
  }

  String dayKey(DateTime now) => '${now.year}-${now.month}-${now.day}';
  int get todayCount => daily[dayKey(DateTime.now())] ?? 0;
  int get mastered => records.values.where((r) => r.mastered).length;
  int get answered => records.values.fold(0, (n, r) => n + r.attempts);
  List<Question> due(DateTime now) =>
      content.questions
          .where((q) => records[q.id]?.due.isAfter(now) == false)
          .toList()
        ..sort((a, b) => records[a.id]!.due.compareTo(records[b.id]!.due));
  List<Question> weak() => content.questions
      .where((q) => records[q.id] != null && !records[q.id]!.lastCorrect)
      .toList();
  List<Question> session(
    int count, {
    String? topic,
    int? level,
    String mode = 'mix',
    Random? random,
  }) {
    final rng = random ?? Random();
    var pool = content.questions
        .where(
          (q) =>
              (topic == null || q.topic == topic) &&
              (level == null || q.level == level),
        )
        .toList();
    if (mode == 'due') pool = due(DateTime.now()).where(pool.contains).toList();
    if (mode == 'bookmarks') {
      pool = pool.where((q) => bookmarks.contains(q.id)).toList()..shuffle(rng);
    }
    if (mode == 'weak') {
      pool = weak().where(pool.contains).toList()..shuffle(rng);
    }
    if (mode == 'mix') {
      final overdue = due(DateTime.now()).where(pool.contains).toList();
      final unseen = pool.where((q) => !records.containsKey(q.id)).toList()
        ..shuffle(rng);
      final rest =
          pool
              .where((q) => !overdue.contains(q) && !unseen.contains(q))
              .toList()
            ..shuffle(rng);
      pool = [...overdue, ...unseen, ...rest];
    }
    return pool.take(count).toList();
  }

  void start(List<Question> questions, String title) {
    active = {
      'ids': questions.map((q) => q.id).toList(),
      'index': 0,
      'title': title,
      'good': 0,
    };
    save();
    notifyListeners();
  }

  void record(Question q, Grade grade, {DateTime? now}) {
    final time = now ?? DateTime.now();
    (records[q.id] ??= ReviewRecord()).grade(grade, time);
    daily.update(dayKey(time), (n) => n + 1, ifAbsent: () => 1);
    if (active != null) {
      active!['index'] = (active!['index'] as int) + 1;
      if (grade == Grade.good) active!['good'] = (active!['good'] as int) + 1;
      if ((active!['index'] as int) >= (active!['ids'] as List).length) {
        active = null;
      }
    }
    save();
    notifyListeners();
  }

  void toggleBookmark(String id) {
    if (!bookmarks.add(id)) bookmarks.remove(id);
    save();
    notifyListeners();
  }

  void toggleProject(String id) {
    if (!projects.add(id)) projects.remove(id);
    save();
    notifyListeners();
  }

  Future<void> reset() async {
    records.clear();
    bookmarks.clear();
    projects.clear();
    daily.clear();
    active = null;
    await save();
  }
}
