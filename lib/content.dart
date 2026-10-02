import 'dart:convert';

import 'package:flutter/services.dart';

class Question {
  final String id, topic, kind, prompt, explanation;
  final int level;
  final List<String> answers, options, reading;
  Question(Map<String, dynamic> j)
    : id = j['id'],
      topic = j['topic'],
      kind = j['kind'],
      prompt = j['prompt'],
      explanation = j['explanation'],
      level = j['level'],
      answers = List<String>.from(j['answers']),
      options = List<String>.from(j['options']),
      reading = List<String>.from(j['reading']);
  bool isCorrect(List<String> selection) {
    if (kind == 'recall' || selection.length != answers.length) return false;
    if (kind == 'order') {
      for (var i = 0; i < answers.length; i++) {
        if (selection[i] != answers[i]) return false;
      }
      return true;
    }
    return answers.every(selection.contains);
  }

  String get format => switch (kind) {
    'recall' => 'Think & reveal',
    'cloze' => 'Tap the blank',
    'multi' => 'Select all that apply',
    'order' => 'Build the sequence',
    'calculate' => 'Quick calculation',
    _ => 'Choose one',
  };
}

class Topic {
  final String id, title, group, subtitle, icon, objectives;
  final List<String> reading;
  Topic(Map<String, dynamic> j)
    : id = j['id'],
      title = j['title'],
      group = j['group'],
      subtitle = j['subtitle'],
      icon = j['icon'],
      objectives = j['objectives'],
      reading = List<String>.from(j['reading']);
}

class Source {
  final String id, title, url, kind, description;
  Source(Map<String, dynamic> j)
    : id = j['id'],
      title = j['title'],
      url = j['url'],
      kind = j['kind'],
      description = j['description'];
}

class Curriculum {
  final List<Question> questions;
  final List<Topic> topics;
  final List<Source> sources;
  final List<Map<String, dynamic>> employers;
  final String researchDate, contentNote;
  Curriculum(Map<String, dynamic> j)
    : questions = (j['questions'] as List).map((q) => Question(q)).toList(),
      topics = (j['topics'] as List).map((q) => Topic(q)).toList(),
      sources = (j['sources'] as List).map((q) => Source(q)).toList(),
      employers = (j['employers'] as List).cast<Map<String, dynamic>>(),
      researchDate = j['researchDate'],
      contentNote = j['contentNote'];
  static Future<Curriculum> load() async => Curriculum(
    jsonDecode(await rootBundle.loadString('assets/curriculum.json')),
  );
  Topic topic(String id) => topics.firstWhere((t) => t.id == id);
  Source source(String id) => sources.firstWhere((s) => s.id == id);
  List<Question> forTopic(String id) =>
      questions.where((q) => q.topic == id).toList();
}
