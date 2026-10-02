import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'content.dart';
import 'quiz_screen.dart';
import 'study_store.dart';
import 'style.dart';
import 'widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const Bootstrap());
}

class Bootstrap extends StatefulWidget {
  const Bootstrap({super.key});
  @override
  State<Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<Bootstrap> {
  late Future<StudyStore> loading = load();
  Future<StudyStore> load() async {
    final store = StudyStore(await Curriculum.load());
    await store.load();
    return store;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<StudyStore>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasData) return LumenApp(store: snapshot.data!);
      return MaterialApp(
        theme: appTheme(),
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: snapshot.hasError
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('The study library could not be loaded.'),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => setState(() => loading = load()),
                        child: const Text('Try again'),
                      ),
                    ],
                  )
                : const CircularProgressIndicator(),
          ),
        ),
      );
    },
  );
}

class LumenApp extends StatelessWidget {
  final StudyStore store;
  const LumenApp({super.key, required this.store});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lumen · Silicon photonics',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: StudyHome(store: store),
  );
}

class StudyHome extends StatefulWidget {
  final StudyStore store;
  const StudyHome({super.key, required this.store});
  @override
  State<StudyHome> createState() => _StudyHomeState();
}

class _StudyHomeState extends State<StudyHome> {
  final searchController = TextEditingController();
  int tab = 0, count = 10, exploreTab = 0;
  int? difficulty;
  String query = '', group = 'All', employerFilter = 'All nearby';
  StudyStore get store => widget.store;
  Curriculum get content => store.content;
  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: store,
    builder: (context, _) {
      final wide = MediaQuery.sizeOf(context).width >= 980;
      return Scaffold(
        appBar: AppBar(
          toolbarHeight: 76,
          title: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: ink,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.blur_circular, color: lime, size: 25),
                ),
                const SizedBox(width: 12),
                const Text(
                  'lumen',
                  style: TextStyle(
                    fontFamily: 'DMSerif',
                    fontSize: 29,
                    color: ink,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              tooltip: 'Progress and backups',
              icon: const Icon(Icons.insights_outlined),
              onPressed: progress,
            ),
            const SizedBox(width: 16),
          ],
        ),
        body: Row(
          children: [
            if (wide)
              NavigationRail(
                selectedIndex: tab,
                onDestinationSelected: (v) => setState(() => tab = v),
                labelType: NavigationRailLabelType.all,
                backgroundColor: paper,
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.wb_sunny_outlined),
                    label: Text('Today'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.auto_stories_outlined),
                    label: Text('Topics'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.history),
                    label: Text('Review'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.explore_outlined),
                    label: Text('Explore'),
                  ),
                ],
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: SingleChildScrollView(
                    key: ValueKey(tab),
                    padding: EdgeInsets.fromLTRB(
                      wide ? 32 : 22,
                      12,
                      wide ? 32 : 22,
                      32,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (store.storageError != null) ...[
                          Surface(
                            color: const Color(0xFFFFF0E8),
                            child: Text(store.storageError!),
                          ),
                          const SizedBox(height: 16),
                        ],
                        switch (tab) {
                          1 => topics(),
                          2 => review(),
                          3 => explore(),
                          _ => today(),
                        },
                        const SizedBox(height: 32),
                        const Text(
                          'Built for quiet moments. Designed for deeper understanding.',
                          style: TextStyle(color: muted, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (v) => setState(() => tab = v),
                backgroundColor: paper,
                indicatorColor: lime,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.wb_sunny_outlined),
                    label: 'Today',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.auto_stories_outlined),
                    label: 'Topics',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.history),
                    label: 'Review',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.explore_outlined),
                    label: 'Explore',
                  ),
                ],
              ),
      );
    },
  );
  Future<void> launch(
    List<Question> questions,
    String title, {
    bool resume = false,
  }) async {
    if (questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No questions match this selection yet.')),
      );
      return;
    }
    if (!resume && store.active != null) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Start a new session?'),
          content: const Text(
            'Your answered questions are saved. This replaces the unfinished session.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep session'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Start new'),
            ),
          ],
        ),
      );
      if (replace != true || !mounted) return;
    }
    final index = resume ? store.active!['index'] as int : 0;
    final good = resume ? store.active!['good'] as int : 0;
    if (!resume) store.start(questions, title);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizScreen(
          store: store,
          questions: questions,
          title: title,
          startIndex: index,
          previousGood: good,
        ),
      ),
    );
  }

  void resume() {
    final active = store.active!;
    final ids = (active['ids'] as List).cast<String>();
    launch(
      ids.map((id) => content.questions.firstWhere((q) => q.id == id)).toList(),
      active['title'],
      resume: true,
    );
  }

  Widget today() {
    final due = store.due(DateTime.now()).length;
    final nextTopic = content.topics.firstWhere(
      (t) =>
          content.forTopic(t.id).any((q) => !store.records.containsKey(q.id)),
      orElse: () => content.topics.first,
    );
    final hero = Container(
      padding: const EdgeInsets.all(26),
      decoration: BoxDecoration(
        color: ink,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow('Your pocket photonics lab', color: lime),
          const SizedBox(height: 16),
          const Text(
            'Small sessions.\nBig possibilities.',
            style: TextStyle(
              fontFamily: 'DMSerif',
              color: Colors.white,
              fontSize: 33,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A bridge from optics expertise to silicon photonics practice.',
            style: TextStyle(color: Color(0xFFBDD0CC), height: 1.6),
          ),
          const SizedBox(height: 18),
          const ChipArt(),
          const SizedBox(height: 20),
          const Text(
            'Session length · questions',
            style: TextStyle(fontSize: 12, color: Colors.white),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final n in [5, 10, 20])
                ChoiceChip(
                  label: Text('$n'),
                  selected: count == n,
                  onSelected: (_) => setState(() => count = n),
                  selectedColor: lime,
                  backgroundColor: const Color(0xFF2E4348),
                  labelStyle: TextStyle(color: count == n ? ink : Colors.white),
                  side: BorderSide.none,
                  showCheckmark: false,
                ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: ink,
              ),
              onPressed: () => launch(store.session(count), 'Daily mix'),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start a study session'),
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Due reviews first, then new questions · No typing',
            style: TextStyle(color: Color(0xFFBDD0CC), fontSize: 11),
          ),
        ],
      ),
    );
    final aside = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Surface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('Make a little progress'),
              const SizedBox(height: 16),
              Text(
                '${store.todayCount} / 10',
                style: const TextStyle(
                  fontFamily: 'DMSerif',
                  fontSize: 34,
                  color: ink,
                ),
              ),
              const Text('questions studied today'),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (store.todayCount / 10).clamp(0, 1),
                  minHeight: 7,
                  backgroundColor: line,
                  color: teal,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 24,
                runSpacing: 12,
                children: [
                  _stat('$due', 'due for review'),
                  _stat('${store.mastered}', 'retained'),
                  _stat('${store.records.length}/320', 'explored'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Surface(
          color: const Color(0xFFEDF1E4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Eyebrow('For your next chapter'),
              const SizedBox(height: 12),
              const Text(
                'From Santa Clara,\ntoward silicon photonics.',
                style: TextStyle(
                  fontFamily: 'DMSerif',
                  fontSize: 24,
                  color: ink,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                '12 local employers, focused courses, and a practical portfolio roadmap.',
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () => setState(() {
                  tab = 3;
                  exploreTab = 0;
                }),
                icon: const Icon(Icons.arrow_forward, size: 18),
                label: const Text('Explore the field'),
              ),
            ],
          ),
        ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'Silicon photonics, one idea at a time',
          'A little light. Every day.',
          'A pocket lab for your next chapter.',
        ),
        if (store.active != null) ...[
          Surface(
            color: const Color(0xFFE9F0E4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Continue ${store.active!['title']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: ink,
                  ),
                ),
                Text(
                  '${store.active!['index']} of ${(store.active!['ids'] as List).length} questions finished',
                ),
                TextButton.icon(
                  onPressed: resume,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume session'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
        LayoutBuilder(
          builder: (context, constraints) => constraints.maxWidth >= 760
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: hero),
                    const SizedBox(width: 24),
                    Expanded(flex: 2, child: aside),
                  ],
                )
              : Column(children: [hero, const SizedBox(height: 20), aside]),
        ),
        const SizedBox(height: 30),
        section('Follow your curiosity', '16 topics · 320 questions'),
        const SizedBox(height: 16),
        topicCard(nextTopic),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: () => setState(() => tab = 1),
          icon: const Icon(Icons.arrow_forward),
          label: const Text('Browse all topics'),
        ),
      ],
    );
  }

  Widget _stat(String value, String label) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        value,
        style: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 20,
          color: ink,
        ),
      ),
      Text(label, style: const TextStyle(fontSize: 11)),
    ],
  );
  Widget section(String title, String subtitle) => Wrap(
    alignment: WrapAlignment.spaceBetween,
    spacing: 16,
    runSpacing: 8,
    children: [
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      Text(subtitle, style: const TextStyle(color: muted, fontSize: 12)),
    ],
  );
  Widget topicCard(Topic topic) {
    final qs = content.forTopic(topic.id);
    final retained = qs
        .where((q) => store.records[q.id]?.mastered ?? false)
        .length;
    return Semantics(
      button: true,
      label: 'Study ${topic.title}',
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: line),
        ),
        child: InkWell(
          onTap: () => showTopic(topic),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEDF1E4),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(topicIcon(topic.icon), color: teal),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Eyebrow(topic.group),
                          const SizedBox(height: 5),
                          Text(
                            topic.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: ink,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward, size: 19, color: muted),
                  ],
                ),
                const SizedBox(height: 12),
                Text(topic.subtitle),
                const SizedBox(height: 16),
                ExcludeSemantics(
                  child: LinearProgressIndicator(
                    value: retained / qs.length,
                    color: teal,
                    backgroundColor: line,
                    minHeight: 3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${qs.length} questions · $retained retained',
                  style: const TextStyle(fontSize: 11, color: muted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget topics() {
    final matches = content.topics
        .where(
          (t) =>
              (group == 'All' || t.group == group) &&
              '${t.title} ${t.subtitle} ${t.objectives}'.toLowerCase().contains(
                query.toLowerCase(),
              ) &&
              content
                  .forTopic(t.id)
                  .any((q) => difficulty == null || q.level == difficulty),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'The study library',
          'Build your understanding.',
          'Start where you need a bridge. Go deeper where you already have a foundation.',
        ),
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            hintText: 'Search topics, devices or skills',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (v) => setState(() => query = v),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final g in [
              'All',
              ...content.topics.map((t) => t.group).toSet(),
            ])
              FilterChip(
                label: Text(g),
                selected: group == g,
                onSelected: (_) => setState(() => group = g),
              ),
          ],
        ),
        const SizedBox(height: 16),
        const Eyebrow('Question level'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final entry in [
              'All levels',
              'Foundation',
              'Applied',
              'Advanced',
            ].indexed)
              ChoiceChip(
                label: Text(entry.$2),
                selected: (difficulty ?? 0) == entry.$1,
                onSelected: (_) => setState(
                  () => difficulty = entry.$1 == 0 ? null : entry.$1,
                ),
              ),
          ],
        ),
        const SizedBox(height: 24),
        if (matches.isEmpty)
          const Surface(
            child: Text('No matching topics. Try another search or level.'),
          ),
        LayoutBuilder(
          builder: (context, c) {
            final columns = c.maxWidth >= 680 ? 2 : 1;
            final width = (c.maxWidth - (columns - 1) * 16) / columns;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                for (final topic in matches)
                  SizedBox(width: width, child: topicCard(topic)),
              ],
            );
          },
        ),
      ],
    );
  }

  void showTopic(Topic topic) {
    final available = content
        .forTopic(topic.id)
        .where((q) => difficulty == null || q.level == difficulty)
        .length;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (sheet) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(sheet).height * 0.78,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(topicIcon(topic.icon), size: 36, color: teal),
                const SizedBox(height: 18),
                Text(
                  topic.title,
                  style: Theme.of(sheet).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                Text(topic.subtitle),
                const SizedBox(height: 24),
                const Eyebrow('What you’ll practice'),
                const SizedBox(height: 10),
                Text(
                  topic.objectives,
                  style: const TextStyle(fontSize: 16, color: ink, height: 1.6),
                ),
                const SizedBox(height: 20),
                Text(
                  '$available questions at ${difficulty == null ? 'all levels' : ['Foundation', 'Applied', 'Advanced'][difficulty! - 1]}',
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: available == 0
                      ? null
                      : () {
                          Navigator.pop(sheet);
                          launch(
                            store.session(
                              20,
                              topic: topic.id,
                              level: difficulty,
                            ),
                            topic.title,
                          );
                        },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Study this topic'),
                ),
                const SizedBox(height: 24),
                ReadingLinks(content: content, ids: topic.reading),
                const SizedBox(height: 16),
                const Text(
                  'Original practice questions · Linked resources are related reading, not copied questions or provider endorsements.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget review() {
    final due = store.due(DateTime.now()).length;
    final weak = store.weak().length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PageHeading(
          'Bring it back to mind',
          'Make knowledge stick.',
          'Review what’s due, revisit difficult ideas, or return to something you saved.',
        ),
        _reviewCard(
          'Spaced review',
          '$due questions ready',
          Icons.history,
          'due',
          due,
          'Missed answers return after 10 minutes. Strong answers return after 1, 3, 7, 14, 30, then 60 days.',
        ),
        const SizedBox(height: 16),
        _reviewCard(
          'Needs another look',
          '$weak questions to strengthen',
          Icons.psychology_outlined,
          'weak',
          weak,
          'Questions whose latest answer was incorrect or whose recall was incomplete.',
        ),
        const SizedBox(height: 16),
        _reviewCard(
          'Your bookmarks',
          '${store.bookmarks.length} questions saved',
          Icons.bookmark_border,
          'bookmarks',
          store.bookmarks.length,
          'Save a question using the bookmark icon during a session.',
        ),
        const SizedBox(height: 24),
        const Surface(
          color: Color(0xFFEDF1E4),
          child: Text(
            'Think & reveal answers are self-assessed. “Almost” schedules tomorrow; “Again” returns in 10 minutes. Retained means three consecutive full recalls or correct answers.',
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: progress,
          icon: const Icon(Icons.insights_outlined),
          label: const Text('View progress & backups'),
        ),
      ],
    );
  }

  Widget _reviewCard(
    String title,
    String subtitle,
    IconData icon,
    String mode,
    int amount,
    String description,
  ) => Surface(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: teal, size: 30),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        Text(
          subtitle,
          style: const TextStyle(color: teal, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Text(description),
        const SizedBox(height: 16),
        FilledButton(
          onPressed: amount == 0
              ? null
              : () => launch(store.session(20, mode: mode), title),
          child: Text(
            amount == 0 ? 'Nothing here yet' : 'Study up to 20 questions',
          ),
        ),
      ],
    ),
  );
  Widget explore() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const PageHeading(
        'Your next chapter',
        'A field within reach.',
        'Local employers, useful learning resources, and a plan for turning expertise into evidence.',
      ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final entry in [
            'Employers',
            'Courses',
            'Reading',
            'My roadmap',
          ].indexed)
            ChoiceChip(
              label: Text(entry.$2),
              selected: exploreTab == entry.$1,
              onSelected: (_) => setState(() => exploreTab = entry.$1),
            ),
        ],
      ),
      const SizedBox(height: 24),
      switch (exploreTab) {
        0 => employers(),
        1 => resources(true),
        2 => resources(false),
        _ => roadmap(),
      },
    ],
  );
  Widget employers() {
    final companies = content.employers
        .where(
          (e) =>
              employerFilter == 'All nearby' ||
              employerFilter == 'Santa Clara' && e['city'] == 'Santa Clara' ||
              employerFilter == 'Startups' && e['kind'] == 'Startup',
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Eyebrow('Research checked · October 1, 2026'),
        const SizedBox(height: 10),
        const Text(
          'Closest cities first. Locations are company offices; individual jobs may be elsewhere. Suggested study topics reflect each company’s work and are not verified hiring requirements.',
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final f in ['All nearby', 'Santa Clara', 'Startups'])
              FilterChip(
                label: Text(f),
                selected: employerFilter == f,
                onSelected: (_) => setState(() => employerFilter = f),
              ),
          ],
        ),
        const SizedBox(height: 20),
        for (final e in companies)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow('${e['city']} · ${e['kind']}'),
                  const SizedBox(height: 10),
                  Text(
                    e['name'],
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 10),
                  Text(e['focus'], style: const TextStyle(color: ink)),
                  const SizedBox(height: 12),
                  Text(
                    'Where your optics background can connect',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: teal,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(e['fit']),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final id in (e['topics'] as List).cast<String>())
                        ActionChip(
                          label: Text(
                            content.topic(id).title,
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () => showTopic(content.topic(id)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(e['note'], style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      TextButton.icon(
                        onPressed: () => openLink(context, e['source']),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Company source'),
                      ),
                      if (e['careers'] != e['source'])
                        TextButton.icon(
                          onPressed: () => openLink(context, e['careers']),
                          icon: const Icon(Icons.work_outline, size: 16),
                          label: const Text('Careers'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget resources(bool courses) {
    final sources = content.sources
        .where((s) => courses ? s.kind == 'Course' : s.kind != 'Course')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          courses
              ? 'Start with UBC’s hands-on PIC course or AIM’s focused modules. Your existing optics background lets you focus on semiconductor devices, layout, RF interfaces and packaging.'
              : 'Use technical documentation for working methods, papers for device depth, and industry publications for market context.',
          style: const TextStyle(color: ink),
        ),
        const SizedBox(height: 20),
        for (final source in sources)
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(source.kind),
                  const SizedBox(height: 10),
                  Text(
                    source.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: ink,
                      fontSize: 17,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(source.description),
                  const SizedBox(height: 10),
                  TextButton.icon(
                    onPressed: () => openLink(context, source.url),
                    icon: const Icon(Icons.open_in_new, size: 16),
                    label: const Text('Open resource'),
                  ),
                ],
              ),
            ),
          ),
        Text(content.contentNote, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget roadmap() {
    const stages = [
      (
        'Weeks 1–2',
        'Translate optics to integrated devices',
        'Review confinement, dispersion and silicon material limits. Compare SOI and SiN. Model one cross section across wavelength and width.',
        ['platforms', 'waveguides', 'passives'],
      ),
      (
        'Weeks 3–4',
        'Design a measurable PIC',
        'Design an MZI or ring using a public or authorized PDK. Add references and length variants; verify connectivity, process rules and test access.',
        ['interferometers', 'resonators', 'layout', 'simulation'],
      ),
      (
        'Weeks 5–6',
        'Understand the electrical interface',
        'Study depletion modulation, germanium detectors, RC limits, traveling-wave electrodes and receiver noise. Build a simple device-to-link budget.',
        ['modulators', 'detectors', 'links'],
      ),
      (
        'Weeks 7–8',
        'Connect design to data',
        'Analyze public, course-provided, or your own authorized measurement data. Extract loss, group index and Q; document calibration and uncertainty.',
        ['characterization', 'fabrication'],
      ),
      (
        'Weeks 9–10',
        'Make it a manufacturable system',
        'Budget fiber coupling, package losses, thermal drift and assembly yield. Identify source and test-access requirements before proposing a CPO engine.',
        ['coupling', 'lasers', 'packaging'],
      ),
      (
        'Weeks 11–12',
        'Build targeted career evidence',
        'Choose PIC design, characterization, integration, or sensing roles. Present one complete reproducible study with assumptions, verified results and limits.',
        ['frontiers', 'links'],
      ),
    ];
    const projects = [
      (
        'model',
        'A mode-and-tolerance study',
        'Sweep one waveguide cross section. Record n_eff, n_g, confinement and supported modes; include numerical convergence and process sensitivity.',
      ),
      (
        'layout',
        'A testable PIC layout',
        'Create an MZI/ring test die with labels, calibration paths, optical access and verification results. Use public/authorized PDKs.',
      ),
      (
        'data',
        'A characterization notebook',
        'Extract propagation loss and resonator metrics from traceable data; show residuals, uncertainty and the optical reference planes.',
      ),
      (
        'link',
        'A device-to-link case study',
        'Connect laser power, coupling, modulator loss, detector response and electronics assumptions into a link and energy budget.',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Surface(
          color: Color(0xFFEDF1E4),
          child: Text(
            'A suggested 12-week bridge for an optics PhD, paced around work. Quiz sessions support recall; hands-on design and measurement build the portfolio. Prioritize PIC design or characterization first, then broaden to integration.',
          ),
        ),
        const SizedBox(height: 20),
        for (final s in stages)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Surface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Eyebrow(s.$1),
                  const SizedBox(height: 10),
                  Text(s.$2, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 10),
                  Text(s.$3),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      for (final id in s.$4)
                        ActionChip(
                          label: Text(
                            content.topic(id).title,
                            style: const TextStyle(fontSize: 11),
                          ),
                          onPressed: () => showTopic(content.topic(id)),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          'My portfolio checklist',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        for (final p in projects)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Surface(
              padding: const EdgeInsets.all(8),
              child: CheckboxListTile(
                value: store.projects.contains(p.$1),
                onChanged: (_) => store.toggleProject(p.$1),
                title: Text(
                  p.$2,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(p.$3),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
          ),
      ],
    );
  }

  void progress() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: paper,
      builder: (sheet) => ListenableBuilder(
        listenable: store,
        builder: (sheet, _) {
          final auto = content.questions
              .where((q) => q.kind != 'recall')
              .map((q) => store.records[q.id])
              .whereType<ReviewRecord>();
          final attempts = auto.fold(0, (n, r) => n + r.attempts),
              correct = auto.fold(0, (n, r) => n + r.correct);
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(sheet).height * 0.82,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your understanding, growing.',
                      style: Theme.of(sheet).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 28,
                      runSpacing: 16,
                      children: [
                        _stat(
                          '${store.records.length}/320',
                          'questions explored',
                        ),
                        _stat('${store.mastered}', 'retained'),
                        _stat('${store.answered}', 'total responses'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      attempts == 0
                          ? 'Checked-question accuracy appears after your first tap question.'
                          : 'Checked-question accuracy: ${(correct / attempts * 100).round()}% ($correct/$attempts).',
                    ),
                    const Text(
                      'Recall ratings are self-assessed and excluded from checked accuracy.',
                    ),
                    const SizedBox(height: 20),
                    for (final t in content.topics)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.title,
                              style: const TextStyle(color: ink, fontSize: 13),
                            ),
                            const SizedBox(height: 5),
                            LinearProgressIndicator(
                              value:
                                  content
                                      .forTopic(t.id)
                                      .where(
                                        (q) =>
                                            store.records[q.id]?.mastered ??
                                            false,
                                      )
                                      .length /
                                  20,
                              backgroundColor: line,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Eyebrow('Keep your progress'),
                    const SizedBox(height: 10),
                    const Text(
                      'Stored on this device/browser. Export a backup to move devices or preserve progress before clearing app data.',
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(
                                text: const JsonEncoder.withIndent('  ')
                                    .convert(jsonDecode(store.export())),
                              ),
                            );
                            if (sheet.mounted) {
                              ScaffoldMessenger.of(sheet).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Progress backup copied to clipboard.',
                                  ),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.copy),
                          label: const Text('Copy backup'),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => importBackup(sheet),
                          icon: const Icon(Icons.restore),
                          label: const Text('Restore backup'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () async {
                        final confirmed = await showDialog<bool>(
                          context: sheet,
                          builder: (dialog) => AlertDialog(
                            title: const Text('Reset all study progress?'),
                            content: const Text(
                              'This clears reviews, bookmarks, the session and portfolio checks. Copy a backup first to keep them.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(dialog, false),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(dialog, true),
                                child: const Text('Reset'),
                              ),
                            ],
                          ),
                        );
                        if (confirmed == true) await store.reset();
                      },
                      child: const Text(
                        'Reset progress',
                        style: TextStyle(color: Color(0xFF9B4638)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> importBackup(BuildContext sheet) async {
    final controller = TextEditingController();
    String? error;
    await showDialog<void>(
      context: sheet,
      builder: (dialog) => StatefulBuilder(
        builder: (dialog, update) => AlertDialog(
          title: const Text('Restore a progress backup'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Paste exported JSON. Restoring replaces current progress.',
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  maxLines: 6,
                  decoration: InputDecoration(
                    hintText: 'Paste backup',
                    errorText: error,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialog),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                try {
                  store.restore(controller.text);
                  await store.save();
                  if (dialog.mounted) Navigator.pop(dialog);
                } catch (_) {
                  update(
                    () => error = 'This backup is invalid or incompatible.',
                  );
                }
              },
              child: const Text('Restore'),
            ),
          ],
        ),
      ),
    );
    // The route may still be animating out; let its text field release the controller.
    await Future<void>.delayed(const Duration(milliseconds: 350));
    controller.dispose();
  }
}
