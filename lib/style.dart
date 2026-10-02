import 'dart:math';

import 'package:flutter/material.dart';

const ink = Color(0xFF182D35);
const muted = Color(0xFF637678);
const paper = Color(0xFFF7F7F0);
const teal = Color(0xFF166B65);
const lime = Color(0xFFD6EC92);
const line = Color(0xFFE1E7DC);
ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: paper,
  fontFamily: 'Manrope',
  fontFamilyFallback: const ['NotoSans'],
  colorScheme: ColorScheme.fromSeed(
    seedColor: teal,
    surface: paper,
    primary: teal,
  ),
  textTheme: const TextTheme(
    displaySmall: TextStyle(
      fontFamily: 'DMSerif',
      fontSize: 40,
      color: ink,
      height: 1.12,
    ),
    headlineMedium: TextStyle(fontFamily: 'DMSerif', fontSize: 30, color: ink),
    titleLarge: TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleMedium: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyLarge: TextStyle(fontSize: 16, height: 1.6, color: ink),
    bodyMedium: TextStyle(fontSize: 14, height: 1.55, color: muted),
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: paper,
    foregroundColor: ink,
    centerTitle: false,
    elevation: 0,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(48, 52),
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(48, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: line),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: line),
    ),
  ),
);
IconData topicIcon(String name) => switch (name) {
  'layers' => Icons.layers_outlined,
  'waves' => Icons.waves,
  'route' => Icons.route,
  'split' => Icons.call_split,
  'circle' => Icons.blur_circular,
  'connect' => Icons.cable,
  'bolt' => Icons.bolt,
  'sensor' => Icons.sensors,
  'sun' => Icons.wb_sunny_outlined,
  'memory' => Icons.memory,
  'code' => Icons.code,
  'grid' => Icons.grid_view,
  'science' => Icons.science_outlined,
  'network' => Icons.hub_outlined,
  'package' => Icons.view_in_ar_outlined,
  _ => Icons.explore_outlined,
};

class Surface extends StatelessWidget {
  final Widget child;
  final Color color;
  final EdgeInsets padding;
  const Surface({
    super.key,
    required this.child,
    this.color = Colors.white,
    this.padding = const EdgeInsets.all(20),
  });
  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: line),
    ),
    child: child,
  );
}

class Eyebrow extends StatelessWidget {
  final String text;
  final Color color;
  const Eyebrow(this.text, {super.key, this.color = teal});
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w800,
      letterSpacing: 1.8,
      color: color,
    ),
  );
}

class ChipArt extends StatelessWidget {
  const ChipArt({super.key});
  @override
  Widget build(BuildContext context) => SizedBox(
    height: 76,
    width: double.infinity,
    child: CustomPaint(painter: _ChipPainter()),
  );
}

class _ChipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final grid = Paint()
      ..color = Colors.white.withValues(alpha: 0.08)
      ..strokeWidth = 1;
    for (double x = 0; x < size.width; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), grid);
    }
    for (double y = 0; y < size.height; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), grid);
    }
    for (var i = 0; i < 3; i++) {
      final p = Path();
      for (double x = 0; x <= size.width; x += 2) {
        final y =
            size.height / 2 +
            sin(x / size.width * pi * 3 + i * 0.7) * (18 + i * 8);
        if (x == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      canvas.drawPath(
        p,
        Paint()
          ..color = [lime, const Color(0xFF71C9B7), const Color(0xFFF2E5B6)][i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8,
      );
    }
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height / 2),
      23,
      Paint()
        ..color = lime
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    canvas.drawCircle(
      Offset(size.width * 0.72, size.height / 2),
      28,
      Paint()
        ..color = lime.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
