import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
import 'bar_geometry.dart';
import 'chart_data.dart';
import 'chart_interaction.dart';
import 'chart_widget_helpers.dart';
import 'hand_drawn_chart_painter.dart';

/// Painter for hand-drawn stacked bar charts.
///
/// Bar segments accumulate from a data baseline of `0.0`. The [yMin] and
/// [yMax] parameters (from [BarChartData]) define the visible Y-range,
/// not the stacking origin.
class HandDrawnBarChartPainter extends HandDrawnChartPainter {
  HandDrawnBarChartPainter({
    required this.data,
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
  }) : super(
         // Project from resolvedCategories so grouped and legacy inputs
         // both produce correct X-axis labels. For legacy `bars` input
         // resolvedCategories yields one single-bar category per
         // BarGroup with the original label, so behavior is unchanged.
         xLabels: [for (final c in data.resolvedCategories) c.label],
         legend: data.legend,
         yMin: data.minY ?? 0,
         yMax: data.maxY ?? _computeMaxY(data),
         yAxisLabel: data.yAxisLabel,
         xAxisLabel: data.xAxisLabel,
         title: data.title,
         labelStyle: labelStyle ?? chartDefaultLabelStyle,
         yValueFormatter: data.yValueFormatter,
       ) {
    // Release-safe validation: reject negative segment values in all
    // build modes. BarSegment's own assert catches this in debug mode at
    // the point of construction; this guard ensures invalid data never
    // reaches paintData in release builds. Iterates resolvedCategories
    // so grouped and legacy inputs are both validated.
    for (final category in data.resolvedCategories) {
      for (final bar in category.bars) {
        for (final segment in bar.segments) {
          if (segment.value < 0) {
            throw ArgumentError(
              'BarSegment.value must be non-negative, got ${segment.value} '
              'in bar "${bar.label}" of category "${category.label}".',
            );
          }
        }
      }
    }
  }

  final BarChartData data;

  /// Computes the default Y-axis maximum from inner-bar totals across
  /// every category.
  ///
  /// Per the grouped-bar plan, the chart scales by the **maximum** inner
  /// bar height (not the sum across siblings) — siblings sit side-by-side,
  /// so the Y-axis only needs to cover the tallest one. For ungrouped
  /// charts this collapses to `max(BarGroup.total)` because the legacy
  /// projection produces one inner bar per category, preserving the
  /// pre-grouped default exactly.
  ///
  /// Note: `BarGroup.total` is not mutated or reinterpreted — it remains
  /// the pure sum of segment values. The "max vs sum" decision lives
  /// here at the chart-rendering level, where it belongs.
  static double _computeMaxY(BarChartData data) {
    double max = 0;
    for (final category in data.resolvedCategories) {
      for (final innerBar in category.bars) {
        if (innerBar.total > max) max = innerBar.total;
      }
    }
    return max == 0 ? 1 : max;
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
      // Deterministic per-segment seed. For ungrouped charts (the
      // legacy projection where every innerBarIndex is 0) the inner
      // term contributes nothing, so wobble patterns are bit-identical
      // to the pre-grouped renderer. For grouped charts each side-by-
      // side bar gets distinct wobble.
      final barSeed =
          seed +
          barChartSeedOffset +
          s.categoryIndex * barSegmentSeedMultiplier +
          s.innerBarIndex * barInnerSeedMultiplier +
          s.segmentIndex * barSegmentSeedStep;
      final path = wobblyRect(s.rect, barSeed);

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
    this.axisColor = chartAxisColor,
    this.grid = GridConfig.standard,
    this.labelStyle,
    this.irregularity = chartIrregularity,
    this.segments = chartSegments,
    this.yDivisions = chartYDivisions,
    this.padding = chartDefaultPadding,
    this.titleStyle,
    this.legendStyle,
    this.axisStrokeWidth = chartAxisStrokeWidth,
    this.emptyStyle,
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

  @override
  Widget build(BuildContext context) {
    return buildChartBody(
      isLoading: data == null,
      isEmpty: data?.isEmpty ?? true,
      height: height,
      emptyStyle: emptyStyle,
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
        ),
      ),
    );
  }
}
