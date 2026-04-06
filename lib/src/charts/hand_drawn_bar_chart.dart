import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
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
    super.gridColor,
    TextStyle? labelStyle,
    super.irregularity,
    super.segments,
    super.yDivisions,
    super.padding,
    super.titleStyle,
    super.legendStyle,
    super.axisStrokeWidth,
    super.gridStrokeWidth,
    super.gridJitterRatio,
  }) : super(
         xLabels: [for (final b in data.bars) b.label],
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
    // reaches paintData in release builds.
    for (final bar in data.bars) {
      for (final segment in bar.segments) {
        if (segment.value < 0) {
          throw ArgumentError(
            'BarSegment.value must be non-negative, got ${segment.value} '
            'in bar "${bar.label}".',
          );
        }
      }
    }
  }

  final BarChartData data;

  /// Computes the default Y-axis maximum from bar totals.
  ///
  /// Assumes all segment values are non-negative (guaranteed by the
  /// non-negative policy enforced in the constructor).
  static double _computeMaxY(BarChartData data) {
    double max = 0;
    for (final bar in data.bars) {
      if (bar.total > max) max = bar.total;
    }
    return max == 0 ? 1 : max;
  }

  /// Computes the logical bar width from slot width, applying the width
  /// ratio and min/max clamping.
  static double _computeBarWidth(double slotWidth) {
    return (slotWidth * barWidthRatio)
        .clamp(slotWidth >= barMinWidth ? barMinWidth : 0.0, barMaxWidth)
        .clamp(0.0, slotWidth);
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

    if (data.bars.isEmpty) {
      return BarChartLayout(
        size: size,
        chartArea: frame.chartArea,
        segments: const [],
      );
    }

    final barCount = data.bars.length;
    final slotWidth = frame.chartArea.width / barCount;
    final barWidth = _computeBarWidth(slotWidth);

    final segments = <BarSegmentLayout>[];

    for (int i = 0; i < barCount; i++) {
      final bar = data.bars[i];
      final centerX = frame.xPositionForBar(i, barCount);

      double cumulativeValue = 0.0;
      for (int j = 0; j < bar.segments.length; j++) {
        final segment = bar.segments[j];
        if (segment.value == 0) continue;

        final segmentBottom = frame.yToCanvas(cumulativeValue);
        final cumulativeStart = cumulativeValue;
        cumulativeValue += segment.value;
        final segmentTop = frame.yToCanvas(cumulativeValue);

        segments.add(
          BarSegmentLayout(
            barIndex: i,
            segmentIndex: j,
            barLabel: bar.label,
            category: segment.category,
            value: segment.value,
            cumulativeStart: cumulativeStart,
            cumulativeEnd: cumulativeValue,
            bounds: Rect.fromLTRB(
              centerX - barWidth / 2,
              segmentTop,
              centerX + barWidth / 2,
              segmentBottom,
            ),
          ),
        );
      }
    }

    return BarChartLayout(
      size: size,
      chartArea: frame.chartArea,
      segments: segments,
    );
  }

  @override
  void paintData(Canvas canvas, Size size) {
    if (data.bars.isEmpty) return;

    final barCount = data.bars.length;
    final slotWidth = chartArea.width / barCount;
    final barWidth = _computeBarWidth(slotWidth);

    for (int i = 0; i < barCount; i++) {
      final bar = data.bars[i];
      final centerX = chartArea.left + slotWidth * (i + 0.5);

      double cumulativeValue = 0.0;
      for (int j = 0; j < bar.segments.length; j++) {
        final segment = bar.segments[j];
        if (segment.value == 0) continue; // Zero height — nothing to draw.

        final segmentBottom = yToCanvas(cumulativeValue);
        cumulativeValue += segment.value;
        final segmentTop = yToCanvas(cumulativeValue);

        final rect = Rect.fromLTRB(
          centerX - barWidth / 2,
          segmentTop,
          centerX + barWidth / 2,
          segmentBottom,
        );

        final barSeed =
            seed +
            barChartSeedOffset +
            i * barSegmentSeedMultiplier +
            j * barSegmentSeedStep;
        final path = wobblyRect(rect, barSeed);

        final fillPaint = Paint()
          ..color = segment.color.withValues(alpha: barFillAlpha)
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
    this.gridColor = chartGridColor,
    this.labelStyle,
    this.irregularity = chartIrregularity,
    this.segments = chartSegments,
    this.yDivisions = chartYDivisions,
    this.padding = chartDefaultPadding,
    this.titleStyle,
    this.legendStyle,
    this.axisStrokeWidth = chartAxisStrokeWidth,
    this.gridStrokeWidth = chartGridStrokeWidth,
    this.gridJitterRatio = chartGridJitterRatio,
    this.emptyStyle,
    super.key,
  });

  final BarChartData? data;
  final double height;
  final int seed;
  final Color axisColor;
  final Color gridColor;
  final TextStyle? labelStyle;
  final double irregularity;
  final int segments;
  final int yDivisions;
  final EdgeInsets padding;
  final TextStyle? titleStyle;
  final TextStyle? legendStyle;
  final double axisStrokeWidth;
  final double gridStrokeWidth;
  final double gridJitterRatio;
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
          gridColor: gridColor,
          labelStyle: labelStyle,
          irregularity: irregularity,
          segments: segments,
          yDivisions: yDivisions,
          padding: padding,
          titleStyle: titleStyle,
          legendStyle: legendStyle,
          axisStrokeWidth: axisStrokeWidth,
          gridStrokeWidth: gridStrokeWidth,
          gridJitterRatio: gridJitterRatio,
        ),
      ),
    );
  }
}
