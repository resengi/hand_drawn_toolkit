import 'dart:math' as math;
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/painting.dart' show EdgeInsets;

import '../hand_drawn_constants.dart'
    show
        chartGridColor,
        chartGridJitterRatio,
        chartGridStrokeWidth,
        chartLabelThinningGap,
        chartLegendEntryGap,
        defaultSampleCount,
        defaultWobbleAnchorStride;

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

/// Visual configuration for axis tick labels (currently the X-axis tick
/// label band).
///
/// Bundles rotation, label-thinning sensitivity, and any future label
/// styling concerns into a single immutable value. The default
/// ([ChartLabelConfig.horizontal]) is no rotation — opt into rotation
/// explicitly:
///
/// ```dart
/// HandDrawnBarChart(
///   data: data,
///   xLabelConfig: const ChartLabelConfig(rotationDegrees: -45),
/// )
/// ```
///
/// Or use one of the named presets:
///
/// ```dart
/// xLabelConfig: ChartLabelConfig.diagonalLeft,   // -45°, slants down to the left
/// xLabelConfig: ChartLabelConfig.diagonalRight,  // +45°, slants up to the right
/// xLabelConfig: ChartLabelConfig.vertical,       // -90°, fully vertical
/// ```
///
/// **How rotation is measured.** Angles are in degrees, anchored at the
/// label's tick. Negative angles tilt the label so its trailing end
/// drops below the tick (the typical "long category labels rotated
/// out of the way" look). Positive angles tilt the leading end down.
/// `0` keeps labels horizontal.
///
/// **Layout effect.** When [rotationDegrees] is non-zero, the X tick
/// label band's reserved height is computed from the rotated bounds
/// of the longest label rather than a fixed constant, so any X-axis
/// title sitting below the labels still has room. Label thinning also
/// uses the rotated label width — a label that fits horizontally may
/// not fit at 45° and vice versa.
///
/// Rotation reserves vertical space in the X tick band but does not
/// adjust the chart's horizontal padding. For long edge labels with
/// diagonal or vertical rotation, increase the chart widget's
/// `padding.left` and/or `padding.right` to prevent spill into the
/// Y-label gutter or past the right edge.
class ChartLabelConfig {
  const ChartLabelConfig({
    this.rotationDegrees = 0,
    this.minVisibleGap = chartLabelThinningGap,
  }) : assert(
         // value.isFinite is not const-evaluable, so we open-code the
         // same predicate: NaN fails the self-equality test, and the
         // two infinities are rejected explicitly.
         rotationDegrees == rotationDegrees &&
             rotationDegrees != double.infinity &&
             rotationDegrees != double.negativeInfinity,
         'ChartLabelConfig.rotationDegrees must be finite',
       ),
       assert(
         minVisibleGap == minVisibleGap &&
             minVisibleGap != double.infinity &&
             minVisibleGap >= 0,
         'ChartLabelConfig.minVisibleGap must be finite and non-negative',
       );

  /// Rotation in degrees. `0` is horizontal (the default).
  /// Negative values rotate counter-clockwise, positive clockwise.
  final double rotationDegrees;

  /// Minimum visible gap between adjacent tick labels in pixels, used
  /// by the thinning algorithm to decide how many labels can fit. Larger
  /// values produce sparser label spacing; smaller values pack more
  /// labels in. Defaults to [chartLabelThinningGap].
  final double minVisibleGap;

  /// Rotation in radians (derived from [rotationDegrees]).
  double get rotationRadians => rotationDegrees * math.pi / 180.0;

  /// Whether this config requests any rotation at all. When `false`,
  /// painters can take a fast horizontal path that skips the rotation
  /// math entirely.
  bool get isRotated => rotationDegrees != 0;

  /// Default horizontal labels. Same instance as the no-arg constructor;
  /// kept as a named constant for readability at call sites.
  static const ChartLabelConfig horizontal = ChartLabelConfig();

  /// Labels rotated -45° (slanted so the right end drops below the tick).
  /// A common, readable choice for long category labels.
  static const ChartLabelConfig diagonalLeft = ChartLabelConfig(
    rotationDegrees: -45,
  );

  /// Labels rotated +45° (slanted so the left end drops below the tick).
  static const ChartLabelConfig diagonalRight = ChartLabelConfig(
    rotationDegrees: 45,
  );

  /// Labels rotated -90° (fully vertical, reading bottom-to-top from
  /// the tick downward).
  static const ChartLabelConfig vertical = ChartLabelConfig(
    rotationDegrees: -90,
  );

  /// Returns a copy of this config with the given fields replaced.
  /// Fields not specified retain their current value.
  ChartLabelConfig copyWith({double? rotationDegrees, double? minVisibleGap}) {
    return ChartLabelConfig(
      rotationDegrees: rotationDegrees ?? this.rotationDegrees,
      minVisibleGap: minVisibleGap ?? this.minVisibleGap,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartLabelConfig &&
          rotationDegrees == other.rotationDegrees &&
          minVisibleGap == other.minVisibleGap;

  @override
  int get hashCode => Object.hash(rotationDegrees, minVisibleGap);
}

/// Where a chart's legend is positioned relative to the plot area.
enum ChartLegendPosition {
  /// Below the plot area, beneath the X-axis title (if any).
  bottom,

  /// To the right of the plot area, in its own column.
  right,
}

/// Visual configuration for a chart's legend.
///
/// Bundles visibility, position, container styling, layout reservation,
/// and wrapping behavior into a single immutable value.
///
/// Common usages:
///
/// ```dart
/// // Default — inline single row, hard-truncates on overflow.
/// HandDrawnLineChart(data: data);
///
/// // External boxed legend below the chart, with wrapping.
/// HandDrawnLineChart(
///   data: data,
///   legendConfig: ChartLegendConfig.externalBottomBoxed,
/// );
///
/// // External boxed legend on the right, narrowing the plot area.
/// HandDrawnLineChart(
///   data: data,
///   legendConfig: ChartLegendConfig.externalRightBoxed,
/// );
///
/// // No chart-managed legend (compose your own with HandDrawnLegend).
/// HandDrawnLineChart(
///   data: data,
///   legendConfig: ChartLegendConfig.hidden,
/// );
/// ```
///
/// **`reserveSpace`.** When `true` (the default for visible legends),
/// the chart layout reserves room for the legend so it cannot overlap
/// axis labels, the X-axis title, or the plot itself. Set to `false`
/// to opt out — useful when you intend to paint a standalone legend
/// outside the chart's bounds.
///
/// **`boxed`.** When `true`, the legend renders inside a wobbly hand-
/// drawn rectangle with the configured [padding]. Defaults to `false`.
///
/// **`wrap`.** When `true`, entries flow onto additional rows when
/// they don't fit on a single line. Defaults to `true` for the
/// external presets and `false` for [inlineBottom] (which keeps the
/// inline single-row layout and hard-truncates on overflow).
class ChartLegendConfig {
  const ChartLegendConfig({
    this.visible = true,
    this.position = ChartLegendPosition.bottom,
    this.boxed = false,
    this.reserveSpace = true,
    this.wrap = false,
    this.padding = const EdgeInsets.all(8),
    this.spacing = chartLegendEntryGap,
    this.runSpacing = 4,
  }) : assert(
         spacing == spacing && spacing != double.infinity && spacing >= 0,
         'ChartLegendConfig.spacing must be finite and non-negative',
       ),
       assert(
         runSpacing == runSpacing &&
             runSpacing != double.infinity &&
             runSpacing >= 0,
         'ChartLegendConfig.runSpacing must be finite and non-negative',
       );
  // [padding] insets are not validated at construction. Dart's const
  // evaluator cannot read EdgeInsets.{left,top,right,bottom} from
  // inside a const constructor's assert (those are instance getters,
  // not const fields), so a const-time finite-and-non-negative check
  // isn't expressible. This matches Flutter's own approach: EdgeInsets
  // values flow through the framework un-validated, and consumers are
  // expected to pass sensible insets.

  /// Whether the chart's own legend is rendered at all. When `false`,
  /// no chart-managed legend appears regardless of other settings —
  /// the chart still tracks `legend` entries internally so a standalone
  /// [HandDrawnLegend] widget can render them.
  final bool visible;

  /// Where the legend is placed relative to the plot area.
  final ChartLegendPosition position;

  /// Whether to wrap the legend in a hand-drawn box.
  final bool boxed;

  /// Whether the chart layout reserves space for the legend.
  ///
  /// When `false`, the legend draws over (or beyond) the chart rather
  /// than carving out its own band. Combine with the standalone
  /// [HandDrawnLegend] widget to compose layouts manually.
  final bool reserveSpace;

  /// Whether legend entries wrap to additional rows when they don't
  /// fit on a single line.
  ///
  /// Only meaningful when [position] is [ChartLegendPosition.bottom] —
  /// right-side legends always stack vertically (one entry per row)
  /// regardless of this flag, since "wrap" doesn't have a natural
  /// meaning for a single-column vertical stack. To control the
  /// number of right-side rows, change the entry list.
  final bool wrap;

  /// Inner padding inside the boxed legend container.
  final EdgeInsets padding;

  /// Horizontal gap between adjacent legend entries on the same row
  /// (or column for vertical legends).
  final double spacing;

  /// Vertical gap between wrapped legend rows (or columns).
  final double runSpacing;

  /// A single inline row at the bottom of the chart, no box, no wrap.
  /// Entries that don't fit on the row are hard-truncated.
  static const ChartLegendConfig inlineBottom = ChartLegendConfig(
    boxed: false,
    wrap: false,
    position: ChartLegendPosition.bottom,
  );

  /// External boxed legend below the chart, wrapping as needed.
  ///
  /// The chart layout reserves the measured legend height (including
  /// the box's padding) so it never overlaps axis content.
  static const ChartLegendConfig externalBottomBoxed = ChartLegendConfig(
    visible: true,
    position: ChartLegendPosition.bottom,
    boxed: true,
    reserveSpace: true,
    wrap: true,
  );

  /// External boxed legend to the right of the chart, stacked
  /// vertically. The chart's plot area becomes narrower to make room.
  ///
  /// Best suited for short legends. With many entries or long wrapped
  /// labels, content that exceeds the reserved column's height is
  /// clipped at paint time. For many series, prefer
  /// [externalBottomBoxed] or compose with a standalone
  /// [HandDrawnLegend] placed in your own scrollable layout.
  static const ChartLegendConfig externalRightBoxed = ChartLegendConfig(
    visible: true,
    position: ChartLegendPosition.right,
    boxed: true,
    reserveSpace: true,
    wrap: true,
  );

  /// Suppresses the chart-managed legend entirely. Use this when you
  /// want to compose a standalone [HandDrawnLegend] widget alongside
  /// the chart and not have the chart paint its own legend at all.
  static const ChartLegendConfig hidden = ChartLegendConfig(
    visible: false,
    reserveSpace: false,
  );

  /// Returns a copy of this config with the given fields replaced.
  /// Fields not specified retain their current value.
  ChartLegendConfig copyWith({
    bool? visible,
    ChartLegendPosition? position,
    bool? boxed,
    bool? reserveSpace,
    bool? wrap,
    EdgeInsets? padding,
    double? spacing,
    double? runSpacing,
  }) {
    return ChartLegendConfig(
      visible: visible ?? this.visible,
      position: position ?? this.position,
      boxed: boxed ?? this.boxed,
      reserveSpace: reserveSpace ?? this.reserveSpace,
      wrap: wrap ?? this.wrap,
      padding: padding ?? this.padding,
      spacing: spacing ?? this.spacing,
      runSpacing: runSpacing ?? this.runSpacing,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChartLegendConfig &&
          visible == other.visible &&
          position == other.position &&
          boxed == other.boxed &&
          reserveSpace == other.reserveSpace &&
          wrap == other.wrap &&
          padding == other.padding &&
          spacing == other.spacing &&
          runSpacing == other.runSpacing;

  @override
  int get hashCode => Object.hash(
    visible,
    position,
    boxed,
    reserveSpace,
    wrap,
    padding,
    spacing,
    runSpacing,
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

/// Helpers for deriving legend entries from chart data classes.
///
/// Today this is only used by line charts. The chart construction site
/// calls [fromLineChartData] unconditionally — the helper handles all
/// three precedence cases internally so callers don't reimplement the
/// fallback logic.
class ChartLegendEntries {
  const ChartLegendEntries._();

  /// Returns the legend entries to display for [data], following these
  /// rules in order:
  ///
  /// 1. If `data.legend` is non-empty, returns it verbatim (wrapped in
  ///    an unmodifiable view) so user-specified entries always win.
  /// 2. Otherwise, when the chart has more than one series
  ///    (`series.length + functionSeries.length > 1`), auto-derives
  ///    one entry per series from each series' name and color.
  /// 3. Otherwise (zero or one series and no explicit legend), returns
  ///    an empty list — single-series charts don't need a legend.
  static List<LegendEntry> fromLineChartData(LineChartData data) {
    if (data.legend.isNotEmpty) return List.unmodifiable(data.legend);

    final totalSeries = data.series.length + data.functionSeries.length;
    if (totalSeries > 1) {
      return List.unmodifiable([
        for (final s in data.series) LegendEntry(label: s.name, color: s.color),
        for (final f in data.functionSeries)
          LegendEntry(label: f.name, color: f.color),
      ]);
    }
    return const [];
  }
}

// ── Bar Chart ──────────────────────────────────────────────────────────────

/// One segment within a stacked bar.
///
/// The [value] must be finite — `NaN` and the infinities are rejected.
/// Negative values are permitted: positive segments stack upward from
/// the zero baseline, negative segments stack downward, and a single
/// stack with mixed signs maintains independent positive and negative
/// accumulators. This is enforced by a debug assertion here and by
/// release-safe validation in [HandDrawnBarChartPainter].
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
  }) : assert(
         // value.isFinite is not const-evaluable, so we open-code the
         // same predicate: NaN fails the self-equality test, and the
         // two infinities are rejected explicitly.
         value == value &&
             value != double.infinity &&
             value != double.negativeInfinity,
         'BarSegment.value must be finite, got $value',
       ),
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
/// Segment values may be positive, negative, or zero — see [BarSegment]
/// for the full validation policy. When the chart actually renders this
/// bar, positive segments stack upward from the zero baseline and
/// negative segments stack downward; consumers don't need to do
/// anything special to opt in.
class BarGroup {
  const BarGroup({required this.label, required this.segments});

  /// X-axis label (e.g., "Mon", "Mar 15", "Week 12").
  final String label;

  /// Segments stacked within this bar, bottom to top.
  final List<BarSegment> segments;

  /// Plain arithmetic sum of all segment values.
  ///
  /// This is a signed value — when a stack contains a mix of positive
  /// and negative segments, [total] reports the net of those signs (it
  /// is *not* the visible bar height in either direction). For chart
  /// scaling that needs the largest extent above zero, sum only the
  /// positive segments; for the largest extent below zero, sum only the
  /// negative segments. The bar painter does exactly this when computing
  /// the default Y range.
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
/// As a convenience, a `BarChartData.bars` entry that is a plain
/// [BarGroup] is treated internally as a single-bar category whose
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
/// By default, the Y-axis scales from `0` (or, when negative segments
/// are present, the smallest negative stack total) to the **largest
/// positive stack total** across all inner bars across all categories —
/// so grouped bars are sized by the maximum sibling, not the sum across
/// siblings. Pass [minY] and/or [maxY] to override the Y-axis range
/// explicitly (for example, to add headroom above bars for value
/// labels).
///
/// Use [axisDisplay] to opt into a zero-crossing X axis. When the data
/// range includes both positive and negative values, setting
/// `axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing)`
/// draws the horizontal axis line at `y = 0` instead of the chart
/// bottom. The vertical axis on a bar chart is categorical, so vertical
/// zero-crossing has no effect for bar charts and is silently ignored.
///
/// Legend semantics are explicit: provide [legend] entries that match
/// how you intend colors to be interpreted. The chart does not infer
/// legend identity from grouped structure.
class BarChartData {
  const BarChartData({
    this.bars = const [],
    this.legend = const [],
    this.title,
    this.yAxisLabel,
    this.xAxisLabel,
    this.minY,
    this.maxY,
    this.yValueFormatter,
    this.categories = const [],
    this.axisDisplay = AxisDisplay.edge,
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

  /// Optional Y-axis minimum.
  ///
  /// Defaults vary with the data: when every segment is non-negative,
  /// the default is `0`. When the chart contains any negative
  /// segments, the default becomes the smallest negative stack total
  /// across all inner bars, so negative bars are fully visible below
  /// the zero baseline.
  final double? minY;

  /// Optional Y-axis maximum. When null, defaults to the largest
  /// positive stack total across all inner bars across all categories.
  /// See the class-level documentation for the full max-not-sum scaling
  /// rule.
  final double? maxY;

  /// Optional formatter for Y-axis tick labels. When null, the default
  /// neutral numeric formatter is used.
  final AxisValueFormatter? yValueFormatter;

  /// Per-axis display configuration. Defaults to edge-aligned axes.
  /// Setting `horizontal: AxisDisplayMode.zeroCrossing` moves the
  /// horizontal axis line to `y = 0` whenever zero is strictly inside
  /// the visible Y range; otherwise the axis silently stays at the
  /// chart's bottom edge. The vertical setting has no effect on bar
  /// charts because the X axis is categorical.
  final AxisDisplay axisDisplay;

  bool get isEmpty => bars.isEmpty && categories.isEmpty;

  /// Returns a copy of this data with the given fields replaced.
  /// Fields not specified retain their current value. Nullable fields
  /// cannot be cleared via [copyWith] — construct a new
  /// [BarChartData] directly when that's needed.
  BarChartData copyWith({
    List<BarGroup>? bars,
    List<LegendEntry>? legend,
    String? title,
    String? yAxisLabel,
    String? xAxisLabel,
    double? minY,
    double? maxY,
    AxisValueFormatter? yValueFormatter,
    List<BarCategory>? categories,
    AxisDisplay? axisDisplay,
  }) {
    return BarChartData(
      bars: bars ?? this.bars,
      legend: legend ?? this.legend,
      title: title ?? this.title,
      yAxisLabel: yAxisLabel ?? this.yAxisLabel,
      xAxisLabel: xAxisLabel ?? this.xAxisLabel,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
      yValueFormatter: yValueFormatter ?? this.yValueFormatter,
      categories: categories ?? this.categories,
      axisDisplay: axisDisplay ?? this.axisDisplay,
    );
  }

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
          listEquals(categories, other.categories) &&
          axisDisplay == other.axisDisplay;

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
    axisDisplay,
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
    this.showFill = true,
  });

  /// Display name for this series. Used for auto-generated legend entries
  /// in multi-series charts.
  final String name;

  final List<LinePoint> points;
  final Color color;

  /// Whether to draw the semi-transparent fill below this series' line.
  /// Defaults to `true` (the existing behavior). Set `false` for an
  /// unfilled stroke-only series.
  final bool showFill;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LineSeriesData &&
          name == other.name &&
          listEquals(points, other.points) &&
          color == other.color &&
          showFill == other.showFill;

  @override
  int get hashCode =>
      Object.hash(name, Object.hashAll(points), color, showFill);
}

/// A mathematical function used with [FunctionSeriesData] to plot a curve.
///
/// Receives an x-value from the chart's numeric x-domain and returns the
/// corresponding y-value. Non-finite outputs (NaN, +∞, −∞) are treated as
/// discontinuities and will split the rendered curve into separate runs.
///
/// Splitting only happens when a sampled output is itself non-finite. If
/// an asymptote falls strictly between samples — where both adjacent
/// samples return finite-but-extreme values — the rendered line will
/// bridge across the discontinuity. Increase
/// [FunctionSeriesData.sampleCount], or have the function return
/// [double.nan] over a small exclusion interval around the
/// discontinuity, to opt out of the bridge.
typedef ChartFunction = double Function(double x);

/// A function-backed line series.
///
/// Unlike [LineSeriesData], which carries an explicit list of visible
/// points, a function series plots a continuous curve across the chart's
/// numeric x-domain. The chart internally samples [function] to build a
/// smooth curve while only rendering dots for the x-values listed in
/// [displayXs].
///
/// A function series can only be used when the enclosing [LineChartData]
/// is in numeric x-mode (i.e. has no categorical [LineChartData.xLabels]).
///
/// ### Equality caveat
///
/// [FunctionSeriesData] holds a Dart closure in [function]. In Dart,
/// closures compare equal by **identity**, not by semantic equivalence —
/// two inline `(x) => x * x` closures in otherwise-identical data objects
/// will compare unequal. When stable equality matters (e.g. to avoid
/// unnecessary repaints), prefer top-level or `static` function references
/// over inline closures.
class FunctionSeriesData {
  const FunctionSeriesData({
    required this.name,
    required this.color,
    required this.function,
    this.displayXs = const [],
    this.sampleCount = defaultSampleCount,
    this.showFill = true,
    this.wobbleAnchorStride = defaultWobbleAnchorStride,
  }) : assert(sampleCount >= 2, 'sampleCount must be at least 2'),
       assert(wobbleAnchorStride >= 1, 'wobbleAnchorStride must be >= 1');

  /// Display name for this series. Used for auto-generated legend entries
  /// in multi-series charts.
  final String name;

  /// Stroke and dot color for this series.
  final Color color;

  /// The function to plot. Called with x-values in `[minX, maxX]`.
  /// Non-finite returns are treated as discontinuities.
  final ChartFunction function;

  /// Sparse x-values whose corresponding points should be rendered as
  /// visible dots and participate in point hit testing.
  ///
  /// - Empty is allowed → draws curve only, no visible dots, no point hits.
  /// - Out-of-range values are ignored.
  /// - Values whose evaluated y is non-finite are skipped.
  /// - Duplicates are preserved.
  /// - Original order is preserved and drives `pointIndex` in hit-test output.
  final List<double> displayXs;

  /// Target number of uniform samples across `[minX, maxX]`. Must be ≥ 2.
  ///
  /// The **actual** number of rendered path vertices may be lower because
  /// non-finite evaluations are skipped and the curve may be split into
  /// multiple runs at discontinuities.
  final int sampleCount;

  /// Whether to draw the semi-transparent fill below this series' curve.
  /// Defaults to `true` (the existing behavior). Set `false` for an
  /// unfilled stroke-only function series.
  final bool showFill;

  /// Stride (in samples) between pinned wobble anchors along the curve.
  /// Every Nth sample is rendered at its true `f(x)` position; samples
  /// in between get a smoothed jitter offset, producing the hand-drawn
  /// look without losing the curve's shape.
  ///
  /// A smaller stride means more pinned points and tighter, more
  /// constrained wobble. A larger stride gives wobble more room to
  /// develop but creates visible facets at each anchor. Must be `>= 1`.
  /// Default is `10`, calibrated for the default `sampleCount: 120`.
  final int wobbleAnchorStride;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FunctionSeriesData &&
          name == other.name &&
          color == other.color &&
          function == other.function &&
          listEquals(displayXs, other.displayXs) &&
          sampleCount == other.sampleCount &&
          showFill == other.showFill &&
          wobbleAnchorStride == other.wobbleAnchorStride;

  @override
  int get hashCode => Object.hash(
    name,
    color,
    function,
    Object.hashAll(displayXs),
    sampleCount,
    showFill,
    wobbleAnchorStride,
  );
}

/// Complete data for rendering a line chart (single or multi-series).
///
/// The X axis supports two modes:
///
/// - **Numeric mode** (default): omit [xLabels] and the chart auto-generates
///   numeric tick labels from [minX]–[maxX].
/// - **Categorical mode**: provide [xLabels] and the chart renders them as
///   evenly spaced string labels. Points are still positioned by [LinePoint.x].
///
/// **Legend.** Pass [legend] entries explicitly, or leave it empty to
/// auto-derive entries from the series list. With multiple series
/// (point + function combined), the auto-derived legend contributes
/// one entry per series using its `name` and `color`; with one or
/// zero series, no auto-derived legend is rendered. See
/// [ChartLegendEntries.fromLineChartData] to obtain the auto-derived
/// list explicitly (e.g., for a standalone [HandDrawnLegend]).
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
    this.functionSeries = const [],
    this.legend = const [],
  });

  /// Function-backed series. Each entry plots a mathematical function
  /// across the numeric x-domain.
  ///
  /// **Validation contract.** When `functionSeries` is non-empty, the
  /// chart requires numeric x-mode (no categorical [xLabels]) and a
  /// valid range (`minX < maxX`). These rules are enforced by the
  /// resolver at first layout/paint — not as constructor assertions —
  /// so that [LineChartData] can stay `const`-constructible and
  /// accept non-canonical empty lists from callers.
  final List<FunctionSeriesData> functionSeries;

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

  /// Custom legend entries.
  ///
  /// When non-empty, the chart renders these entries as supplied.
  /// When empty (the default), entries are auto-derived from
  /// [series] and [functionSeries] via
  /// [ChartLegendEntries.fromLineChartData] — multi-series charts
  /// get a generated legend; single-series charts get none.
  final List<LegendEntry> legend;

  bool get isEmpty =>
      series.every((s) => s.points.isEmpty) && functionSeries.isEmpty;

  /// Returns a copy of this data with the given fields replaced.
  /// Fields not specified retain their current value. Nullable fields
  /// cannot be cleared via [copyWith] — construct a new
  /// [LineChartData] directly when that's needed.
  LineChartData copyWith({
    List<LineSeriesData>? series,
    double? minX,
    double? maxX,
    double? minY,
    double? maxY,
    List<String>? xLabels,
    String? title,
    String? yAxisLabel,
    String? xAxisLabel,
    AxisValueFormatter? yValueFormatter,
    AxisValueFormatter? xValueFormatter,
    AxisDisplay? axisDisplay,
    List<FunctionSeriesData>? functionSeries,
    List<LegendEntry>? legend,
  }) {
    return LineChartData(
      series: series ?? this.series,
      minX: minX ?? this.minX,
      maxX: maxX ?? this.maxX,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
      xLabels: xLabels ?? this.xLabels,
      title: title ?? this.title,
      yAxisLabel: yAxisLabel ?? this.yAxisLabel,
      xAxisLabel: xAxisLabel ?? this.xAxisLabel,
      yValueFormatter: yValueFormatter ?? this.yValueFormatter,
      xValueFormatter: xValueFormatter ?? this.xValueFormatter,
      axisDisplay: axisDisplay ?? this.axisDisplay,
      functionSeries: functionSeries ?? this.functionSeries,
      legend: legend ?? this.legend,
    );
  }

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
          axisDisplay == other.axisDisplay &&
          listEquals(functionSeries, other.functionSeries) &&
          listEquals(legend, other.legend);

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
    Object.hashAll(functionSeries),
    Object.hashAll(legend),
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
    this.legend = const [],
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

  /// Custom legend entries.
  ///
  /// Scatter plots don't auto-derive entries — supply them explicitly
  /// here when a legend is needed. Defaults to empty (no legend).
  final List<LegendEntry> legend;

  bool get isEmpty => points.isEmpty;

  /// Returns a copy of this data with the given fields replaced.
  /// Fields not specified retain their current value. Nullable fields
  /// cannot be cleared via [copyWith] — construct a new
  /// [ScatterPlotData] directly when that's needed.
  ScatterPlotData copyWith({
    List<ScatterPoint>? points,
    double? minX,
    double? maxX,
    double? minY,
    double? maxY,
    String? xAxisLabel,
    String? yAxisLabel,
    String? title,
    AxisValueFormatter? yValueFormatter,
    AxisValueFormatter? xValueFormatter,
    AxisDisplay? axisDisplay,
    List<LegendEntry>? legend,
  }) {
    return ScatterPlotData(
      points: points ?? this.points,
      minX: minX ?? this.minX,
      maxX: maxX ?? this.maxX,
      minY: minY ?? this.minY,
      maxY: maxY ?? this.maxY,
      xAxisLabel: xAxisLabel ?? this.xAxisLabel,
      yAxisLabel: yAxisLabel ?? this.yAxisLabel,
      title: title ?? this.title,
      yValueFormatter: yValueFormatter ?? this.yValueFormatter,
      xValueFormatter: xValueFormatter ?? this.xValueFormatter,
      axisDisplay: axisDisplay ?? this.axisDisplay,
      legend: legend ?? this.legend,
    );
  }

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
          axisDisplay == other.axisDisplay &&
          listEquals(legend, other.legend);

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
    Object.hashAll(legend),
  );
}
