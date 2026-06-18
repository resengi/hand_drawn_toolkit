/// Single source of truth for all default values in the hand_drawn_toolkit
/// package.
///
/// This file centralizes every named constant: core widget defaults, chart
/// and table colors, layout measurements, rendering parameters, seed
/// offsets, and typography. It is NOT exported from the barrel file —
/// external consumers customize via widget constructor parameters or
/// through [HandDrawnDefaults], which references these values.
library;

import 'dart:ui' show Color, FontWeight;

import 'package:flutter/painting.dart' show EdgeInsets, TextStyle;

// ══════════════════════════════════════════════════════════════════════════
// CORE WIDGET DEFAULTS
// These are the underlying values for HandDrawnDefaults. Every value in
// HandDrawnDefaults references a constant from this section.
// ══════════════════════════════════════════════════════════════════════════

// ── Stroke appearance ──────────────────────────────────────────────────────

const double defaultStrokeWidth = 2.0;
const double defaultBorderOpacity = 1.0;

// ── Path generation ────────────────────────────────────────────────────────

const double defaultIrregularity = 3.5;
const int defaultSegments = 24;
const int defaultSeed = 42;

// ── Container ──────────────────────────────────────────────────────────────

const double defaultContainerPadding = 20.0;
const Color defaultContainerBackgroundColor = Color(0xFFFFFFFF);
const Color defaultContainerStrokeColor = Color(0xFF000000);

// ── Divider ────────────────────────────────────────────────────────────────

const double defaultDividerThickness = 1.5;
const double defaultDividerIrregularity = 1.0;
const int defaultDividerSegments = 30;
const Color defaultDividerColor = Color(0x8A000000);

/// The cross-axis drawing extent reserved by a divider with the given
/// thickness. A small multiple of thickness so the jittered stroke has
/// comfortable room without clipping at the stroke ends. The factor of
/// 4 is empirical — large enough to absorb the default
/// `defaultDividerIrregularity` wobble, small enough not to waste
/// layout space.
double dividerCrossAxisExtent(double thickness) => thickness * 4;

// ── StatusSquare ───────────────────────────────────────────────────────────

const double defaultStatusSquareSize = 14.0;
const double defaultStatusSquareStrokeWidth = 1.5;
const double defaultStatusSquareIndicatorStrokeWidth = 2.0;
const double defaultStatusSquareTapPadding = 6.0;
const double defaultStatusSquareIrregularity = 1.0;
const int defaultStatusSquareSegments = 6;
const Color defaultStatusSquareIndicatorColor = Color(0xFFFFFFFF);

// ── TextField ──────────────────────────────────────────────────────────────

const double defaultTextFieldFontSize = 16.0;
const double defaultTextFieldBorderRadius = 8.0;
const double defaultTextFieldDividerThickness = 1.0;
const Color defaultTextFieldBackgroundColor = Color(0xFFF5F5F5);
const Color defaultTextFieldTextColor = Color(0xFF1A1A1A);
const Color defaultTextFieldHintColor = Color(0xFF999999);
const Color defaultTextFieldDividerColor = Color(0xFFE0E0E0);
const double defaultTextFieldHorizontalPadding = 12.0;
const double defaultTextFieldVerticalPadding = 2.0;
const EdgeInsets defaultTextFieldPadding = EdgeInsets.symmetric(
  horizontal: defaultTextFieldHorizontalPadding,
  vertical: defaultTextFieldVerticalPadding,
);
const double defaultTextFieldContentVerticalPadding = 6.0;

// ── Notebook ───────────────────────────────────────────────────────────────

const double defaultNotebookLineHeight = 28.0;
const double defaultNotebookStrokeWidth = 1.0;
const double defaultNotebookIrregularity = 1.0;
const int defaultNotebookSegments = 30;
const Color defaultNotebookLineColor = Color(0xFFE0E0E0);

// ══════════════════════════════════════════════════════════════════════════
// CHART DEFAULTS
// ══════════════════════════════════════════════════════════════════════════

// ── Chart colors ───────────────────────────────────────────────────────────

const Color defaultChartAxisColor = Color(0xFF555555);
const Color defaultChartGridColor = Color(0xFFC4C4C4);
const Color chartLabelColor = Color(0xFF777777);
const Color defaultScatterDotColor = Color(0xFF6B9BD2);

// ── Chart typography ───────────────────────────────────────────────────────

const double chartLabelFontSize = 10.0;
const double chartTitleFontSize = 13.0;
const FontWeight chartTitleFontWeight = FontWeight.w600;
const double chartLegendFontSize = 9.0;

/// Single source of truth for the default label style. Referenced by both
/// the base painter's constructor default and every subclass's null-fallback
/// for the `labelStyle` parameter.
const TextStyle defaultChartLabelStyle = TextStyle(
  fontSize: chartLabelFontSize,
  color: chartLabelColor,
);

// ── Chart widget defaults ──────────────────────────────────────────────────

const double defaultChartHeight = 220.0;

// ── Chart painter configuration ────────────────────────────────────────────

const double defaultChartIrregularity = 3.0;
const int defaultChartSegments = 12;
const int defaultChartYDivisions = 4;
const int defaultChartXDivisions = 4;

// ── Chart layout measurements ──────────────────────────────────────────────

const double chartPaddingLeft = 40.0;
const double chartPaddingBottom = 12.0;
const double chartPaddingTop = 12.0;
const double chartPaddingRight = 12.0;

/// Assembled default padding for chart painters and widgets.
const EdgeInsets defaultChartPadding = EdgeInsets.only(
  left: chartPaddingLeft,
  bottom: chartPaddingBottom,
  top: chartPaddingTop,
  right: chartPaddingRight,
);

const double chartTickLength = 4.0;
const double chartTickLabelGap = 6.0;
const double chartTickStrokeWidth = 1.0;
const double chartYLabelGap = 4.0;
const double chartXTickBandHeight = 20.0;
const double chartXAxisTitleSpacing = 6.0;
const double chartXAxisTitleGap = 2.0;
const double chartLegendBandHeight = 18.0;
const double defaultChartLabelThinningGap = 8.0;
const double chartTitleSpacing = 8.0;
const double chartYAxisLabelOffset = 28.0;
const double chartLegendDotRadius = 4.0;
const double chartLegendDotOffset = 5.0;
const double chartLegendTextOffset = 13.0;
const double defaultChartLegendEntryGap = 12.0;

// ── Chart rendering parameters ─────────────────────────────────────────────

const double defaultChartAxisStrokeWidth = 1.5;
const double defaultChartGridStrokeWidth = 1.0;
const double defaultChartGridJitterRatio = 0.3;

// ── Wobble shape defaults ──────────────────────────────────────────────────

const int defaultWobblyRectSegments = 6;
const int wobblyCirclePoints = 12;

// ── Seed offsets (centralized for collision avoidance) ──────────────────────

const int chartAxisSeedOffset = 100;
const int chartGridSeedOffset = 200;

/// Seed offset for vertical grid lines (numeric-X charts only). Kept
/// in its own range so vertical and horizontal grid wobble patterns
/// are independent — prevents the grid from looking like it has a
/// diagonal bias from correlated randomness.
const int chartVerticalGridSeedOffset = 300;

/// Seed offsets for sub-grid lines. Each line gets a unique seed via
/// `base + i * subCount + k` indexing — the bucket needs enough room
/// for `yDivisions * horizontalSubGridLinesBetweenTicks` horizontal
/// sub-lines (similarly for vertical). The chosen offsets leave ~600
/// and ~400 seed slots respectively before colliding with the next
/// bucket (`barChartSeedOffset = 3000`), which is generous relative
/// to any realistic grid density.
const int chartSubGridSeedOffset = 400;
const int chartVerticalSubGridSeedOffset = 1000;
const int barChartSeedOffset = 3000;
const int barSegmentSeedMultiplier = 100;
const int barSegmentSeedStep = 10;

/// Seed offset added per inner bar within a grouped-bar category. When
/// the chart has no grouping (a single inner bar per category), the
/// `innerBarIndex` is always 0 → contributes 0 to the seed → adjacent
/// stacked segments still get distinct wobble via the segment-index
/// term.
///
/// **Practical limit:** the seed scheme uses
/// `categoryIndex*100 + innerBarIndex*1 + segmentIndex*10`. Because
/// `barInnerSeedMultiplier` (1) divides into `barSegmentSeedStep` (10),
/// distinct `(innerBarIndex, segmentIndex)` pairs collide once
/// `innerBarIndex >= 10` (e.g. innerBarIndex=10, segmentIndex=0 collides
/// with innerBarIndex=0, segmentIndex=1). The scheme already implies a
/// "≤9 segments per bar" limit from the same multiplier choice, so
/// this just extends the same constraint to "≤9 inner bars per
/// category" — well above any realistic grouped-bar UX. If you ever
/// need more, rework the multipliers as a coherent set rather than
/// tweaking just this one (which would silently change wobble for
/// existing charts).
const int barInnerSeedMultiplier = 1;
const int lineChartSeedOffset = 4000;
const int lineDotSeedOffset = 5000;
const int lineSeriesSeedMultiplier = 1000;
const int linePointSeedStep = 10;

/// Per-run seed offset used by the function-series stroke so that
/// distinct runs of the same logical series (e.g. either side of a 1/x
/// discontinuity) get independent wobble phases.
const int lineRunSeedMultiplier = 100;
const int scatterSeedOffset = 6000;
const int scatterPointSeedStep = 10;

/// Seed offset for the wobbly border drawn around external boxed
/// legends. Sits clear of the chart-content seed buckets above
/// (`barChartSeedOffset = 3000`, `lineChartSeedOffset = 4000`,
/// `lineDotSeedOffset = 5000`, `scatterSeedOffset = 6000`) so legend
/// wobble doesn't share a phase with any data series.
const int chartLegendBoxSeedOffset = 7000;

// ── Bar chart rendering ────────────────────────────────────────────────────

const double barWidthRatio = 0.6;
const double barMinWidth = 4.0;
const double barMaxWidth = 40.0;
const double barFillAlpha = 0.15;
const double barStrokeWidth = 1.5;

// ── Line chart rendering ───────────────────────────────────────────────────

const double lineFillAlpha = 0.12;
const double lineStrokeWidth = 2.0;
const double lineDotRadius = 3.0;
const int lineSegmentCount = 6;
const int lineDotCirclePoints = 8;
const double lineDotJitterRatio = 0.5;
const int defaultSampleCount = 120;
const int defaultWobbleAnchorStride = 10;
const double percentageIrregularityCap = 0.05;

// ── Scatter plot rendering ─────────────────────────────────────────────────

const double scatterStrokeAlpha = 0.6;
const double scatterStrokeWidth = 1.0;
const double scatterDefaultDotRadius = 5.0;
const double scatterCircleJitterRatio = 0.5;

// ── Chart hit-test defaults ───────────────────────────────────────────────

/// Default touch tolerance for scatter point hit-testing.
const double scatterHitTestTolerance = 16.0;

/// Default touch tolerance for line chart point hit-testing.
const double linePointHitTestTolerance = 12.0;

/// Default touch tolerance for line chart segment hit-testing.
const double lineSegmentHitTestTolerance = 16.0;

// ══════════════════════════════════════════════════════════════════════════
// TABLE DEFAULTS
// ══════════════════════════════════════════════════════════════════════════

const double defaultTableHeaderFontSize = 11.0;
const double defaultTableCellFontSize = 13.0;
const double defaultTableTitleFontSize = 14.0;
const double defaultTablePadding = 12.0;
const double tableColumnDividerCellPadding = 4.0;

const Color tableHeaderColor = Color(0xFF888888);
const Color tableCellColor = Color(0xFF444444);
const Color tableTitleColor = Color(0xFF444444);
const Color defaultTableHighlightColor = Color(0xFF6BAF7A);
const double defaultTableHighlightAlpha = 0.08;
const double tableHeaderLetterSpacing = 0.3;
const double defaultTableTitleBottomPadding = 8.0;
const double defaultTableRowVerticalPadding = 6.0;
const FontWeight tableHeaderFontWeight = FontWeight.w600;
const FontWeight tableTitleFontWeight = FontWeight.w600;
const FontWeight tableHighlightFontWeight = FontWeight.w700;

// ── Empty/loading state (shared across charts and table) ───────────────────

const double loadingIndicatorSize = 24.0;
const double loadingStrokeWidth = 2.0;
const double emptyMessageFontSize = 13.0;
const Color emptyMessageColor = Color(0xFF999999);
