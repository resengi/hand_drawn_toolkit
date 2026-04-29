import 'dart:ui' show PictureRecorder;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

// ── Helpers ────────────────────────────────────────────────────────────────

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
      await tester.pumpWidget(testApp(const HandDrawnBarChart(data: null)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when data is empty', (tester) async {
      await tester.pumpWidget(
        testApp(
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
      await tester.pumpWidget(testApp(HandDrawnBarChart(data: barTestData())));
      expect(_findChartPaint<HandDrawnBarChartPainter>(), findsOneWidget);
    });

    testWidgets('applies height parameter', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(), height: 300)),
      );
      final box = tester.getSize(find.byType(HandDrawnBarChart));
      expect(box.height, 300.0);
    });

    testWidgets('passes seed to painter', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(), seed: 99)),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnBarChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnBarChartPainter;
      expect(painter.seed, 99);
    });

    testWidgets('accepts custom minY and maxY', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(minY: -10, maxY: 50))),
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
        testApp(HandDrawnBarChart(data: barTestData(barCount: 50))),
      );
      expect(_findChartPaint<HandDrawnBarChartPainter>(), findsOneWidget);
    });

    testWidgets('dense bars in constrained width render without error', (
      tester,
    ) async {
      // 50 bars in 100px → slotWidth = 2, well below barMinWidth (4).
      await tester.pumpWidget(
        testApp(
          SizedBox(
            width: 100,
            child: HandDrawnBarChart(data: barTestData(barCount: 50)),
          ),
        ),
      );
      expect(_findChartPaint<HandDrawnBarChartPainter>(), findsOneWidget);
    });

    testWidgets('normal density bar chart renders correctly', (tester) async {
      // 5 bars — a typical use case that should be unaffected by the
      // dense-bar fix.
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(barCount: 5))),
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
      await tester.pumpWidget(testApp(const HandDrawnLineChart(data: null)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when all series are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
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

    testWidgets('renders custom emptyMessage when provided', (tester) async {
      await tester.pumpWidget(
        testApp(
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
            emptyMessage: 'Nothing to show yet',
          ),
        ),
      );
      expect(find.text('Nothing to show yet'), findsOneWidget);
      expect(find.text('No data for this range'), findsNothing);
    });

    testWidgets('renders CustomPaint with correct painter for valid data', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(HandDrawnLineChart(data: lineTestData())),
      );
      expect(_findChartPaint<HandDrawnLineChartPainter>(), findsOneWidget);
    });

    testWidgets('passes seed to painter', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnLineChart(data: lineTestData(), seed: 77)),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnLineChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnLineChartPainter;
      expect(painter.seed, 77);
    });

    testWidgets('auto-generates legend for multi-series data', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnLineChart(data: lineTestData(seriesCount: 3))),
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
        testApp(HandDrawnLineChart(data: lineTestData(seriesCount: 1))),
      );
      final customPaint = tester.widget<CustomPaint>(
        _findChartPaint<HandDrawnLineChartPainter>(),
      );
      final painter = customPaint.painter as HandDrawnLineChartPainter;
      expect(painter.legend, isEmpty);
    });

    testWidgets('passes xLabels for categorical mode', (tester) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnLineChart(
            data: lineTestData(xLabels: ['A', 'B', 'C', 'D', 'E']),
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
      await tester.pumpWidget(
        testApp(HandDrawnLineChart(data: lineTestData())),
      );
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
      await tester.pumpWidget(testApp(const HandDrawnScatterPlot(data: null)));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows empty message when points are empty', (tester) async {
      await tester.pumpWidget(
        testApp(
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
        testApp(HandDrawnScatterPlot(data: scatterTestData())),
      );
      expect(_findChartPaint<HandDrawnScatterPlotPainter>(), findsOneWidget);
    });

    testWidgets('passes seed and dotColor to painter', (tester) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnScatterPlot(
            data: scatterTestData(),
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
        testApp(HandDrawnScatterPlot(data: scatterTestData())),
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
        testApp(HandDrawnBarChart(data: barTestData(), axisColor: Colors.red)),
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

    testWidgets('bar chart forwards grid color via GridConfig', (tester) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnBarChart(
            data: barTestData(),
            grid: const GridConfig(color: Colors.blue),
          ),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnBarChartPainter>(),
                  )
                  .painter
              as HandDrawnBarChartPainter;
      expect(painter.grid.color, Colors.blue);
    });

    testWidgets('bar chart passes custom labelStyle to painter', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(), labelStyle: style)),
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
      await tester.pumpWidget(testApp(HandDrawnBarChart(data: barTestData())));
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnBarChartPainter>(),
                  )
                  .painter
              as HandDrawnBarChartPainter;
      expect(painter.axisColor, const Color(0xFF555555));
      expect(painter.grid.color, const Color(0xFFC4C4C4));
    });

    // ── Line chart ─────────────────────────────────────────────────────

    testWidgets('line chart passes axisColor to painter', (tester) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnLineChart(data: lineTestData(), axisColor: Colors.red),
        ),
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

    testWidgets('line chart forwards grid color via GridConfig', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnLineChart(
            data: lineTestData(),
            grid: const GridConfig(color: Colors.blue),
          ),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnLineChartPainter>(),
                  )
                  .painter
              as HandDrawnLineChartPainter;
      expect(painter.grid.color, Colors.blue);
    });

    testWidgets('line chart passes custom labelStyle to painter', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
      await tester.pumpWidget(
        testApp(HandDrawnLineChart(data: lineTestData(), labelStyle: style)),
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
      await tester.pumpWidget(
        testApp(HandDrawnLineChart(data: lineTestData())),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnLineChartPainter>(),
                  )
                  .painter
              as HandDrawnLineChartPainter;
      expect(painter.axisColor, const Color(0xFF555555));
      expect(painter.grid.color, const Color(0xFFC4C4C4));
    });

    // ── Scatter plot ───────────────────────────────────────────────────

    testWidgets('scatter plot passes axisColor to painter', (tester) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnScatterPlot(data: scatterTestData(), axisColor: Colors.red),
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

    testWidgets('scatter plot forwards grid color via GridConfig', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnScatterPlot(
            data: scatterTestData(),
            grid: const GridConfig(color: Colors.blue),
          ),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnScatterPlotPainter>(),
                  )
                  .painter
              as HandDrawnScatterPlotPainter;
      expect(painter.grid.color, Colors.blue);
    });

    testWidgets('scatter plot passes custom labelStyle to painter', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 14, color: Color(0xFF000000));
      await tester.pumpWidget(
        testApp(
          HandDrawnScatterPlot(data: scatterTestData(), labelStyle: style),
        ),
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
        testApp(HandDrawnScatterPlot(data: scatterTestData())),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnScatterPlotPainter>(),
                  )
                  .painter
              as HandDrawnScatterPlotPainter;
      expect(painter.axisColor, const Color(0xFF555555));
      expect(painter.grid.color, const Color(0xFFC4C4C4));
      expect(painter.dotColor, const Color(0xFF6B9BD2));
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART WIDGET — extended configurability (Groups 1, 2, 3, 5)
  // ════════════════════════════════════════════════════════════════════════

  group('Chart widget extended configurability', () {
    testWidgets('bar chart forwards irregularity to painter', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(), irregularity: 5.0)),
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
        testApp(HandDrawnLineChart(data: lineTestData(), segments: 20)),
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
        testApp(HandDrawnScatterPlot(data: scatterTestData(), yDivisions: 8)),
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
        testApp(HandDrawnBarChart(data: barTestData(), padding: customPadding)),
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
        testApp(HandDrawnLineChart(data: lineTestData(), titleStyle: style)),
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
        testApp(HandDrawnBarChart(data: barTestData(), axisStrokeWidth: 3.0)),
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

    testWidgets('line chart forwards grid stroke width via GridConfig', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnLineChart(
            data: lineTestData(),
            grid: const GridConfig(strokeWidth: 2.0),
          ),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnLineChartPainter>(),
                  )
                  .painter
              as HandDrawnLineChartPainter;
      expect(painter.grid.strokeWidth, 2.0);
    });

    testWidgets('scatter plot forwards grid jitter ratio via GridConfig', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnScatterPlot(
            data: scatterTestData(),
            grid: const GridConfig(jitterRatio: 0.8),
          ),
        ),
      );
      final painter =
          tester
                  .widget<CustomPaint>(
                    _findChartPaint<HandDrawnScatterPlotPainter>(),
                  )
                  .painter
              as HandDrawnScatterPlotPainter;
      expect(painter.grid.jitterRatio, 0.8);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART PAINTER — shouldRepaint
  // ════════════════════════════════════════════════════════════════════════

  group('Chart painter shouldRepaint', () {
    test('HandDrawnBarChartPainter: same data → false', () {
      final data = barTestData();
      final a = HandDrawnBarChartPainter(data: data, seed: 42);
      final b = HandDrawnBarChartPainter(data: data, seed: 42);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('HandDrawnBarChartPainter: different seed → true', () {
      final data = barTestData();
      final a = HandDrawnBarChartPainter(data: data, seed: 42);
      final b = HandDrawnBarChartPainter(data: data, seed: 99);
      expect(a.shouldRepaint(b), isTrue);
    });

    test('HandDrawnLineChartPainter: same data → false', () {
      final data = lineTestData();
      final a = HandDrawnLineChartPainter(data: data, seed: 42);
      final b = HandDrawnLineChartPainter(data: data, seed: 42);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('HandDrawnLineChartPainter: different data → true', () {
      final a = HandDrawnLineChartPainter(data: lineTestData(pointCount: 3));
      final b = HandDrawnLineChartPainter(data: lineTestData(pointCount: 5));
      expect(a.shouldRepaint(b), isTrue);
    });

    test('HandDrawnScatterPlotPainter: same data → false', () {
      final data = scatterTestData();
      final a = HandDrawnScatterPlotPainter(data: data, seed: 42);
      final b = HandDrawnScatterPlotPainter(data: data, seed: 42);
      expect(a.shouldRepaint(b), isFalse);
    });

    test('HandDrawnScatterPlotPainter: different dotColor → true', () {
      final data = scatterTestData();
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
      final painter = HandDrawnBarChartPainter(data: barTestData());
      expect(painter.formatYValue(5), '5');
      expect(painter.formatYValue(100), '100');
      expect(painter.formatYValue(0), '0');
    });

    test('formats fractional values with one decimal place', () {
      final painter = HandDrawnBarChartPainter(data: barTestData());
      expect(painter.formatYValue(0.25), '0.3'); // toStringAsFixed(1)
      expect(painter.formatYValue(3.7), '3.7');
    });

    test('does NOT treat fractional values as percentages', () {
      final painter = HandDrawnBarChartPainter(data: barTestData());
      // This was the old bug: 0.5 should NOT become "50%"
      final result = painter.formatYValue(0.5);
      expect(result, isNot(contains('%')));
      expect(result, '0.5');
    });

    test('formats negative values symmetrically with positive', () {
      final painter = HandDrawnBarChartPainter(data: barTestData());
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
        testApp(HandDrawnBarChart(data: barTestData(barCount: 1))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('line chart with single point', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnLineChart(data: lineTestData(pointCount: 1))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('scatter plot with single point', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnScatterPlot(data: scatterTestData(pointCount: 1))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('bar chart with title and yAxisLabel', (tester) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnBarChart(
            data: barTestData(title: 'Revenue', yAxisLabel: 'USD'),
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
      await tester.pumpWidget(testApp(const HandDrawnLineChart(data: data)));
      expect(tester.takeException(), isNull);
    });

    testWidgets('scatter plot with title', (tester) async {
      await tester.pumpWidget(
        testApp(
          HandDrawnScatterPlot(data: scatterTestData(title: 'Correlation')),
        ),
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
      await tester.pumpWidget(testApp(const HandDrawnLineChart(data: data)));
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
      await tester.pumpWidget(testApp(const HandDrawnScatterPlot(data: data)));
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
    test('accepts negative segment value (release-safe finite check)', () {
      // Negative values are valid — they stack downward from the zero
      // baseline. Only non-finite values (NaN, infinities) are rejected
      // by the painter's release-safe guard.
      expect(
        () => HandDrawnBarChartPainter(
          data: const BarChartData(
            bars: [
              BarGroup(
                label: 'A',
                segments: [
                  BarSegment(
                    category: 'x',
                    value: -5,
                    color: Color(0xFF000000),
                  ),
                ],
              ),
            ],
            legend: [],
          ),
        ),
        returnsNormally,
      );
    });

    test('rejects non-finite segment value', () {
      // Wrap construction in a closure since BarSegment's debug
      // assertion will fire first — accept either an AssertionError
      // (debug builds) or an ArgumentError (release builds, from the
      // painter's release-safe guard).
      expect(
        () => HandDrawnBarChartPainter(
          data: BarChartData(
            bars: [
              BarGroup(
                label: 'A',
                segments: [
                  BarSegment(
                    category: 'x',
                    value: double.nan,
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
      expect(
        () => HandDrawnBarChartPainter(data: barTestData()),
        returnsNormally,
      );
    });

    test('default yMin stays at 0 when no negative segments are present', () {
      // Backward-compat: an all-positive bar chart must keep its
      // historical default of yMin == 0.
      final painter = HandDrawnBarChartPainter(
        data: const BarChartData(
          bars: [
            BarGroup(
              label: 'A',
              segments: [
                BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
              ],
            ),
            BarGroup(
              label: 'B',
              segments: [
                BarSegment(category: 'x', value: 5, color: Color(0xFF000000)),
              ],
            ),
          ],
          legend: [],
        ),
      );
      expect(painter.yMin, 0);
    });

    test(
      'default yMin becomes negative when negative segments are present',
      () {
        // The default minY tracks the smallest negative stack total
        // across inner bars so negative bars are fully visible.
        final painter = HandDrawnBarChartPainter(
          data: const BarChartData(
            bars: [
              BarGroup(
                label: 'A',
                segments: [
                  BarSegment(
                    category: 'x',
                    value: 10,
                    color: Color(0xFF000000),
                  ),
                  BarSegment(
                    category: 'x',
                    value: -4,
                    color: Color(0xFF000000),
                  ),
                ],
              ),
              BarGroup(
                label: 'B',
                segments: [
                  BarSegment(
                    category: 'x',
                    value: -7,
                    color: Color(0xFF000000),
                  ),
                ],
              ),
            ],
            legend: [],
          ),
        );
        expect(painter.yMin, -7);
      },
    );

    test('default yMax uses positive stack totals, not net of mixed signs', () {
      // For a bar with segments [10, -4, 6, -3] the net total is 9 but
      // the visible upward extent is the positive-only sum: 16.
      final painter = HandDrawnBarChartPainter(
        data: const BarChartData(
          bars: [
            BarGroup(
              label: 'A',
              segments: [
                BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
                BarSegment(category: 'x', value: -4, color: Color(0xFF000000)),
                BarSegment(category: 'x', value: 6, color: Color(0xFF000000)),
                BarSegment(category: 'x', value: -3, color: Color(0xFF000000)),
              ],
            ),
          ],
          legend: [],
        ),
      );
      expect(painter.yMax, 16);
      expect(painter.yMin, -7);
    });

    test('all-negative bars still get a sensible non-zero upper bound', () {
      // When no positive segments exist, _computeMaxY's all-zero
      // fallback (-> 1) keeps the plot rect from collapsing.
      final painter = HandDrawnBarChartPainter(
        data: const BarChartData(
          bars: [
            BarGroup(
              label: 'A',
              segments: [
                BarSegment(category: 'x', value: -5, color: Color(0xFF000000)),
              ],
            ),
          ],
          legend: [],
        ),
      );
      expect(painter.yMax, 1);
      expect(painter.yMin, -5);
    });

    test('grouped bars compute extents per inner bar, not across siblings', () {
      // A category with two side-by-side bars of [10] and [20] must
      // give yMax = 20, not 30. Same rule on the negative side.
      final painter = HandDrawnBarChartPainter(
        data: const BarChartData(
          bars: [],
          legend: [],
          categories: [
            BarCategory(
              label: 'Q1',
              bars: [
                BarGroup(
                  label: 'North',
                  segments: [
                    BarSegment(
                      category: 'x',
                      value: 10,
                      color: Color(0xFF000000),
                    ),
                  ],
                ),
                BarGroup(
                  label: 'South',
                  segments: [
                    BarSegment(
                      category: 'x',
                      value: 20,
                      color: Color(0xFF000000),
                    ),
                  ],
                ),
                BarGroup(
                  label: 'East',
                  segments: [
                    BarSegment(
                      category: 'x',
                      value: -8,
                      color: Color(0xFF000000),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      );
      expect(painter.yMax, 20);
      expect(painter.yMin, -8);
    });
  });

  // ════════════════════════════════════════════════════════════════════════
  // BAR CHART — baseline correctness
  // ════════════════════════════════════════════════════════════════════════

  group('Bar chart baseline correctness', () {
    testWidgets('renders without throwing when minY > 0', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(minY: 10, maxY: 50))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without throwing when minY < 0', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(minY: -10, maxY: 50))),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without throwing with custom Y range', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(minY: 5, maxY: 200))),
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
        testApp(HandDrawnBarChart(data: barTestData(), yDivisions: 0)),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('line chart rejects xDivisions: 0', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnLineChart(data: lineTestData(), xDivisions: 0)),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('scatter plot rejects yDivisions: -1', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnScatterPlot(data: scatterTestData(), yDivisions: -1)),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('bar chart rejects yMin > yMax', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(minY: 10, maxY: 5))),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('scatter plot rejects xMin > xMax', (tester) async {
      await tester.pumpWidget(
        testApp(
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
        testApp(HandDrawnLineChart(data: lineTestData(), xDivisions: 5)),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('line chart rejects NaN minY', (tester) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnLineChart(
            data: LineChartData(
              series: [
                LineSeriesData(
                  name: 'S',
                  color: Color(0xFF000000),
                  points: [LinePoint(x: 0, y: 0)],
                ),
              ],
              minX: 0,
              maxX: 1,
              minY: double.nan,
              maxY: 1,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('scatter plot rejects positive infinity maxY', (tester) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnScatterPlot(
            data: ScatterPlotData(
              points: [ScatterPoint(x: 0, y: 0)],
              minX: 0,
              maxX: 1,
              minY: 0,
              maxY: double.infinity,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('scatter plot rejects negative infinity xMin', (tester) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnScatterPlot(
            data: ScatterPlotData(
              points: [ScatterPoint(x: 0, y: 0)],
              minX: double.negativeInfinity,
              maxX: 1,
              minY: 0,
              maxY: 1,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('bar chart rejects NaN explicit maxY', (tester) async {
      await tester.pumpWidget(
        testApp(HandDrawnBarChart(data: barTestData(maxY: double.nan))),
      );
      expect(tester.takeException(), isA<ArgumentError>());
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
        testApp(
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
        testApp(
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
        testApp(
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
      final a = HandDrawnBarChartPainter(data: barTestData());
      final b = HandDrawnBarChartPainter(data: barTestData(barCount: 5));
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
      final data = barTestData();
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
          testApp(
            SizedBox(
              width: 300,
              height: 10,
              child: HandDrawnBarChart(data: barTestData()),
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
            testApp(
              SizedBox(
                width: 300,
                height: 10,
                child: HandDrawnLineChart(data: lineTestData()),
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

  // ════════════════════════════════════════════════════════════════════════
  // CHART LABEL CONFIG — rotated X-axis tick labels
  // ════════════════════════════════════════════════════════════════════════

  group('ChartLabelConfig integration', () {
    // Bar data with deliberately long category labels so rotation has a
    // visible effect on the reserved tick band height and on thinning.
    BarChartData longLabelBarData() => const BarChartData(
      bars: [
        BarGroup(
          label: 'September',
          segments: [
            BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
          ],
        ),
        BarGroup(
          label: 'October',
          segments: [
            BarSegment(category: 'x', value: 20, color: Color(0xFF000000)),
          ],
        ),
        BarGroup(
          label: 'November',
          segments: [
            BarSegment(category: 'x', value: 15, color: Color(0xFF000000)),
          ],
        ),
        BarGroup(
          label: 'December',
          segments: [
            BarSegment(category: 'x', value: 25, color: Color(0xFF000000)),
          ],
        ),
      ],
      legend: [],
    );

    test('default (horizontal) preserves the historical layout', () {
      // The unrotated fast path reserves exactly the
      // chartXTickBandHeight constant so existing charts get the same
      // bottom band they always have.
      final painter = HandDrawnBarChartPainter(data: longLabelBarData());
      final defaultLayout = painter.computeLayout(kChartTestSize);

      // We verify the contract indirectly: a horizontal config
      // produces the same chartArea as no config at all (the baseline).
      final explicitHorizontal = HandDrawnBarChartPainter(
        data: longLabelBarData(),
        xLabelConfig: ChartLabelConfig.horizontal,
      ).computeLayout(kChartTestSize);

      expect(defaultLayout.chartArea, equals(explicitHorizontal.chartArea));
    });

    test('rotated config reserves more bottom space than horizontal', () {
      // Vertical labels (long words) push the chart area higher than
      // horizontal because the reserved tick band grows.
      final horizontal = HandDrawnBarChartPainter(
        data: longLabelBarData(),
      ).computeLayout(kChartTestSize);
      final rotated = HandDrawnBarChartPainter(
        data: longLabelBarData(),
        xLabelConfig: ChartLabelConfig.vertical,
      ).computeLayout(kChartTestSize);

      // Rotated config must shrink the chart area vertically (more
      // bottom space reserved for tilted/vertical labels).
      expect(rotated.chartArea.height, lessThan(horizontal.chartArea.height));
    });

    test(
      'rotated label width informs thinning so dense labels can collide',
      () {
        // Smoke-test: thinning actually responds to rotation rather
        // than ignoring it. Both horizontal and rotated paths must
        // paint cleanly even at high label densities (30 labels at
        // typical chart widths). The thinning algorithm uses the
        // minimum non-overlapping rectangle distance per the
        // Separating Axis Theorem, which means rotated labels of any
        // angle pack tighter than horizontal — but the algorithm must
        // still run cleanly without throwing in either path.
        final manyLabelData = BarChartData(
          bars: [
            for (int i = 0; i < 30; i++)
              BarGroup(
                label: 'Category-$i',
                segments: const [
                  BarSegment(
                    category: 'x',
                    value: 10,
                    color: Color(0xFF000000),
                  ),
                ],
              ),
          ],
          legend: const [],
        );

        // Smoke-paint at horizontal vs 45° to make sure thinning runs
        // both paths cleanly.
        final recorder1 = PictureRecorder();
        expect(
          () => HandDrawnBarChartPainter(
            data: manyLabelData,
          ).paint(Canvas(recorder1), kChartTestSize),
          returnsNormally,
        );
        recorder1.endRecording();

        final recorder2 = PictureRecorder();
        expect(
          () => HandDrawnBarChartPainter(
            data: manyLabelData,
            xLabelConfig: ChartLabelConfig.diagonalLeft,
          ).paint(Canvas(recorder2), kChartTestSize),
          returnsNormally,
        );
        recorder2.endRecording();
      },
    );

    test('diagonal labels pack tighter than horizontal does', () {
      // The thinning algorithm uses the actual minimum non-overlapping
      // rectangle distance (per the Separating Axis Theorem), not the
      // rotated bounding box. For long labels at -45°, the
      // perpendicular constraint `h/|sinθ|` dominates and is much
      // smaller than the label width, so all 6 labels fit on a
      // 400px-wide canvas where horizontal labels of the same length
      // would thin to 3-4.
      const longLabelData = BarChartData(
        bars: [
          BarGroup(
            label: 'October 2024',
            segments: [
              BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
            ],
          ),
          BarGroup(
            label: 'November 2024',
            segments: [
              BarSegment(category: 'x', value: 12, color: Color(0xFF000000)),
            ],
          ),
          BarGroup(
            label: 'December 2024',
            segments: [
              BarSegment(category: 'x', value: 14, color: Color(0xFF000000)),
            ],
          ),
          BarGroup(
            label: 'January 2025',
            segments: [
              BarSegment(category: 'x', value: 16, color: Color(0xFF000000)),
            ],
          ),
          BarGroup(
            label: 'February 2025',
            segments: [
              BarSegment(category: 'x', value: 18, color: Color(0xFF000000)),
            ],
          ),
          BarGroup(
            label: 'March 2025',
            segments: [
              BarSegment(category: 'x', value: 20, color: Color(0xFF000000)),
            ],
          ),
        ],
        legend: [],
      );
      final labels = [for (final b in longLabelData.bars) b.label];

      // Horizontal: long labels should thin out — the parallel
      // constraint dominates and slot width ≈ label width.
      final horizontalPainter = HandDrawnBarChartPainter(data: longLabelData);
      final horizontalChartArea = horizontalPainter
          .computeLayout(kChartTestSize)
          .chartArea;
      final horizontalVisible = horizontalPainter.debugSelectedLabelPositions(
        labels,
        horizontalChartArea.width,
      );
      expect(
        horizontalVisible.length,
        lessThan(labels.length),
        reason: 'horizontal long labels should thin on a 400px canvas',
      );

      // Diagonal -45°: the perpendicular constraint h/|sinθ|
      // dominates, dropping the slot width to ~h*sqrt(2). All 6
      // labels should fit on the same canvas.
      final diagonalPainter = HandDrawnBarChartPainter(
        data: longLabelData,
        xLabelConfig: ChartLabelConfig.diagonalLeft,
      );
      final diagonalChartArea = diagonalPainter
          .computeLayout(kChartTestSize)
          .chartArea;
      final diagonalVisible = diagonalPainter.debugSelectedLabelPositions(
        labels,
        diagonalChartArea.width,
      );
      expect(
        diagonalVisible.length,
        equals(labels.length),
        reason: 'all 6 diagonal labels should fit on a 400px canvas',
      );

      // Vertical -90°: cos→0 so the parallel constraint vanishes
      // and slot width = label height. All 6 labels should fit
      // here too.
      final verticalPainter = HandDrawnBarChartPainter(
        data: longLabelData,
        xLabelConfig: ChartLabelConfig.vertical,
      );
      final verticalChartArea = verticalPainter
          .computeLayout(kChartTestSize)
          .chartArea;
      final verticalVisible = verticalPainter.debugSelectedLabelPositions(
        labels,
        verticalChartArea.width,
      );
      expect(
        verticalVisible.length,
        equals(labels.length),
        reason: 'all 6 vertical labels should fit on a 400px canvas',
      );
    });

    test(
      'bar/line/scatter all paint at -45°, +45°, and -90° without throwing',
      () {
        final configs = [
          ChartLabelConfig.diagonalLeft,
          ChartLabelConfig.diagonalRight,
          ChartLabelConfig.vertical,
          const ChartLabelConfig(rotationDegrees: 30),
        ];

        for (final cfg in configs) {
          // Bar.
          final r1 = PictureRecorder();
          expect(
            () => HandDrawnBarChartPainter(
              data: longLabelBarData(),
              xLabelConfig: cfg,
            ).paint(Canvas(r1), kChartTestSize),
            returnsNormally,
            reason: 'bar paint failed at ${cfg.rotationDegrees}°',
          );
          r1.endRecording();

          // Line — uses numeric X ticks so this exercises the
          // _paintNumericXTicks rotated path.
          const lineData = LineChartData(
            minX: 0,
            maxX: 10,
            minY: 0,
            maxY: 100,
            series: [
              LineSeriesData(
                name: 'S',
                color: Color(0xFF000000),
                points: [
                  LinePoint(x: 0, y: 10),
                  LinePoint(x: 5, y: 50),
                  LinePoint(x: 10, y: 90),
                ],
              ),
            ],
          );
          final r2 = PictureRecorder();
          expect(
            () => HandDrawnLineChartPainter(
              data: lineData,
              xLabelConfig: cfg,
            ).paint(Canvas(r2), kChartTestSize),
            returnsNormally,
            reason: 'line paint failed at ${cfg.rotationDegrees}°',
          );
          r2.endRecording();

          // Scatter — also numeric X ticks.
          const scatterData = ScatterPlotData(
            minX: 0,
            maxX: 10,
            minY: 0,
            maxY: 100,
            points: [
              ScatterPoint(x: 1, y: 10),
              ScatterPoint(x: 5, y: 50),
              ScatterPoint(x: 9, y: 90),
            ],
          );
          final r3 = PictureRecorder();
          expect(
            () => HandDrawnScatterPlotPainter(
              data: scatterData,
              xLabelConfig: cfg,
            ).paint(Canvas(r3), kChartTestSize),
            returnsNormally,
            reason: 'scatter paint failed at ${cfg.rotationDegrees}°',
          );
          r3.endRecording();
        }
      },
    );

    test('shouldRepaint propagates xLabelConfig changes', () {
      // Bar.
      final bar1 = HandDrawnBarChartPainter(data: longLabelBarData());
      final bar2 = HandDrawnBarChartPainter(
        data: longLabelBarData(),
        xLabelConfig: ChartLabelConfig.diagonalLeft,
      );
      expect(bar2.shouldRepaint(bar1), isTrue);

      // Line.
      const lineData = LineChartData(
        minX: 0,
        maxX: 4,
        minY: 0,
        maxY: 50,
        series: [
          LineSeriesData(
            name: 'S',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 10), LinePoint(x: 4, y: 40)],
          ),
        ],
      );
      final line1 = HandDrawnLineChartPainter(data: lineData);
      final line2 = HandDrawnLineChartPainter(
        data: lineData,
        xLabelConfig: ChartLabelConfig.vertical,
      );
      expect(line2.shouldRepaint(line1), isTrue);

      // Scatter.
      const scatterData = ScatterPlotData(
        minX: 0,
        maxX: 4,
        minY: 0,
        maxY: 50,
        points: [ScatterPoint(x: 1, y: 10), ScatterPoint(x: 3, y: 40)],
      );
      final s1 = HandDrawnScatterPlotPainter(data: scatterData);
      final s2 = HandDrawnScatterPlotPainter(
        data: scatterData,
        xLabelConfig: ChartLabelConfig.diagonalRight,
      );
      expect(s2.shouldRepaint(s1), isTrue);
    });

    test('numeric X labels reserve more height than "0" for wide bounds', () {
      // Numeric X tick height reservation samples the default formatter
      // at xMin and xMax, so wide bounds (e.g. ±1,000,000) reserve
      // enough space for their rotated labels — even without a custom
      // formatter.
      const wideData = LineChartData(
        minX: -1000000,
        maxX: 1000000,
        minY: 0,
        maxY: 100,
        series: [
          LineSeriesData(
            name: 'S',
            color: Color(0xFF000000),
            points: [LinePoint(x: -1000000, y: 0), LinePoint(x: 1000000, y: 0)],
          ),
        ],
      );
      const narrowData = LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 100,
        series: [
          LineSeriesData(
            name: 'S',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 0), LinePoint(x: 1, y: 0)],
          ),
        ],
      );
      // Force the labels to be tall enough that the difference shows up
      // in the reserved height — vertical rotation magnifies width.
      const verticalLabels = ChartLabelConfig.vertical;

      final wideLayout = HandDrawnLineChartPainter(
        data: wideData,
        xLabelConfig: verticalLabels,
      ).computeLayout(kChartTestSize);
      final narrowLayout = HandDrawnLineChartPainter(
        data: narrowData,
        xLabelConfig: verticalLabels,
      ).computeLayout(kChartTestSize);

      // Wide labels (-1000000, 1000000) rotated 90° take MORE
      // vertical space than narrow labels (0, 1). Wide chartArea
      // must therefore be SHORTER (more reserved at the bottom).
      expect(
        wideLayout.chartArea.height,
        lessThan(narrowLayout.chartArea.height),
      );
    });

    test(
      'rotated numeric X-axis reserves space for the longest middle tick',
      () {
        // Two charts with identical endpoint labels but different middle-tick
        // labels: one chart's formatter produces a wide label only at the
        // middle tick (x=0.5); the other returns a uniformly short label at
        // every tick. The rotated tick band measures every tick the painter
        // renders, so the long-middle chart reserves more bottom space than
        // the short-everywhere chart, even though their endpoints match.

        String shortAtAllTicks(double value) => 'X';

        String longAtMiddleOnly(double value) {
          if ((value - 0.5).abs() < 0.0001) return 'MID-LABEL';
          return 'X';
        }

        LineChartData makeData(String Function(double) formatter) =>
            LineChartData(
              minX: 0,
              maxX: 1,
              minY: 0,
              maxY: 1,
              xValueFormatter: formatter,
              series: const [
                LineSeriesData(
                  name: 'S',
                  color: Color(0xFF000000),
                  points: [LinePoint(x: 0, y: 0), LinePoint(x: 1, y: 1)],
                ),
              ],
            );

        Rect chartAreaFor(LineChartData data) => HandDrawnLineChartPainter(
          data: data,
          xLabelConfig: ChartLabelConfig.diagonalLeft,
        ).computeLayout(kChartTestSize).chartArea;

        final longMid = chartAreaFor(makeData(longAtMiddleOnly));
        final shortAll = chartAreaFor(makeData(shortAtAllTicks));

        // The long-middle tick contributes to the band height, so the
        // long-middle chart reserves more space at the bottom of the
        // canvas, leaving less for the chart area itself.
        expect(longMid.height, lessThan(shortAll.height));
      },
    );
  });

  // ════════════════════════════════════════════════════════════════════════
  // CHART LEGEND CONFIG — external boxed legends + standalone widget
  // ════════════════════════════════════════════════════════════════════════

  group('ChartLegendConfig integration', () {
    BarChartData barWithLegend({int entryCount = 3}) => BarChartData(
      bars: [
        const BarGroup(
          label: 'A',
          segments: [
            BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
          ],
        ),
      ],
      legend: [
        for (int i = 0; i < entryCount; i++)
          LegendEntry(label: 'Series $i', color: const Color(0xFF000000)),
      ],
    );

    test('empty legend reserves no space', () {
      // No entries → no legend rendering, no carved-out band.
      final painter = HandDrawnBarChartPainter(
        data: const BarChartData(bars: [], legend: []),
      );
      final layout = painter.computeLayout(kChartTestSize);
      // chartArea should occupy nearly the full padded area (modulo
      // the small fixed bands for axis labels). Verify there's no
      // legend-specific reservation by comparing against a reference
      // painter with an explicitly hidden legend.
      final hiddenPainter = HandDrawnBarChartPainter(
        data: const BarChartData(bars: [], legend: []),
        legendConfig: ChartLegendConfig.hidden,
      );
      final hiddenLayout = hiddenPainter.computeLayout(kChartTestSize);
      expect(layout.chartArea, equals(hiddenLayout.chartArea));
    });

    test('default inline legend reserves the historical bottom band', () {
      // Backward-compat hard guarantee: a chart with non-empty legend
      // entries and no explicit legendConfig override must reserve
      // the same number of pixels at the bottom as it always has.
      final withLegend = HandDrawnBarChartPainter(
        data: barWithLegend(),
      ).computeLayout(kChartTestSize);
      final withoutLegend = HandDrawnBarChartPainter(
        data: const BarChartData(bars: [], legend: []),
      ).computeLayout(kChartTestSize);
      // The plot rect with a legend must be at least chartLegendBandHeight
      // shorter than the no-legend plot rect.
      final delta =
          withoutLegend.chartArea.height - withLegend.chartArea.height;
      expect(delta, greaterThanOrEqualTo(18 - 0.01));
    });

    test('external bottom boxed reserves more space than inline', () {
      // The boxed preset adds padding around the entries, which
      // should produce a taller reserved band than the historical
      // floor of chartLegendBandHeight.
      final inline = HandDrawnBarChartPainter(
        data: barWithLegend(entryCount: 5),
      ).computeLayout(kChartTestSize);
      final boxed = HandDrawnBarChartPainter(
        data: barWithLegend(entryCount: 5),
        legendConfig: ChartLegendConfig.externalBottomBoxed,
      ).computeLayout(kChartTestSize);
      // Boxed must shrink the chart area at least as much as inline,
      // and typically more (the box adds padding).
      expect(
        boxed.chartArea.height,
        lessThanOrEqualTo(inline.chartArea.height),
      );
    });

    test('external right boxed shrinks chart area horizontally', () {
      final inline = HandDrawnBarChartPainter(
        data: barWithLegend(entryCount: 4),
      ).computeLayout(kChartTestSize);
      final right = HandDrawnBarChartPainter(
        data: barWithLegend(entryCount: 4),
        legendConfig: ChartLegendConfig.externalRightBoxed,
      ).computeLayout(kChartTestSize);
      expect(right.chartArea.width, lessThan(inline.chartArea.width));
      // And vertically, the right-side legend should NOT eat bottom
      // space — chartArea.height should match the same-data baseline
      // with no legend reserved (the inline preset reserves a bottom
      // band, so we use a hidden-legend baseline instead).
      final noLegendBaseline = HandDrawnBarChartPainter(
        data: barWithLegend(entryCount: 4),
        legendConfig: ChartLegendConfig.hidden,
      ).computeLayout(kChartTestSize);
      expect(
        right.chartArea.height,
        closeTo(noLegendBaseline.chartArea.height, 0.01),
      );
    });

    test('hidden preset suppresses chart-managed legend rendering', () {
      // With the hidden preset, the chart paints no legend AND
      // reserves no space, even when entries are non-empty. The
      // baseline uses the same data with `legend: []` so the
      // comparison isolates the legend's effect — bar geometry,
      // X-tick reservation, and title bands stay identical.
      final hidden = HandDrawnBarChartPainter(
        data: barWithLegend(entryCount: 3),
        legendConfig: ChartLegendConfig.hidden,
      ).computeLayout(kChartTestSize);
      final noLegend = HandDrawnBarChartPainter(
        data: BarChartData(bars: barWithLegend().bars, legend: const []),
      ).computeLayout(kChartTestSize);
      expect(hidden.chartArea, equals(noLegend.chartArea));

      // And paint must succeed without throwing.
      final recorder = PictureRecorder();
      expect(
        () => HandDrawnBarChartPainter(
          data: barWithLegend(entryCount: 3),
          legendConfig: ChartLegendConfig.hidden,
        ).paint(Canvas(recorder), kChartTestSize),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test('explicit data.legend wins over auto-derive on line charts', () {
      // Line charts auto-derive entries from series when data.legend
      // is empty; otherwise data.legend takes precedence. This test
      // locks in that contract.
      const customEntries = [
        LegendEntry(label: 'Custom A', color: Color(0xFFFF0000)),
        LegendEntry(label: 'Custom B', color: Color(0xFF00FF00)),
      ];
      const data = LineChartData(
        series: [
          LineSeriesData(
            name: 'Series 1',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 0)],
          ),
          LineSeriesData(
            name: 'Series 2',
            color: Color(0xFF111111),
            points: [LinePoint(x: 0, y: 0)],
          ),
        ],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        legend: customEntries,
      );
      final painter = HandDrawnLineChartPainter(data: data);
      expect(
        painter.legend,
        equals(customEntries),
        reason: 'data.legend should override the auto-derived list',
      );
    });

    test('scatter plot renders the legend supplied on its data', () {
      const entries = [LegendEntry(label: 'Group A', color: Color(0xFFAA0000))];
      const data = ScatterPlotData(
        points: [ScatterPoint(x: 0, y: 0)],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        legend: entries,
      );
      final painter = HandDrawnScatterPlotPainter(data: data);
      expect(painter.legend, equals(entries));
    });

    test('long legends wrap instead of disappearing', () {
      // 12 entries with long labels would silently overflow and
      // truncate under the historical inline behavior. With wrap
      // enabled, every entry must be measured and accounted for in
      // the reserved band.
      final manyEntries = [
        for (int i = 0; i < 12; i++)
          LegendEntry(
            label: 'Long label series $i',
            color: const Color(0xFF000000),
          ),
      ];
      final dataWithMany = BarChartData(
        bars: const [
          BarGroup(
            label: 'A',
            segments: [
              BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
            ],
          ),
        ],
        legend: manyEntries,
      );
      final inline = HandDrawnBarChartPainter(
        data: dataWithMany,
      ).computeLayout(kChartTestSize);
      final wrapped = HandDrawnBarChartPainter(
        data: dataWithMany,
        legendConfig: ChartLegendConfig.externalBottomBoxed,
      ).computeLayout(kChartTestSize);
      // The wrapped variant must reserve more bottom space than the
      // inline single-row case (because multiple rows need vertical
      // room).
      expect(wrapped.chartArea.height, lessThan(inline.chartArea.height));

      // And wrapped paint must succeed.
      final recorder = PictureRecorder();
      expect(
        () => HandDrawnBarChartPainter(
          data: dataWithMany,
          legendConfig: ChartLegendConfig.externalBottomBoxed,
        ).paint(Canvas(recorder), kChartTestSize),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test('boxed legends paint without throwing', () {
      for (final cfg in [
        ChartLegendConfig.externalBottomBoxed,
        ChartLegendConfig.externalRightBoxed,
      ]) {
        final recorder = PictureRecorder();
        expect(
          () => HandDrawnBarChartPainter(
            data: barWithLegend(entryCount: 4),
            legendConfig: cfg,
          ).paint(Canvas(recorder), kChartTestSize),
          returnsNormally,
          reason: 'paint failed for ${cfg.position}',
        );
        recorder.endRecording();
      }
    });

    test(
      'shouldRepaint propagates legendConfig changes for all chart types',
      () {
        final bar1 = HandDrawnBarChartPainter(data: barWithLegend());
        final bar2 = HandDrawnBarChartPainter(
          data: barWithLegend(),
          legendConfig: ChartLegendConfig.externalRightBoxed,
        );
        expect(bar2.shouldRepaint(bar1), isTrue);

        const lineData = LineChartData(
          minX: 0,
          maxX: 4,
          minY: 0,
          maxY: 50,
          series: [
            LineSeriesData(
              name: 'S',
              color: Color(0xFF000000),
              points: [LinePoint(x: 0, y: 10), LinePoint(x: 4, y: 40)],
            ),
          ],
          legend: [LegendEntry(label: 'S', color: Color(0xFF000000))],
        );
        final line1 = HandDrawnLineChartPainter(data: lineData);
        final line2 = HandDrawnLineChartPainter(
          data: lineData,
          legendConfig: ChartLegendConfig.hidden,
        );
        expect(line2.shouldRepaint(line1), isTrue);

        const scatterData = ScatterPlotData(
          minX: 0,
          maxX: 4,
          minY: 0,
          maxY: 50,
          points: [ScatterPoint(x: 1, y: 10), ScatterPoint(x: 3, y: 40)],
        );
        final s1 = HandDrawnScatterPlotPainter(data: scatterData);
        final s2 = HandDrawnScatterPlotPainter(
          data: scatterData,
          legendConfig: ChartLegendConfig.externalBottomBoxed,
        );
        expect(s2.shouldRepaint(s1), isTrue);
      },
    );

    test('reserveSpace: false renders without aborting', () {
      // When reserveSpace is false, the chart area must occupy the full
      // padded bounds (no carve-out) and the legend must still paint as
      // an overlay rather than aborting on a zero-height rect.
      const overlay = ChartLegendConfig(
        position: ChartLegendPosition.bottom,
        boxed: true,
        reserveSpace: false,
        padding: EdgeInsets.all(6),
      );
      final painter = HandDrawnLineChartPainter(
        data: lineTestData(seriesCount: 2),
        legendConfig: overlay,
      );
      final recorder = PictureRecorder();
      painter.paint(Canvas(recorder), kChartTestSize);
      // Also assert the chart area got the FULL padded bounds
      // (overlay legend doesn't carve out space).
      final layoutWith = painter.computeLayout(kChartTestSize);
      final layoutWithout = HandDrawnLineChartPainter(
        data: lineTestData(seriesCount: 2),
        legendConfig: ChartLegendConfig.hidden,
      ).computeLayout(kChartTestSize);
      expect(layoutWith.chartArea.height, layoutWithout.chartArea.height);
    });

    test('right-side legend caps column width to half of padded bounds', () {
      // The right-side legend column is hard-capped at half the padded
      // width, so even a label long enough to fill the entire chart
      // horizontally can't collapse the plot area.
      const longLabel =
          'A label so long it would otherwise overflow horizontally beyond any reasonable column';
      const data = LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        series: [
          LineSeriesData(
            name: 'S',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 0), LinePoint(x: 1, y: 1)],
          ),
        ],
        legend: [LegendEntry(label: longLabel, color: Color(0xFF000000))],
      );

      final layout = HandDrawnLineChartPainter(
        data: data,
        legendConfig: ChartLegendConfig.externalRightBoxed,
      ).computeLayout(kChartTestSize);

      // Padded width is kChartTestSize.width minus default chart
      // padding. The right-column cap is paddedBounds.width / 2;
      // therefore chartArea.right loses at MOST ~paddedWidth/2
      // relative to the no-legend baseline.
      final baseline = HandDrawnLineChartPainter(
        data: data,
        legendConfig: ChartLegendConfig.hidden,
      ).computeLayout(kChartTestSize);

      final reservedWidth = baseline.chartArea.right - layout.chartArea.right;
      // Strictly: cap = paddedBounds.width / 2 + small entry-gap.
      // Loose-bound here at half of overall canvas width which
      // dominates paddedBounds.width / 2.
      expect(reservedWidth, lessThanOrEqualTo(kChartTestSize.width / 2));
      expect(reservedWidth, greaterThan(0));
    });

    test('bottom legend constrains long single label width', () {
      // A single very long label on a bottom legend must be measured
      // against the chart's available width — otherwise the entry
      // would lay out unbounded and visually spill past the chart's
      // right edge. The painter relies on the layout to bound
      // individual entry widths so the painted result stays inside
      // the chart's footprint.
      const longLabel =
          'An exceptionally long legend label that on its own '
          'would exceed any reasonable single-row legend width';
      const data = LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        series: [
          LineSeriesData(
            name: 'S',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 0), LinePoint(x: 1, y: 1)],
          ),
        ],
        legend: [LegendEntry(label: longLabel, color: Color(0xFF000000))],
      );

      final painter = HandDrawnLineChartPainter(
        data: data,
        legendConfig: ChartLegendConfig.externalBottomBoxed,
      );
      final recorder = PictureRecorder();
      painter.paint(Canvas(recorder), kChartTestSize);
      recorder.endRecording();

      final frame = painter.frame;
      expect(frame.legendLayout, isNotNull);
      expect(
        frame.legendLayout!.size.width,
        lessThanOrEqualTo(frame.legendArea.width + 0.01),
        reason:
            'Bottom legend content width must not exceed the legend rect '
            'so individual long entries cannot spill past chart bounds.',
      );
    });

    test('right-side legend content fits inside its reserved column', () {
      // Long label that would saturate the column width budget. With
      // the right-side legend's measurement budget aligned to the
      // legendArea's actual width, the measured layout always fits
      // inside the reserved box. Long single-word labels still follow
      // TextPainter's normal overflow behavior — the cap governs
      // measurement, not glyph shaping.
      const longLabel =
          'A label so long it would otherwise overflow '
          'horizontally beyond any reasonable legend column';
      const data = LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        series: [
          LineSeriesData(
            name: 'S',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 0), LinePoint(x: 1, y: 1)],
          ),
        ],
        legend: [LegendEntry(label: longLabel, color: Color(0xFF000000))],
      );

      final painter = HandDrawnLineChartPainter(
        data: data,
        legendConfig: ChartLegendConfig.externalRightBoxed,
      );

      // Paint succeeds without throwing — exercises the full
      // measure → reserve → render path for the wide-label case.
      final recorder = PictureRecorder();
      expect(
        () => painter.paint(Canvas(recorder), kChartTestSize),
        returnsNormally,
      );
      recorder.endRecording();

      // Core invariant: the measured legend content must fit within
      // the rect carved out for it. If the measurement budget and the
      // reserved column width drift apart, this fails.
      final frame = painter.frame;
      expect(frame.legendLayout, isNotNull);
      expect(
        frame.legendLayout!.size.width,
        lessThanOrEqualTo(frame.legendArea.width),
        reason: 'Legend content width must not exceed its reserved area',
      );
    });

    test('right legend with many entries paints without throwing', () {
      // Many entries can lay out taller than the reserved column. The
      // painter must clip its output rather than paint past the
      // reserved rect or otherwise fail.
      final manyEntries = [
        for (int i = 0; i < 30; i++)
          LegendEntry(label: 'Series $i', color: const Color(0xFF000000)),
      ];
      final painter = HandDrawnBarChartPainter(
        data: BarChartData(
          bars: const [
            BarGroup(
              label: 'A',
              segments: [
                BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
              ],
            ),
          ],
          legend: manyEntries,
        ),
        legendConfig: ChartLegendConfig.externalRightBoxed,
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(() => painter.paint(canvas, kChartTestSize), returnsNormally);
      recorder.endRecording();
    });
  });

  group('HandDrawnLegend standalone widget', () {
    testWidgets('renders provided entries', (tester) async {
      const entries = [
        LegendEntry(label: 'Apples', color: Color(0xFFFF0000)),
        LegendEntry(label: 'Pears', color: Color(0xFF00FF00)),
        LegendEntry(label: 'Plums', color: Color(0xFF0000FF)),
      ];
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: HandDrawnLegend(entries: entries),
            ),
          ),
        ),
      );
      // Widget should mount without errors and find a CustomPaint
      // descendant (its render surface).
      expect(find.byType(HandDrawnLegend), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('entry label Text uses single-line ellipsis', (tester) async {
      // Long labels under bounded width must truncate gracefully
      // rather than overflow the legend's footprint.
      const entries = [
        LegendEntry(
          label: 'An extremely long legend label that should ellipsize',
          color: Color(0xFFFF0000),
        ),
      ];
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: HandDrawnLegend(entries: entries),
            ),
          ),
        ),
      );
      // Layout must complete without RenderFlex overflow exceptions.
      expect(tester.takeException(), isNull);

      final labelText = tester.widget<Text>(find.text(entries.first.label));
      expect(labelText.maxLines, 1);
      expect(labelText.overflow, TextOverflow.ellipsis);
    });

    testWidgets('empty entries produce a zero-size shrink', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HandDrawnLegend(entries: [])),
        ),
      );
      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('HandDrawnLegend hides itself when config.visible is false', (
      tester,
    ) async {
      // HandDrawnLegend honors config.visible: a hidden config
      // suppresses all rendering even when entries are non-empty.
      const entries = [
        LegendEntry(label: 'Apples', color: Color(0xFFFF0000)),
        LegendEntry(label: 'Pears', color: Color(0xFF00FF00)),
      ];
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandDrawnLegend(
              entries: entries,
              config: ChartLegendConfig.hidden,
            ),
          ),
        ),
      );
      // Hidden — no entry text should render anywhere in the tree.
      expect(find.text('Apples'), findsNothing);
      expect(find.text('Pears'), findsNothing);
    });

    testWidgets('HandDrawnLegend non-wrap mode does not flex-overflow', (
      tester,
    ) async {
      // Non-wrapping HandDrawnLegend lays entries out in an unbounded-
      // width Row clipped to the parent's bounds, so overflowing
      // entries don't trigger a Flex Overflow assertion in debug.
      // pumpWidget surfaces overflow as a thrown exception, so a clean
      // pump is sufficient assertion.
      const longEntries = [
        LegendEntry(
          label: 'Entry one with a long descriptive label',
          color: Color(0xFFFF0000),
        ),
        LegendEntry(
          label: 'Entry two with a long descriptive label',
          color: Color(0xFF00FF00),
        ),
        LegendEntry(
          label: 'Entry three with a long descriptive label',
          color: Color(0xFF0000FF),
        ),
      ];
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 100,
              child: HandDrawnLegend(
                entries: longEntries,
                config: ChartLegendConfig(wrap: false),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
