import 'dart:math';

import 'package:flutter/material.dart';

import 'content.dart';
import 'study_store.dart';
import 'style.dart';
import 'widgets.dart';

class QuizScreen extends StatefulWidget {
  final StudyStore store;
  final List<Question> questions;
  final String title;
  final int startIndex, previousGood;
  const QuizScreen({
    super.key,
    required this.store,
    required this.questions,
    required this.title,
    this.startIndex = 0,
    this.previousGood = 0,
  });
  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  late int index, good;
  late List<String> options;
  final List<String> selected = [];
  final ScrollController scroll = ScrollController();
  final feedbackKey = GlobalKey();
  bool revealed = false, graded = false, complete = false;
  Grade? grade;
  Question get q => widget.questions[index];
  @override
  void initState() {
    super.initState();
    index = widget.startIndex;
    good = widget.previousGood;
    prepare();
  }

  void prepare() {
    options = [...q.options]..shuffle(Random());
    // A sequencing task must not start with the answer accidentally displayed.
    if (q.kind == 'order' && q.isCorrect(options)) {
      options = [...options.skip(1), options.first];
    }
    selected.clear();
    revealed = false;
    graded = false;
    grade = null;
  }

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void assess(Grade value) {
    if (graded) return;
    widget.store.record(q, value);
    setState(() {
      grade = value;
      graded = true;
      revealed = true;
      if (value == Grade.good) good++;
    });
    showFeedback();
  }

  void showFeedback() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || feedbackKey.currentContext == null) return;
      Scrollable.ensureVisible(
        feedbackKey.currentContext!,
        duration: const Duration(milliseconds: 250),
        alignment: 0.1,
      );
    });
  }

  void next() {
    if (index == widget.questions.length - 1) {
      setState(() => complete = true);
      return;
    }
    setState(() {
      index++;
      prepare();
    });
    scroll.jumpTo(0);
  }

  void select(String value) {
    if (revealed) return;
    setState(() {
      if (q.kind == 'order' || q.kind == 'multi') {
        if (selected.contains(value)) {
          selected.remove(value);
        } else {
          selected.add(value);
        }
      } else {
        selected.clear();
        selected.add(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (complete) return _summary(context);
    final recall = q.kind == 'recall';
    final canCheck =
        selected.isNotEmpty &&
        (q.kind != 'order' || selected.length == options.length);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Save and close session',
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          ListenableBuilder(
            listenable: widget.store,
            builder: (context, _) => IconButton(
              tooltip: widget.store.bookmarks.contains(q.id)
                  ? 'Remove bookmark'
                  : 'Bookmark question',
              onPressed: () => widget.store.toggleBookmark(q.id),
              icon: Icon(
                widget.store.bookmarks.contains(q.id)
                    ? Icons.bookmark
                    : Icons.bookmark_border,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Question ${index + 1} of ${widget.questions.length}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${((index / widget.questions.length) * 100).round()}%',
                          style: const TextStyle(color: muted),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: index / widget.questions.length,
                        minHeight: 6,
                        backgroundColor: line,
                        color: teal,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  controller: scroll,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            label: Text(q.format),
                            backgroundColor: const Color(0xFFE5EEE6),
                            side: BorderSide.none,
                          ),
                          Chip(
                            label: Text(
                              ['Foundation', 'Applied', 'Advanced'][q.level -
                                  1],
                            ),
                            side: const BorderSide(color: line),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Eyebrow(widget.store.content.topic(q.topic).title),
                      const SizedBox(height: 12),
                      Semantics(
                        header: true,
                        child: Text(
                          q.prompt,
                          style: const TextStyle(
                            fontSize: 25,
                            height: 1.4,
                            fontWeight: FontWeight.w700,
                            color: ink,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(switch (q.kind) {
                        'recall' => 'Explain it to yourself, out loud or in your head. Reveal the answer when you’re ready.',
                        'multi' => 'Tap every correct answer, then check.',
                        'order' => 'Tap the steps in order. Tap a selected step again to remove it.',
                        'cloze' =>
                          'Choose the phrase that completes the blank.',
                        'calculate' => 'Estimate or calculate mentally, then tap your answer.',
                        _ => 'Choose the best answer.',
                      }),
                      const SizedBox(height: 20),
                      if (!recall) ...[
                        if (q.kind == 'order' && selected.isNotEmpty)
                          Surface(
                            color: const Color(0xFFEDF2E5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Eyebrow('Your sequence'),
                                const SizedBox(height: 8),
                                for (final entry in selected.indexed)
                                  Text(
                                    '${entry.$1 + 1}. ${entry.$2}',
                                    style: const TextStyle(
                                      color: ink,
                                      height: 1.8,
                                    ),
                                  ),
                                if (!revealed)
                                  TextButton(
                                    onPressed: () => setState(selected.clear),
                                    child: const Text('Clear sequence'),
                                  ),
                              ],
                            ),
                          ),
                        if (q.kind == 'order' && selected.isNotEmpty)
                          const SizedBox(height: 12),
                        for (final option in options)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _option(option),
                          ),
                      ],
                      if (revealed) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          key: feedbackKey,
                          liveRegion: true,
                          child: Surface(
                            color: grade == Grade.again
                                ? const Color(0xFFFFF0E8)
                                : const Color(0xFFEDF2E5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Eyebrow(
                                  recall && !graded
                                      ? 'Answer checklist'
                                      : grade == Grade.good
                                      ? 'Well recalled'
                                      : grade == Grade.hard
                                      ? 'Keep practicing'
                                      : 'Let’s revisit this',
                                ),
                                const SizedBox(height: 12),
                                for (final entry in q.answers.indexed)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 6),
                                    child: Text(
                                      q.kind == 'order'
                                          ? '${entry.$1 + 1}. ${entry.$2}'
                                          : entry.$2,
                                      style: const TextStyle(
                                        color: ink,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 8),
                                Text(
                                  q.explanation,
                                  style: const TextStyle(
                                    color: ink,
                                    height: 1.6,
                                  ),
                                ),
                                if (graded) ...[
                                  const SizedBox(height: 12),
                                  Text(
                                    grade == Grade.again
                                        ? 'Scheduled for review in 10 minutes.'
                                        : grade == Grade.hard
                                        ? 'Scheduled for review tomorrow.'
                                        : 'Next review in ${widget.store.records[q.id]!.interval} day(s).',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: teal,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        ReadingLinks(
                          content: widget.store.content,
                          ids: q.reading,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
                  decoration: const BoxDecoration(
                    color: paper,
                    border: Border(top: BorderSide(color: line)),
                  ),
                  child: graded
                      ? FilledButton(
                          onPressed: next,
                          child: Text(
                            index == widget.questions.length - 1
                                ? 'Finish session'
                                : 'Next question',
                          ),
                        )
                      : recall && revealed
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Self-assessment · how much did you recall?',
                              style: TextStyle(fontSize: 12, color: muted),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                OutlinedButton(
                                  onPressed: () => assess(Grade.again),
                                  child: const Text('Again'),
                                ),
                                OutlinedButton(
                                  onPressed: () => assess(Grade.hard),
                                  child: const Text('Almost'),
                                ),
                                FilledButton(
                                  onPressed: () => assess(Grade.good),
                                  child: const Text('Got it'),
                                ),
                              ],
                            ),
                          ],
                        )
                      : recall
                      ? FilledButton(
                          onPressed: () {
                            setState(() => revealed = true);
                            showFeedback();
                          },
                          child: const Text('Reveal answer'),
                        )
                      : FilledButton(
                          onPressed: canCheck
                              ? () => assess(
                                  q.isCorrect(selected)
                                      ? Grade.good
                                      : Grade.again,
                                )
                              : null,
                          child: const Text('Check answer'),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _option(String option) {
    final chosen = selected.contains(option);
    final correct = revealed && q.answers.contains(option) && q.kind != 'order';
    final wrong = revealed && chosen && !correct && q.kind != 'order';
    return Semantics(
      button: true,
      selected: chosen,
      child: Material(
        color: correct
            ? const Color(0xFFE7F0DC)
            : wrong
            ? const Color(0xFFFFE8DE)
            : chosen
            ? const Color(0xFFE6F0EB)
            : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: chosen || correct ? teal : line,
            width: chosen ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: revealed ? null : () => select(option),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                SizedBox(
                  width: 26,
                  child: q.kind == 'order' && chosen
                      ? Text(
                          '${selected.indexOf(option) + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: teal,
                          ),
                        )
                      : Icon(
                          correct
                              ? Icons.check_circle_outline
                              : wrong
                              ? Icons.cancel_outlined
                              : chosen
                              ? Icons.check_circle
                              : q.kind == 'multi'
                              ? Icons.check_box_outline_blank
                              : Icons.radio_button_unchecked,
                          size: 22,
                          color: chosen || correct ? teal : muted,
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    option,
                    style: const TextStyle(
                      fontSize: 15,
                      color: ink,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _summary(BuildContext context) => Scaffold(
    appBar: AppBar(
      automaticallyImplyLeading: false,
      title: const Text('Session complete'),
    ),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.auto_awesome, color: teal, size: 48),
              const SizedBox(height: 24),
              Text(
                'A little more light.',
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 16),
              Text(
                '$good of ${widget.questions.length} fully recalled or correct.',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              const Text(
                'Tap questions are checked against answers. Think & reveal questions use your own assessment.',
              ),
              const SizedBox(height: 24),
              const Surface(
                child: Text(
                  'Your progress is saved. Questions that need work are in Review; spaced repetition will bring them back. Three consecutive “Got it” or correct responses mark a question as retained.',
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Back to my study'),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
