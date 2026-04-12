import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
import 'chart_data.dart';
import 'chart_interaction.dart';
import 'chart_widget_helpers.dart';
import 'hand_drawn_chart_painter.dart';

/// Validates that [radius] is positive; throws [ArgumentError] otherwise.
void _validateScatterRadius(double radius, double? rawSize, int index) {
  if (radius <= 0) {
    throw ArgumentError(
      'ScatterPoint.size must be positive, got $rawSize at index $index.',
    );
  }
}

/// Painter for hand-drawn scatter plots.
///
/// Draws wobbly circles at each data point. All axis furniture is
/// handled by the base [HandDrawnChartPainter].
class HandDrawnScatterPlotPainter extends HandDrawnChartPainter {
  HandDrawnScatterPlotPainter({
    required this.data,
    this.dotColor = scatterDotColor,
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
    super.axisStrokeWidth,
  }) : super(
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

  final ScatterPlotData data;
  final Color dotColor;

  @override
  void paintData(Canvas canvas, Size size) {
    if (data.points.isEmpty) return;

    final dotPaint = Paint()
      ..color = dotColor
      ..style = PaintingStyle.fill;
    final strokePaint = Paint()
      ..color = dotColor.withValues(alpha: scatterStrokeAlpha)
      ..style = PaintingStyle.stroke
      ..strokeWidth = scatterStrokeWidth;

    for (int i = 0; i < data.points.length; i++) {
      final p = data.points[i];
      final x = xToCanvasValue(p.x);
      final y = yToCanvas(p.y);
      final radius = p.size ?? scatterDefaultDotRadius;
      _validateScatterRadius(radius, p.size, i);

      final dotSeed = seed + scatterSeedOffset + i * scatterPointSeedStep;
      final circle = wobblyCircle(Offset(x, y), radius, dotSeed);
      canvas.drawPath(circle, dotPaint);
      canvas.drawPath(circle, strokePaint);
    }
  }

  /// Computes an immutable layout snapshot for this scatter plot at [size].
  ///
  /// The returned [ScatterPlotLayout] is valid only for the given [size].
  /// Recompute when the rendered size changes.
  ScatterPlotLayout computeLayout(Size size) {
    final frame = buildFrame(size);

    if (data.points.isEmpty) {
      return ScatterPlotLayout(
        size: size,
        chartArea: frame.chartArea,
        points: const [],
      );
    }

    final points = <ScatterPointLayout>[];
    for (int i = 0; i < data.points.length; i++) {
      final p = data.points[i];
      final x = frame.xToCanvasValue(p.x);
      final y = frame.yToCanvas(p.y);
      final radius = p.size ?? scatterDefaultDotRadius;
      _validateScatterRadius(radius, p.size, i);

      points.add(
        ScatterPointLayout(
          pointIndex: i,
          rawPoint: p,
          center: Offset(x, y),
          visualRadius: radius,
        ),
      );
    }

    return ScatterPlotLayout(
      size: size,
      chartArea: frame.chartArea,
      points: points,
    );
  }

  @override
  bool shouldRepaint(covariant HandDrawnScatterPlotPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.dotColor != dotColor ||
        super.shouldRepaint(oldDelegate);
  }
}

/// Widget wrapper for the hand-drawn scatter plot.
class HandDrawnScatterPlot extends StatelessWidget {
  const HandDrawnScatterPlot({
    required this.data,
    this.height = HandDrawnDefaults.chartHeight,
    this.dotColor = scatterDotColor,
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
    this.axisStrokeWidth = chartAxisStrokeWidth,
    this.emptyStyle,
    super.key,
  });

  final ScatterPlotData? data;
  final double height;
  final Color dotColor;
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
        painter: HandDrawnScatterPlotPainter(
          data: data!,
          dotColor: dotColor,
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
          axisStrokeWidth: axisStrokeWidth,
        ),
      ),
    );
  }
}
