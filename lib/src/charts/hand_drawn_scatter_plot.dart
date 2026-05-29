import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
import 'chart_data.dart';
import 'chart_interaction.dart';
import 'chart_widget_helpers.dart';
import 'hand_drawn_chart_painter.dart';

/// Painter for hand-drawn scatter plots.
///
/// Draws wobbly circles at each data point. All axis furniture is
/// handled by the base [HandDrawnChartPainter].
class HandDrawnScatterPlotPainter extends HandDrawnChartPainter {
  HandDrawnScatterPlotPainter({
    required this.data,
    super.clipToChartArea,
    this.dotColor = HandDrawnDefaults.scatterDotColor,
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
    super.xLabelConfig,
    super.legendConfig,
    super.legendStyle,
  }) : super(
         yMin: data.minY,
         yMax: data.maxY,
         xMin: data.minX,
         xMax: data.maxX,
         yAxisLabel: data.yAxisLabel,
         xAxisLabel: data.xAxisLabel,
         title: data.title,
         labelStyle: labelStyle ?? HandDrawnDefaults.chartLabelStyle,
         yValueFormatter: data.yValueFormatter,
         xValueFormatter: data.xValueFormatter,
         axisDisplay: data.axisDisplay,
         legend: data.legend,
       ) {
    for (int i = 0; i < data.points.length; i++) {
      final p = data.points[i];
      if (!p.x.isFinite || !p.y.isFinite) {
        throw ArgumentError(
          'ScatterPoint coordinates must be finite, got (${p.x}, ${p.y}) at '
          'index $i.',
        );
      }
      final radius = p.size ?? scatterDefaultDotRadius;
      if (!radius.isFinite || radius <= 0) {
        throw ArgumentError(
          'ScatterPoint.size must be finite and positive, got ${p.size} at '
          'index $i.',
        );
      }
    }
  }

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
    this.dotColor = HandDrawnDefaults.scatterDotColor,
    this.seed = HandDrawnDefaults.seed,
    this.axisColor = HandDrawnDefaults.chartAxisColor,
    this.grid = GridConfig.standard,
    this.labelStyle,
    this.irregularity = HandDrawnDefaults.chartIrregularity,
    this.segments = HandDrawnDefaults.chartSegments,
    this.yDivisions = HandDrawnDefaults.chartYDivisions,
    this.xDivisions = HandDrawnDefaults.chartXDivisions,
    this.padding = HandDrawnDefaults.chartPadding,
    this.titleStyle,
    this.axisStrokeWidth = HandDrawnDefaults.chartAxisStrokeWidth,
    this.emptyStyle,
    this.emptyMessage = 'No data for this range',
    this.clipToChartArea = false,
    this.xLabelConfig = ChartLabelConfig.horizontal,
    this.legendConfig = ChartLegendConfig.inlineBottom,
    this.legendStyle,
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

  /// Message shown when [data] is non-null but empty.
  final String emptyMessage;

  /// When `true`, data rendering is clipped to the chart's plot area so
  /// outlier points can't paint outside the chart. See
  /// [HandDrawnScatterPlotPainter.clipToChartArea] for details.
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

  /// Optional text style override for legend entry labels. When null,
  /// derives from [labelStyle] at the chart's legend font size.
  final TextStyle? legendStyle;

  /// Returns a copy of this widget with the given fields replaced.
  /// Fields not specified retain their current value. Nullable fields
  /// cannot be cleared via [copyWith] — construct a new
  /// [HandDrawnScatterPlot] directly when that's needed. Follows the same
  /// convention as [ScatterPlotData.copyWith].
  HandDrawnScatterPlot copyWith({
    ScatterPlotData? data,
    double? height,
    Color? dotColor,
    int? seed,
    Color? axisColor,
    GridConfig? grid,
    TextStyle? labelStyle,
    double? irregularity,
    int? segments,
    int? yDivisions,
    int? xDivisions,
    EdgeInsets? padding,
    TextStyle? titleStyle,
    double? axisStrokeWidth,
    TextStyle? emptyStyle,
    String? emptyMessage,
    bool? clipToChartArea,
    ChartLabelConfig? xLabelConfig,
    ChartLegendConfig? legendConfig,
    TextStyle? legendStyle,
    Key? key,
  }) {
    return HandDrawnScatterPlot(
      data: data ?? this.data,
      height: height ?? this.height,
      dotColor: dotColor ?? this.dotColor,
      seed: seed ?? this.seed,
      axisColor: axisColor ?? this.axisColor,
      grid: grid ?? this.grid,
      labelStyle: labelStyle ?? this.labelStyle,
      irregularity: irregularity ?? this.irregularity,
      segments: segments ?? this.segments,
      yDivisions: yDivisions ?? this.yDivisions,
      xDivisions: xDivisions ?? this.xDivisions,
      padding: padding ?? this.padding,
      titleStyle: titleStyle ?? this.titleStyle,
      axisStrokeWidth: axisStrokeWidth ?? this.axisStrokeWidth,
      emptyStyle: emptyStyle ?? this.emptyStyle,
      emptyMessage: emptyMessage ?? this.emptyMessage,
      clipToChartArea: clipToChartArea ?? this.clipToChartArea,
      xLabelConfig: xLabelConfig ?? this.xLabelConfig,
      legendConfig: legendConfig ?? this.legendConfig,
      legendStyle: legendStyle ?? this.legendStyle,
      key: key ?? this.key,
    );
  }

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
          clipToChartArea: clipToChartArea,
          xLabelConfig: xLabelConfig,
          legendConfig: legendConfig,
          legendStyle: legendStyle,
        ),
      ),
    );
  }
}
