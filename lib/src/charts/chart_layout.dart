import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import 'package:flutter/painting.dart' show EdgeInsets, TextPainter, TextStyle;

import '../hand_drawn_constants.dart';
import '../hand_drawn_toolkit_defaults.dart';
import '../hand_drawn_toolkit_helpers.dart' show layoutText;
import 'chart_data.dart'
    show
        AxisValueFormatter,
        ChartLabelConfig,
        ChartLegendConfig,
        ChartLegendPosition,
        LegendEntry;

/// Default neutral numeric formatter used by chart axes when no
/// custom [AxisValueFormatter] is supplied.
///
/// Whole-number values render without a decimal; values under 100
/// render with one decimal place; larger values round to the nearest
/// integer. No domain assumptions (no currency, units, dates).
///
/// For ranges with values below 1.0, this formatter rounds to one
/// decimal place (so `0.001` renders as `'0.0'`). Supply a custom
/// formatter via the chart data's `yValueFormatter` or
/// `xValueFormatter` when finer precision is needed.
///
/// Package-internal — `chart_layout.dart` is not exported from the
/// public surface, so this stays out of the public API while still
/// being shared between the layout engine and the painter.
String defaultNumericFormatter(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  if (value.abs() < 100) return value.toStringAsFixed(1);
  return value.round().toString();
}

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
    this.legendArea = Rect.zero,
    this.legendLayout,
    this.xMin,
    this.xMax,
    this.xLabels = const [],
  });

  /// Bounds after applying outer padding.
  final Rect paddedBounds;

  /// The main plotting region after all bands are reserved.
  final Rect chartArea;

  /// Reserved height for X-axis tick labels.
  final double xTickHeight;

  /// Rect carved out for the chart's legend. `Rect.zero` when the
  /// chart has no visible legend or no entries — callers should check
  /// for this before painting.
  final Rect legendArea;

  /// Pre-computed legend layout (per-entry origins, row height, outer
  /// size) produced during frame construction. The painter reads this
  /// directly so layout work isn't repeated at paint time.
  /// `null` when there is no legend to paint.
  final ({Size size, double rowHeight, List<(TextPainter, Offset)> origins})?
  legendLayout;

  // Y-axis range.
  final double yMin;
  final double yMax;

  // Optional X-axis numeric range.
  final double? xMin;
  final double? xMax;

  /// Categorical X-axis labels, if the chart uses categorical mode.
  ///
  /// Empty (the default) indicates a numeric X axis. When non-empty,
  /// the chart positions points by [xMin]/[xMax] for layout but treats
  /// the X axis as categorical for grid and axis-rendering decisions —
  /// see [isZeroVisibleX].
  final List<String> xLabels;

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

  // ── Axis-position resolution (zero-crossing support) ───────────────────

  /// Whether `y = 0` lies strictly inside the visible Y range
  /// (exclusive of the edges — at the edges the resolved position would
  /// coincide with the edge axis anyway).
  bool get isZeroVisibleY => yMin < 0 && yMax > 0;

  /// Whether `x = 0` lies strictly inside the visible numeric X range.
  /// Returns false when the chart has no numeric X range configured.
  bool get isZeroVisibleX {
    if (xLabels.isNotEmpty) return false;
    final lo = xMin;
    final hi = xMax;
    if (lo == null || hi == null) return false;
    return lo < 0 && hi > 0;
  }

  /// Canvas Y where the horizontal (X) axis line should be drawn.
  ///
  /// Returns the zero-crossing position when [zeroCrossing] is true AND
  /// zero is inside the visible Y range; otherwise returns the chart's
  /// bottom edge.
  double resolvedHorizontalAxisY({required bool zeroCrossing}) {
    if (zeroCrossing && isZeroVisibleY) return yToCanvas(0);
    return chartArea.bottom;
  }

  /// Canvas X where the vertical (Y) axis line should be drawn.
  ///
  /// Returns the zero-crossing position when [zeroCrossing] is true AND
  /// zero is inside the visible numeric X range; otherwise returns the
  /// chart's left edge. Zero-crossing on the vertical axis requires a
  /// numeric X scale — if none is configured, falls back to the edge.
  double resolvedVerticalAxisX({required bool zeroCrossing}) {
    if (zeroCrossing && isZeroVisibleX) return xToCanvasValue(0);
    return chartArea.left;
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
  required TextStyle legendTextStyle,
  required String? xAxisLabel,
  required List<String> xLabels,
  required bool hasNumericXAxis,
  required List<LegendEntry> legendEntries,
  required ChartLegendConfig legendConfig,
  ChartLabelConfig xLabelConfig = ChartLabelConfig.horizontal,
  double? xMin,
  double? xMax,
  int xDivisions = HandDrawnDefaults.chartXDivisions,
  AxisValueFormatter? xValueFormatter,
}) {
  final paddedBounds = Rect.fromLTWH(
    padding.left,
    padding.top,
    size.width - padding.left - padding.right,
    size.height - padding.top - padding.bottom,
  );

  // Measure title and X tick band first — those are unaffected by the
  // legend's position, so they always carve from the top and bottom of
  // the padded bounds respectively.
  final titleHeight = _measureTitleHeight(title, titleStyle, labelStyle);
  final xTickHeight = _measureXTickHeight(
    xLabels,
    hasNumericXAxis,
    labelStyle,
    xLabelConfig,
    xMin: xMin,
    xMax: xMax,
    xDivisions: xDivisions,
    xValueFormatter: xValueFormatter,
  );
  final xAxisTitleHeight = _measureXAxisTitleHeight(xAxisLabel, labelStyle);

  // Legend reservation. Three branches:
  //   1) Not visible OR empty entries → no legend, no reservation.
  //   2) position == bottom → reserve a measured-height bottom band.
  //   3) position == right  → reserve a measured-width right column.
  //
  // For unboxed bottom legends the band height is floored at
  // `chartLegendBandHeight` so the inline default sits in a
  // consistent strip even when the measured content is shorter.
  final showLegend = legendConfig.visible && legendEntries.isNotEmpty;

  ({Size size, double rowHeight, List<(TextPainter, Offset)> origins})?
  legendLayout;
  double bottomLegendHeight = 0;
  double rightLegendWidth = 0;

  if (showLegend) {
    // Width budget for the legend. Bottom-positioned: full padded
    // width. Right-positioned: cap the CONTENT width separately from
    // the chart/legend gap so the value passed to layoutLegend matches
    // the final legendArea.width exactly. The invariant maintained
    // here is `legendLayout.size.width <= legendArea.width`, which
    // keeps wrapped or boxed legends from spilling past the reserved
    // column. Long single-word labels still follow TextPainter's
    // overflow behavior — the cap governs measurement, not glyph
    // shaping.
    final legendMaxWidth = legendConfig.position == ChartLegendPosition.right
        ? math.max(0.0, paddedBounds.width / 2 - defaultChartLegendEntryGap)
        : paddedBounds.width;

    legendLayout = layoutLegend(
      entries: legendEntries,
      textStyle: legendTextStyle,
      config: legendConfig,
      maxWidth: legendMaxWidth,
    );

    if (legendConfig.reserveSpace) {
      if (legendConfig.position == ChartLegendPosition.bottom) {
        bottomLegendHeight = legendConfig.boxed
            ? legendLayout.size.height
            : math.max(legendLayout.size.height, chartLegendBandHeight);
      } else {
        // legendMaxWidth above already enforced the half-width cap on
        // content, so legendLayout.size.width is guaranteed to fit.
        // Add the gap to get the total reserved width.
        rightLegendWidth = legendLayout.size.width + defaultChartLegendEntryGap;
      }
    }
  }

  // Chart area fills whatever is left after all reserved bands.
  final chartTop = paddedBounds.top + titleHeight;
  final rawBottom =
      paddedBounds.bottom - xTickHeight - xAxisTitleHeight - bottomLegendHeight;
  final chartRight = paddedBounds.right - rightLegendWidth;

  assert(
    rawBottom >= chartTop,
    'Chart has been given insufficient vertical space for its configured '
    'title, tick, axis-label, and legend bands. Provide more height or '
    'reduce the number of visible bands.',
  );
  assert(
    chartRight >= paddedBounds.left,
    'Chart has been given insufficient horizontal space for its '
    'right-side legend. Provide more width or use a bottom legend.',
  );

  // Clamp for release safety so the plot rect never inverts.
  final chartBottom = math.max(chartTop, rawBottom);
  final chartAreaRight = math.max(paddedBounds.left, chartRight);
  final chartArea = Rect.fromLTRB(
    paddedBounds.left,
    chartTop,
    chartAreaRight,
    chartBottom,
  );

  // Build the legend rect now that the chart area is finalized.
  Rect legendArea = Rect.zero;
  if (showLegend && legendLayout != null) {
    if (legendConfig.position == ChartLegendPosition.bottom) {
      // Anchor at the bottom edge of the padded bounds. When
      // reserveSpace is true, the rect is sized to the reserved band
      // (bottomLegendHeight). When false, the rect is sized to the
      // legend's measured height — clamped against paddedBounds.top
      // with math.max so a tall overlay legend can never extend
      // above the widget — and the rect overlays the chart area.
      final height = legendConfig.reserveSpace
          ? bottomLegendHeight
          : legendLayout.size.height;
      final top = math.max(paddedBounds.top, paddedBounds.bottom - height);
      legendArea = Rect.fromLTRB(
        paddedBounds.left,
        top,
        paddedBounds.right,
        paddedBounds.bottom,
      );
    } else {
      // Anchor at the right edge of the padded bounds. When
      // reserveSpace is true, the rect sits to the right of the
      // chart area. When false, the rect is sized to the legend's
      // measured width — clamped against paddedBounds.left with
      // math.max so a wide overlay legend can never extend past the
      // left edge — and the rect overlays the chart area.
      if (legendConfig.reserveSpace) {
        legendArea = Rect.fromLTRB(
          chartAreaRight + defaultChartLegendEntryGap,
          chartTop,
          paddedBounds.right,
          chartBottom,
        );
      } else {
        final width = legendLayout.size.width;
        final left = math.max(paddedBounds.left, paddedBounds.right - width);
        legendArea = Rect.fromLTRB(
          left,
          paddedBounds.top,
          paddedBounds.right,
          paddedBounds.bottom,
        );
      }
    }
  }

  return ChartFrameLayout(
    paddedBounds: paddedBounds,
    chartArea: chartArea,
    xTickHeight: xTickHeight,
    legendArea: legendArea,
    legendLayout: legendLayout,
    yMin: yMin,
    yMax: yMax,
    xMin: xMin,
    xMax: xMax,
    xLabels: xLabels,
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
  final tp = layoutText(title, _effectiveTitleStyle(titleStyle, labelStyle));
  return tp.height + chartTitleSpacing;
}

/// Reserves vertical space for the X tick label band.
///
/// When [xLabelConfig] requests no rotation, returns the constant
/// [chartXTickBandHeight] (a fixed band sized for single-line
/// horizontal labels).
///
/// When rotation is requested, the band's height is the maximum
/// rotated bounding-box height across all labels, plus the same
/// [chartTickLabelGap] padding the horizontal path uses (via the
/// constant). This guarantees rotated labels never spill into the
/// X-axis title band below them.
///
/// For numeric X axes that generate labels on the fly (line / scatter
/// charts with [hasNumericXAxis] true and no [xLabels]), iterates the
/// same tick index loop the painter renders so the band reserves
/// enough height for the longest label that actually gets drawn —
/// including middle ticks, which custom formatters can make wider
/// than either endpoint. Charts with explicit [xLabels] always get
/// exact measurement.
double _measureXTickHeight(
  List<String> xLabels,
  bool hasNumericXAxis,
  TextStyle labelStyle,
  ChartLabelConfig xLabelConfig, {
  double? xMin,
  double? xMax,
  int xDivisions = HandDrawnDefaults.chartXDivisions,
  AxisValueFormatter? xValueFormatter,
}) {
  if (xLabels.isEmpty && !hasNumericXAxis) return 0;

  // Fast path: no rotation → fixed band height.
  if (!xLabelConfig.isRotated) return chartXTickBandHeight;

  final theta = xLabelConfig.rotationRadians;
  final cosT = math.cos(theta).abs();
  final sinT = math.sin(theta).abs();

  double maxRotatedHeight = 0;

  if (xLabels.isNotEmpty) {
    for (final label in xLabels) {
      final tp = layoutText(label, labelStyle);
      final rotatedHeight = tp.width * sinT + tp.height * cosT;
      if (rotatedHeight > maxRotatedHeight) {
        maxRotatedHeight = rotatedHeight;
      }
    }
  } else {
    // Numeric X axis with generated labels. Iterate the same tick
    // index loop _paintNumericXTicks uses so the band reserves enough
    // height for the longest label that actually gets drawn — middle
    // ticks included. Falls back to a single zero sample when the
    // numeric range isn't configured (the painter renders nothing in
    // that case anyway).
    if (xMin != null && xMax != null) {
      final formatter = xValueFormatter ?? defaultNumericFormatter;
      for (int i = 0; i <= xDivisions; i++) {
        final value = xMin + (xMax - xMin) * (i / xDivisions);
        final tp = layoutText(formatter(value), labelStyle);
        final rotatedHeight = tp.width * sinT + tp.height * cosT;
        if (rotatedHeight > maxRotatedHeight) {
          maxRotatedHeight = rotatedHeight;
        }
      }
    } else {
      final tp = layoutText('0', labelStyle);
      maxRotatedHeight = tp.width * sinT + tp.height * cosT;
    }
  }

  return maxRotatedHeight + chartTickLabelGap;
}

double _measureXAxisTitleHeight(String? xAxisLabel, TextStyle labelStyle) {
  if (xAxisLabel == null) return 0;
  final tp = layoutText(xAxisLabel, labelStyle);
  return tp.height + chartXAxisTitleSpacing;
}

/// Lays out the legend's entries within an optional [maxWidth].
///
/// Returns the outer size the legend will occupy (including box padding
/// when [ChartLegendConfig.boxed]) and a list of `(painter, origin)`
/// pairs in input order — origins are relative to the inner content
/// rect (i.e. inside box padding when boxed).
///
/// For [ChartLegendPosition.bottom] with [ChartLegendConfig.wrap] true,
/// entries flow left-to-right and wrap onto a new row when the next
/// entry would overflow [maxWidth]. With wrap false, entries that
/// would overflow are dropped (truncate-on-overflow); the returned
/// origin list reflects only the surviving ones.
///
/// For [ChartLegendPosition.right], entries stack vertically — one row
/// per entry — and the returned size's width matches the widest entry.
({Size size, double rowHeight, List<(TextPainter, Offset)> origins})
layoutLegend({
  required List<LegendEntry> entries,
  required TextStyle textStyle,
  required ChartLegendConfig config,
  double? maxWidth,
}) {
  if (entries.isEmpty) {
    return (size: Size.zero, rowHeight: 0, origins: const []);
  }

  // Outer box padding (boxed only) is reserved on both sides of the
  // legend's content rect. The text-layout maxWidth has to subtract
  // both that padding and the per-entry chartLegendTextOffset (which
  // covers the dot + dot-to-text gap) — what's left is the budget the
  // text itself can occupy before wrapping.
  final padHor = config.boxed ? config.padding.horizontal : 0.0;
  final padVer = config.boxed ? config.padding.vertical : 0.0;

  // For right-position legends, constrain each text painter to the
  // available column width so long labels wrap onto multiple lines
  // instead of overflowing horizontally. For bottom-position legends
  // with a finite [maxWidth], constrain each label to at most the
  // available row width with single-line ellipsis truncation —
  // otherwise a single very long label would lay out unbounded and
  // visually spill past the chart's right edge.
  final double textMaxWidth;
  final int? textMaxLines;
  final String? textEllipsis;
  if (config.position == ChartLegendPosition.right && maxWidth != null) {
    textMaxWidth = math.max(0, maxWidth - padHor - chartLegendTextOffset);
    textMaxLines = null;
    textEllipsis = null;
  } else if (config.position == ChartLegendPosition.bottom &&
      maxWidth != null) {
    textMaxWidth = math.max(0, maxWidth - padHor - chartLegendTextOffset);
    textMaxLines = 1;
    textEllipsis = '…';
  } else {
    textMaxWidth = double.infinity;
    textMaxLines = null;
    textEllipsis = null;
  }

  // Per-entry text painters and widths. Each entry's display width is
  // chartLegendTextOffset (covers the dot + dot-to-text gap) plus its
  // text width. The row-height floor is the max of any entry's text
  // height or the dot diameter — used as a baseline; the right branch
  // additionally advances per-entry to handle wrapped multi-line text.
  final tps = <TextPainter>[
    for (final e in entries)
      layoutText(
        e.label,
        textStyle,
        maxWidth: textMaxWidth,
        maxLines: textMaxLines,
        ellipsis: textEllipsis,
      ),
  ];
  final entryWidths = <double>[
    for (final tp in tps) chartLegendTextOffset + tp.width,
  ];
  double rowHeight = 0;
  for (final tp in tps) {
    if (tp.height > rowHeight) rowHeight = tp.height;
  }
  const dotDiameter = chartLegendDotRadius * 2;
  if (dotDiameter > rowHeight) rowHeight = dotDiameter;

  final innerMaxWidth = maxWidth == null ? null : maxWidth - padHor;

  final origins = <(TextPainter, Offset)>[];
  double contentWidth = 0;
  double contentHeight = 0;

  if (config.position == ChartLegendPosition.right) {
    // Vertical stack: one entry per row. Each entry's row height is
    // its own painter height (which may be > rowHeight when the
    // label has wrapped onto multiple lines), floored at the dot
    // diameter. This prevents wrapped multi-line entries from
    // overlapping each other.
    double y = 0;
    double maxRowWidth = 0;
    for (int i = 0; i < entries.length; i++) {
      origins.add((tps[i], Offset(0, y)));
      if (entryWidths[i] > maxRowWidth) maxRowWidth = entryWidths[i];
      final entryRowHeight = math.max(dotDiameter, tps[i].height);
      y += entryRowHeight;
      if (i < entries.length - 1) y += config.runSpacing;
    }
    contentWidth = maxRowWidth;
    contentHeight = y;
  } else {
    // Horizontal flow: wrap onto new rows when needed (wrap=true), or
    // drop overflowing entries (wrap=false). All entries are
    // single-line (text isn't constrained), so a single shared
    // rowHeight is correct for vertical advancement.
    double rowX = 0;
    double rowY = 0;
    double maxRowReach = 0;
    for (int i = 0; i < entries.length; i++) {
      final w = entryWidths[i];
      final wouldOverflow =
          innerMaxWidth != null && rowX > 0 && rowX + w > innerMaxWidth;
      if (wouldOverflow) {
        if (config.wrap) {
          rowY += rowHeight + config.runSpacing;
          rowX = 0;
        } else {
          // Truncate: drop this entry and any after it.
          break;
        }
      }
      origins.add((tps[i], Offset(rowX, rowY)));
      rowX += w + config.spacing;
      final reach = rowX - config.spacing;
      if (reach > maxRowReach) maxRowReach = reach;
    }
    contentWidth = maxRowReach;
    contentHeight = rowY + rowHeight;
  }

  return (
    size: Size(contentWidth + padHor, contentHeight + padVer),
    rowHeight: rowHeight,
    origins: origins,
  );
}
