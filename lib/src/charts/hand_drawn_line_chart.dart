import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
import 'chart_data.dart';
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
    super.gridColor,
    TextStyle? labelStyle,
    super.irregularity,
    super.segments,
    super.yDivisions,
    super.xDivisions,
    super.padding,
    super.titleStyle,
    super.legendStyle,
    super.axisStrokeWidth,
    super.gridStrokeWidth,
    super.gridJitterRatio,
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
       );

  final LineChartData data;

  /// Paints line series with a semi-transparent fill below each line.
  ///
  /// The fill area extends from the data line down to the bottom of the
  /// chart area (`chartArea.bottom`), not to a zero baseline. When `minY`
  /// is negative, the fill will cover the full area beneath the line
  /// including the negative region. This is the intended aesthetic for
  /// the hand-drawn style.
  @override
  void paintData(Canvas canvas, Size size) {
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

      // Semi-transparent fill below the line.
      if (points.length >= 2) {
        final fillPath = Path()..moveTo(points.first.dx, chartArea.bottom);
        for (final p in points) {
          fillPath.lineTo(p.dx, p.dy);
        }
        fillPath.lineTo(points.last.dx, chartArea.bottom);
        fillPath.close();

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
    this.gridColor = chartGridColor,
    this.labelStyle,
    this.irregularity = chartIrregularity,
    this.segments = chartSegments,
    this.yDivisions = chartYDivisions,
    this.xDivisions = chartXDivisions,
    this.padding = chartDefaultPadding,
    this.titleStyle,
    this.legendStyle,
    this.axisStrokeWidth = chartAxisStrokeWidth,
    this.gridStrokeWidth = chartGridStrokeWidth,
    this.gridJitterRatio = chartGridJitterRatio,
    this.emptyStyle,
    super.key,
  });

  final LineChartData? data;
  final double height;
  final int seed;
  final Color axisColor;
  final Color gridColor;
  final TextStyle? labelStyle;
  final double irregularity;
  final int segments;
  final int yDivisions;
  final int xDivisions;
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
        painter: HandDrawnLineChartPainter(
          data: data!,
          seed: seed,
          axisColor: axisColor,
          gridColor: gridColor,
          labelStyle: labelStyle,
          irregularity: irregularity,
          segments: segments,
          yDivisions: yDivisions,
          xDivisions: xDivisions,
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
