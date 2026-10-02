import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:photonics_quiz/content.dart';

void main() {
  final content = Curriculum(
    jsonDecode(File('assets/curriculum.json').readAsStringSync()),
  );
  test(
    '320 distinct questions cover every topic with valid reading and answers',
    () {
      expect(content.questions.length, 320);
      expect(content.questions.map((q) => q.id).toSet().length, 320);
      expect(content.questions.map((q) => q.prompt).toSet().length, 320);
      expect(content.topics.length, 16);
      expect(content.employers.length, 12);
      for (final topic in content.topics) {
        expect(content.forTopic(topic.id).length, 20);
      }
      for (final q in content.questions) {
        expect(q.level, inInclusiveRange(1, 3));
        expect(q.explanation.isNotEmpty, isTrue);
        for (final id in q.reading) {
          expect(content.source(id).url, startsWith('https://'));
        }
        if (q.kind != 'recall') {
          expect(q.options.toSet().length, q.options.length);
          expect(q.answers.every(q.options.contains), isTrue);
          expect(q.isCorrect(q.answers), isTrue);
          expect(q.isCorrect([]), isFalse);
        }
      }
      expect(content.questions.map((q) => q.kind).toSet(), {
        'choice',
        'cloze',
        'recall',
        'multi',
        'order',
        'calculate',
      });
    },
  );
  test('multiple-select rejects missing or extra answers; sequence requires correct order', () {
    final multi = content.questions.firstWhere((q) => q.kind == 'multi');
    expect(multi.isCorrect(multi.answers.reversed.toList()), isTrue);
    expect(multi.isCorrect([multi.answers.first]), isFalse);
    expect(multi.isCorrect([...multi.answers, multi.options.last]), isFalse);
    final order = content.questions.firstWhere((q) => q.kind == 'order');
    expect(order.isCorrect(order.answers.reversed.toList()), isFalse);
    expect(order.isCorrect(order.answers), isTrue);
  });
  test('calculation answers agree with independent physical calculations', () {
    Question get(String id) => content.questions.firstWhere((q) => q.id == id);
    expect(4 * 0.003 / 3e8 * 1e12, closeTo(40, 0.001));
    expect(get('waveguides-12').answers.single, '40 ps');
    expect(
      1 / (2 * 3.141592653589793 * 50 * 100e-15) / 1e9,
      closeTo(31.83, 0.01),
    );
    expect(get('modulators-09').answers.single, '32 GHz');
    expect(8 / 2e12 * 1e12, 4);
    expect(get('links-16').answers.single, '4 pJ/bit');
    expect(0.9 * 0.9 * 0.9 * 100, closeTo(72.9, 0.0001));
    expect(get('packaging-12').answers.single, '72.9%');
  });
}
