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
const Color defaultContainerStrokeColor = Color(0xDD000000);

// ── Divider ────────────────────────────────────────────────────────────────

const double defaultDividerThickness = 1.5;
const double defaultDividerIrregularity = 1.0;
const int defaultDividerSegments = 30;
const Color defaultDividerColor = Color(0x8A000000);

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

const double defaultNotebookStrokeWidth = 1.0;
const double defaultNotebookIrregularity = 1.0;
const int defaultNotebookSegments = 30;
const Color defaultNotebookLineColor = Color(0xFFE0E0E0);

// ══════════════════════════════════════════════════════════════════════════
// CHART DEFAULTS
// ══════════════════════════════════════════════════════════════════════════

// ── Chart colors ───────────────────────────────────────────────────────────

const Color chartAxisColor = Color(0xFF555555);
const Color chartGridColor = Color(0xFFDDDDDD);
const Color chartLabelColor = Color(0xFF777777);
const Color scatterDotColor = Color(0xFF6B9BD2);

// ── Chart typography ───────────────────────────────────────────────────────

const double chartLabelFontSize = 10.0;
const double chartTitleFontSize = 13.0;
const FontWeight chartTitleFontWeight = FontWeight.w600;
const double chartLegendFontSize = 9.0;

/// Single source of truth for the default label style. Referenced by both
/// the base painter's constructor default and every subclass's null-fallback
/// for the `labelStyle` parameter.
const TextStyle chartDefaultLabelStyle = TextStyle(
  fontSize: chartLabelFontSize,
  color: chartLabelColor,
);

// ── Chart widget defaults ──────────────────────────────────────────────────

const double defaultChartHeight = 220.0;

// ── Chart painter configuration ────────────────────────────────────────────

const double chartIrregularity = 3.0;
const int chartSegments = 12;
const int chartYDivisions = 4;
const int chartXDivisions = 4;

// ── Chart layout measurements ──────────────────────────────────────────────

const double chartPaddingLeft = 40.0;
const double chartPaddingBottom = 12.0;
const double chartPaddingTop = 12.0;
const double chartPaddingRight = 12.0;

/// Assembled default padding for chart painters and widgets.
const EdgeInsets chartDefaultPadding = EdgeInsets.only(
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
const double chartLabelThinningGap = 8.0;
const double chartTitleSpacing = 8.0;
const double chartYAxisLabelOffset = 28.0;
const double chartLegendDotRadius = 4.0;
const double chartLegendDotOffset = 5.0;
const double chartLegendTextOffset = 13.0;
const double chartLegendEntryGap = 12.0;
const double chartLegendBottomOffset = 2.0;

// ── Chart rendering parameters ─────────────────────────────────────────────

const double chartAxisStrokeWidth = 1.5;
const double chartGridStrokeWidth = 0.5;
const double chartGridJitterRatio = 0.3;

// ── Wobble shape defaults ──────────────────────────────────────────────────

const int wobblyRectSegments = 6;
const int wobblyCirclePoints = 12;

// ── Seed offsets (centralized for collision avoidance) ──────────────────────

const int chartAxisSeedOffset = 100;
const int chartGridSeedOffset = 200;
const int barChartSeedOffset = 3000;
const int barSegmentSeedMultiplier = 100;
const int barSegmentSeedStep = 10;
const int lineChartSeedOffset = 4000;
const int lineDotSeedOffset = 5000;
const int lineSeriesSeedMultiplier = 1000;
const int linePointSeedStep = 10;
const int scatterSeedOffset = 6000;
const int scatterPointSeedStep = 10;

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

// ── Scatter plot rendering ─────────────────────────────────────────────────

const double scatterStrokeAlpha = 0.6;
const double scatterStrokeWidth = 1.0;
const double scatterDefaultDotRadius = 5.0;

// ══════════════════════════════════════════════════════════════════════════
// TABLE DEFAULTS
// ══════════════════════════════════════════════════════════════════════════

const double defaultTableHeaderFontSize = 11.0;
const double defaultTableCellFontSize = 13.0;
const double defaultTableTitleFontSize = 14.0;
const double defaultTablePadding = 12.0;

const Color tableHeaderColor = Color(0xFF888888);
const Color tableCellColor = Color(0xFF444444);
const Color tableTitleColor = Color(0xFF444444);
const Color tableHighlightColor = Color(0xFF6BAF7A);
const double tableHighlightAlpha = 0.08;
const double tableHeaderLetterSpacing = 0.3;
const double tableTitleBottomPadding = 8.0;
const double tableRowVerticalPadding = 6.0;
const FontWeight tableHeaderFontWeight = FontWeight.w600;
const FontWeight tableTitleFontWeight = FontWeight.w600;
const FontWeight tableHighlightFontWeight = FontWeight.w700;

// ── Empty/loading state (shared across charts and table) ───────────────────

const double loadingIndicatorSize = 24.0;
const double loadingStrokeWidth = 2.0;
const double emptyMessageFontSize = 13.0;
const Color emptyMessageColor = Color(0xFF999999);
