import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show listEquals;

import '../hand_drawn_constants.dart'
    show chartGridColor, chartGridStrokeWidth, chartGridJitterRatio;

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

/// How an axis line should be drawn.
///
/// - [edge]: the default. Horizontal axis drawn at the chart bottom;
///   vertical axis drawn at the chart left.
/// - [zeroCrossing]: when the axis is numeric and zero is inside the
///   visible range, draw the axis line at the zero position instead of
///   the chart edge. Tick labels remain in their outer label bands.
///   Falls back to [edge] behavior when zero is outside the visible
///   range.
enum AxisDisplayMode { edge, zeroCrossing }

/// Per-axis display configuration for numeric charts.
///
/// Both axes default to [AxisDisplayMode.edge] — the existing behavior.
/// Opt into zero-crossing axes explicitly:
///
/// ```dart
/// LineChartData(
///   axisDisplay: const AxisDisplay(
///     horizontal: AxisDisplayMode.zeroCrossing,
///     vertical: AxisDisplayMode.zeroCrossing,
///   ),
///   // ...
/// )
/// ```
///
/// **Fall-back rules.** Zero-crossing only takes effect when zero is
/// strictly inside the relevant range; otherwise the axis silently
/// reverts to its chart edge:
///
/// - [horizontal] zero-crossing requires `minY < 0 < maxY`.
/// - [vertical] zero-crossing requires a numeric X scale (i.e. the
///   chart actually has `minX`/`maxX` configured) AND `minX < 0 < maxX`.
///   On categorical-X charts the vertical axis stays at the chart's
///   left edge regardless of this setting.
///
/// Tick labels are unaffected — they always render in the bottom band
/// (X) and left gutter (Y) regardless of axis mode.
class AxisDisplay {
  const AxisDisplay({
    this.horizontal = AxisDisplayMode.edge,
    this.vertical = AxisDisplayMode.edge,
  });

  /// Display mode for the horizontal (X) axis line.
  final AxisDisplayMode horizontal;

  /// Display mode for the vertical (Y) axis line.
  final AxisDisplayMode vertical;

  static const AxisDisplay edge = AxisDisplay();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AxisDisplay &&
          horizontal == other.horizontal &&
          vertical == other.vertical;

  @override
  int get hashCode => Object.hash(horizontal, vertical);
}

/// Visual configuration for a chart's background grid.
///
/// Bundles styling, visibility, and density controls into a single
/// immutable value. Replaces the older flat `gridColor` /
/// `gridStrokeWidth` / `gridJitterRatio` painter fields — they are now
/// accessed as `grid.color`, `grid.strokeWidth`, etc.
///
/// The defaults ([GridConfig.standard]) render both axes' grid lines
/// at each tick position with no sub-divisions. To hide a grid,
/// combine with one of the named presets:
///
/// ```dart
/// HandDrawnLineChart(
///   data: data,
///   grid: GridConfig.horizontalOnly,  // no vertical lines
/// )
/// ```
///
/// Sub-grid lines ([horizontalSubGridLinesBetweenTicks] and
/// [verticalSubGridLinesBetweenTicks]) insert N additional lines
/// between each pair of tick-aligned grid lines. Those lines render
/// at [subGridAlphaMultiplier] of the main grid color's alpha, giving
/// a graph-paper-style two-tier grid without visual noise. A value of
/// `0` (the default) disables the feature.
///
/// Vertical grid lines only render for charts with a numeric X axis
/// (line and scatter plots with `minX`/`maxX` set). Bar charts and
/// categorical-X line charts ignore [showVertical].
class GridConfig {
  const GridConfig({
    this.color = chartGridColor,
    this.strokeWidth = chartGridStrokeWidth,
    this.jitterRatio = chartGridJitterRatio,
    this.showHorizontal = true,
    this.showVertical = true,
    this.horizontalSubGridLinesBetweenTicks = 0,
    this.verticalSubGridLinesBetweenTicks = 0,
    this.subGridAlphaMultiplier = 0.6,
  }) : assert(
         horizontalSubGridLinesBetweenTicks >= 0,
         'horizontalSubGridLinesBetweenTicks must be non-negative',
       ),
       assert(
         verticalSubGridLinesBetweenTicks >= 0,
         'verticalSubGridLinesBetweenTicks must be non-negative',
       ),
       assert(
         subGridAlphaMultiplier >= 0 && subGridAlphaMultiplier <= 1,
         'subGridAlphaMultiplier must be in [0, 1]',
       );

  /// Grid line color. Applied to both horizontal and vertical grids.
  final Color color;

  /// Stroke width of grid lines in logical pixels.
  final double strokeWidth;

  /// Irregularity multiplier applied to the grid-line wobble. Lower
  /// values produce straighter grid lines (keeping them visually
  /// distinct from data).
  final double jitterRatio;

  /// Whether to draw horizontal (Y-division) grid lines.
  final bool showHorizontal;

  /// Whether to draw vertical (X-division) grid lines. Only applies
  /// to charts with a numeric X axis; categorical-X charts ignore it.
  final bool showVertical;

  /// Extra horizontal grid lines to insert between each pair of
  /// tick-aligned horizontal grid lines. `0` disables sub-grids.
  final int horizontalSubGridLinesBetweenTicks;

  /// Extra vertical grid lines to insert between each pair of
  /// tick-aligned vertical grid lines. `0` disables sub-grids.
  final int verticalSubGridLinesBetweenTicks;

  /// Alpha multiplier applied to [color] when drawing sub-grid lines.
  /// `1.0` makes sub-grid lines visually identical to main grid lines;
  /// lower values produce the familiar graph-paper two-tier look.
  final double subGridAlphaMultiplier;

  /// Default configuration — both grids shown at every tick with no
  /// sub-divisions. Matches the pre-GridConfig behavior exactly.
  static const GridConfig standard = GridConfig();

  /// No grid lines at all.
  static const GridConfig none = GridConfig(
    showHorizontal: false,
    showVertical: false,
  );

  /// Horizontal grid only (no vertical lines even on numeric-X charts).
  static const GridConfig horizontalOnly = GridConfig(showVertical: false);

  /// Vertical grid only (useful for categorical-Y charts, though most
  /// charts in this package have numeric Y).
  static const GridConfig verticalOnly = GridConfig(showHorizontal: false);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GridConfig &&
          color == other.color &&
          strokeWidth == other.strokeWidth &&
          jitterRatio == other.jitterRatio &&
          showHorizontal == other.showHorizontal &&
          showVertical == other.showVertical &&
          horizontalSubGridLinesBetweenTicks ==
              other.horizontalSubGridLinesBetweenTicks &&
          verticalSubGridLinesBetweenTicks ==
              other.verticalSubGridLinesBetweenTicks &&
          subGridAlphaMultiplier == other.subGridAlphaMultiplier;

  @override
  int get hashCode => Object.hash(
    color,
    strokeWidth,
    jitterRatio,
    showHorizontal,
    showVertical,
    horizontalSubGridLinesBetweenTicks,
    verticalSubGridLinesBetweenTicks,
    subGridAlphaMultiplier,
  );
}

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

/// A single x-axis category that may contain one or more side-by-side
/// bars (grouped bars). Each inner [BarGroup] can still contain stacked
/// [BarSegment]s — grouping and stacking compose cleanly.
///
/// For backward compatibility, a `BarChartData.bars` entry that is a
/// plain [BarGroup] is treated internally as a single-bar category whose
/// [label] matches the group's label. You only need [BarCategory]
/// directly when you want more than one bar per x-axis tick.
class BarCategory {
  // The `bars` list should be non-empty in practice (an empty category
  // renders nothing). We can't assert this in the constructor because
  // const-constructor assertions cannot evaluate `.length` or
  // `.isNotEmpty` on a parameter of type `List<T>` — the const
  // evaluator only sees the declared type, not the runtime const-ness
  // of the passed value. Keeping the constructor `const` matters more
  // here than the runtime check, since it lets `BarChartData` itself
  // remain const-constructible when grouped bars are used.
  const BarCategory({required this.label, required this.bars});

  /// X-axis label for this category (e.g. "Mon", "Q1").
  final String label;

  /// One or more bars to render side-by-side within this category slot.
  /// Each bar may contain stacked segments.
  final List<BarGroup> bars;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BarCategory &&
          label == other.label &&
          listEquals(bars, other.bars);

  @override
  int get hashCode => Object.hash(label, Object.hashAll(bars));
}

/// Complete data for rendering a bar chart (stacked, grouped, or both).
///
/// Two input shapes are supported:
///
/// - **Legacy / ungrouped**: pass [bars]. Each [BarGroup] occupies one
///   x-axis tick and may contain stacked segments. This is the original
///   API and continues to behave identically.
/// - **Grouped**: pass [categories]. Each [BarCategory] occupies one
///   x-axis tick and contains one or more side-by-side bars (each of
///   which may still be stacked). When [categories] is non-empty it
///   takes precedence over [bars].
///
/// By default, the Y-axis scales from 0 to the **tallest inner bar**
/// across all categories — so grouped bars sized by the maximum sibling,
/// not the sum. Pass [minY] and/or [maxY] to override the Y-axis range
/// (for example, to add headroom above bars for value labels).
///
/// Legend semantics are explicit: provide [legend] entries that match
/// how you intend colors to be interpreted. The chart does not infer
/// legend identity from grouped structure.
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
    this.categories = const [],
  });

  /// Optional chart title rendered above the chart area.
  final String? title;

  final List<BarGroup> bars;

  /// Optional grouped-bar layout. When non-empty, this takes precedence
  /// over [bars]: each [BarCategory] occupies one x-axis slot and
  /// contains one or more side-by-side bars (each of which may still be
  /// stacked). When empty, the chart renders from [bars] as before.
  ///
  /// To keep a single API surface, [resolvedCategories] always returns
  /// the effective category list — either [categories], or a
  /// one-bar-per-category projection of [bars].
  final List<BarCategory> categories;

  /// Effective category list used by the renderer. Returns [categories]
  /// when non-empty; otherwise projects each [BarGroup] in [bars] into a
  /// single-bar category that preserves the current data shape.
  List<BarCategory> get resolvedCategories {
    if (categories.isNotEmpty) return categories;
    return [
      for (final b in bars) BarCategory(label: b.label, bars: [b]),
    ];
  }

  /// Whether any category in this chart contains more than one bar.
  bool get hasGroupedBars => categories.any((c) => c.bars.length > 1);

  final List<LegendEntry> legend;

  /// Optional Y-axis title rendered rotated along the left edge.
  final String? yAxisLabel;

  /// Optional X-axis title rendered below the X tick labels.
  final String? xAxisLabel;

  /// Optional Y-axis minimum. Defaults to `0` when null.
  final double? minY;

  /// Optional Y-axis maximum. When null, defaults to the tallest inner
  /// bar's total across all categories (see class-level documentation
  /// for the full max-not-sum scaling rule).
  final double? maxY;

  /// Optional formatter for Y-axis tick labels. When null, the default
  /// neutral numeric formatter is used.
  final AxisValueFormatter? yValueFormatter;

  bool get isEmpty => bars.isEmpty && categories.isEmpty;

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
          yValueFormatter == other.yValueFormatter &&
          listEquals(categories, other.categories);

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
    Object.hashAll(categories),
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
    this.axisDisplay = AxisDisplay.edge,
  });

  /// Axis display configuration. Defaults to edge-aligned axes (current
  /// behavior). Set to enable zero-crossing axes for charts with mixed
  /// positive/negative values.
  final AxisDisplay axisDisplay;

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
          xValueFormatter == other.xValueFormatter &&
          axisDisplay == other.axisDisplay;

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
    axisDisplay,
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
    this.axisDisplay = AxisDisplay.edge,
  });

  /// Axis display configuration. Defaults to edge-aligned axes (current
  /// behavior). Set to enable zero-crossing axes for plots with mixed
  /// positive/negative values.
  final AxisDisplay axisDisplay;

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
          xValueFormatter == other.xValueFormatter &&
          axisDisplay == other.axisDisplay;

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
    axisDisplay,
  );
}
