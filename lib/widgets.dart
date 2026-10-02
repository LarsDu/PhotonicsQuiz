import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'content.dart';
import 'style.dart';

Future<void> openLink(BuildContext context, String url) async {
  try {
    if (await launchUrl(Uri.parse(url), mode: LaunchMode.platformDefault)) {
      return;
    }
  } catch (_) {
    /* The visible fallback below also covers plugin errors. */
  }
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: SelectableText('Could not open this link: $url')),
    );
  }
}

class ReadingLinks extends StatelessWidget {
  final Curriculum content;
  final List<String> ids;
  const ReadingLinks({super.key, required this.content, required this.ids});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Eyebrow('Related reading'),
      const SizedBox(height: 8),
      for (final id in ids)
        TextButton.icon(
          onPressed: () => openLink(context, content.source(id).url),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(content.source(id).title),
          style: TextButton.styleFrom(
            alignment: Alignment.centerLeft,
            minimumSize: const Size(48, 48),
          ),
        ),
    ],
  );
}

class PageHeading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  const PageHeading(this.eyebrow, this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Eyebrow(eyebrow),
      const SizedBox(height: 12),
      Text(title, style: Theme.of(context).textTheme.displaySmall),
      const SizedBox(height: 12),
      Text(subtitle, style: Theme.of(context).textTheme.bodyLarge),
      const SizedBox(height: 28),
    ],
  );
}
