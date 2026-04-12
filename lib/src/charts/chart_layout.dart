import 'dart:math' as math;
import 'dart:ui' show Rect, Size;

import 'package:flutter/painting.dart'
    show EdgeInsets, TextDirection, TextPainter, TextSpan, TextStyle;

import '../hand_drawn_constants.dart';

/// Internal immutable frame describing the chart's spatial layout bands.
///
/// Both `paint()` and `computeLayout()` obtain their geometry from this
/// object, ensuring a single source of truth. This type is intentionally
/// package-private — consumers access chart area data through the public
/// layout objects returned by `computeLayout()`.
class ChartFrameLayout {
  const ChartFrameLayout({
    required this.paddedBounds,
    required this.chartArea,
    required this.xTickHeight,
    required this.yMin,
    required this.yMax,
    this.xMin,
    this.xMax,
  });

  /// Bounds after applying outer padding.
  final Rect paddedBounds;

  /// The main plotting region after all bands are reserved.
  final Rect chartArea;

  /// Reserved height for X-axis tick labels.
  final double xTickHeight;

  // Y-axis range.
  final double yMin;
  final double yMax;

  // Optional X-axis numeric range.
  final double? xMin;
  final double? xMax;

  // ── Coordinate mapping ──────────────────────────────────────────────────

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

  /// Returns the X pixel position for a bar-chart slot at [index]
  /// using slot-center spacing.
  double xPositionForBar(int index, int count) {
    if (count <= 0) return chartArea.center.dx;
    final slotWidth = chartArea.width / count;
    return chartArea.left + slotWidth * (index + 0.5);
  }
}

/// Builds a [ChartFrameLayout] from the painter's configuration.
///
/// This is the single canonical geometry path. Both `paint()` and
/// `computeLayout()` call this function.
ChartFrameLayout buildChartFrame({
  required Size size,
  required EdgeInsets padding,
  required double yMin,
  required double yMax,
  required String? title,
  required TextStyle? titleStyle,
  required TextStyle labelStyle,
  required String? xAxisLabel,
  required List<String> xLabels,
  required bool hasNumericXAxis,
  required bool hasLegend,
  double? xMin,
  double? xMax,
}) {
  final paddedBounds = Rect.fromLTWH(
    padding.left,
    padding.top,
    size.width - padding.left - padding.right,
    size.height - padding.top - padding.bottom,
  );

  // Measure band heights.
  final titleHeight = _measureTitleHeight(title, titleStyle, labelStyle);
  final xTickHeight = _measureXTickHeight(xLabels, hasNumericXAxis);
  final xAxisTitleHeight = _measureXAxisTitleHeight(xAxisLabel, labelStyle);
  final legendHeight = hasLegend ? chartLegendBandHeight : 0.0;

  // Chart area fills whatever is left.
  final chartTop = paddedBounds.top + titleHeight;
  final rawBottom =
      paddedBounds.bottom - xTickHeight - xAxisTitleHeight - legendHeight;

  assert(
    rawBottom >= chartTop,
    'Chart has been given insufficient vertical space for its configured '
    'title, tick, axis-label, and legend bands. Provide more height or '
    'reduce the number of visible bands.',
  );

  // Clamp for release safety so the plot rect never inverts.
  final chartBottom = math.max(chartTop, rawBottom);
  final chartArea = Rect.fromLTRB(
    paddedBounds.left,
    chartTop,
    paddedBounds.right,
    chartBottom,
  );

  return ChartFrameLayout(
    paddedBounds: paddedBounds,
    chartArea: chartArea,
    xTickHeight: xTickHeight,
    yMin: yMin,
    yMax: yMax,
    xMin: xMin,
    xMax: xMax,
  );
}

// ── Private measurement helpers ───────────────────────────────────────────

TextStyle _effectiveTitleStyle(TextStyle? titleStyle, TextStyle labelStyle) {
  return titleStyle ??
      labelStyle.copyWith(
        fontSize: chartTitleFontSize,
        fontWeight: chartTitleFontWeight,
      );
}

double _measureTitleHeight(
  String? title,
  TextStyle? titleStyle,
  TextStyle labelStyle,
) {
  if (title == null) return 0;
  final tp = _layoutText(title, _effectiveTitleStyle(titleStyle, labelStyle));
  return tp.height + chartTitleSpacing;
}

double _measureXTickHeight(List<String> xLabels, bool hasNumericXAxis) {
  if (xLabels.isNotEmpty || hasNumericXAxis) {
    return chartXTickBandHeight;
  }
  return 0;
}

double _measureXAxisTitleHeight(String? xAxisLabel, TextStyle labelStyle) {
  if (xAxisLabel == null) return 0;
  final tp = _layoutText(xAxisLabel, labelStyle);
  return tp.height + chartXAxisTitleSpacing;
}

TextPainter _layoutText(String text, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
  )..layout();
  return tp;
}
