import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
import 'chart_data.dart';
import 'chart_interaction.dart';
import 'chart_widget_helpers.dart';
import 'hand_drawn_chart_painter.dart';
import 'line_series_resolver.dart';

/// Painter for hand-drawn line charts.
///
/// Points are positioned using [LinePoint.x] within the `minX`–`maxX` range.
/// Supports both numeric and categorical X-axis modes.
///
/// Legend entries follow [ChartLegendEntries.fromLineChartData] — when
/// the data contains multiple series (point + function combined),
/// entries are auto-generated from each series' name and color. With
/// one or zero series the chart renders no legend by default. The
/// helper is the single source of truth, so a standalone
/// [HandDrawnLegend] fed the same data renders the exact same
/// entries.
class HandDrawnLineChartPainter extends HandDrawnChartPainter {
  HandDrawnLineChartPainter({
    required this.data,
    super.clipToChartArea,
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
    super.xLabelConfig,
    super.legendConfig,
  }) : super(
         xLabels: data.xLabels,
         legend: ChartLegendEntries.fromLineChartData(data),
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

    final resolved = resolveLineSeries(data);

    for (int s = 0; s < resolved.length; s++) {
      final series = resolved[s];

      // Point layout from sparse displayPoints (index into displayPoints).
      for (int i = 0; i < series.displayPoints.length; i++) {
        final pt = series.displayPoints[i];
        final center = Offset(
          frame.xToCanvasValue(pt.x),
          frame.yToCanvas(pt.y),
        );
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

      // Segment layout from every pathRun. segmentIndex is flat across
      // runs within a series; discontinuities appear as gaps in the
      // segment stream rather than as bridging segments.
      int segIdx = 0;
      for (final run in series.pathRuns) {
        if (run.length < 2) continue;
        final canvas = [
          for (final p in run)
            Offset(frame.xToCanvasValue(p.x), frame.yToCanvas(p.y)),
        ];
        for (int i = 0; i < run.length - 1; i++) {
          allSegments.add(
            LineSegmentLayout(
              seriesIndex: s,
              seriesName: series.name,
              segmentIndex: segIdx++,
              rawStartPoint: run[i],
              rawEndPoint: run[i + 1],
              start: canvas[i],
              end: canvas[i + 1],
            ),
          );
        }
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

    final resolved = resolveLineSeries(data);

    for (int s = 0; s < resolved.length; s++) {
      final series = resolved[s];

      // Per-run rendering: each pathRun becomes an independent fill +
      // stroke. Ordinary series always have a single run; function series
      // may have multiple when the function has discontinuities.
      for (int r = 0; r < series.pathRuns.length; r++) {
        final run = series.pathRuns[r];
        if (run.isEmpty) continue;

        final points = [
          for (final p in run) Offset(xToCanvasValue(p.x), yToCanvas(p.y)),
        ];

        if (series.showFill && points.length >= 2) {
          final fillPath = Path();
          if (useZeroBaseline) {
            _appendSignSplitFill(
              fillPath,
              run,
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

        final linePaint = Paint()
          ..color = series.color
          ..strokeWidth = lineStrokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round;

        if (series.renderMode == ResolvedLineRenderMode.segmentedStroke) {
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
        } else if (points.length >= 2) {
          // Anchor-stride wobble: walk the sampled polyline in fixed
          // strides, treating every Nth sample as a pinned anchor and
          // wobbling the samples in between. Each anchor segment shares
          // its endpoint with the next, so the line stays continuous,
          // but each segment's wobble phase is independent (per-segment
          // seed) and amplitude is auto-capped to the segment's length.
          final stride = series.wobbleAnchorStride;
          for (int i = 0; i < points.length - 1; i += stride) {
            final endIdx = math.min(i + stride, points.length - 1);
            final sub = points.sublist(i, endIdx + 1);
            final anchorSeed =
                seed +
                lineChartSeedOffset +
                s * lineSeriesSeedMultiplier +
                r * lineRunSeedMultiplier +
                i * linePointSeedStep;
            canvas.drawPath(wobblePolyline(sub, anchorSeed), linePaint);
          }
        }
      }

      final dotPaint = Paint()
        ..color = series.color
        ..style = PaintingStyle.fill;
      for (int i = 0; i < series.displayPoints.length; i++) {
        final pt = series.displayPoints[i];
        final center = Offset(xToCanvasValue(pt.x), yToCanvas(pt.y));
        final dotSeed =
            seed +
            lineDotSeedOffset +
            s * lineSeriesSeedMultiplier +
            i * linePointSeedStep;
        canvas.drawPath(
          wobblyCircle(
            center,
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
    this.clipToChartArea = false,
    this.xLabelConfig = ChartLabelConfig.horizontal,
    this.legendConfig = ChartLegendConfig.inlineBottom,
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

  /// When `true`, data rendering is clipped to the chart's plot area so
  /// values outside `[minY, maxY]` can't paint outside the chart. See
  /// [HandDrawnLineChartPainter.clipToChartArea] for details.
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
          clipToChartArea: clipToChartArea,
          xLabelConfig: xLabelConfig,
          legendConfig: legendConfig,
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
