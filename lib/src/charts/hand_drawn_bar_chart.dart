import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
import '../hand_drawn_toolkit_helpers.dart';
import 'bar_geometry.dart';
import 'chart_data.dart';
import 'chart_interaction.dart';
import 'chart_widget_helpers.dart';
import 'hand_drawn_chart_painter.dart';

/// Painter for hand-drawn stacked bar charts.
///
/// Bar segments accumulate from a data baseline of `0.0` — positive
/// segments stack upward, negative segments stack downward, and a
/// single bar may mix the two. The [yMin] and [yMax] parameters (from
/// [BarChartData]) define the visible Y-range, not the stacking
/// origin.
class HandDrawnBarChartPainter extends HandDrawnChartPainter {
  HandDrawnBarChartPainter({
    required this.data,
    super.clipToChartArea,
    super.seed,
    super.axisColor,
    super.grid,
    TextStyle? labelStyle,
    super.irregularity,
    super.segments,
    super.yDivisions,
    super.padding,
    super.titleStyle,
    super.legendStyle,
    super.axisStrokeWidth,
    super.xLabelConfig,
    super.legendConfig,
  }) : super(
         // Project from resolvedCategories so grouped and ungrouped inputs
         // both produce correct X-axis labels. For ungrouped `bars` input,
         // resolvedCategories yields one single-bar category per BarGroup
         // with the original label.
         xLabels: [for (final c in data.resolvedCategories) c.label],
         legend: data.legend,
         yMin: data.minY ?? _computeMinY(data),
         yMax: data.maxY ?? _computeMaxY(data),
         yAxisLabel: data.yAxisLabel,
         xAxisLabel: data.xAxisLabel,
         title: data.title,
         labelStyle: labelStyle ?? HandDrawnDefaults.chartLabelStyle,
         yValueFormatter: data.yValueFormatter,
         axisDisplay: data.axisDisplay,
       ) {
    // Release-safe validation: reject non-finite segment values and
    // out-of-range fillAlpha in all build modes. BarSegment's own
    // asserts catch these in debug mode at the point of construction;
    // these guards ensure invalid data never reaches paintData in
    // release builds (where const asserts are stripped). Iterates
    // resolvedCategories so grouped and ungrouped inputs are both
    // validated.
    //
    // Note: the fillAlpha guard cannot be exercised from `flutter test`
    // because tests run with asserts enabled — the BarSegment const
    // assert fires first. This is defense-in-depth for production
    // builds; covered by code review and the companion debug-assert
    // test in chart_data_test.dart.
    for (final category in data.resolvedCategories) {
      for (final bar in category.bars) {
        for (final segment in bar.segments) {
          if (!segment.value.isFinite) {
            throw ArgumentError(
              'BarSegment.value must be finite, got ${segment.value} '
              'in bar "${bar.label}" of category "${category.label}".',
            );
          }
          final fa = segment.fillAlpha;
          if (fa != null && (!fa.isFinite || fa < 0 || fa > 1)) {
            throw ArgumentError(
              'BarSegment.fillAlpha must be in [0, 1], got $fa '
              'in bar "${bar.label}" of category "${category.label}".',
            );
          }
        }
      }
    }
  }

  final BarChartData data;

  /// Computes the default Y-axis maximum from inner-bar **positive**
  /// stack totals across every category.
  ///
  /// The chart scales by the **maximum** inner  bar height (not the
  /// sum across siblings) — siblings sit side-by-side, so the Y-axis
  /// only needs to cover the tallest one. With signed segments allowed,
  /// "tallest" means the largest positive stack total — i.e. summing
  /// only the positive segments within each inner bar. Negative-only
  /// or all-zero data falls back to a sensible non-zero upper bound
  /// so the plot rect never collapses.
  ///
  /// For ungrouped, all-positive charts this is exactly `max(BarGroup.total)`
  /// — positive-only sums equal the arithmetic total when no segment is
  /// negative.
  static double _computeMaxY(BarChartData data) {
    double max = 0;
    for (final category in data.resolvedCategories) {
      for (final innerBar in category.bars) {
        final positive = _positiveStackTotal(innerBar);
        if (positive > max) max = positive;
      }
    }
    return max == 0 ? 1 : max;
  }

  /// Computes the default Y-axis minimum from inner-bar **negative**
  /// stack totals.
  ///
  /// Symmetric to [_computeMaxY]: with signed segments, the lowest
  /// extent each inner bar reaches below the zero baseline is the sum
  /// of its negative segments. Returns `0` when no inner bar has any
  /// negative segments, so all-positive charts default to a `minY` of
  /// zero.
  static double _computeMinY(BarChartData data) {
    double min = 0;
    for (final category in data.resolvedCategories) {
      for (final innerBar in category.bars) {
        final negative = _negativeStackTotal(innerBar);
        if (negative < min) min = negative;
      }
    }
    return min;
  }

  static double _positiveStackTotal(BarGroup bar) {
    double sum = 0;
    for (final s in bar.segments) {
      if (s.value > 0) sum += s.value;
    }
    return sum;
  }

  static double _negativeStackTotal(BarGroup bar) {
    double sum = 0;
    for (final s in bar.segments) {
      if (s.value < 0) sum += s.value;
    }
    return sum;
  }

  @override
  double xPositionForLabel(int index, int count) {
    if (count <= 0) return chartArea.center.dx;
    final slotWidth = chartArea.width / count;
    return chartArea.left + slotWidth * (index + 0.5);
  }

  /// Computes an immutable layout snapshot for this bar chart at [size].
  ///
  /// The returned [BarChartLayout] is valid only for the given [size].
  /// Recompute when the rendered size changes.
  ///
  /// ```dart
  /// LayoutBuilder(
  ///   builder: (context, constraints) {
  ///     final size = Size(constraints.maxWidth, 240);
  ///     final layout = painter.computeLayout(size);
  ///     return GestureDetector(
  ///       onTapDown: (d) {
  ///         final hit = layout.hitTest(d.localPosition);
  ///         // Consumer-owned behavior.
  ///       },
  ///       child: CustomPaint(size: size, painter: painter),
  ///     );
  ///   },
  /// )
  /// ```
  BarChartLayout computeLayout(Size size) {
    final frame = buildFrame(size);

    if (data.isEmpty) {
      return BarChartLayout(
        size: size,
        chartArea: frame.chartArea,
        segments: const [],
      );
    }

    // Single source of truth for bar segment rectangles. The painter
    // consumes the same helper so paint output and hit-test bounds can
    // never drift.
    final specs = computeBarSegmentRects(
      frame: frame,
      categories: data.resolvedCategories,
    );

    final segments = <BarSegmentLayout>[
      for (final s in specs)
        BarSegmentLayout(
          barIndex: s.categoryIndex,
          innerBarIndex: s.innerBarIndex,
          innerBarLabel: s.innerBarLabel,
          segmentIndex: s.segmentIndex,
          barLabel: s.categoryLabel,
          category: s.segment.category,
          value: s.segment.value,
          cumulativeStart: s.cumulativeStart,
          cumulativeEnd: s.cumulativeEnd,
          bounds: s.rect,
        ),
    ];

    return BarChartLayout(
      size: size,
      chartArea: frame.chartArea,
      segments: segments,
    );
  }

  @override
  void paintData(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Same geometry source as computeLayout() — guarantees painted
    // bars and hit-testable bounds always match.
    final specs = computeBarSegmentRects(
      frame: frame,
      categories: data.resolvedCategories,
    );

    for (final s in specs) {
      // Skip zero-area segments. They're kept in the layout list so
      // segment indices stay stable for hit testing, but painting a
      // wobbly border around a degenerate rect produces an ink-blob
      // artifact — and `Rect.contains` already excludes zero-area
      // rects from hit detection, so user-visible behavior on
      // hover/click is unchanged.
      if (s.rect.width <= 0 || s.rect.height <= 0) continue;

      // Deterministic per-segment seed. The inner-bar term lets
      // grouped (side-by-side) bars get distinct wobble; for charts
      // without grouping the term contributes zero and adjacent
      // segments still get distinct wobble via the segment-index term.
      final barSeed =
          seed +
          barChartSeedOffset +
          s.categoryIndex * barSegmentSeedMultiplier +
          s.innerBarIndex * barInnerSeedMultiplier +
          s.segmentIndex * barSegmentSeedStep;
      final helpers = HandDrawnHelpers(
        seed: barSeed,
        segments: defaultWobblyRectSegments,
        irregularity: irregularity,
      );
      final path = helpers.rectBorder(s.rect.size).shift(s.rect.topLeft);

      final segment = s.segment;
      final fillPaint = Paint()
        ..color = (segment.fillColor ?? segment.color).withValues(
          alpha: segment.fillAlpha ?? barFillAlpha,
        )
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      final strokePaint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = barStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(path, strokePaint);
    }
  }

  @override
  bool shouldRepaint(covariant HandDrawnBarChartPainter oldDelegate) {
    return oldDelegate.data != data || super.shouldRepaint(oldDelegate);
  }
}

/// Widget wrapper for the hand-drawn bar chart.
class HandDrawnBarChart extends StatelessWidget {
  const HandDrawnBarChart({
    required this.data,
    this.height = HandDrawnDefaults.chartHeight,
    this.seed = HandDrawnDefaults.seed,
    this.axisColor = HandDrawnDefaults.chartAxisColor,
    this.grid = GridConfig.standard,
    this.labelStyle,
    this.irregularity = HandDrawnDefaults.chartIrregularity,
    this.segments = HandDrawnDefaults.chartSegments,
    this.yDivisions = HandDrawnDefaults.chartYDivisions,
    this.padding = HandDrawnDefaults.chartPadding,
    this.titleStyle,
    this.legendStyle,
    this.axisStrokeWidth = HandDrawnDefaults.chartAxisStrokeWidth,
    this.emptyStyle,
    this.emptyMessage = 'No data for this range',
    this.clipToChartArea = false,
    this.xLabelConfig = ChartLabelConfig.horizontal,
    this.legendConfig = ChartLegendConfig.inlineBottom,
    super.key,
  });

  final BarChartData? data;
  final double height;
  final int seed;
  final Color axisColor;

  /// Grid configuration bundle. See [GridConfig] for all knobs.
  final GridConfig grid;
  final TextStyle? labelStyle;
  final double irregularity;
  final int segments;
  final int yDivisions;
  final EdgeInsets padding;
  final TextStyle? titleStyle;
  final TextStyle? legendStyle;
  final double axisStrokeWidth;
  final TextStyle? emptyStyle;

  /// Message shown when [data] is non-null but empty.
  final String emptyMessage;

  /// When `true`, data rendering is clipped to the chart's plot area so
  /// bars can't paint outside the chart. See
  /// [HandDrawnBarChartPainter.clipToChartArea] for details.
  final bool clipToChartArea;

  /// X-axis tick label configuration (rotation, thinning sensitivity).
  /// Defaults to horizontal labels. See [ChartLabelConfig] for usage
  /// and named presets.
  final ChartLabelConfig xLabelConfig;

  /// Legend layout configuration. Defaults to
  /// [ChartLegendConfig.inlineBottom] — a single inline row at the
  /// bottom of the chart, no box, hard-truncates on overflow. See
  /// [ChartLegendConfig] for external boxed presets and the
  /// standalone-widget composition pattern.
  final ChartLegendConfig legendConfig;

  @override
  Widget build(BuildContext context) {
    return buildChartBody(
      isLoading: data == null,
      isEmpty: data?.isEmpty ?? true,
      height: height,
      emptyStyle: emptyStyle,
      emptyMessage: emptyMessage,
      builder: () => CustomPaint(
        size: Size.infinite,
        painter: HandDrawnBarChartPainter(
          data: data!,
          seed: seed,
          axisColor: axisColor,
          grid: grid,
          labelStyle: labelStyle,
          irregularity: irregularity,
          segments: segments,
          yDivisions: yDivisions,
          padding: padding,
          titleStyle: titleStyle,
          legendStyle: legendStyle,
          axisStrokeWidth: axisStrokeWidth,
          clipToChartArea: clipToChartArea,
          xLabelConfig: xLabelConfig,
          legendConfig: legendConfig,
        ),
      ),
    );
  }
}
