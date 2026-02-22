import 'package:flutter/material.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

// ── Palette ───────────────────────────────────────────────────────────────
const _ink = Color(0xFF2C2C2C);
const _inkLight = Color(0xFF6B6B6B);
const _accent = Color(0xFF4A7C6F);
const _cardFill = Color(0xFFFAF7F2);

void main() => runApp(const MyJournalApp());

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

String _formatDate(DateTime date) =>
    '${_months[date.month - 1]} ${date.day}, ${date.year}';

class MyJournalApp extends StatelessWidget {
  const MyJournalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hand Drawn Toolkit Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF5F0E8),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(fontFamily: 'Georgia'),
        ),
      ),
      home: const JournalPage(),
    );
  }
}

class JournalPage extends StatelessWidget {
  const JournalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page title with hand-drawn underline ──────────────────
              const Text(
                'Hand Drawn Toolkit',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 2),
              SizedBox(
                width: 170,
                height: 8,
                child: CustomPaint(
                  painter: HandDrawnLinePainter(
                    color: _ink,
                    strokeWidth: 2.0,
                    irregularity: 2.0,
                    seed: 42,
                    buildPath: (size, h) => h.lineHorizontal(size),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ── Date ─────────────────────────────────────────────────
              Text(
                _formatDate(DateTime.now()),
                style: const TextStyle(
                  fontSize: 14,
                  color: _inkLight,
                  fontStyle: FontStyle.italic,
                ),
              ),

              const SizedBox(height: 8),
              const HandDrawnDivider(color: _inkLight, seed: 42),
              const SizedBox(height: 24),

              // ── Journal entry card ───────────────────────────────────
              const HandDrawnContainer(
                backgroundColor: _cardFill,
                strokeColor: _ink,
                strokeWidth: 1.8,
                irregularity: 3.0,
                seed: 6,
                padding: EdgeInsets.all(20),
                child: Text(
                  'Hand Drawn Toolkit is a lightweight Flutter package for '
                  'rendering sketchy, organic lines, borders, and containers. '
                  'It generates random perpendicular offsets along a path and '
                  'smooths them with a three-point moving average to produce '
                  'natural-looking wobble.\n\n'
                  'The package has zero external dependencies and relies '
                  'entirely on the Flutter SDK. All randomness is seed-based, '
                  'so identical parameters always produce identical strokes. '
                  'Paths are cached internally and only recomputed when the '
                  'widget size or generation parameters change.',
                  style: TextStyle(fontSize: 15, height: 1.6, color: _ink),
                ),
              ),

              const SizedBox(height: 28),

              // ── "Key Components" heading ──────────────────────────────
              const Text(
                'Key Components',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 14),

              // ── Component items with unique seeds ────────────────────
              const _GoalItem(
                seed: 9,
                text:
                    'HandDrawnContainer wraps any child widget with a '
                    'sketchy rectangular border and solid background fill.',
              ),
              const SizedBox(height: 10),
              const _GoalItem(
                seed: 20,
                text:
                    'HandDrawnDivider is a drop-in replacement for '
                    "Flutter's Divider, supporting both horizontal and "
                    'vertical orientations.',
              ),
              const SizedBox(height: 10),
              const _GoalItem(
                seed: 49,
                text:
                    'HandDrawnLinePainter provides full control via a '
                    'buildPath callback for custom jittered shapes.',
              ),

              const SizedBox(height: 28),

              // ── Indented divider ─────────────────────────────────────
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 40,
              ),
              const SizedBox(height: 28),

              // ── "Tip" callout ───────────────────────────────────────
              const HandDrawnContainer(
                backgroundColor: Color(0xFFF0F6F4),
                strokeColor: _accent,
                strokeWidth: 2.0,
                irregularity: 4.5,
                seed: 5,
                padding: EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tip',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Use a unique seed for each adjacent element to avoid '
                      'identical wobble patterns lining up. The irregularity '
                      'parameter controls roughness — values around 2.0 to '
                      '4.0 work well for borders, while 0.5 to 1.5 suit '
                      'dividers.',
                      style: TextStyle(fontSize: 14, height: 1.55, color: _ink),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Custom path section ──────────────────────────────────
              const Text(
                'Custom Paths',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'HandDrawnLinePainter also accepts a buildPath callback '
                'for arbitrary shapes. The diagonal line below is built '
                'by calling smoothedOffsets() directly and interpolating '
                'between two corners.',
                style: TextStyle(fontSize: 14, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: CustomPaint(
                  painter: HandDrawnLinePainter(
                    color: _ink,
                    strokeWidth: 3.0,
                    irregularity: 2.0,
                    seed: 100,
                    segments: 100,
                    buildPath: (size, h) {
                      final offsets = h.smoothedOffsets();
                      final dx = size.width / h.segments;
                      final path = Path()..moveTo(0, size.height);
                      for (int i = 1; i <= h.segments; i++) {
                        final t = i / h.segments;
                        final y = size.height * (1 - t) + offsets[i];
                        path.lineTo(dx * i, y);
                      }
                      return path;
                    },
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// A single component description wrapped in a hand-drawn container.
///
/// Each item uses a unique [seed] so adjacent borders have distinct
/// wobble patterns.
class _GoalItem extends StatelessWidget {
  const _GoalItem({required this.seed, required this.text});

  final int seed;
  final String text;

  @override
  Widget build(BuildContext context) {
    return HandDrawnContainer(
      backgroundColor: _cardFill,
      strokeColor: _ink,
      strokeWidth: 1.4,
      irregularity: 2.2,
      seed: seed,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(fontSize: 15, color: _ink)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.5, color: _ink),
            ),
          ),
        ],
      ),
    );
  }
}
