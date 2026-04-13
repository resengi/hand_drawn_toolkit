// Internal resolver layer for line-chart rendering.
//
// Transforms public [LineChartData] (ordinary [LineSeriesData] + new
// [FunctionSeriesData]) into a render-ready list of [ResolvedLineSeries].
//
// This file is intentionally **not** exported from `hand_drawn_toolkit.dart`.
// Consumers should never depend on these types; they are painter plumbing.

import 'dart:ui' show Color;

import 'chart_data.dart';

/// Controls how the line painter should render a resolved series.
enum ResolvedLineRenderMode {
  /// Ordinary segmented stroke — each pair of adjacent points is wobbled
  /// independently. Preserves the pre-existing hand-drawn aesthetic for
  /// [LineSeriesData]-sourced charts.
  segmentedStroke,

  /// One coherent wobble pass per run. Used for function-series curves to
  /// avoid per-sample pinch points and phase discontinuities when the
  /// sample count is high.
  continuousCurve,
}

/// Internal render-ready series representation.
///
/// Produced by [resolveLineSeries]. Not part of the public API.
class ResolvedLineSeries {
  const ResolvedLineSeries({
    required this.name,
    required this.color,
    required this.pathRuns,
    required this.displayPoints,
    required this.renderMode,
    required this.showFill,
    required this.wobbleAnchorStride,
  });

  final String name;
  final Color color;

  /// One or more drawable runs used to build the stroke. Multiple runs
  /// represent discontinuities (e.g. 1/x at x=0). Each run fills and
  /// strokes independently.
  final List<List<LinePoint>> pathRuns;

  /// Sparse visible points. Drives rendered circles and point hit testing.
  /// For function series, `pointIndex` in hit-test output is the index
  /// into this list.
  final List<LinePoint> displayPoints;

  final ResolvedLineRenderMode renderMode;

  /// Whether the painter should draw the fill under this series. Copied
  /// verbatim from the source [LineSeriesData.showFill] or
  /// [FunctionSeriesData.showFill].
  final bool showFill;

  /// Stride for the function-series wobble anchors. Read by the painter
  /// when [renderMode] is [ResolvedLineRenderMode.continuousCurve];
  /// ignored for [ResolvedLineRenderMode.segmentedStroke] (ordinary
  /// series use the legacy per-data-segment wobble).
  final int wobbleAnchorStride;
}

/// Resolves [LineChartData] into a render-ready list of [ResolvedLineSeries].
///
/// Ordering contract:
///  1. Ordinary [LineChartData.series], in declaration order, first.
///  2. [LineChartData.functionSeries], in declaration order, after.
///
/// Ordinary series are resolved as a single `pathRun == series.points`
/// with `displayPoints == series.points` and `segmentedStroke` mode —
/// preserving existing line-chart behavior exactly.
///
/// Function series are uniformly sampled across `[minX, maxX]`. Non-finite
/// samples split the curve into separate runs. `displayPoints` are
/// evaluated at the series's `displayXs` (out-of-range and non-finite
/// values are dropped; duplicates and order are preserved).
List<ResolvedLineSeries> resolveLineSeries(LineChartData data) {
  // Cross-field validation lives here (not in the constructor) so that
  // `LineChartData` stays const-constructible and tolerates non-canonical
  // empty lists. The rules below only apply when function series are
  // actually being plotted; an empty `functionSeries` (whatever its list
  // identity) imposes no constraints.
  if (data.functionSeries.isNotEmpty) {
    if (data.xLabels.isNotEmpty) {
      throw ArgumentError(
        'functionSeries cannot be combined with categorical xLabels.',
      );
    }
    if (data.minX >= data.maxX) {
      throw ArgumentError(
        'functionSeries requires minX < maxX (got minX=${data.minX}, '
        'maxX=${data.maxX}).',
      );
    }
  }

  final resolved = <ResolvedLineSeries>[];

  // Ordinary series — one-to-one passthrough.
  for (final s in data.series) {
    resolved.add(
      ResolvedLineSeries(
        name: s.name,
        color: s.color,
        pathRuns: [s.points],
        displayPoints: s.points,
        renderMode: ResolvedLineRenderMode.segmentedStroke,
        showFill: s.showFill,
        wobbleAnchorStride: 1, // unused for segmented stroke
      ),
    );
  }

  // Function series — sample + split + evaluate display points.
  for (final f in data.functionSeries) {
    resolved.add(_resolveFunctionSeries(f, data.minX, data.maxX));
  }

  return resolved;
}

ResolvedLineSeries _resolveFunctionSeries(
  FunctionSeriesData f,
  double minX,
  double maxX,
) {
  // Uniform sampling across [minX, maxX]. Split on non-finite y.
  final runs = <List<LinePoint>>[];
  var current = <LinePoint>[];
  final step = (maxX - minX) / (f.sampleCount - 1);

  for (var i = 0; i < f.sampleCount; i++) {
    // Pin endpoints exactly to avoid fp drift at the boundaries.
    final x = i == f.sampleCount - 1 ? maxX : minX + i * step;
    final y = f.function(x);

    if (y.isFinite) {
      current.add(LinePoint(x: x, y: y));
    } else {
      if (current.isNotEmpty) {
        runs.add(current);
        current = <LinePoint>[];
      }
    }
  }
  if (current.isNotEmpty) runs.add(current);

  // Sparse visible points from displayXs. Order + duplicates preserved.
  final displayPoints = <LinePoint>[];
  for (final dx in f.displayXs) {
    if (dx < minX || dx > maxX) continue;
    final dy = f.function(dx);
    if (!dy.isFinite) continue;
    displayPoints.add(LinePoint(x: dx, y: dy));
  }

  return ResolvedLineSeries(
    name: f.name,
    color: f.color,
    pathRuns: runs,
    displayPoints: displayPoints,
    renderMode: ResolvedLineRenderMode.continuousCurve,
    showFill: f.showFill,
    wobbleAnchorStride: f.wobbleAnchorStride,
  );
}
