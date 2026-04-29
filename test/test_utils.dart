import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

// ── Wrappers ──────────────────────────────────────────────────────────────

/// Wraps [child] in a [MaterialApp] + [Scaffold] for widget tests.
Widget testApp(Widget child) => MaterialApp(home: Scaffold(body: child));

/// Redirects [FlutterError.onError] for the duration of [body], collecting
/// all errors instead of failing the test. Returns the captured errors so
/// the caller can assert on their content.
///
/// Use this when a widget is expected to emit layout or assertion errors
/// during build, and the test needs to inspect those errors rather than
/// let them fail the harness.
Future<List<FlutterErrorDetails>> captureFlutterErrors(
  Future<void> Function() body,
) async {
  final captured = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = (details) => captured.add(details);
  try {
    await body();
  } finally {
    FlutterError.onError = previous;
  }
  return captured;
}

/// Finds [CustomPaint] widgets whose painter or foregroundPainter is a
/// [HandDrawnLinePainter]. Filters out framework-internal CustomPaint
/// instances (Scaffold, Material, etc.).
Finder findHandDrawnPaint() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        (widget.painter is HandDrawnLinePainter ||
            widget.foregroundPainter is HandDrawnLinePainter),
  );
}

// ── Shared test constants ─────────────────────────────────────────────────

/// Canonical canvas size for painter / layout tests across the suite.
///
/// All chart test files use the same size so that painters produce
/// directly-comparable layouts and assertions on chart area dimensions
/// don't drift between files. Prefer this over a file-local `_size`.
const Size kChartTestSize = Size(400, 300);

// ── Shared chart-test data factories ──────────────────────────────────────

/// Generic bar-chart test data. Single-segment bars, monotonic values,
/// one legend entry. Pass `barCount` to control the number of bars and
/// the title/axis-label parameters when a test needs them populated.
BarChartData barTestData({
  int barCount = 3,
  String? title,
  String? yAxisLabel,
  String? xAxisLabel,
  double? minY,
  double? maxY,
}) {
  return BarChartData(
    title: title,
    yAxisLabel: yAxisLabel,
    xAxisLabel: xAxisLabel,
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
    legend: const [LegendEntry(label: 'Category', color: Color(0xFF6B9BD2))],
  );
}

/// Generic line-chart test data. Linear ramp from (0, 10) to
/// (pointCount-1, pointCount*10), seriesCount distinct series.
LineChartData lineTestData({
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

/// Generic scatter-plot test data. pointCount points along a diagonal.
ScatterPlotData scatterTestData({
  int pointCount = 5,
  String? title,
  String xAxisLabel = 'Weight',
  String yAxisLabel = 'Height',
}) {
  return ScatterPlotData(
    title: title,
    xAxisLabel: xAxisLabel,
    yAxisLabel: yAxisLabel,
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
