import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show listEquals;

/// Generic color mapping keyed by category name (e.g., "completed",
/// "skipped", "primary").
typedef ChartColorPalette = Map<String, Color>;

/// Optional callback for formatting axis tick values.
///
/// When provided on a chart data model, this replaces the default numeric
/// formatter for the corresponding axis. For example:
///
/// ```dart
/// LineChartData(
///   yValueFormatter: (v) => '${v.toStringAsFixed(1)} kg',
///   // ...
/// )
/// ```
typedef AxisValueFormatter = String Function(double value);

/// A single entry in a chart legend.
class LegendEntry {
  const LegendEntry({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LegendEntry && label == other.label && color == other.color;

  @override
  int get hashCode => Object.hash(label, color);
}

// ── Bar Chart ──────────────────────────────────────────────────────────────

/// One segment within a stacked bar.
///
/// The [value] must be non-negative. This is enforced by a debug assertion
/// here and by release-safe validation in [HandDrawnBarChartPainter].
///
/// By default, segments are filled with a translucent version of [color].
/// Use [fillColor] to set a completely different fill hue, or [fillAlpha]
/// to control fill opacity (0.0 = empty, 1.0 = solid). Both are optional
/// and can be combined.
class BarSegment {
  const BarSegment({
    required this.category,
    required this.value,
    required this.color,
    this.fillColor,
    this.fillAlpha,
  }) : assert(value >= 0, 'BarSegment.value must be non-negative, got $value'),
       assert(
         fillAlpha == null || (fillAlpha >= 0 && fillAlpha <= 1),
         'BarSegment.fillAlpha must be between 0 and 1, got $fillAlpha',
       );

  final String category;
  final double value;
  final Color color;

  /// Optional fill color. When null, falls back to [color].
  final Color? fillColor;

  /// Optional fill opacity. When null, falls back to the default (0.15).
  /// Use `0.0` for an empty (unfilled) bar or `1.0` for a fully solid fill.
  final double? fillAlpha;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarSegment &&
          category == other.category &&
          value == other.value &&
          color == other.color &&
          fillColor == other.fillColor &&
          fillAlpha == other.fillAlpha;

  @override
  int get hashCode => Object.hash(category, value, color, fillColor, fillAlpha);
}

/// One bar in a bar chart (may contain multiple stacked segments).
///
/// All segments must have non-negative values. This is enforced by
/// [BarSegment]'s debug assertion and by release-safe validation in
/// [HandDrawnBarChartPainter].
class BarGroup {
  const BarGroup({required this.label, required this.segments});

  /// X-axis label (e.g., "Mon", "Mar 15", "Week 12").
  final String label;

  /// Segments stacked within this bar, bottom to top.
  final List<BarSegment> segments;

  /// Sum of all segment values. Always non-negative because the package
  /// enforces a non-negative policy on segment values — via debug
  /// assertions on [BarSegment] and release-safe validation in
  /// [HandDrawnBarChartPainter].
  double get total => segments.fold(0.0, (sum, s) => sum + s.value);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarGroup &&
          label == other.label &&
          listEquals(segments, other.segments);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(segments));
}

/// Complete data for rendering a bar chart (stacked or single).
///
/// By default, bars scale from 0 to the tallest bar total. Pass [minY]
/// and/or [maxY] to override the Y-axis range — for example, to add
/// headroom above bars for value labels.
class BarChartData {
  const BarChartData({
    required this.bars,
    required this.legend,
    this.title,
    this.yAxisLabel,
    this.xAxisLabel,
    this.minY,
    this.maxY,
    this.yValueFormatter,
  });

  /// Optional chart title rendered above the chart area.
  final String? title;

  final List<BarGroup> bars;
  final List<LegendEntry> legend;

  /// Optional Y-axis title rendered rotated along the left edge.
  final String? yAxisLabel;

  /// Optional X-axis title rendered below the X tick labels.
  final String? xAxisLabel;

  /// Optional Y-axis minimum. Defaults to `0` when null.
  final double? minY;

  /// Optional Y-axis maximum. Defaults to the tallest bar total when null.
  final double? maxY;

  /// Optional formatter for Y-axis tick labels. When null, the default
  /// neutral numeric formatter is used.
  final AxisValueFormatter? yValueFormatter;

  bool get isEmpty => bars.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarChartData &&
          title == other.title &&
          listEquals(bars, other.bars) &&
          listEquals(legend, other.legend) &&
          yAxisLabel == other.yAxisLabel &&
          xAxisLabel == other.xAxisLabel &&
          minY == other.minY &&
          maxY == other.maxY &&
          yValueFormatter == other.yValueFormatter;

  @override
  int get hashCode => Object.hash(
    title,
    Object.hashAll(bars),
    Object.hashAll(legend),
    yAxisLabel,
    xAxisLabel,
    minY,
    maxY,
    yValueFormatter,
  );
}

// ── Line Chart ─────────────────────────────────────────────────────────────

/// A single point on a line chart.
///
/// Points are positioned using their [x] and [y] values. The [x] value
/// determines horizontal placement within the chart's `minX`–`maxX` range.
class LinePoint {
  const LinePoint({required this.x, required this.y});

  /// Numeric X value used for horizontal positioning.
  final double x;

  /// Numeric Y value used for vertical positioning.
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LinePoint && x == other.x && y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// One line series within a line chart.
///
/// For coherent line rendering, [points] should be sorted by
/// [LinePoint.x] in ascending order. Unsorted points will still render
/// but may produce crossing line segments.
class LineSeriesData {
  const LineSeriesData({
    required this.name,
    required this.points,
    required this.color,
  });

  /// Display name for this series. Used for auto-generated legend entries
  /// in multi-series charts.
  final String name;

  final List<LinePoint> points;
  final Color color;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineSeriesData &&
          name == other.name &&
          listEquals(points, other.points) &&
          color == other.color;

  @override
  int get hashCode => Object.hash(name, Object.hashAll(points), color);
}

/// Complete data for rendering a line chart (single or multi-series).
///
/// The X axis supports two modes:
///
/// - **Numeric mode** (default): omit [xLabels] and the chart auto-generates
///   numeric tick labels from [minX]–[maxX].
/// - **Categorical mode**: provide [xLabels] and the chart renders them as
///   evenly spaced string labels. Points are still positioned by [LinePoint.x].
class LineChartData {
  const LineChartData({
    required this.series,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    this.xLabels = const [],
    this.title,
    this.yAxisLabel,
    this.xAxisLabel,
    this.yValueFormatter,
    this.xValueFormatter,
  });

  /// Optional chart title rendered above the chart area.
  final String? title;

  final List<LineSeriesData> series;

  /// Categorical X-axis labels. When non-empty, these are rendered as
  /// evenly spaced string labels instead of auto-generated numeric ticks.
  ///
  /// **Important:** labels replace the tick text only — points are still
  /// positioned by their numeric [LinePoint.x] values. For intuitive
  /// categorical behavior, use consecutive integer X values (`0, 1, 2, …`)
  /// and provide a matching-length [xLabels] list:
  ///
  /// ```dart
  /// LineChartData(
  ///   minX: 0, maxX: 2,
  ///   xLabels: ['Mon', 'Tue', 'Wed'],
  ///   series: [
  ///     LineSeriesData(
  ///       name: 'Sales',
  ///       color: Colors.blue,
  ///       points: [
  ///         LinePoint(x: 0, y: 10),
  ///         LinePoint(x: 1, y: 24),
  ///         LinePoint(x: 2, y: 18),
  ///       ],
  ///     ),
  ///   ],
  /// )
  /// ```
  final List<String> xLabels;

  /// Optional Y-axis title rendered rotated along the left edge.
  final String? yAxisLabel;

  /// Optional X-axis title rendered below the X tick labels.
  final String? xAxisLabel;

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  /// Optional formatter for Y-axis tick labels.
  final AxisValueFormatter? yValueFormatter;

  /// Optional formatter for X-axis tick labels (numeric mode only).
  final AxisValueFormatter? xValueFormatter;

  bool get isEmpty => series.every((s) => s.points.isEmpty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineChartData &&
          title == other.title &&
          listEquals(series, other.series) &&
          listEquals(xLabels, other.xLabels) &&
          yAxisLabel == other.yAxisLabel &&
          xAxisLabel == other.xAxisLabel &&
          minX == other.minX &&
          maxX == other.maxX &&
          minY == other.minY &&
          maxY == other.maxY &&
          yValueFormatter == other.yValueFormatter &&
          xValueFormatter == other.xValueFormatter;

  @override
  int get hashCode => Object.hash(
    title,
    Object.hashAll(series),
    Object.hashAll(xLabels),
    yAxisLabel,
    xAxisLabel,
    minX,
    maxX,
    minY,
    maxY,
    yValueFormatter,
    xValueFormatter,
  );
}

// ── Scatter Plot ───────────────────────────────────────────────────────────

/// A single point on a scatter plot.
///
/// Each point is positioned at ([x], [y]) within the plot's range.
/// An optional [size] controls the dot radius in logical pixels
/// (defaults to 5.0).
class ScatterPoint {
  const ScatterPoint({required this.x, required this.y, this.size})
    : assert(size == null || size > 0, 'size must be positive when provided');

  final double x;
  final double y;

  /// Dot radius in logical pixels. Defaults to 5.0 when null.
  final double? size;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterPoint &&
          x == other.x &&
          y == other.y &&
          size == other.size;

  @override
  int get hashCode => Object.hash(x, y, size);
}

/// Complete data for rendering a scatter plot.
class ScatterPlotData {
  const ScatterPlotData({
    required this.points,
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
    this.xAxisLabel,
    this.yAxisLabel,
    this.title,
    this.yValueFormatter,
    this.xValueFormatter,
  });

  /// Optional chart title rendered above the chart area.
  final String? title;

  final List<ScatterPoint> points;

  /// Optional X-axis title rendered below the X tick labels.
  final String? xAxisLabel;

  /// Optional Y-axis title rendered rotated along the left edge.
  final String? yAxisLabel;

  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  /// Optional formatter for Y-axis tick labels.
  final AxisValueFormatter? yValueFormatter;

  /// Optional formatter for X-axis tick labels.
  final AxisValueFormatter? xValueFormatter;

  bool get isEmpty => points.isEmpty;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScatterPlotData &&
          title == other.title &&
          listEquals(points, other.points) &&
          xAxisLabel == other.xAxisLabel &&
          yAxisLabel == other.yAxisLabel &&
          minX == other.minX &&
          maxX == other.maxX &&
          minY == other.minY &&
          maxY == other.maxY &&
          yValueFormatter == other.yValueFormatter &&
          xValueFormatter == other.xValueFormatter;

  @override
  int get hashCode => Object.hash(
    title,
    Object.hashAll(points),
    xAxisLabel,
    yAxisLabel,
    minX,
    maxX,
    minY,
    maxY,
    yValueFormatter,
    xValueFormatter,
  );
}
