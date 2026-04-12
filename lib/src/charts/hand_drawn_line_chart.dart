import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
import 'chart_data.dart';
import 'chart_interaction.dart';
import 'chart_widget_helpers.dart';
import 'hand_drawn_chart_painter.dart';

/// Painter for hand-drawn line charts.
///
/// Points are positioned using [LinePoint.x] within the `minX`–`maxX` range.
/// Supports both numeric and categorical X-axis modes.
/// Auto-generates legend for multi-series charts.
class HandDrawnLineChartPainter extends HandDrawnChartPainter {
  HandDrawnLineChartPainter({
    required this.data,
    super.seed,
    super.axisColor,
    super.grid,
    TextStyle? labelStyle,
    super.irregularity,
    super.segments,
    super.yDivisions,
    super.xDivisions,
    super.padding,
    super.titleStyle,
    super.legendStyle,
    super.axisStrokeWidth,
  }) : super(
         xLabels: data.xLabels,
         legend: data.series.length > 1
             ? [
                 for (final s in data.series)
                   LegendEntry(label: s.name, color: s.color),
               ]
             : const [],
         yMin: data.minY,
         yMax: data.maxY,
         xMin: data.minX,
         xMax: data.maxX,
         yAxisLabel: data.yAxisLabel,
         xAxisLabel: data.xAxisLabel,
         title: data.title,
         labelStyle: labelStyle ?? chartDefaultLabelStyle,
         yValueFormatter: data.yValueFormatter,
         xValueFormatter: data.xValueFormatter,
         axisDisplay: data.axisDisplay,
       );

  final LineChartData data;

  /// Computes an immutable layout snapshot for this line chart at [size].
  ///
  /// The returned [LineChartLayout] contains point and segment layouts
  /// across all series, using logical (non-wobbly) geometry. Hit-test
  /// results are based on these logical positions, ensuring wobble does
  /// not affect interaction behavior.
  ///
  /// Valid only for the given [size]. Recompute when size changes.
  LineChartLayout computeLayout(Size size) {
    final frame = buildFrame(size);

    final allPoints = <LinePointLayout>[];
    final allSegments = <LineSegmentLayout>[];

    for (int s = 0; s < data.series.length; s++) {
      final series = data.series[s];
      if (series.points.isEmpty) continue;

      // Compute canvas positions for each point in this series.
      final canvasPoints = <Offset>[];
      for (int i = 0; i < series.points.length; i++) {
        final pt = series.points[i];
        final x = frame.xToCanvasValue(pt.x);
        final y = frame.yToCanvas(pt.y);
        final center = Offset(x, y);
        canvasPoints.add(center);

        allPoints.add(
          LinePointLayout(
            seriesIndex: s,
            seriesName: series.name,
            pointIndex: i,
            rawPoint: pt,
            center: center,
          ),
        );
      }

      // Build segments between consecutive points.
      for (int i = 0; i < canvasPoints.length - 1; i++) {
        allSegments.add(
          LineSegmentLayout(
            seriesIndex: s,
            seriesName: series.name,
            segmentIndex: i,
            rawStartPoint: series.points[i],
            rawEndPoint: series.points[i + 1],
            start: canvasPoints[i],
            end: canvasPoints[i + 1],
          ),
        );
      }
    }

    return LineChartLayout(
      size: size,
      chartArea: frame.chartArea,
      points: allPoints,
      segments: allSegments,
    );
  }

  /// Paints line series with a semi-transparent fill below each line.
  ///
  /// By default the fill area extends from the data line down to the
  /// bottom of the chart area (`chartArea.bottom`). When the chart has
  /// opted into a zero-crossing horizontal axis
  /// (`data.axisDisplay.horizontal == AxisDisplayMode.zeroCrossing`)
  /// AND zero is inside the visible Y range, the fill instead anchors
  /// to the zero baseline — so positive lobes fill downward to zero and
  /// negative lobes fill upward to zero. This matches the visual
  /// relationship a moved-axis chart implies.
  @override
  void paintData(Canvas canvas, Size size) {
    // Resolve the fill baseline once per paint. Falls back to the chart
    // bottom whenever zero-crossing is off OR zero isn't inside the
    // visible Y range — both of which preserve the original behavior.
    final useZeroBaseline =
        data.axisDisplay.horizontal == AxisDisplayMode.zeroCrossing &&
        frame.isZeroVisibleY;
    final fillBaselineY = useZeroBaseline ? yToCanvas(0) : chartArea.bottom;

    for (int s = 0; s < data.series.length; s++) {
      final series = data.series[s];
      if (series.points.isEmpty) continue;

      final points = <Offset>[];
      for (int i = 0; i < series.points.length; i++) {
        final pt = series.points[i];
        final x = xToCanvasValue(pt.x);
        final y = yToCanvas(pt.y);
        points.add(Offset(x, y));
      }

      // Semi-transparent fill below (or above, when in negative region)
      // the line, anchored to the resolved baseline.
      //
      // When the baseline is at the chart bottom (legacy behavior), a
      // single closed polygon is always correct — no region ever crosses
      // the bottom. When the baseline is at y=0 and the data crosses
      // that line, we must split the fill so each closed sub-region
      // stays on ONE side of zero. Otherwise the polygon bridges across
      // sign flips and tints regions that should be empty.
      //
      // Algorithm: walk segment-by-segment in data space. Each run of
      // same-sign points (treating y==0 points as boundaries that
      // belong to both sides) becomes one closed sub-path anchored to
      // the baseline. When a segment strictly flips sign (y0*y1 < 0)
      // we interpolate the zero-crossing X, emit it as the closing
      // vertex of the current sub-path, and reopen a new sub-path from
      // that same X for the next sign region.
      if (points.length >= 2) {
        final fillPath = Path();
        if (useZeroBaseline) {
          _appendSignSplitFill(
            fillPath,
            series.points,
            points,
            fillBaselineY,
            xToCanvasValue,
          );
        } else {
          fillPath.moveTo(points.first.dx, fillBaselineY);
          for (final p in points) {
            fillPath.lineTo(p.dx, p.dy);
          }
          fillPath.lineTo(points.last.dx, fillBaselineY);
          fillPath.close();
        }

        canvas.drawPath(
          fillPath,
          Paint()
            ..color = series.color.withValues(alpha: lineFillAlpha)
            ..style = PaintingStyle.fill,
        );
      }

      // Wobbly line segments.
      final linePaint = Paint()
        ..color = series.color
        ..strokeWidth = lineStrokeWidth
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (int i = 0; i < points.length - 1; i++) {
        final lineSeed =
            seed +
            lineChartSeedOffset +
            s * lineSeriesSeedMultiplier +
            i * linePointSeedStep;
        canvas.drawPath(
          wobblyLine(
            points[i],
            points[i + 1],
            lineSeed,
            segmentCount: lineSegmentCount,
          ),
          linePaint,
        );
      }

      // Wobbly circles at each data point.
      final dotPaint = Paint()
        ..color = series.color
        ..style = PaintingStyle.fill;

      for (int i = 0; i < points.length; i++) {
        final dotSeed =
            seed +
            lineDotSeedOffset +
            s * lineSeriesSeedMultiplier +
            i * linePointSeedStep;
        canvas.drawPath(
          wobblyCircle(
            points[i],
            lineDotRadius,
            dotSeed,
            jitter: irregularity * lineDotJitterRatio,
            points: lineDotCirclePoints,
          ),
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant HandDrawnLineChartPainter oldDelegate) {
    return oldDelegate.data != data || super.shouldRepaint(oldDelegate);
  }
}

/// Widget wrapper for the hand-drawn line chart.
class HandDrawnLineChart extends StatelessWidget {
  const HandDrawnLineChart({
    required this.data,
    this.height = HandDrawnDefaults.chartHeight,
    this.seed = HandDrawnDefaults.seed,
    this.axisColor = chartAxisColor,
    this.grid = GridConfig.standard,
    this.labelStyle,
    this.irregularity = chartIrregularity,
    this.segments = chartSegments,
    this.yDivisions = chartYDivisions,
    this.xDivisions = chartXDivisions,
    this.padding = chartDefaultPadding,
    this.titleStyle,
    this.legendStyle,
    this.axisStrokeWidth = chartAxisStrokeWidth,
    this.emptyStyle,
    super.key,
  });

  final LineChartData? data;
  final double height;
  final int seed;
  final Color axisColor;

  /// Grid configuration bundle. See [GridConfig] for all knobs.
  final GridConfig grid;
  final TextStyle? labelStyle;
  final double irregularity;
  final int segments;
  final int yDivisions;
  final int xDivisions;
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
        painter: HandDrawnLineChartPainter(
          data: data!,
          seed: seed,
          axisColor: axisColor,
          grid: grid,
          labelStyle: labelStyle,
          irregularity: irregularity,
          segments: segments,
          yDivisions: yDivisions,
          xDivisions: xDivisions,
          padding: padding,
          titleStyle: titleStyle,
          legendStyle: legendStyle,
          axisStrokeWidth: axisStrokeWidth,
        ),
      ),
    );
  }
}

// Builds a fill path that respects the y=0 baseline by emitting a
// separate closed sub-region per contiguous run of same-sign data.
//
// Zero-endpoint handling:
//   * A data point at exactly y==0 acts as a natural boundary and does
//     not trigger interpolation — its canvas position is already on the
//     baseline. The current region closes at that point; the next
//     region opens from the same point.
//   * A segment with BOTH endpoints at y==0 contributes nothing to
//     fill (zero-height strip) and is skipped.
//   * A segment strictly flipping sign (y0*y1 < 0) gets an
//     interpolated crossing X inserted as the closing vertex of the
//     current region and opening vertex of the next.
void _appendSignSplitFill(
  Path fillPath,
  List<LinePoint> dataPoints,
  List<Offset> canvasPoints,
  double baselineY,
  double Function(double) xToCanvasValue,
) {
  // Sign: -1, 0, +1. A "region" collects consecutive points whose
  // sign is not strictly opposite to the region's sign.
  int signOf(double y) => y == 0 ? 0 : (y > 0 ? 1 : -1);

  // Current region buffer of canvas-space vertices.
  final region = <Offset>[];
  int regionSign = 0;

  void flushRegion() {
    if (region.length < 2) {
      region.clear();
      return;
    }
    fillPath.moveTo(region.first.dx, baselineY);
    for (final p in region) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(region.last.dx, baselineY);
    fillPath.close();
    region.clear();
  }

  for (int i = 0; i < dataPoints.length; i++) {
    final y = dataPoints[i].y;
    final sign = signOf(y);
    final canvasPt = canvasPoints[i];

    if (region.isEmpty) {
      region.add(canvasPt);
      regionSign = sign;
      continue;
    }

    final prevY = dataPoints[i - 1].y;
    final prevSign = signOf(prevY);

    if (prevSign * sign < 0) {
      // Strict sign flip — interpolate crossing X in data space,
      // emit crossing as closing vertex, flush, reopen from crossing.
      final t = prevY / (prevY - y); // 0..1 along the segment
      final crossingDataX =
          dataPoints[i - 1].x + (dataPoints[i].x - dataPoints[i - 1].x) * t;
      final crossingCanvasX = xToCanvasValue(crossingDataX);
      final crossingPt = Offset(crossingCanvasX, baselineY);

      region.add(crossingPt);
      flushRegion();
      region.add(crossingPt);
      region.add(canvasPt);
      regionSign = sign;
    } else if (prevSign == 0 && sign != 0) {
      // Previous point was exactly at zero and we're leaving it. The
      // previous point already sits on the baseline. Flush whatever
      // region we had (which may be just a boundary point + earlier
      // content), then start the new region from the same zero point.
      flushRegion();
      region.add(canvasPoints[i - 1]);
      region.add(canvasPt);
      regionSign = sign;
    } else if (sign == 0 && prevSign != 0) {
      // Arriving at an exact-zero point. Include it as the closing
      // boundary of the current region, flush, then hold the zero
      // point as a seed for the next region (will be extended on the
      // next iteration).
      region.add(canvasPt);
      flushRegion();
      region.add(canvasPt);
      regionSign = 0;
    } else {
      // Same sign (or one of them is zero on a zero-to-zero segment).
      region.add(canvasPt);
      if (regionSign == 0) regionSign = sign;
    }
  }

  flushRegion();
}
