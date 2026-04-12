import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

// ── Test data factories ────────────────────────────────────────────────────

BarChartData _barData({
  int barCount = 3,
  String? title,
  String? yAxisLabel,
  double? minY,
  double? maxY,
}) {
  return BarChartData(
    title: title,
    yAxisLabel: yAxisLabel,
    minY: minY,
    maxY: maxY,
    bars: List.generate(
      barCount,
      (i) => BarGroup(
        label: 'Bar $i',
        segments: [
          BarSegment(
            category: 'cat',
            value: (i + 1) * 10.0,
            color: const Color(0xFF6B9BD2),
          ),
        ],
      ),
    ),
    legend: [const LegendEntry(label: 'Category', color: Color(0xFF6B9BD2))],
  );
}

LineChartData _lineData({
  int pointCount = 5,
  int seriesCount = 1,
  List<String> xLabels = const [],
  String? title,
  String? yAxisLabel,
}) {
  return LineChartData(
    title: title,
    yAxisLabel: yAxisLabel,
    xLabels: xLabels,
    minX: 0,
    maxX: (pointCount - 1).toDouble(),
    minY: 0,
    maxY: 100,
    series: List.generate(
      seriesCount,
      (s) => LineSeriesData(
        name: 'Series $s',
        color: Color(0xFF000000 + s * 0x110000),
        points: List.generate(
          pointCount,
          (i) => LinePoint(x: i.toDouble(), y: (i + 1) * 10.0),
        ),
      ),
    ),
  );
}

ScatterPlotData _scatterData({int pointCount = 5, String? title}) {
  return ScatterPlotData(
    title: title,
    xAxisLabel: 'Weight',
    yAxisLabel: 'Height',
    minX: 0,
    maxX: 100,
    minY: 0,
    maxY: 200,
    points: List.generate(
      pointCount,
      (i) => ScatterPoint(x: i * 20.0, y: i * 40.0),
    ),
  );
}

// ── Helpers ────────────────────────────────────────────────────────────────

/// Wraps a widget in MaterialApp + Scaffold for testing.
Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

/// Finds [CustomPaint] widgets that use a chart painter.
Finder _findChartPaint<T extends CustomPainter>() {
  return find.byWidgetPredicate(
    (widget) => widget is CustomPaint && widget.painter is T,
  );
}

void main() {
  // ════════════════════════════════════════════════════════════════════════
  // BAR CHART
  // ════════════════════════════════════════════════════════════════════════

  group('HandDrawnBarChart', () {
    testWidgets('shows loading indicator when data is null', (tester) async {
      await tester.pumpWidget(_wrap(const HandDrawnBarChart(data: null)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when data is empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnBarChart(
            data: BarChartData(bars: [], legend: []),
          ),
        ),
      );
      expect(find.text('No data for this range'), findsOneWidget);
    });

    testWidgets('renders CustomPaint with correct painter for valid data', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(HandDrawnBarChart(data: _barData())));
      expect(_findChartPaint<HandDrawnBarChartPainter>(), findsOneWidget);
    });

    testWidgets('applies height parameter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(), height: 300)),
      );
      final box = tester.getSize(find.byType(HandDrawnBarChart));
      expect(box.height, 300.0);
    });

    testWidgets('passes seed to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(), seed: 99)),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnBarChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnBarChartPainter;
      expect(painter.seed, 99);
    });

    testWidgets('accepts custom minY and maxY', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(minY: -10, maxY: 50))),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnBarChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnBarChartPainter;
      expect(painter.yMin, -10);
      expect(painter.yMax, 50);
    });

    testWidgets('dense bar chart renders without error', (tester) async {
      // 50 bars in default width — slotWidth will be well below barMinWidth.
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(barCount: 50))),
      );
      expect(_findChartPaint<HandDrawnBarChartPainter>(), findsOneWidget);
    });

    testWidgets('dense bars in constrained width render without error', (
      tester,
    ) async {
      // 50 bars in 100px → slotWidth = 2, well below barMinWidth (4).
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 100,
            child: HandDrawnBarChart(data: _barData(barCount: 50)),
          ),
        ),
      );
      expect(_findChartPaint<HandDrawnBarChartPainter>(), findsOneWidget);
    });

    testWidgets('normal density bar chart renders correctly', (tester) async {
      // 5 bars — a typical use case that should be unaffected by the
      // dense-bar fix.
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(barCount: 5))),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnBarChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnBarChartPainter;
      expect(painter.data.bars.length, 5);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // LINE CHART
  // ════════════════════════════════════════════════════════════════════════

  group('HandDrawnLineChart', () {
    testWidgets('shows loading indicator when data is null', (tester) async {
      await tester.pumpWidget(_wrap(const HandDrawnLineChart(data: null)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when all series are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnLineChart(
            data: LineChartData(
              series: [
                LineSeriesData(name: 'A', points: [], color: Color(0xFF000000)),
              ],
              minX: 0,
              maxX: 10,
              minY: 0,
              maxY: 100,
            ),
          ),
        ),
      );
      expect(find.text('No data for this range'), findsOneWidget);
    });

    testWidgets('renders CustomPaint with correct painter for valid data', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(HandDrawnLineChart(data: _lineData())));
      expect(_findChartPaint<HandDrawnLineChartPainter>(), findsOneWidget);
    });

    testWidgets('passes seed to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(), seed: 77)),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnLineChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnLineChartPainter;
      expect(painter.seed, 77);
    });

    testWidgets('auto-generates legend for multi-series data', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(seriesCount: 3))),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnLineChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnLineChartPainter;
      expect(painter.legend, hasLength(3));
      expect(painter.legend[0].label, 'Series 0');
      expect(painter.legend[1].label, 'Series 1');
      expect(painter.legend[2].label, 'Series 2');
    });

    testWidgets('suppresses legend for single-series data', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(seriesCount: 1))),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnLineChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnLineChartPainter;
      expect(painter.legend, isEmpty);
    });

    testWidgets('passes xLabels for categorical mode', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HandDrawnLineChart(
            data: _lineData(xLabels: ['A', 'B', 'C', 'D', 'E']),
          ),
        ),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnLineChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnLineChartPainter;
      expect(painter.xLabels, hasLength(5));
      // xMin/xMax are always passed for point positioning,
      // even in categorical mode.
      expect(painter.xMin, isNotNull);
      expect(painter.xMax, isNotNull);
    });

    testWidgets('uses numeric X when xLabels is empty', (tester) async {
      await tester.pumpWidget(_wrap(HandDrawnLineChart(data: _lineData())));
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnLineChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnLineChartPainter;
      expect(painter.xLabels, isEmpty);
      expect(painter.xMin, isNotNull);
      expect(painter.xMax, isNotNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // SCATTER PLOT
  // ════════════════════════════════════════════════════════════════════════

  group('HandDrawnScatterPlot', () {
    testWidgets('shows loading indicator when data is null', (tester) async {
      await tester.pumpWidget(_wrap(const HandDrawnScatterPlot(data: null)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when points are empty', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnScatterPlot(
            data: ScatterPlotData(
              points: [],
              xAxisLabel: 'X',
              yAxisLabel: 'Y',
              minX: 0,
              maxX: 10,
              minY: 0,
              maxY: 10,
            ),
          ),
        ),
      );
      expect(find.text('No data for this range'), findsOneWidget);
    });

    testWidgets('renders CustomPaint with correct painter for valid data', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HandDrawnScatterPlot(data: _scatterData())),
      );
      expect(_findChartPaint<HandDrawnScatterPlotPainter>(), findsOneWidget);
    });

    testWidgets('passes seed and dotColor to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HandDrawnScatterPlot(
            data: _scatterData(),
            seed: 55,
            dotColor: Colors.red,
          ),
        ),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnScatterPlotPainter>(),
      );
      final painter = customPaint.painter as HandDrawnScatterPlotPainter;
      expect(painter.seed, 55);
      expect(painter.dotColor, Colors.red);
    });

    testWidgets('passes xAxisLabel to base painter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnScatterPlot(data: _scatterData())),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnScatterPlotPainter>(),
      );
      final painter = customPaint.painter as HandDrawnScatterPlotPainter;
      expect(painter.xAxisLabel, 'Weight');
      expect(painter.xMin, 0);
      expect(painter.xMax, 100);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART WIDGET — color/style configurability
  // ════════════════════════════════════════════════════════════════════════

  group('Chart widget color/style configurability', () {
    // ── Bar chart ──────────────────────────────────────────────────────

    testWidgets('bar chart passes axisColor to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(), axisColor: Colors.red)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnBarChartPainter>(),
                  )
                  .painter
              as HandDrawnBarChartPainter;
      expect(painter.axisColor, Colors.red);
    });

    testWidgets('bar chart passes gridColor to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(), gridColor: Colors.blue)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnBarChartPainter>(),
                  )
                  .painter
              as HandDrawnBarChartPainter;
      expect(painter.gridColor, Colors.blue);
    });

    testWidgets('bar chart passes custom labelStyle to painter', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(), labelStyle: style)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnBarChartPainter>(),
                  )
                  .painter
              as HandDrawnBarChartPainter;
      expect(painter.labelStyle.fontSize, 14);
    });

    testWidgets('bar chart uses default colors when not specified', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(HandDrawnBarChart(data: _barData())));
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnBarChartPainter>(),
                  )
                  .painter
              as HandDrawnBarChartPainter;
      expect(painter.axisColor, const Color(0xFF555555));
      expect(painter.gridColor, const Color(0xFFDDDDDD));
    });

    // ── Line chart ─────────────────────────────────────────────────────

    testWidgets('line chart passes axisColor to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(), axisColor: Colors.red)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnLineChartPainter>(),
                  )
                  .painter
              as HandDrawnLineChartPainter;
      expect(painter.axisColor, Colors.red);
    });

    testWidgets('line chart passes gridColor to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(), gridColor: Colors.blue)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnLineChartPainter>(),
                  )
                  .painter
              as HandDrawnLineChartPainter;
      expect(painter.gridColor, Colors.blue);
    });

    testWidgets('line chart passes custom labelStyle to painter', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(), labelStyle: style)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnLineChartPainter>(),
                  )
                  .painter
              as HandDrawnLineChartPainter;
      expect(painter.labelStyle.fontSize, 14);
    });

    testWidgets('line chart uses default colors when not specified', (
      tester,
    ) async {
      await tester.pumpWidget(_wrap(HandDrawnLineChart(data: _lineData())));
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnLineChartPainter>(),
                  )
                  .painter
              as HandDrawnLineChartPainter;
      expect(painter.axisColor, const Color(0xFF555555));
      expect(painter.gridColor, const Color(0xFFDDDDDD));
    });

    // ── Scatter plot ───────────────────────────────────────────────────

    testWidgets('scatter plot passes axisColor to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HandDrawnScatterPlot(data: _scatterData(), axisColor: Colors.red),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnScatterPlotPainter>(),
                  )
                  .painter
              as HandDrawnScatterPlotPainter;
      expect(painter.axisColor, Colors.red);
    });

    testWidgets('scatter plot passes gridColor to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HandDrawnScatterPlot(data: _scatterData(), gridColor: Colors.blue),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnScatterPlotPainter>(),
                  )
                  .painter
              as HandDrawnScatterPlotPainter;
      expect(painter.gridColor, Colors.blue);
    });

    testWidgets('scatter plot passes custom labelStyle to painter', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
      await tester.pumpWidget(
        _wrap(HandDrawnScatterPlot(data: _scatterData(), labelStyle: style)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnScatterPlotPainter>(),
                  )
                  .painter
              as HandDrawnScatterPlotPainter;
      expect(painter.labelStyle.fontSize, 14);
    });

    testWidgets('scatter plot uses default colors when not specified', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HandDrawnScatterPlot(data: _scatterData())),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnScatterPlotPainter>(),
                  )
                  .painter
              as HandDrawnScatterPlotPainter;
      expect(painter.axisColor, const Color(0xFF555555));
      expect(painter.gridColor, const Color(0xFFDDDDDD));
      expect(painter.dotColor, const Color(0xFF6B9BD2));
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART WIDGET — extended configurability (Groups 1, 2, 3, 5)
  // ════════════════════════════════════════════════════════════════════════

  group('Chart widget extended configurability', () {
    testWidgets('bar chart forwards irregularity to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(), irregularity: 5.0)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnBarChartPainter>(),
                  )
                  .painter
              as HandDrawnBarChartPainter;
      expect(painter.irregularity, 5.0);
    });

    testWidgets('line chart forwards segments to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(), segments: 20)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnLineChartPainter>(),
                  )
                  .painter
              as HandDrawnLineChartPainter;
      expect(painter.segments, 20);
    });

    testWidgets('scatter plot forwards yDivisions to painter', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnScatterPlot(data: _scatterData(), yDivisions: 8)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnScatterPlotPainter>(),
                  )
                  .painter
              as HandDrawnScatterPlotPainter;
      expect(painter.yDivisions, 8);
    });

    testWidgets('bar chart forwards custom padding to painter', (tester) async {
      const customPadding = EdgeInsets.all(20);
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(), padding: customPadding)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnBarChartPainter>(),
                  )
                  .painter
              as HandDrawnBarChartPainter;
      expect(painter.padding, customPadding);
    });

    testWidgets('line chart forwards titleStyle to painter', (tester) async {
      const style = TextStyle(fontSize: 20, color: Color(0xFFFF0000));
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(), titleStyle: style)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnLineChartPainter>(),
                  )
                  .painter
              as HandDrawnLineChartPainter;
      expect(painter.titleStyle, style);
    });

    testWidgets('bar chart forwards axisStrokeWidth to painter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(), axisStrokeWidth: 3.0)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnBarChartPainter>(),
                  )
                  .painter
              as HandDrawnBarChartPainter;
      expect(painter.axisStrokeWidth, 3.0);
    });

    testWidgets('line chart forwards gridStrokeWidth to painter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(), gridStrokeWidth: 2.0)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnLineChartPainter>(),
                  )
                  .painter
              as HandDrawnLineChartPainter;
      expect(painter.gridStrokeWidth, 2.0);
    });

    testWidgets('scatter plot forwards gridJitterRatio to painter', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(HandDrawnScatterPlot(data: _scatterData(), gridJitterRatio: 0.8)),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnScatterPlotPainter>(),
                  )
                  .painter
              as HandDrawnScatterPlotPainter;
      expect(painter.gridJitterRatio, 0.8);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART PAINTER — shouldRepaint
  // ════════════════════════════════════════════════════════════════════════

  group('Chart painter shouldRepaint', () {
    test('HandDrawnBarChartPainter: same data → false', () {
      final data = _barData();
      final a = HandDrawnBarChartPainter(data: data, seed: 42);
      final b = HandDrawnBarChartPainter(data: data, seed: 42);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('HandDrawnBarChartPainter: different seed → true', () {
      final data = _barData();
      final a = HandDrawnBarChartPainter(data: data, seed: 42);
      final b = HandDrawnBarChartPainter(data: data, seed: 99);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('HandDrawnLineChartPainter: same data → false', () {
      final data = _lineData();
      final a = HandDrawnLineChartPainter(data: data, seed: 42);
      final b = HandDrawnLineChartPainter(data: data, seed: 42);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('HandDrawnLineChartPainter: different data → true', () {
      final a = HandDrawnLineChartPainter(data: _lineData(pointCount: 3));
      final b = HandDrawnLineChartPainter(data: _lineData(pointCount: 5));
      expect(a.shouldRepaint(b), isTrue);
    });

    test('HandDrawnScatterPlotPainter: same data → false', () {
      final data = _scatterData();
      final a = HandDrawnScatterPlotPainter(data: data, seed: 42);
      final b = HandDrawnScatterPlotPainter(data: data, seed: 42);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('HandDrawnScatterPlotPainter: different dotColor → true', () {
      final data = _scatterData();
      final a = HandDrawnScatterPlotPainter(data: data);
      final b = HandDrawnScatterPlotPainter(data: data, dotColor: Colors.red);
      expect(a.shouldRepaint(b), isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART PAINTER — value formatting
  // ════════════════════════════════════════════════════════════════════════

  group('Chart painter value formatting', () {
    test('formats whole numbers as integers', () {
      final painter = HandDrawnBarChartPainter(data: _barData());
      expect(painter.formatYValue(5), '5');
      expect(painter.formatYValue(100), '100');
      expect(painter.formatYValue(0), '0');
    });

    test('formats fractional values with one decimal place', () {
      final painter = HandDrawnBarChartPainter(data: _barData());
      expect(painter.formatYValue(0.25), '0.3'); // toStringAsFixed(1)
      expect(painter.formatYValue(3.7), '3.7');
    });

    test('does NOT treat fractional values as percentages', () {
      final painter = HandDrawnBarChartPainter(data: _barData());
      // This was the old bug: 0.5 should NOT become "50%"
      final result = painter.formatYValue(0.5);
      expect(result, isNot(contains('%')));
      expect(result, '0.5');
    });

    test('formats negative values symmetrically with positive', () {
      final painter = HandDrawnBarChartPainter(data: _barData());
      final pos = painter.formatYValue(0.5);
      final neg = painter.formatYValue(-0.5);
      // Both should use the same format (no sign asymmetry)
      expect(neg, '-0.5');
      expect(pos, '0.5');
    });

    test('uses custom formatter when provided', () {
      final data = BarChartData(
        bars: [],
        legend: [],
        yValueFormatter: (v) => '${v.toStringAsFixed(2)} kg',
      );
      final painter = HandDrawnBarChartPainter(data: data);
      expect(painter.formatYValue(3.5), '3.50 kg');
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART PAINTER — smoke tests (no-throw)
  // ════════════════════════════════════════════════════════════════════════

  group('Chart painters render without throwing', () {
    testWidgets('bar chart with single bar', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(barCount: 1))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('line chart with single point', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(pointCount: 1))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('scatter plot with single point', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnScatterPlot(data: _scatterData(pointCount: 1))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('bar chart with title and yAxisLabel', (tester) async {
      await tester.pumpWidget(
        _wrap(
          HandDrawnBarChart(
            data: _barData(title: 'Revenue', yAxisLabel: 'USD'),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('line chart with title and axis labels', (tester) async {
      const data = LineChartData(
        title: 'Trends',
        yAxisLabel: 'Count',
        xAxisLabel: 'Month',
        series: [
          LineSeriesData(
            name: 'A',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 10), LinePoint(x: 1, y: 20)],
          ),
        ],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 30,
      );
      await tester.pumpWidget(_wrap(const HandDrawnLineChart(data: data)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('scatter plot with title', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnScatterPlot(data: _scatterData(title: 'Correlation'))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('degenerate range (minY == maxY) does not crash', (
      tester,
    ) async {
      const data = LineChartData(
        series: [
          LineSeriesData(
            name: 'Flat',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 5), LinePoint(x: 1, y: 5)],
          ),
        ],
        minX: 0,
        maxX: 1,
        minY: 5,
        maxY: 5,
      );
      await tester.pumpWidget(_wrap(const HandDrawnLineChart(data: data)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('degenerate X range (minX == maxX) does not crash', (
      tester,
    ) async {
      const data = ScatterPlotData(
        points: [ScatterPoint(x: 5, y: 10)],
        xAxisLabel: 'X',
        yAxisLabel: 'Y',
        minX: 5,
        maxX: 5,
        minY: 0,
        maxY: 20,
      );
      await tester.pumpWidget(_wrap(const HandDrawnScatterPlot(data: data)));
      expect(tester.takeException(), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // BAR CHART — painter validation (release-safe)
  // ════════════════════════════════════════════════════════════════════════

  group('Bar chart painter validation', () {
    // In debug mode, BarSegment's assert fires first (AssertionError).
    // In release mode, the painter constructor's validation fires (ArgumentError).
    // Both paths reject invalid data; we accept either error type.
    test('rejects negative segment value', () {
      expect(
        () => HandDrawnBarChartPainter(
          data: BarChartData(
            bars: [
              BarGroup(
                label: 'A',
                segments: [
                  BarSegment(
                    category: 'x',
                    value: -5,
                    color: const Color(0xFF000000),
                  ),
                ],
              ),
            ],
            legend: [],
          ),
        ),
        throwsA(anyOf(isA<AssertionError>(), isA<ArgumentError>())),
      );
    });

    test('accepts zero segment value without error', () {
      expect(
        () => HandDrawnBarChartPainter(
          data: const BarChartData(
            bars: [
              BarGroup(
                label: 'A',
                segments: [
                  BarSegment(category: 'x', value: 0, color: Color(0xFF000000)),
                ],
              ),
            ],
            legend: [],
          ),
        ),
        returnsNormally,
      );
    });

    test('accepts positive segment values without error', () {
      expect(() => HandDrawnBarChartPainter(data: _barData()), returnsNormally);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // BAR CHART — baseline correctness
  // ════════════════════════════════════════════════════════════════════════

  group('Bar chart baseline correctness', () {
    testWidgets('renders without throwing when minY > 0', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(minY: 10, maxY: 50))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without throwing when minY < 0', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(minY: -10, maxY: 50))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without throwing with custom Y range', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(minY: 5, maxY: 200))),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART — division validation
  // ════════════════════════════════════════════════════════════════════════

  group('Chart division validation', () {
    testWidgets('bar chart rejects yDivisions: 0', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(), yDivisions: 0)),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('line chart rejects xDivisions: 0', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(), xDivisions: 0)),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('scatter plot rejects yDivisions: -1', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnScatterPlot(data: _scatterData(), yDivisions: -1)),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('bar chart rejects yMin > yMax', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnBarChart(data: _barData(minY: 10, maxY: 5))),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('scatter plot rejects xMin > xMax', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnScatterPlot(
            data: ScatterPlotData(
              points: [ScatterPoint(x: 1, y: 2)],
              minX: 100,
              maxX: 0,
              minY: 0,
              maxY: 10,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('line chart accepts valid divisions', (tester) async {
      await tester.pumpWidget(
        _wrap(HandDrawnLineChart(data: _lineData(), xDivisions: 5)),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // SCATTER — point size validation
  // ════════════════════════════════════════════════════════════════════════

  group('Scatter point size validation', () {
    test('rejects negative ScatterPoint.size', () {
      // The assert fires in the const ScatterPoint constructor (debug mode),
      // before any widget tree processing — same pattern as BarSegment.value.
      expect(
        () => ScatterPoint(x: 1, y: 2, size: -5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects zero ScatterPoint.size', () {
      expect(
        () => ScatterPoint(x: 1, y: 2, size: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    testWidgets('accepts positive ScatterPoint.size', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnScatterPlot(
            data: ScatterPlotData(
              points: [ScatterPoint(x: 1, y: 2, size: 8)],
              minX: 0,
              maxX: 10,
              minY: 0,
              maxY: 10,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART — numeric X-axis label thinning
  // ════════════════════════════════════════════════════════════════════════

  group('Numeric X-axis label thinning', () {
    testWidgets('high xDivisions in narrow width paints without error', (
      tester,
    ) async {
      // With 20 divisions in a 200px-wide widget and a verbose formatter,
      // the thinning logic must skip overlapping labels without crashing.
      await tester.pumpWidget(
        _wrap(
          const SizedBox(
            width: 200,
            child: HandDrawnScatterPlot(
              data: ScatterPlotData(
                points: [ScatterPoint(x: 50, y: 50)],
                minX: 0,
                maxX: 1000,
                minY: 0,
                maxY: 100,
              ),
              xDivisions: 20,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('verbose formatter with many divisions paints without error', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 150,
            child: HandDrawnLineChart(
              data: LineChartData(
                series: [
                  const LineSeriesData(
                    name: 'S',
                    color: Color(0xFF000000),
                    points: [LinePoint(x: 0, y: 0), LinePoint(x: 100, y: 100)],
                  ),
                ],
                minX: 0,
                maxX: 100,
                minY: 0,
                maxY: 100,
                xValueFormatter: (v) => '\$${v.toStringAsFixed(2)} USD',
              ),
              xDivisions: 15,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART PAINTER — shouldRepaint list field completeness
  // ════════════════════════════════════════════════════════════════════════

  group('Chart painter shouldRepaint list fields', () {
    test('shouldRepaint true when xLabels differ', () {
      final a = HandDrawnBarChartPainter(data: _barData());
      final b = HandDrawnBarChartPainter(data: _barData(barCount: 5));
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint true when legend entries differ', () {
      const dataA = BarChartData(
        bars: [
          BarGroup(
            label: 'A',
            segments: [
              BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
            ],
          ),
        ],
        legend: [LegendEntry(label: 'X', color: Color(0xFF000000))],
      );
      const dataB = BarChartData(
        bars: [
          BarGroup(
            label: 'A',
            segments: [
              BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
            ],
          ),
        ],
        legend: [LegendEntry(label: 'Y', color: Color(0xFFFF0000))],
      );
      final a = HandDrawnBarChartPainter(data: dataA);
      final b = HandDrawnBarChartPainter(data: dataB);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('shouldRepaint false when xLabels and legend are identical', () {
      final data = _barData();
      final a = HandDrawnBarChartPainter(data: data);
      final b = HandDrawnBarChartPainter(data: data);
      expect(a.shouldRepaint(b), isFalse);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART PAINTER — wobbly circle primitive
  // ════════════════════════════════════════════════════════════════════════

  // The wobbly-circle helper previously sampled the wrap-around angle
  // twice, producing two separately-jittered points at the same angular
  // position. When the path closed, the two points left a visible notch.
  // The fix samples the circle exactly once per angular position and
  // lets path.close() connect the last segment back to the first.
  group('wobblyCircle primitive', () {
    HandDrawnScatterPlotPainter makePainter({int seed = 42}) {
      return HandDrawnScatterPlotPainter(
        data: const ScatterPlotData(
          points: [ScatterPoint(x: 0, y: 0)],
          minX: -1,
          maxX: 1,
          minY: -1,
          maxY: 1,
        ),
        seed: seed,
      );
    }

    test('same seed and inputs produce identical path bounds', () {
      final painter = makePainter();
      final a = painter.wobblyCircle(const Offset(100, 100), 20.0, 42);
      final b = painter.wobblyCircle(const Offset(100, 100), 20.0, 42);

      expect(a.getBounds(), equals(b.getBounds()));
    });

    test('generates a single closed contour (no seam gap)', () {
      final painter = makePainter(seed: 99);
      final path = painter.wobblyCircle(const Offset(50, 50), 15.0, 99);
      final metrics = path.computeMetrics().toList();

      expect(metrics, hasLength(1));
      expect(metrics.first.isClosed, isTrue);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART LAYOUT — insufficient vertical space
  // ════════════════════════════════════════════════════════════════════════

  // When a chart is given less vertical space than its title, tick, axis
  // label, and legend bands collectively require, the derived plot
  // rectangle would invert (bottom above top). The layout asserts on raw
  // pre-clamp geometry in debug so the developer sees the misconfiguration,
  // and clamps bottom to at least top for release-safe rendering.
  group('Chart layout tight vertical constraints', () {
    testWidgets('bar chart with insufficient height fires the size assertion', (
      tester,
    ) async {
      final errors = await captureFlutterErrors(() async {
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 300,
              height: 10,
              child: HandDrawnBarChart(data: _barData()),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      // The geometry assertion must fire; no plot-rect inversion may occur.
      expect(
        errors.any(
          (e) =>
              e.exception is AssertionError &&
              e.exception.toString().contains('insufficient vertical space'),
        ),
        isTrue,
        reason:
            'Chart given insufficient vertical space must trigger the '
            'buildChartFrame geometry assertion.',
      );
    });

    testWidgets(
      'line chart with insufficient height fires the size assertion',
      (tester) async {
        final errors = await captureFlutterErrors(() async {
          await tester.pumpWidget(
            _wrap(
              SizedBox(
                width: 300,
                height: 10,
                child: HandDrawnLineChart(data: _lineData()),
              ),
            ),
          );
          await tester.pumpAndSettle();
        });

        expect(
          errors.any(
            (e) =>
                e.exception is AssertionError &&
                e.exception.toString().contains('insufficient vertical space'),
          ),
          isTrue,
          reason:
              'Chart given insufficient vertical space must trigger the '
              'buildChartFrame geometry assertion.',
        );
      },
    );
  });
}
