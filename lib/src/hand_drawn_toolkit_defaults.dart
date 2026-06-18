/// Default values used throughout the hand_drawn_toolkit package.
///
/// These constants provide sensible starting points for the painter and widget
/// parameters. Override them per-widget to fine-tune the hand-drawn aesthetic.
///
/// All values are sourced from the internal constants file. This class is
/// the public-facing API for consumers who want to reference defaults
/// programmatically.
library;

import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;

import 'hand_drawn_constants.dart';

/// Default configuration values for hand-drawn rendering.
///
/// Every value here references an internal constant from the package's
/// central constants file. Consumers can use these as baseline values
/// when programmatically configuring widgets.
abstract final class HandDrawnDefaults {
  // ── Stroke appearance ────────────────────────────────────────────────────

  /// Default stroke width in logical pixels.
  static const double strokeWidth = defaultStrokeWidth;

  /// Default stroke color opacity when used with [HandDrawnContainer.borderOpacity].
  static const double borderOpacity = defaultBorderOpacity;

  // ── Path generation ──────────────────────────────────────────────────────

  /// Controls the magnitude of random offset applied to each path segment
  /// point. Higher values produce a rougher, more hand-drawn look. Lower
  /// values approach a straight line.
  ///
  /// Typical range: 0.5 (subtle wobble) – 6.0 (very rough sketch).
  static const double irregularity = defaultIrregularity;

  /// The number of linear segments used to approximate each edge of a shape.
  /// More segments produce smoother jitter; fewer segments create a chunkier
  /// feel.
  static const int segments = defaultSegments;

  /// The default random seed. Using a fixed seed guarantees the same jitter
  /// pattern on every rebuild so the shape doesn't "dance" during animations
  /// or hot-reloads.
  static const int seed = defaultSeed;

  // ── Container defaults ─────────────────────────────────────────────────

  /// Default inner padding for [HandDrawnContainer].
  static const double containerPadding = defaultContainerPadding;

  /// Default background color for [HandDrawnContainer].
  static const Color containerBackgroundColor = defaultContainerBackgroundColor;

  /// Default stroke color for [HandDrawnContainer].
  static const Color containerStrokeColor = defaultContainerStrokeColor;

  // ── Divider defaults ───────────────────────────────────────────────────

  /// Default thickness for [HandDrawnDivider].
  static const double dividerThickness = defaultDividerThickness;

  /// Default irregularity for [HandDrawnDivider] (subtler than borders).
  static const double dividerIrregularity = defaultDividerIrregularity;

  /// Default segment count for [HandDrawnDivider].
  static const int dividerSegments = defaultDividerSegments;

  /// Default color for [HandDrawnDivider].
  static const Color dividerColor = defaultDividerColor;

  // ── StatusSquare defaults ──────────────────────────────────────────────

  /// Default side length for [HandDrawnStatusSquare] in logical pixels.
  static const double statusSquareSize = defaultStatusSquareSize;

  /// Default border stroke width for [HandDrawnStatusSquare].
  static const double statusSquareStrokeWidth = defaultStatusSquareStrokeWidth;

  /// Default stroke width for the check / dash indicator drawn on top of
  /// the filled square.
  static const double statusSquareIndicatorStrokeWidth =
      defaultStatusSquareIndicatorStrokeWidth;

  /// Default padding around the painted square that enlarges the tap target
  /// when [HandDrawnStatusSquare.onTap] is non-null.
  static const double statusSquareTapPadding = defaultStatusSquareTapPadding;

  /// Default irregularity for [HandDrawnStatusSquare]. Subtler than the
  /// container default because the square is small.
  static const double statusSquareIrregularity =
      defaultStatusSquareIrregularity;

  /// Default segment count for [HandDrawnStatusSquare]. Fewer segments than
  /// the container default for a chunkier feel at small sizes.
  static const int statusSquareSegments = defaultStatusSquareSegments;

  /// Default color for the indicator (check / dash) drawn on top of
  /// the filled square.
  static const Color statusSquareIndicatorColor =
      defaultStatusSquareIndicatorColor;

  // ── TextField defaults ─────────────────────────────────────────────────

  /// Default font size for [HandDrawnTextField] when no custom [TextStyle]
  /// is provided.
  static const double textFieldFontSize = defaultTextFieldFontSize;

  /// Default corner radius of the [HandDrawnTextField] background container.
  static const double textFieldBorderRadius = defaultTextFieldBorderRadius;

  /// Default thickness of the [HandDrawnDivider] underline inside
  /// [HandDrawnTextField].
  static const double textFieldDividerThickness =
      defaultTextFieldDividerThickness;

  /// Default background color for [HandDrawnTextField].
  static const Color textFieldBackgroundColor = defaultTextFieldBackgroundColor;

  /// Default text color for [HandDrawnTextField].
  static const Color textFieldTextColor = defaultTextFieldTextColor;

  /// Default hint text color for [HandDrawnTextField].
  static const Color textFieldHintColor = defaultTextFieldHintColor;

  /// Default divider color for [HandDrawnTextField].
  static const Color textFieldDividerColor = defaultTextFieldDividerColor;

  /// Default padding inside [HandDrawnTextField].
  static const EdgeInsets textFieldPadding = defaultTextFieldPadding;

  /// Default content padding for the inner [TextField] input area.
  static const double textFieldContentVerticalPadding =
      defaultTextFieldContentVerticalPadding;

  // ── Notebook defaults ──────────────────────────────────────────────────

  /// Default row height (rule spacing) for notebook ruling.
  static const double notebookLineHeight = defaultNotebookLineHeight;

  /// Default stroke width for notebook ruled lines.
  static const double notebookStrokeWidth = defaultNotebookStrokeWidth;

  /// Default irregularity for notebook ruled lines. Subtle wobble appropriate
  /// for full-width horizontal strokes.
  static const double notebookIrregularity = defaultNotebookIrregularity;

  /// Default segment count for notebook ruled lines.
  static const int notebookSegments = defaultNotebookSegments;

  /// Default color for notebook ruled lines.
  static const Color notebookLineColor = defaultNotebookLineColor;

  // ── Chart defaults ──────────────────────────────────────────────────

  /// Default height for chart widgets.
  static const double chartHeight = defaultChartHeight;

  /// Default color for chart axes.
  static const Color chartAxisColor = defaultChartAxisColor;

  /// Default text style for chart tick labels and X-axis labels.
  static const TextStyle chartLabelStyle = defaultChartLabelStyle;

  /// Default irregularity for chart strokes (axes, lines, bars).
  static const double chartIrregularity = defaultChartIrregularity;

  /// Default segment count for chart strokes.
  static const int chartSegments = defaultChartSegments;

  /// Default number of horizontal divisions on chart Y axes.
  static const int chartYDivisions = defaultChartYDivisions;

  /// Default number of vertical divisions on chart X axes (line and
  /// scatter charts).
  static const int chartXDivisions = defaultChartXDivisions;

  /// Default outer padding inside chart widgets.
  static const EdgeInsets chartPadding = defaultChartPadding;

  /// Default stroke width for chart axis lines.
  static const double chartAxisStrokeWidth = defaultChartAxisStrokeWidth;

  /// Default color for scatter plot dots.
  static const Color scatterDotColor = defaultScatterDotColor;

  /// Default color for chart grid lines.
  static const Color chartGridColor = defaultChartGridColor;

  /// Default stroke width for chart grid lines.
  static const double chartGridStrokeWidth = defaultChartGridStrokeWidth;

  /// Default jitter ratio applied to chart grid lines.
  static const double chartGridJitterRatio = defaultChartGridJitterRatio;

  /// Default minimum visible gap between X-axis labels before thinning kicks in.
  static const double chartLabelThinningGap = defaultChartLabelThinningGap;

  /// Default horizontal gap between legend entries.
  static const double chartLegendEntryGap = defaultChartLegendEntryGap;

  /// Default segment count for wobbly rectangle borders (legend boxes,
  /// inline label backgrounds).
  static const int wobblyRectSegments = defaultWobblyRectSegments;

  /// Default number of samples used by [FunctionSeriesData].
  static const int functionSampleCount = defaultSampleCount;

  /// Default wobble-anchor stride used by [FunctionSeriesData].
  static const int functionWobbleAnchorStride = defaultWobbleAnchorStride;

  // ── Table defaults ──────────────────────────────────────────────────

  /// Default font size for table header text.
  static const double tableHeaderFontSize = defaultTableHeaderFontSize;

  /// Default font size for table cell text.
  static const double tableCellFontSize = defaultTableCellFontSize;

  /// Default font size for the optional table title.
  static const double tableTitleFontSize = defaultTableTitleFontSize;

  /// Default inner padding for the table container.
  static const double tablePadding = defaultTablePadding;

  /// Default highlight color applied to highlighted rows.
  static const Color tableHighlightColor = defaultTableHighlightColor;

  /// Default alpha multiplier for highlighted rows.
  static const double tableHighlightAlpha = defaultTableHighlightAlpha;

  /// Default vertical padding around table rows.
  static const double tableRowVerticalPadding = defaultTableRowVerticalPadding;

  /// Default bottom padding below the table title.
  static const double tableTitleBottomPadding = defaultTableTitleBottomPadding;
}
