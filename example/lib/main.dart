import 'package:flutter/material.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

// ── Palette ───────────────────────────────────────────────────────────────
const _ink = Color(0xFF2C2C2C);
const _inkLight = Color(0xFF6B6B6B);
const _accent = Color(0xFF4A7C6F);
const _cardFill = Color(0xFFFAF7F2);

// ── Notebook grid ─────────────────────────────────────────────────────────
const _notebookFontSize = 15.0;
const _notebookLineHeight = 28.0;

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

class JournalPage extends StatefulWidget {
  const JournalPage({super.key});

  @override
  State<JournalPage> createState() => _JournalPageState();
}

class _JournalPageState extends State<JournalPage> {
  // ── Status square demo state ───────────────────────────────────────────
  final List<_TaskItem> _tasks = [
    const _TaskItem('Read a chapter of a good book'),
    const _TaskItem('Sketch something from observation'),
    const _TaskItem('Take a 20-minute walk', status: _TaskStatus.completed),
    const _TaskItem('Write morning pages', status: _TaskStatus.skipped),
  ];

  void _cycleStatus(int index) {
    setState(() {
      _tasks[index] = _tasks[index].cycled();
    });
  }

  // ── Interactive chart state ────────────────────────────────────────────
  String? _barHitLabel;
  String? _lineHitLabel;
  String? _scatterHitLabel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Page title with hand-drawn underline ────────────────
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

              // ── Date ───────────────────────────────────────────────
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

              // ── Journal entry card ─────────────────────────────────
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

              // ── "Key Components" heading ──────────────────────────
              const Text(
                'Key Components',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 14),

              // ── Component items with unique seeds ──────────────────
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

              // ── Indented divider ───────────────────────────────────
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 40,
              ),
              const SizedBox(height: 28),

              // ── Status square demo ─────────────────────────────────
              const Text(
                'Status Square',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'HandDrawnStatusSquare is a tappable indicator with a '
                'hand-drawn border. Tap each square below to cycle '
                'through empty, checked, and dashed states.',
                style: TextStyle(fontSize: 14, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 16),

              HandDrawnContainer(
                backgroundColor: _cardFill,
                strokeColor: _ink,
                strokeWidth: 1.4,
                irregularity: 2.5,
                seed: 77,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HandDrawnNotebook(
                  lineHeight: _notebookLineHeight,
                  lineColor: const Color(0xFFB0AAA0),
                  irregularity: 2.0,
                  uniformLines: false,
                  seed: 50,
                  child: Column(
                    children: [
                      for (var i = 0; i < _tasks.length; i++)
                        _TaskRow(
                          task: _tasks[i],
                          seed: i * 13 + 5,
                          onTap: () => _cycleStatus(i),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 55,
              ),
              const SizedBox(height: 28),

              // ── Text field demo ────────────────────────────────────
              const Text(
                'Text Field',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'HandDrawnTextField pairs a standard TextField with a '
                'hand-drawn divider underline.',
                style: TextStyle(fontSize: 14, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 16),

              const HandDrawnTextField(
                hintText: 'Title your entry…',
                backgroundColor: _cardFill,
                textColor: _ink,
                hintColor: _inkLight,
                dividerColor: Color(0xFFD8D3CB),
                fontSize: 16,
                seed: 33,
              ),
              const SizedBox(height: 12),
              const HandDrawnTextField(
                hintText: 'Write your thoughts…',
                maxLines: 4,
                backgroundColor: _cardFill,
                textColor: _ink,
                hintColor: _inkLight,
                dividerColor: Color(0xFFD8D3CB),
                fontSize: 14,
                seed: 34,
              ),

              const SizedBox(height: 28),
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 65,
              ),
              const SizedBox(height: 28),

              // ── Notebook demo ──────────────────────────────────────
              const Text(
                'Notebook',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'HandDrawnNotebook draws ruled lines behind content. '
                'NotebookRow snaps children to the line grid.',
                style: TextStyle(fontSize: 14, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 16),

              const Text(
                'Uniform lines',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _inkLight,
                ),
              ),
              const SizedBox(height: 8),
              HandDrawnContainer(
                backgroundColor: _cardFill,
                strokeColor: _ink,
                strokeWidth: 1.4,
                irregularity: 2.5,
                seed: 88,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: HandDrawnNotebook(
                  lineHeight: _notebookLineHeight,
                  lineColor: const Color(0xFFB0AAA0),
                  irregularity: 2.5,
                  seed: 10,
                  child: Column(
                    children: [
                      for (final text in [
                        'First line on the grid',
                        'Second line sits neatly',
                        'Third line, same wobble',
                      ])
                        NotebookRow(
                          lineHeight: _notebookLineHeight,
                          child: Text(
                            text,
                            style: const TextStyle(
                              fontSize: _notebookFontSize,
                              height: _notebookLineHeight / _notebookFontSize,
                              color: _ink,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 70,
              ),
              const SizedBox(height: 28),

              // ════════════════════════════════════════════════════════
              // CHARTS
              // ════════════════════════════════════════════════════════
              const Text(
                'Charts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bar, line, and scatter charts with wobbly axes, grid '
                'lines, auto-generated legends, and smart label thinning.',
                style: TextStyle(fontSize: 14, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 20),

              // ── Bar chart ──────────────────────────────────────────
              _sectionHeading('Stacked Bar Chart'),
              const SizedBox(height: 12),
              HandDrawnBarChart(data: _sampleBarData(), height: 260, seed: 10),

              const SizedBox(height: 28),

              // ── Line chart ─────────────────────────────────────────
              _sectionHeading('Multi-Series Line Chart'),
              const SizedBox(height: 12),
              HandDrawnLineChart(
                data: _sampleLineData(),
                height: 260,
                seed: 20,
              ),

              const SizedBox(height: 28),

              // ── Scatter plot ───────────────────────────────────────
              _sectionHeading('Scatter Plot'),
              const SizedBox(height: 12),
              HandDrawnScatterPlot(
                data: _sampleScatterData(),
                height: 260,
                seed: 30,
              ),

              const SizedBox(height: 28),
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 80,
              ),
              const SizedBox(height: 28),

              // ════════════════════════════════════════════════════════
              // TABLE
              // ════════════════════════════════════════════════════════
              const Text(
                'Table',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'HandDrawnTable renders column-aligned data inside a '
                'hand-drawn container with divider separators.',
                style: TextStyle(fontSize: 14, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 16),

              const HandDrawnTable(
                title: 'Reading Log',
                columns: [
                  HandDrawnTableColumn(header: 'TITLE', flex: 3),
                  HandDrawnTableColumn(
                    header: 'PAGES',
                    width: 100,
                    alignment: Alignment.centerRight,
                  ),
                  HandDrawnTableColumn(
                    header: 'RATING',
                    width: 100,
                    alignment: Alignment.center,
                  ),
                ],
                rows: [
                  HandDrawnTableRow(
                    cells: ['Dune', '412', '★★★★★'],
                    highlight: true,
                  ),
                  HandDrawnTableRow(cells: ['Neuromancer', '271', '★★★★']),
                  HandDrawnTableRow(cells: ['Foundation', '244', '★★★★']),
                  HandDrawnTableRow(cells: ['Snow Crash', '480', '★★★']),
                ],
                rowDividers: TableDividerStyle(
                  seed: 60,
                  irregularity: 2,
                  uniform: false,
                ),
                columnDividers: TableDividerStyle(seed: 70, irregularity: 2),
              ),

              const SizedBox(height: 20),

              _sectionHeading('Resizable Columns'),
              const SizedBox(height: 4),
              const Text(
                'Drag the column edges to resize. Built entirely with '
                'the public API — explicit widths, column dividers, '
                'and consumer-owned gesture handling.',
                style: TextStyle(fontSize: 13, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 12),
              const _ResizableTableDemo(),

              const SizedBox(height: 28),
              const HandDrawnDivider(
                color: _inkLight,
                indent: 32,
                endIndent: 32,
                seed: 85,
              ),
              const SizedBox(height: 28),

              // ════════════════════════════════════════════════════════
              // INTERACTIVE CHARTS
              // ════════════════════════════════════════════════════════
              const Text(
                'Interactive Charts',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'The package provides computeLayout() and hitTest() so '
                'consumers can build their own tap, hover, and drag '
                'behaviors. Tap the charts below to see hit-test results.',
                style: TextStyle(fontSize: 14, height: 1.55, color: _inkLight),
              ),
              const SizedBox(height: 20),

              // ── Interactive bar chart ──────────────────────────────
              _sectionHeading('Tap a Bar Segment'),
              const SizedBox(height: 4),
              _hitLabel(_barHitLabel),
              const SizedBox(height: 8),
              _InteractiveBarChart(
                data: _sampleBarData(),
                onHit: (label) => setState(() => _barHitLabel = label),
              ),

              const SizedBox(height: 28),

              // ── Interactive line chart ─────────────────────────────
              _sectionHeading('Tap the Line Chart'),
              const SizedBox(height: 4),
              _hitLabel(_lineHitLabel),
              const SizedBox(height: 8),
              _InteractiveLineChart(
                data: _sampleLineData(),
                onHit: (label) => setState(() => _lineHitLabel = label),
              ),

              const SizedBox(height: 28),

              // ── Interactive scatter plot ───────────────────────────
              _sectionHeading('Tap a Scatter Point'),
              const SizedBox(height: 4),
              _hitLabel(_scatterHitLabel),
              const SizedBox(height: 8),
              _InteractiveScatterPlot(
                data: _sampleScatterData(),
                onHit: (label) => setState(() => _scatterHitLabel = label),
              ),

              const SizedBox(height: 28),

              // ── "Tip" callout ──────────────────────────────────────
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
                      'dividers and chart grid lines.',
                      style: TextStyle(fontSize: 14, height: 1.55, color: _ink),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Custom path section ────────────────────────────────
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
                'for arbitrary shapes.',
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

// ══════════════════════════════════════════════════════════════════════════
// SAMPLE DATA
// ══════════════════════════════════════════════════════════════════════════

BarChartData _sampleBarData() {
  return const BarChartData(
    title: 'Weekly Activity',
    yAxisLabel: 'Minutes',
    bars: [
      BarGroup(
        label: 'Mon',
        segments: [
          BarSegment(
            category: 'Exercise',
            value: 30,
            color: Color(0xFF6BAF7A),
            fillColor: Color(0xFFA8D5B0),
            fillAlpha: 0.5,
          ),
          BarSegment(category: 'Reading', value: 25, color: Color(0xFF6B9BD2)),
          BarSegment(
            category: 'Creative',
            value: 15,
            color: Color(0xFFE8943A),
            fillAlpha: 0.0,
          ),
        ],
      ),
      BarGroup(
        label: 'Tue',
        segments: [
          BarSegment(
            category: 'Exercise',
            value: 50,
            color: Color(0xFF6BAF7A),
            fillColor: Color(0xFFA8D5B0),
            fillAlpha: 0.5,
          ),
          BarSegment(category: 'Reading', value: 20, color: Color(0xFF6B9BD2)),
          BarSegment(
            category: 'Creative',
            value: 25,
            color: Color(0xFFE8943A),
            fillAlpha: 0.0,
          ),
        ],
      ),
      BarGroup(
        label: 'Wed',
        segments: [
          BarSegment(
            category: 'Exercise',
            value: 25,
            color: Color(0xFF6BAF7A),
            fillColor: Color(0xFFA8D5B0),
            fillAlpha: 0.5,
          ),
          BarSegment(category: 'Reading', value: 40, color: Color(0xFF6B9BD2)),
          BarSegment(
            category: 'Creative',
            value: 20,
            color: Color(0xFFE8943A),
            fillAlpha: 0.0,
          ),
        ],
      ),
      BarGroup(
        label: 'Thu',
        segments: [
          BarSegment(
            category: 'Exercise',
            value: 40,
            color: Color(0xFF6BAF7A),
            fillColor: Color(0xFFA8D5B0),
            fillAlpha: 0.5,
          ),
          BarSegment(category: 'Reading', value: 15, color: Color(0xFF6B9BD2)),
          BarSegment(
            category: 'Creative',
            value: 30,
            color: Color(0xFFE8943A),
            fillAlpha: 0.0,
          ),
        ],
      ),
      BarGroup(
        label: 'Fri',
        segments: [
          BarSegment(
            category: 'Exercise',
            value: 45,
            color: Color(0xFF6BAF7A),
            fillColor: Color(0xFFA8D5B0),
            fillAlpha: 0.5,
          ),
          BarSegment(category: 'Reading', value: 30, color: Color(0xFF6B9BD2)),
          BarSegment(
            category: 'Creative',
            value: 10,
            color: Color(0xFFE8943A),
            fillAlpha: 0.0,
          ),
        ],
      ),
    ],
    legend: [
      LegendEntry(label: 'Exercise', color: Color(0xFF6BAF7A)),
      LegendEntry(label: 'Reading', color: Color(0xFF6B9BD2)),
      LegendEntry(label: 'Creative', color: Color(0xFFE8943A)),
    ],
  );
}

LineChartData _sampleLineData() {
  return const LineChartData(
    title: 'Mood Tracker',
    xAxisLabel: 'Day',
    yAxisLabel: 'Score',
    minX: 0,
    maxX: 6,
    minY: 0,
    maxY: 10,
    xLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    series: [
      LineSeriesData(
        name: 'Energy',
        color: Color(0xFFE8943A),
        points: [
          LinePoint(x: 0, y: 6),
          LinePoint(x: 1, y: 7),
          LinePoint(x: 2, y: 5),
          LinePoint(x: 3, y: 8),
          LinePoint(x: 4, y: 7),
          LinePoint(x: 5, y: 9),
          LinePoint(x: 6, y: 8),
        ],
      ),
      LineSeriesData(
        name: 'Focus',
        color: Color(0xFF7B68C4),
        points: [
          LinePoint(x: 0, y: 5),
          LinePoint(x: 1, y: 6),
          LinePoint(x: 2, y: 4),
          LinePoint(x: 3, y: 7),
          LinePoint(x: 4, y: 8),
          LinePoint(x: 5, y: 6),
          LinePoint(x: 6, y: 7),
        ],
      ),
    ],
  );
}

ScatterPlotData _sampleScatterData() {
  return const ScatterPlotData(
    title: 'Sleep vs Productivity',
    xAxisLabel: 'Hours of Sleep',
    yAxisLabel: 'Productivity Score',
    minX: 4,
    maxX: 10,
    minY: 0,
    maxY: 100,
    points: [
      ScatterPoint(x: 5.0, y: 35),
      ScatterPoint(x: 5.5, y: 42),
      ScatterPoint(x: 6.0, y: 55),
      ScatterPoint(x: 6.5, y: 50),
      ScatterPoint(x: 7.0, y: 68),
      ScatterPoint(x: 7.0, y: 72),
      ScatterPoint(x: 7.5, y: 78, size: 7),
      ScatterPoint(x: 8.0, y: 82, size: 7),
      ScatterPoint(x: 8.0, y: 75),
      ScatterPoint(x: 8.5, y: 88, size: 8),
      ScatterPoint(x: 9.0, y: 85),
      ScatterPoint(x: 9.5, y: 80),
    ],
  );
}

// ══════════════════════════════════════════════════════════════════════════
// INTERACTIVE CHART WIDGETS
// ══════════════════════════════════════════════════════════════════════════

/// Interactive bar chart using LayoutBuilder + GestureDetector + computeLayout.
class _InteractiveBarChart extends StatelessWidget {
  const _InteractiveBarChart({required this.data, required this.onHit});

  final BarChartData data;
  final ValueChanged<String?> onHit;

  @override
  Widget build(BuildContext context) {
    final painter = HandDrawnBarChartPainter(data: data, seed: 10);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 240);
        final layout = painter.computeLayout(size);

        return GestureDetector(
          onTapDown: (details) {
            final hit = layout.hitTest(details.localPosition);
            if (hit != null) {
              final seg = hit.segment;
              onHit(
                '${seg.barLabel} — ${seg.category}: '
                '${seg.value.toInt()} min',
              );
            } else {
              onHit(null);
            }
          },
          child: CustomPaint(size: size, painter: painter),
        );
      },
    );
  }
}

/// Interactive line chart demonstrating sealed hit-test results.
class _InteractiveLineChart extends StatelessWidget {
  const _InteractiveLineChart({required this.data, required this.onHit});

  final LineChartData data;
  final ValueChanged<String?> onHit;

  @override
  Widget build(BuildContext context) {
    final painter = HandDrawnLineChartPainter(data: data, seed: 20);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 240);
        final layout = painter.computeLayout(size);

        return GestureDetector(
          onTapDown: (details) {
            final hit = layout.hitTest(details.localPosition);
            if (hit != null) {
              final label = switch (hit) {
                LinePointHit(
                  :final seriesName,
                  :final pointIndex,
                  :final point,
                ) =>
                  '$seriesName point $pointIndex: ${point.y.toInt()}',
                LineSegmentHit(
                  :final seriesName,
                  :final interpolatedX,
                  :final interpolatedY,
                ) =>
                  '$seriesName segment at '
                      'x=${interpolatedX.toStringAsFixed(1)}, '
                      'y=${interpolatedY.toStringAsFixed(1)}',
              };
              onHit(label);
            } else {
              onHit(null);
            }
          },
          child: CustomPaint(size: size, painter: painter),
        );
      },
    );
  }
}

/// Interactive scatter plot with nearest-point hit-testing.
class _InteractiveScatterPlot extends StatelessWidget {
  const _InteractiveScatterPlot({required this.data, required this.onHit});

  final ScatterPlotData data;
  final ValueChanged<String?> onHit;

  @override
  Widget build(BuildContext context) {
    final painter = HandDrawnScatterPlotPainter(data: data, seed: 30);

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = Size(constraints.maxWidth, 240);
        final layout = painter.computeLayout(size);

        return GestureDetector(
          onTapDown: (details) {
            final hit = layout.hitTest(details.localPosition);
            if (hit != null) {
              final p = hit.point.rawPoint;
              onHit(
                'Point ${hit.point.pointIndex}: '
                '(${p.x.toStringAsFixed(1)} hrs, '
                '${p.y.toInt()} score)',
              );
            } else {
              onHit(null);
            }
          },
          child: CustomPaint(size: size, painter: painter),
        );
      },
    );
  }
}

/// Resizable table demo — consumer-owned column drag using explicit widths,
/// column dividers, and GestureDetector strips at column boundaries.
class _ResizableTableDemo extends StatefulWidget {
  const _ResizableTableDemo();

  @override
  State<_ResizableTableDemo> createState() => _ResizableTableDemoState();
}

class _ResizableTableDemoState extends State<_ResizableTableDemo> {
  static const _minColWidth = 40.0;
  static const _tablePadding = 12.0;
  static const _handleWidth = 16.0;
  // Proportional ratios: 3:1:1 for Title, Pages, Rating.
  static const _initialRatios = [3.0, 1.0, 1.0];

  List<double>? _widths;

  final _rows = const [
    HandDrawnTableRow(cells: ['Dune', '412', '★★★★★'], highlight: true),
    HandDrawnTableRow(cells: ['Neuromancer', '271', '★★★★']),
    HandDrawnTableRow(cells: ['Foundation', '244', '★★★★']),
  ];

  List<double> _initWidths(double contentWidth) {
    final totalRatio = _initialRatios.fold(0.0, (s, r) => s + r);
    return [for (final r in _initialRatios) contentWidth * r / totalRatio];
  }

  void _onDrag(int boundary, double delta) {
    setState(() {
      final maxGrow = _widths![boundary + 1] - _minColWidth;
      final maxShrink = _widths![boundary] - _minColWidth;
      final clamped = delta.clamp(-maxShrink, maxGrow);
      _widths![boundary] += clamped;
      _widths![boundary + 1] -= clamped;
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final contentWidth = constraints.maxWidth - _tablePadding * 2;
        _widths ??= _initWidths(contentWidth);

        return Stack(
          children: [
            HandDrawnTable(
              columns: [
                HandDrawnTableColumn(header: 'TITLE', width: _widths![0]),
                HandDrawnTableColumn(
                  header: 'PAGES',
                  width: _widths![1],
                  alignment: Alignment.centerRight,
                ),
                HandDrawnTableColumn(
                  header: 'RATING',
                  width: _widths![2],
                  alignment: Alignment.center,
                ),
              ],
              rows: _rows,
              rowDividers: const TableDividerStyle(irregularity: 3),
              columnDividers: const TableDividerStyle(irregularity: 3),
            ),
            for (int i = 0; i < _widths!.length - 1; i++)
              Positioned(
                left:
                    _tablePadding +
                    _widths!.take(i + 1).fold(0.0, (sum, w) => sum + w) -
                    _handleWidth / 2,
                top: 0,
                bottom: 0,
                width: _handleWidth,
                child: MouseRegion(
                  cursor: SystemMouseCursors.resizeColumn,
                  child: GestureDetector(
                    onHorizontalDragUpdate: (d) => _onDrag(i, d.delta.dx),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// UI HELPERS
// ══════════════════════════════════════════════════════════════════════════

Widget _sectionHeading(String text) {
  return Text(
    text,
    style: const TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: _ink,
    ),
  );
}

Widget _hitLabel(String? label) {
  return Text(
    label ?? 'Tap a data element…',
    style: TextStyle(
      fontSize: 13,
      color: label != null ? _accent : _inkLight,
      fontStyle: label != null ? FontStyle.normal : FontStyle.italic,
    ),
  );
}

// ══════════════════════════════════════════════════════════════════════════
// STATUS SQUARE DEMO HELPERS
// ══════════════════════════════════════════════════════════════════════════

enum _TaskStatus { pending, completed, skipped }

class _TaskItem {
  const _TaskItem(this.label, {this.status = _TaskStatus.pending});

  final String label;
  final _TaskStatus status;

  _TaskItem cycled() {
    final next = switch (status) {
      _TaskStatus.pending => _TaskStatus.completed,
      _TaskStatus.completed => _TaskStatus.skipped,
      _TaskStatus.skipped => _TaskStatus.pending,
    };
    return _TaskItem(label, status: next);
  }

  Color get color => switch (status) {
    _TaskStatus.pending => _ink,
    _TaskStatus.completed => _accent,
    _TaskStatus.skipped => _inkLight,
  };

  bool get isFilled => status != _TaskStatus.pending;

  StatusIndicator get indicator => switch (status) {
    _TaskStatus.pending => StatusIndicator.none,
    _TaskStatus.completed => StatusIndicator.check,
    _TaskStatus.skipped => StatusIndicator.dash,
  };
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task, required this.seed, required this.onTap});

  final _TaskItem task;
  final int seed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return NotebookRow(
      lineHeight: _notebookLineHeight,
      child: Row(
        children: [
          HandDrawnStatusSquare(
            color: task.color,
            isFilled: task.isFilled,
            indicator: task.indicator,
            size: 18,
            seed: seed,
            onTap: onTap,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.label,
              style: TextStyle(
                fontSize: _notebookFontSize,
                height: _notebookLineHeight / _notebookFontSize,
                color: _ink,
                decoration: task.isFilled ? TextDecoration.lineThrough : null,
                decorationColor: _inkLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single component description wrapped in a hand-drawn container.
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
