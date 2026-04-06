import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
import '../hand_drawn_toolkit_helpers.dart';
import 'chart_data.dart';

/// Abstract base painter for hand-drawn charts.
///
/// Provides shared chart furniture: wobbly axes, grid lines, Y-axis labels,
/// smart X-axis label placement, numeric X tick generation, optional chart
/// title, axis titles, and an optional legend. Concrete subclasses override
/// [paintData] to render their specific chart content.
///
/// ## Layout bands
///
/// The chart area is divided into vertical bands computed during [paint]:
///
/// 1. **Title band** — optional chart title
/// 2. **Chart area** — the main plotting region
/// 3. **X tick label band** — categorical or numeric X labels
/// 4. **X-axis title band** — optional axis title (e.g., "Weight (kg)")
/// 5. **Legend band** — optional color legend
///
/// The public [padding] field acts as an outer margin around these bands.
///
/// ## Deterministic rendering
///
/// All wobble is derived from [seed] via deterministic sub-seeds, so
/// identical parameters always produce the same chart.
abstract class HandDrawnChartPainter extends CustomPainter {
  HandDrawnChartPainter({
    this.irregularity = chartIrregularity,
    this.segments = chartSegments,
    this.axisColor = chartAxisColor,
    this.gridColor = chartGridColor,
    this.labelStyle = chartDefaultLabelStyle,
    this.padding = chartDefaultPadding,
    this.xLabels = const [],
    this.legend = const [],
    this.title,
    this.yAxisLabel,
    this.xAxisLabel,
    this.yMin = 0,
    this.yMax = 1,
    this.yDivisions = chartYDivisions,
    this.xMin,
    this.xMax,
    this.xDivisions = chartXDivisions,
    this.seed = HandDrawnDefaults.seed,
    this.yValueFormatter,
    this.xValueFormatter,
    this.titleStyle,
    this.legendStyle,
    this.axisStrokeWidth = chartAxisStrokeWidth,
    this.gridStrokeWidth = chartGridStrokeWidth,
    this.gridJitterRatio = chartGridJitterRatio,
  }) {
    if (yDivisions <= 0) {
      throw ArgumentError.value(yDivisions, 'yDivisions', 'must be positive');
    }
    if (xDivisions <= 0) {
      throw ArgumentError.value(xDivisions, 'xDivisions', 'must be positive');
    }
    if (yMin > yMax) {
      throw ArgumentError('yMin ($yMin) must be <= yMax ($yMax)');
    }
    if (xMin != null && xMax != null && xMin! > xMax!) {
      throw ArgumentError('xMin ($xMin) must be <= xMax ($xMax)');
    }
  }

  final double irregularity;
  final int segments;
  final Color axisColor;
  final Color gridColor;
  final TextStyle labelStyle;

  /// Outer padding around the chart layout bands.
  ///
  /// The [left] value controls the gutter reserved for Y-axis labels.
  /// The default (40 px) suits short numeric labels. When using a
  /// [yValueFormatter] that produces longer strings (e.g. `"$1,234.56"`),
  /// increase [left] to prevent label clipping.
  final EdgeInsets padding;
  final List<String> xLabels;

  /// Legend entries rendered below the chart area.
  ///
  /// Entries are laid out left-to-right in a single row. When chart width
  /// cannot fit all entries, later entries are silently omitted. For best
  /// results, use concise labels, keep entries to 4–6, and ensure adequate
  /// chart width.
  final List<LegendEntry> legend;
  final String? title;
  final String? yAxisLabel;
  final String? xAxisLabel;
  final double yMin;
  final double yMax;
  final int yDivisions;
  final double? xMin;
  final double? xMax;
  final int xDivisions;
  final int seed;
  final AxisValueFormatter? yValueFormatter;
  final AxisValueFormatter? xValueFormatter;

  /// Optional style for the chart title. When null, derives from [labelStyle].
  final TextStyle? titleStyle;

  /// Optional style for legend entry labels. When null, derives from [labelStyle].
  final TextStyle? legendStyle;

  final double axisStrokeWidth;
  final double gridStrokeWidth;
  final double gridJitterRatio;

  /// Chart area after layout bands are computed. Set during [paint].
  late Rect chartArea;

  @override
  void paint(Canvas canvas, Size size) {
    // Compute layout bands within the padded area.
    final padded = Rect.fromLTWH(
      padding.left,
      padding.top,
      size.width - padding.left - padding.right,
      size.height - padding.top - padding.bottom,
    );

    // Measure band heights.
    final titleHeight = _measureTitleHeight();
    final xTickHeight = _measureXTickHeight();
    final xAxisTitleHeight = _measureXAxisTitleHeight();
    final legendHeight = legend.isNotEmpty ? chartLegendBandHeight : 0.0;

    // Chart area fills whatever is left.
    chartArea = Rect.fromLTRB(
      padded.left,
      padded.top + titleHeight,
      padded.right,
      padded.bottom - xTickHeight - xAxisTitleHeight - legendHeight,
    );

    // Paint in order: background → axes → data → overlays.
    if (title != null) _paintTitle(canvas, padded);
    _paintGridLines(canvas);
    _paintAxes(canvas);
    _paintYLabels(canvas);
    if (yAxisLabel != null) _paintYAxisLabel(canvas, padded);
    _paintXTicksOrLabels(canvas);
    if (xAxisLabel != null) _paintXAxisTitle(canvas);
    paintData(canvas, size);
    if (legend.isNotEmpty) _paintLegend(canvas, size);
  }

  /// Override in subclasses to paint chart-specific content.
  void paintData(Canvas canvas, Size size);

  @override
  bool shouldRepaint(covariant HandDrawnChartPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.irregularity != irregularity ||
        oldDelegate.segments != segments ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.padding != padding ||
        oldDelegate.yMin != yMin ||
        oldDelegate.yMax != yMax ||
        oldDelegate.yDivisions != yDivisions ||
        oldDelegate.xMin != xMin ||
        oldDelegate.xMax != xMax ||
        oldDelegate.xDivisions != xDivisions ||
        oldDelegate.title != title ||
        oldDelegate.yAxisLabel != yAxisLabel ||
        oldDelegate.xAxisLabel != xAxisLabel ||
        oldDelegate.yValueFormatter != yValueFormatter ||
        oldDelegate.xValueFormatter != xValueFormatter ||
        oldDelegate.titleStyle != titleStyle ||
        oldDelegate.legendStyle != legendStyle ||
        oldDelegate.axisStrokeWidth != axisStrokeWidth ||
        oldDelegate.gridStrokeWidth != gridStrokeWidth ||
        oldDelegate.gridJitterRatio != gridJitterRatio ||
        !listEquals(oldDelegate.xLabels, xLabels) ||
        !listEquals(oldDelegate.legend, legend);
  }

  // ── Layout measurement helpers ───────────────────────────────────────

  double _measureTitleHeight() {
    if (title == null) return 0;
    final tp = _layoutText(title!, _effectiveTitleStyle);
    return tp.height + chartTitleSpacing;
  }

  double _measureXTickHeight() {
    if (xLabels.isNotEmpty || _hasNumericXAxis) {
      return chartXTickBandHeight;
    }
    return 0;
  }

  double _measureXAxisTitleHeight() {
    if (xAxisLabel == null) return 0;
    final tp = _layoutText(xAxisLabel!, labelStyle);
    return tp.height + chartXAxisTitleSpacing;
  }

  bool get _hasNumericXAxis => xMin != null && xMax != null;

  // ── Text helper ──────────────────────────────────────────────────────

  TextPainter _layoutText(String text, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    return tp;
  }

  /// Resolved title style: caller override or derived from [labelStyle].
  TextStyle get _effectiveTitleStyle =>
      titleStyle ??
      labelStyle.copyWith(
        fontSize: chartTitleFontSize,
        fontWeight: chartTitleFontWeight,
      );

  /// Resolved legend style: caller override or derived from [labelStyle].
  TextStyle get _effectiveLegendStyle =>
      legendStyle ?? labelStyle.copyWith(fontSize: chartLegendFontSize);

  // ── Value formatting ─────────────────────────────────────────────────

  String formatYValue(double value) {
    if (yValueFormatter != null) return yValueFormatter!(value);
    return _defaultFormat(value);
  }

  String formatXValue(double value) {
    if (xValueFormatter != null) return xValueFormatter!(value);
    return _defaultFormat(value);
  }

  /// Neutral numeric formatter. No domain assumptions.
  static String _defaultFormat(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    if (value.abs() < 100) return value.toStringAsFixed(1);
    return value.round().toString();
  }

  // ── Wobble shared helpers ────────────────────────────────────────────

  /// Generates smoothed 2D offsets for a wobbly path segment.
  ///
  /// Uses the same irregularity convention as [HandDrawnHelpers.smoothedOffsets]:
  /// each raw offset is `(random - 0.5) * irr`, giving an effective range of
  /// `[-irr/2, +irr/2]` before smoothing.
  ({List<double> x, List<double> y}) _smoothedOffsets2D(
    int offsetSeed,
    int segs,
    double irr,
  ) {
    final rng = math.Random(offsetSeed);
    final rawX = List<double>.filled(segs + 1, 0);
    final rawY = List<double>.filled(segs + 1, 0);
    for (int i = 1; i < segs; i++) {
      rawX[i] = (rng.nextDouble() - 0.5) * irr;
      rawY[i] = (rng.nextDouble() - 0.5) * irr;
    }
    return (x: HandDrawnHelpers.smooth(rawX), y: HandDrawnHelpers.smooth(rawY));
  }

  // ── Wobble path builders (smoothed) ──────────────────────────────────

  /// Builds a wobbly line path between two points.
  ///
  /// Uses the shared [HandDrawnHelpers.smooth] algorithm for organic
  /// hand-drawn character consistent with the rest of the package.
  Path wobblyLine(
    Offset from,
    Offset to,
    int lineSeed, {
    double? jitter,
    int? segmentCount,
  }) {
    final segs = segmentCount ?? segments;
    final irr = jitter ?? irregularity;
    final offsets = _smoothedOffsets2D(lineSeed, segs, irr);

    final path = Path()..moveTo(from.dx, from.dy);
    for (int i = 1; i <= segs; i++) {
      final t = i / segs;
      final x = from.dx + (to.dx - from.dx) * t;
      final y = from.dy + (to.dy - from.dy) * t;

      if (i == segs) {
        path.lineTo(to.dx, to.dy);
      } else {
        path.lineTo(x + offsets.x[i], y + offsets.y[i]);
      }
    }
    return path;
  }

  /// Builds a wobbly rectangle as one continuous closed path.
  Path wobblyRect(
    Rect rect,
    int rectSeed, {
    double? jitter,
    int segmentCount = wobblyRectSegments,
  }) {
    final irr = jitter ?? irregularity;
    final tl = rect.topLeft;
    final tr = rect.topRight;
    final br = rect.bottomRight;
    final bl = rect.bottomLeft;

    final path = Path()..moveTo(tl.dx, tl.dy);
    _addEdge(path, tl, tr, rectSeed, irr, segmentCount);
    _addEdge(path, tr, br, rectSeed + 1, irr, segmentCount);
    _addEdge(path, br, bl, rectSeed + 2, irr, segmentCount);
    _addEdge(path, bl, tl, rectSeed + 3, irr, segmentCount);
    path.close();
    return path;
  }

  /// Appends one edge to [path] without starting a new sub-path.
  void _addEdge(
    Path path,
    Offset from,
    Offset to,
    int edgeSeed,
    double irr,
    int segs,
  ) {
    final offsets = _smoothedOffsets2D(edgeSeed, segs, irr);
    for (int i = 1; i <= segs; i++) {
      final t = i / segs;
      final x = from.dx + (to.dx - from.dx) * t;
      final y = from.dy + (to.dy - from.dy) * t;
      if (i == segs) {
        path.lineTo(to.dx, to.dy);
      } else {
        path.lineTo(x + offsets.x[i], y + offsets.y[i]);
      }
    }
  }

  /// Builds a wobbly circle path by jittering the radius at each point.
  Path wobblyCircle(
    Offset center,
    double radius,
    int circleSeed, {
    double? jitter,
    int points = wobblyCirclePoints,
  }) {
    final rng = math.Random(circleSeed);
    final irr = jitter ?? (irregularity * 0.5);

    final raw = List<double>.filled(points + 1, 0);
    for (int i = 0; i <= points; i++) {
      raw[i] = (rng.nextDouble() - 0.5) * irr;
    }
    final smoothed = HandDrawnHelpers.smooth(raw);

    final path = Path();
    final step = 2 * math.pi / points;

    for (int i = 0; i <= points; i++) {
      final angle = i * step;
      final r = radius + smoothed[i];
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  // ── Axes ─────────────────────────────────────────────────────────────

  void _paintAxes(Canvas canvas) {
    final axisPaint = Paint()
      ..color = axisColor
      ..strokeWidth = axisStrokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawPath(
      wobblyLine(
        chartArea.bottomLeft,
        chartArea.bottomRight,
        seed + chartAxisSeedOffset,
      ),
      axisPaint,
    );
    canvas.drawPath(
      wobblyLine(
        chartArea.bottomLeft,
        chartArea.topLeft,
        seed + chartAxisSeedOffset + 1,
      ),
      axisPaint,
    );
  }

  // ── Grid ─────────────────────────────────────────────────────────────

  void _paintGridLines(Canvas canvas) {
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = gridStrokeWidth
      ..style = PaintingStyle.stroke;

    for (int i = 1; i <= yDivisions; i++) {
      final fraction = i / yDivisions;
      final y = chartArea.bottom - chartArea.height * fraction;
      canvas.drawPath(
        wobblyLine(
          Offset(chartArea.left, y),
          Offset(chartArea.right, y),
          seed + chartGridSeedOffset + i,
          jitter: irregularity * gridJitterRatio,
        ),
        gridPaint,
      );
    }
  }

  // ── Title ────────────────────────────────────────────────────────────

  void _paintTitle(Canvas canvas, Rect padded) {
    final tp = _layoutText(title!, _effectiveTitleStyle);
    tp.paint(
      canvas,
      Offset(padded.left + (padded.width - tp.width) / 2, padded.top),
    );
  }

  // ── Y-axis label ────────────────────────────────────────────────────

  void _paintYAxisLabel(Canvas canvas, Rect padded) {
    final tp = _layoutText(yAxisLabel!, labelStyle);
    canvas.save();
    final x = padded.left - tp.height - chartYAxisLabelOffset;
    final y = chartArea.top + (chartArea.height + tp.width) / 2;
    canvas.translate(x, y);
    canvas.rotate(-math.pi / 2);
    tp.paint(canvas, Offset.zero);
    canvas.restore();
  }

  // ── Y Labels ─────────────────────────────────────────────────────────

  void _paintYLabels(Canvas canvas) {
    for (int i = 0; i <= yDivisions; i++) {
      final fraction = i / yDivisions;
      final value = yMin + (yMax - yMin) * fraction;
      final y = chartArea.bottom - chartArea.height * fraction;

      final tp = _layoutText(formatYValue(value), labelStyle);
      tp.paint(
        canvas,
        Offset(chartArea.left - tp.width - chartYLabelGap, y - tp.height / 2),
      );
    }
  }

  // ── X ticks / labels ─────────────────────────────────────────────────

  void _paintXTicksOrLabels(Canvas canvas) {
    if (xLabels.isNotEmpty) {
      _paintCategoricalXLabels(canvas);
    } else if (_hasNumericXAxis) {
      _paintNumericXTicks(canvas);
    }
  }

  void _paintCategoricalXLabels(Canvas canvas) {
    if (xLabels.isEmpty) return;

    final positions = _selectLabelPositions(xLabels, chartArea.width);
    final tickPaint = Paint()
      ..color = axisColor
      ..strokeWidth = chartTickStrokeWidth;

    for (int i = 0; i < xLabels.length; i++) {
      final x = xPositionForLabel(i, xLabels.length);

      canvas.drawLine(
        Offset(x, chartArea.bottom),
        Offset(x, chartArea.bottom + chartTickLength),
        tickPaint,
      );

      if (positions.contains(i)) {
        final tp = _layoutText(xLabels[i], labelStyle);
        tp.paint(
          canvas,
          Offset(x - tp.width / 2, chartArea.bottom + chartTickLabelGap),
        );
      }
    }
  }

  /// Returns the X pixel position for a categorical label at [index].
  ///
  /// Default implementation uses edge-to-edge spacing (suitable for line
  /// charts). Bar charts override this to use slot-center spacing.
  double xPositionForLabel(int index, int count) {
    if (count <= 1) return chartArea.left + chartArea.width / 2;
    final slotWidth = chartArea.width / (count - 1);
    return chartArea.left + slotWidth * index;
  }

  void _paintNumericXTicks(Canvas canvas) {
    if (xMin == null || xMax == null) return;

    final tickPaint = Paint()
      ..color = axisColor
      ..strokeWidth = chartTickStrokeWidth;

    // Pre-generate all formatted labels for thinning.
    final labels = <String>[
      for (int i = 0; i <= xDivisions; i++)
        formatXValue(xMin! + (xMax! - xMin!) * (i / xDivisions)),
    ];
    final visible = _selectLabelPositions(labels, chartArea.width);

    for (int i = 0; i <= xDivisions; i++) {
      final fraction = i / xDivisions;
      final x = chartArea.left + chartArea.width * fraction;

      canvas.drawLine(
        Offset(x, chartArea.bottom),
        Offset(x, chartArea.bottom + chartTickLength),
        tickPaint,
      );

      if (visible.contains(i)) {
        final tp = _layoutText(labels[i], labelStyle);
        tp.paint(
          canvas,
          Offset(x - tp.width / 2, chartArea.bottom + chartTickLabelGap),
        );
      }
    }
  }

  // ── X-axis title ─────────────────────────────────────────────────────

  void _paintXAxisTitle(Canvas canvas) {
    final xTickH = _measureXTickHeight();
    final tp = _layoutText(xAxisLabel!, labelStyle);
    tp.paint(
      canvas,
      Offset(
        chartArea.center.dx - tp.width / 2,
        chartArea.bottom + xTickH + chartXAxisTitleGap,
      ),
    );
  }

  // ── Label thinning ───────────────────────────────────────────────────

  List<int> _selectLabelPositions(List<String> labels, double width) {
    if (labels.length <= 2) return List.generate(labels.length, (i) => i);

    double maxW = 0;
    for (final label in labels) {
      final tp = _layoutText(label, labelStyle);
      if (tp.width > maxW) maxW = tp.width;
    }

    final slotWidth = maxW + chartLabelThinningGap;
    if (slotWidth <= 0) return [0, labels.length - 1];
    final maxLabels = (width / slotWidth).floor().clamp(2, labels.length);
    if (maxLabels >= labels.length) {
      return List.generate(labels.length, (i) => i);
    }

    final result = <int>[0];
    if (maxLabels > 2) {
      final step = (labels.length - 1) / (maxLabels - 1);
      for (int i = 1; i < maxLabels - 1; i++) {
        result.add((step * i).round());
      }
    }
    result.add(labels.length - 1);
    return result;
  }

  // ── Legend ────────────────────────────────────────────────────────────

  void _paintLegend(Canvas canvas, Size size) {
    double x = chartArea.left;
    final maxX = chartArea.right;
    final y = size.height - padding.bottom - chartLegendBottomOffset;

    for (final entry in legend) {
      final tp = _layoutText(entry.label, _effectiveLegendStyle);

      final entryWidth = chartLegendTextOffset + tp.width + chartLegendEntryGap;
      if (x + entryWidth > maxX && x > chartArea.left) break;

      final dotPaint = Paint()..color = entry.color;
      canvas.drawCircle(
        Offset(x + chartLegendDotOffset, y),
        chartLegendDotRadius,
        dotPaint,
      );
      tp.paint(canvas, Offset(x + chartLegendTextOffset, y - tp.height / 2));
      x += entryWidth;
    }
  }

  // ── Coordinate helpers for subclasses ────────────────────────────────

  /// Converts a Y data value to canvas Y coordinate.
  double yToCanvas(double value) {
    if (yMax == yMin) return chartArea.center.dy;
    final fraction = (value - yMin) / (yMax - yMin);
    return chartArea.bottom - chartArea.height * fraction;
  }

  /// Converts an X data value to canvas X coordinate using numeric range.
  double xToCanvasValue(double value) {
    final minVal = xMin ?? 0;
    final maxVal = xMax ?? 1;
    if (maxVal == minVal) return chartArea.center.dx;
    final fraction = (value - minVal) / (maxVal - minVal);
    return chartArea.left + chartArea.width * fraction;
  }

  /// Converts a point index to canvas X coordinate (for categorical axes).
  @Deprecated('Use xToCanvasValue or xPositionForLabel instead')
  double xToCanvas(int index, int total) {
    if (total <= 1) return chartArea.center.dx;
    return chartArea.left + chartArea.width * index / (total - 1);
  }
}
