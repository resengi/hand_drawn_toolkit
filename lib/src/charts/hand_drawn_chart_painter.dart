import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals, visibleForTesting;
import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
import '../hand_drawn_toolkit_helpers.dart';
import 'chart_data.dart';
import 'chart_layout.dart';

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
    this.irregularity = HandDrawnDefaults.chartIrregularity,
    this.segments = HandDrawnDefaults.chartSegments,
    this.axisColor = HandDrawnDefaults.chartAxisColor,
    this.grid = GridConfig.standard,
    this.labelStyle = HandDrawnDefaults.chartLabelStyle,
    this.padding = HandDrawnDefaults.chartPadding,
    this.xLabels = const [],
    this.legend = const [],
    this.title,
    this.yAxisLabel,
    this.xAxisLabel,
    this.yMin = 0,
    this.yMax = 1,
    this.yDivisions = HandDrawnDefaults.chartYDivisions,
    this.xMin,
    this.xMax,
    this.xDivisions = HandDrawnDefaults.chartXDivisions,
    this.seed = HandDrawnDefaults.seed,
    this.yValueFormatter,
    this.xValueFormatter,
    this.titleStyle,
    this.legendStyle,
    this.axisStrokeWidth = HandDrawnDefaults.chartAxisStrokeWidth,
    this.axisDisplay = AxisDisplay.edge,
    this.xLabelConfig = ChartLabelConfig.horizontal,
    this.legendConfig = ChartLegendConfig.inlineBottom,
    this.clipToChartArea = false,
  }) {
    if (yDivisions <= 0) {
      throw ArgumentError.value(yDivisions, 'yDivisions', 'must be positive');
    }
    if (xDivisions <= 0) {
      throw ArgumentError.value(xDivisions, 'xDivisions', 'must be positive');
    }
    // Finite-value checks run before the ordering checks below: NaN
    // comparisons return false in Dart, so without these guards a NaN
    // bound would slip past `yMin > yMax` and produce silent NaN canvas
    // coordinates downstream.
    if (!yMin.isFinite || !yMax.isFinite) {
      throw ArgumentError(
        'yMin and yMax must be finite, got yMin=$yMin, yMax=$yMax',
      );
    }
    if (xMin != null && !xMin!.isFinite) {
      throw ArgumentError.value(xMin, 'xMin', 'must be finite');
    }
    if (xMax != null && !xMax!.isFinite) {
      throw ArgumentError.value(xMax, 'xMax', 'must be finite');
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

  /// When `true`, subclass data rendering (the `paintData` call) is
  /// clipped to the plot area so values outside the declared axis
  /// bounds can't paint across axes, labels, title, or legend. Defaults
  /// to `false`.
  final bool clipToChartArea;

  /// Grid configuration bundle. See [GridConfig] for all knobs.
  final GridConfig grid;
  final TextStyle labelStyle;

  /// Outer padding around the chart layout bands.
  ///
  /// The [left] value controls the gutter reserved for Y-axis labels.
  /// The default (40 px) suits short numeric labels. When using a
  /// [yValueFormatter] that produces longer strings (e.g. `"$1,234.56"`),
  /// increase [left] to prevent label clipping. The same applies when
  /// using a [labelStyle] with a larger font: the Y-axis title (when
  /// [yAxisLabel] is set) reserves left-gutter space proportional to
  /// the rendered text height, so increase [left] enough to clear the
  /// label height plus a few pixels of breathing room.
  ///
  /// With rotated x-axis labels (see [ChartLabelConfig]), increase
  /// [left] and/or [right] when the first or last tick label is long:
  /// rotation reserves vertical space in the X tick band but does not
  /// adjust horizontal padding, so a long diagonal or vertical label
  /// at an edge tick can spill into the Y-label gutter or past the
  /// chart's right edge.
  final EdgeInsets padding;
  final List<String> xLabels;

  /// Legend entries for this chart.
  ///
  /// Layout, position, and styling are controlled via [legendConfig].
  /// To render entries without the chart painting its own legend
  /// (e.g. when composing a standalone [HandDrawnLegend]), pass
  /// [ChartLegendConfig.hidden].
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

  /// Per-axis display configuration. Defaults to edge-aligned axes.
  /// When set to zero-crossing, an axis line is drawn at the zero
  /// position instead of the chart edge — but only when zero is
  /// strictly inside the visible range for that axis. The horizontal
  /// setting applies to all numeric Y-range chart types (line,
  /// scatter, and bar). The vertical setting requires a numeric X
  /// scale and is therefore a no-op on bar charts (whose X axis is
  /// categorical) and on line charts that don't configure
  /// `xMin`/`xMax`.
  final AxisDisplay axisDisplay;

  /// Per-axis tick label configuration (currently the X tick label
  /// band — rotation, thinning sensitivity, and so on). Defaults to
  /// horizontal labels. See [ChartLabelConfig] for usage.
  final ChartLabelConfig xLabelConfig;

  /// Legend layout configuration — visibility, position (bottom or
  /// right), boxed/unboxed, wrapping, padding, spacing. Defaults to
  /// [ChartLegendConfig.inlineBottom] (a single inline row at the
  /// bottom of the chart, no box, hard-truncates on overflow). Opt
  /// into external boxed legends with
  /// [ChartLegendConfig.externalBottomBoxed] / `.externalRightBoxed`,
  /// or suppress the chart-managed legend entirely with
  /// [ChartLegendConfig.hidden] when composing your own
  /// [HandDrawnLegend] widget.
  final ChartLegendConfig legendConfig;

  /// Internal frame layout, set during [paint] via [buildFrame].
  late ChartFrameLayout _frame;

  /// Cached wobbly-box path for the legend, retained on the painter
  /// instance across paints when the legend rect hasn't changed.
  /// Generating the wobbly path involves seeded RNG and segment
  /// construction — repeating it every paint would be wasteful when
  /// the same painter instance is reused (e.g. when the parent
  /// triggers a repaint without rebuilding the [CustomPaint]).
  Path? _cachedLegendBox;

  /// The legend rect that [_cachedLegendBox] was generated for. Used
  /// as the cache key — when the live rect's LTRB matches this, the
  /// cached path is reused; otherwise we regenerate.
  Rect? _cachedLegendRect;

  /// The internal frame layout, valid after [paint] has been called.
  /// Subclass painters may need it to call into shared geometry helpers
  /// (e.g. `bar_geometry.dart`) that work in canvas coordinates.
  @protected
  @visibleForTesting
  ChartFrameLayout get frame => _frame;

  /// The main plotting region. Read-only; computed during [paint].
  ///
  /// Throws `LateInitializationError` if accessed before [paint] has
  /// run; calling `computeLayout()` does not initialize this getter.
  /// Consumers should read `chartArea` from a `BarChartLayout`,
  /// `LineChartLayout`, or `ScatterPlotLayout` returned by
  /// `computeLayout()` instead of reading this directly.
  Rect get chartArea => _frame.chartArea;

  /// Builds the canonical [ChartFrameLayout] for a given [size].
  ///
  /// Both [paint] and subclass `computeLayout()` methods use this to
  /// ensure a single source of truth for chart geometry.
  @protected
  ChartFrameLayout buildFrame(Size size) {
    return buildChartFrame(
      size: size,
      padding: padding,
      yMin: yMin,
      yMax: yMax,
      xMin: xMin,
      xMax: xMax,
      title: title,
      titleStyle: titleStyle,
      labelStyle: labelStyle,
      legendTextStyle: _effectiveLegendStyle,
      xAxisLabel: xAxisLabel,
      xLabels: xLabels,
      hasNumericXAxis: _hasNumericXAxis,
      legendEntries: legend,
      legendConfig: legendConfig,
      xLabelConfig: xLabelConfig,
      xValueFormatter: xValueFormatter,
      xDivisions: xDivisions,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    _frame = buildFrame(size);
    final padded = _frame.paddedBounds;

    // Paint in order: background → axes → data → overlays.
    if (title != null) _paintTitle(canvas, padded);
    _paintGridLines(canvas);
    _paintAxes(canvas);
    _paintYLabels(canvas);
    if (yAxisLabel != null) _paintYAxisLabel(canvas, padded);
    _paintXTicksOrLabels(canvas);
    if (xAxisLabel != null) _paintXAxisTitle(canvas);
    if (clipToChartArea) {
      canvas.save();
      canvas.clipRect(_frame.chartArea);
      paintData(canvas, size);
      canvas.restore();
    } else {
      paintData(canvas, size);
    }
    if (legend.isNotEmpty && legendConfig.visible) _paintLegend(canvas);
  }

  /// Override in subclasses to paint chart-specific content.
  void paintData(Canvas canvas, Size size);

  @override
  bool shouldRepaint(covariant HandDrawnChartPainter oldDelegate) {
    return oldDelegate.seed != seed ||
        oldDelegate.irregularity != irregularity ||
        oldDelegate.segments != segments ||
        oldDelegate.axisColor != axisColor ||
        oldDelegate.grid != grid ||
        oldDelegate.labelStyle != labelStyle ||
        oldDelegate.padding != padding ||
        oldDelegate.yMin != yMin ||
        oldDelegate.yMax != yMax ||
        oldDelegate.yDivisions != yDivisions ||
        oldDelegate.xMin != xMin ||
        oldDelegate.xMax != xMax ||
        oldDelegate.xDivisions != xDivisions ||
        oldDelegate.title != title ||
        oldDelegate.clipToChartArea != clipToChartArea ||
        oldDelegate.yAxisLabel != yAxisLabel ||
        oldDelegate.xAxisLabel != xAxisLabel ||
        oldDelegate.yValueFormatter != yValueFormatter ||
        oldDelegate.xValueFormatter != xValueFormatter ||
        oldDelegate.titleStyle != titleStyle ||
        oldDelegate.legendStyle != legendStyle ||
        oldDelegate.axisStrokeWidth != axisStrokeWidth ||
        oldDelegate.axisDisplay != axisDisplay ||
        oldDelegate.xLabelConfig != xLabelConfig ||
        oldDelegate.legendConfig != legendConfig ||
        !listEquals(oldDelegate.xLabels, xLabels) ||
        !listEquals(oldDelegate.legend, legend);
  }

  bool get _hasNumericXAxis => xLabels.isEmpty && xMin != null && xMax != null;

  // ── Text helper ──────────────────────────────────────────────────────

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
    return defaultNumericFormatter(value);
  }

  String formatXValue(double value) {
    if (xValueFormatter != null) return xValueFormatter!(value);
    return defaultNumericFormatter(value);
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

  /// Builds a wobbly stroke through a pre-sampled polyline, pinning only
  /// the first and last vertices and applying smoothed jitter to every
  /// interior sample.
  ///
  /// Intended for the function-series anchor-stride renderer: the caller
  /// hands in a sub-polyline (e.g. samples `[i .. i+stride]` from a
  /// `pathRun`) and the result is one wobbled "anchor segment" that
  /// passes through the true sampled values at both ends and wobbles in
  /// between. Multiple consecutive calls share their endpoint anchors
  /// (the previous segment's last point is the next segment's first),
  /// which gives the line continuity at anchors and independent wobble
  /// phase between them.
  ///
  /// Wobble amplitude is automatically capped based off of the straight-
  /// line distance between the first and last point, so short anchor
  /// segments don't get overwhelmed by jitter that was tuned for
  /// longer strokes.
  Path wobblePolyline(List<Offset> sub, int polySeed, {double? jitter}) {
    assert(sub.length >= 2, 'wobbleAlongPolyline requires at least 2 points');

    final segs = sub.length - 1;
    final anchorSpan = (sub.last - sub.first).distance;
    final irrCap = anchorSpan * percentageIrregularityCap;
    final effectiveIrr = math.min(jitter ?? irregularity, irrCap);

    final offsets = _smoothedOffsets2D(polySeed, segs, effectiveIrr);

    final path = Path()..moveTo(sub.first.dx, sub.first.dy);
    for (int i = 1; i <= segs; i++) {
      if (i == segs) {
        path.lineTo(sub.last.dx, sub.last.dy);
      } else {
        path.lineTo(sub[i].dx + offsets.x[i], sub[i].dy + offsets.y[i]);
      }
    }
    return path;
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
    final irr = jitter ?? (irregularity * scatterCircleJitterRatio);

    final raw = List<double>.filled(points, 0);
    for (int i = 0; i < points; i++) {
      raw[i] = (rng.nextDouble() - 0.5) * irr;
    }
    final smoothed = HandDrawnHelpers.smooth(raw);

    final path = Path();
    final step = 2 * math.pi / points;

    for (int i = 0; i < points; i++) {
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

    // Resolved positions: fall back to edges unless the caller opted
    // into zero-crossing AND zero is actually visible on that axis.
    final horizontalY = _frame.resolvedHorizontalAxisY(
      zeroCrossing: axisDisplay.horizontal == AxisDisplayMode.zeroCrossing,
    );
    final verticalX = _frame.resolvedVerticalAxisX(
      zeroCrossing: axisDisplay.vertical == AxisDisplayMode.zeroCrossing,
    );

    // Horizontal (X) axis — spans full chart width at the resolved Y.
    canvas.drawPath(
      wobblyLine(
        Offset(chartArea.left, horizontalY),
        Offset(chartArea.right, horizontalY),
        seed + chartAxisSeedOffset,
      ),
      axisPaint,
    );
    // Vertical (Y) axis — spans full chart height at the resolved X.
    canvas.drawPath(
      wobblyLine(
        Offset(verticalX, chartArea.bottom),
        Offset(verticalX, chartArea.top),
        seed + chartAxisSeedOffset + 1,
      ),
      axisPaint,
    );
  }

  // ── Grid ─────────────────────────────────────────────────────────────

  void _paintGridLines(Canvas canvas) {
    final gridPaint = Paint()
      ..color = grid.color
      ..strokeWidth = grid.strokeWidth
      ..style = PaintingStyle.stroke;

    // Sub-grid lines use the same color with alpha scaled by the
    // config's multiplier — giving the familiar graph-paper two-tier
    // look without introducing a second style knob.
    final subGridPaint = Paint()
      ..color = grid.color.withValues(
        alpha: grid.color.a * grid.subGridAlphaMultiplier,
      )
      ..strokeWidth = grid.strokeWidth
      ..style = PaintingStyle.stroke;

    // Horizontal grid lines — one per Y division. Loop runs from 0
    // (bottom edge) through yDivisions (top edge) so every chart has a
    // complete grid. In edge mode, the bottom-edge grid line at i=0
    // sits directly under the X-axis line, which is drawn afterward
    // and fully obscures it. In zero-crossing mode, the bottom-edge
    // grid line is the only thing marking that boundary.
    if (grid.showHorizontal) {
      for (int i = 0; i <= yDivisions; i++) {
        final fraction = i / yDivisions;
        final y = chartArea.bottom - chartArea.height * fraction;
        canvas.drawPath(
          wobblyLine(
            Offset(chartArea.left, y),
            Offset(chartArea.right, y),
            seed + chartGridSeedOffset + i,
            jitter: irregularity * grid.jitterRatio,
          ),
          gridPaint,
        );
      }

      // Sub-grid horizontal lines — N extra lines evenly spaced
      // between each pair of adjacent main grid lines.
      final subCount = grid.horizontalSubGridLinesBetweenTicks;
      if (subCount > 0) {
        for (int i = 0; i < yDivisions; i++) {
          for (int k = 0; k < subCount; k++) {
            final fraction = (i + (k + 1) / (subCount + 1)) / yDivisions;
            final y = chartArea.bottom - chartArea.height * fraction;
            canvas.drawPath(
              wobblyLine(
                Offset(chartArea.left, y),
                Offset(chartArea.right, y),
                seed + chartSubGridSeedOffset + i * subCount + k,
                jitter: irregularity * grid.jitterRatio,
              ),
              subGridPaint,
            );
          }
        }
      }
    }

    // Vertical grid lines — only for numeric-X charts (line, scatter).
    // Bar charts use categorical X with no "divisions" concept, so no
    // vertical grid makes sense there. X positions match the numeric
    // X tick positions exactly so ticks and grid line up. Same edge
    // symmetry as the horizontal loop: left-edge grid line at i=0 sits
    // under the Y-axis line in edge mode (obscured); in zero-crossing
    // mode, it anchors the chart's left boundary.
    if (_hasNumericXAxis && grid.showVertical) {
      for (int i = 0; i <= xDivisions; i++) {
        final fraction = i / xDivisions;
        final x = chartArea.left + chartArea.width * fraction;
        canvas.drawPath(
          wobblyLine(
            Offset(x, chartArea.top),
            Offset(x, chartArea.bottom),
            seed + chartVerticalGridSeedOffset + i,
            jitter: irregularity * grid.jitterRatio,
          ),
          gridPaint,
        );
      }

      // Sub-grid vertical lines.
      final subCount = grid.verticalSubGridLinesBetweenTicks;
      if (subCount > 0) {
        for (int i = 0; i < xDivisions; i++) {
          for (int k = 0; k < subCount; k++) {
            final fraction = (i + (k + 1) / (subCount + 1)) / xDivisions;
            final x = chartArea.left + chartArea.width * fraction;
            canvas.drawPath(
              wobblyLine(
                Offset(x, chartArea.top),
                Offset(x, chartArea.bottom),
                seed + chartVerticalSubGridSeedOffset + i * subCount + k,
                jitter: irregularity * grid.jitterRatio,
              ),
              subGridPaint,
            );
          }
        }
      }
    }
  }

  // ── Title ────────────────────────────────────────────────────────────

  void _paintTitle(Canvas canvas, Rect padded) {
    final tp = layoutText(title!, _effectiveTitleStyle);
    tp.paint(
      canvas,
      Offset(padded.left + (padded.width - tp.width) / 2, padded.top),
    );
  }

  // ── Y-axis label ────────────────────────────────────────────────────

  void _paintYAxisLabel(Canvas canvas, Rect padded) {
    final tp = layoutText(yAxisLabel!, labelStyle);
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

      final tp = layoutText(formatYValue(value), labelStyle);
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

    final isRotated = xLabelConfig.isRotated;

    for (int i = 0; i < xLabels.length; i++) {
      final x = xPositionForLabel(i, xLabels.length);

      canvas.drawLine(
        Offset(x, chartArea.bottom),
        Offset(x, chartArea.bottom + chartTickLength),
        tickPaint,
      );

      if (positions.contains(i)) {
        final tp = layoutText(xLabels[i], labelStyle);
        if (isRotated) {
          _paintRotatedXLabel(
            canvas: canvas,
            tp: tp,
            tickX: x,
            tickTopY: chartArea.bottom + chartTickLabelGap,
            angleDegrees: xLabelConfig.rotationDegrees,
          );
        } else {
          tp.paint(
            canvas,
            Offset(x - tp.width / 2, chartArea.bottom + chartTickLabelGap),
          );
        }
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
    final isRotated = xLabelConfig.isRotated;

    for (int i = 0; i <= xDivisions; i++) {
      final fraction = i / xDivisions;
      final x = chartArea.left + chartArea.width * fraction;

      canvas.drawLine(
        Offset(x, chartArea.bottom),
        Offset(x, chartArea.bottom + chartTickLength),
        tickPaint,
      );

      if (visible.contains(i)) {
        final tp = layoutText(labels[i], labelStyle);
        if (isRotated) {
          _paintRotatedXLabel(
            canvas: canvas,
            tp: tp,
            tickX: x,
            tickTopY: chartArea.bottom + chartTickLabelGap,
            angleDegrees: xLabelConfig.rotationDegrees,
          );
        } else {
          tp.paint(
            canvas,
            Offset(x - tp.width / 2, chartArea.bottom + chartTickLabelGap),
          );
        }
      }
    }
  }

  /// Paints an X tick label rotated around its tick anchor.
  ///
  /// The pivot is `(tickX, tickTopY)` — the top of where the unrotated
  /// label would otherwise sit. The text bounding box is anchored so
  /// the corner closest to the tick stays pinned at that pivot:
  ///
  /// - For [angleDegrees] ≤ 0 (the typical case for long-label
  ///   diagonals like -45° and -90° vertical) we anchor the unrotated
  ///   upper-right corner at the pivot, so the text fans down and to
  ///   the left of the tick.
  /// - For positive angles we anchor the unrotated upper-left corner,
  ///   so the text fans down and to the right.
  ///
  /// In both cases the pivot itself sits [chartTickLabelGap] below the
  /// tick line, which preserves the same vertical gap-to-tick that the
  /// horizontal path produces — labels never sit on top of their ticks
  /// regardless of rotation.
  void _paintRotatedXLabel({
    required Canvas canvas,
    required TextPainter tp,
    required double tickX,
    required double tickTopY,
    required double angleDegrees,
  }) {
    final theta = angleDegrees * math.pi / 180.0;
    final dx = angleDegrees <= 0 ? -tp.width : 0.0;

    canvas.save();
    canvas.translate(tickX, tickTopY);
    canvas.rotate(theta);
    tp.paint(canvas, Offset(dx, 0));
    canvas.restore();
  }

  // ── X-axis title ─────────────────────────────────────────────────────

  void _paintXAxisTitle(Canvas canvas) {
    final xTickH = _frame.xTickHeight;
    final tp = layoutText(xAxisLabel!, labelStyle);
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

    // Minimum non-overlapping horizontal distance between adjacent
    // rotated labels, derived via the Separating Axis Theorem applied
    // to two same-orientation rectangles. Reduces to `w` at θ=0
    // (horizontal labels) and to `h` at θ=±90° (vertical labels). For
    // diagonal angles, the perpendicular-projection term `h/|sinθ|`
    // typically dominates, giving much tighter packing than a
    // bounding-box approach would — which is what we want, since
    // diagonal labels' bounding boxes interleave their empty corners
    // without the text actually overlapping.
    final theta = xLabelConfig.rotationRadians;
    final cosT = math.cos(theta).abs();
    final sinT = math.sin(theta).abs();

    double maxLabelW = 0;
    double maxLabelH = 0;
    for (final label in labels) {
      final tp = layoutText(label, labelStyle);
      if (tp.width > maxLabelW) maxLabelW = tp.width;
      if (tp.height > maxLabelH) maxLabelH = tp.height;
    }

    // Explicit zero-guards: at θ=0 only the parallel constraint
    // applies; at θ=±π/2 only the perpendicular constraint applies.
    final parallelLimit = cosT == 0 ? double.infinity : maxLabelW / cosT;
    final perpendicularLimit = sinT == 0 ? double.infinity : maxLabelH / sinT;
    final visualWidth = math.min(parallelLimit, perpendicularLimit);

    final slotWidth = visualWidth + xLabelConfig.minVisibleGap;
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

  /// Test-only accessor for the label thinning algorithm. Returns the
  /// indices into [labels] of the labels that would render visibly given
  /// the chart-area [width] in logical pixels and the painter's current
  /// [xLabelConfig] and [labelStyle]. Not part of the public API; used
  /// by tests that need to verify thinning behavior.
  @visibleForTesting
  List<int> debugSelectedLabelPositions(List<String> labels, double width) =>
      _selectLabelPositions(labels, width);

  // ── Legend ────────────────────────────────────────────────────────────

  void _paintLegend(Canvas canvas) {
    final layout = _frame.legendLayout;
    final rect = _frame.legendArea;
    if (layout == null || layout.origins.isEmpty || rect.isEmpty) return;

    // Optional wobbly box border around the legend rect. Painted
    // unclipped: the hand-drawn wobble is meant to extend a couple
    // of pixels past the rect's mathematical edges, matching how
    // every other wobbly box in the package renders. The path is
    // cached across paints — regenerated only when the rect changes
    // (Dart's Rect equality is value-based on LTRB, so this works
    // without explicit hashing). This is material when the chart
    // sits inside a scrolling list: re-running the seeded RNG and
    // segment construction every frame would otherwise stutter.
    if (legendConfig.boxed) {
      if (_cachedLegendBox == null || _cachedLegendRect != rect) {
        final helpers = HandDrawnHelpers(
          seed: seed + chartLegendBoxSeedOffset,
          segments: defaultWobblyRectSegments,
          irregularity: irregularity,
        );
        _cachedLegendBox = helpers.rectBorder(rect.size).shift(rect.topLeft);
        _cachedLegendRect = rect;
      }
      final boxPaint = Paint()
        ..color = axisColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = chartTickStrokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_cachedLegendBox!, boxPaint);
    }

    // Clip only the entry painting to the reserved rect so neither
    // overflowing entry text nor color dots can paint into adjacent
    // chart bands (X tick labels, axis title, plot area). A
    // right-position legend with many entries or a bottom legend
    // with an unusually wide single label would otherwise spill
    // beyond its reservation.
    canvas.save();
    canvas.clipRect(rect);

    // Anchor inside the rect: indent by padding when boxed; otherwise
    // vertical-center the content within the available rect height so
    // the legend sits midway in its reserved band.
    final innerLeft =
        rect.left + (legendConfig.boxed ? legendConfig.padding.left : 0.0);
    final innerTop = legendConfig.boxed
        ? rect.top + legendConfig.padding.top
        : rect.top + (rect.height - layout.size.height) / 2;

    // Walk the pre-computed entry origins and paint each one. Index i
    // ties each laid-out entry back to its `legend` entry — order is
    // preserved by `layoutLegend`, and truncated layouts contain a
    // strict prefix of `legend`.
    for (int i = 0; i < layout.origins.length; i++) {
      final (painter, origin) = layout.origins[i];
      final entry = legend[i];
      final entryX = innerLeft + origin.dx;
      final entryY = innerTop + origin.dy;
      // For right-position legends, painters may have wrapped onto
      // multiple lines and report a height larger than rowHeight
      // (which is the floor: max single-line height or dot
      // diameter). Take the max so the dot sits at the vertical
      // center of the actual entry's row, not the floor's row.
      final entryRowHeight = math.max(layout.rowHeight, painter.height);
      final centerY = entryY + entryRowHeight / 2;

      final dotPaint = Paint()..color = entry.color;
      canvas.drawCircle(
        Offset(entryX + chartLegendDotOffset, centerY),
        chartLegendDotRadius,
        dotPaint,
      );
      painter.paint(
        canvas,
        Offset(entryX + chartLegendTextOffset, centerY - painter.height / 2),
      );
    }

    canvas.restore();
  }

  // ── Coordinate helpers for subclasses ────────────────────────────────

  /// Converts a Y data value to canvas Y coordinate.
  ///
  /// Delegates to the internal frame layout for consistency with
  /// `computeLayout()`.
  double yToCanvas(double value) => _frame.yToCanvas(value);

  /// Converts an X data value to canvas X coordinate using numeric range.
  ///
  /// Delegates to the internal frame layout for consistency with
  /// `computeLayout()`.
  double xToCanvasValue(double value) => _frame.xToCanvasValue(value);
}
