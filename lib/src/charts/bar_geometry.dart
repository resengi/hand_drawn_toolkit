import 'dart:ui' show Rect;

import '../hand_drawn_constants.dart';
import 'chart_data.dart';
import 'chart_layout.dart';

/// One rendered bar segment's geometry, with enough identity information
/// to reconstruct interaction metadata, paint seeds, and styling.
///
/// This is the **single source of truth** for bar segment rectangles —
/// both `computeLayout()` and `paintData()` in the bar painter consume
/// the same list produced by [computeBarSegmentRects] so painted bars
/// and hit-test bounds can never drift out of sync.
class BarRectSpec {
  const BarRectSpec({
    required this.categoryIndex,
    required this.innerBarIndex,
    required this.segmentIndex,
    required this.categoryLabel,
    required this.innerBarLabel,
    required this.segment,
    required this.cumulativeStart,
    required this.cumulativeEnd,
    required this.rect,
  });

  /// Index of the outer x-axis category this segment belongs to.
  final int categoryIndex;

  /// Index of the inner bar within its category. For ungrouped charts
  /// (the legacy single-bar-per-category projection) this is always 0.
  /// For grouped charts it ranges over `0..N-1` for the side-by-side
  /// bars under one category.
  final int innerBarIndex;

  /// Index of this segment within its inner bar (bottom = 0).
  final int segmentIndex;

  /// X-axis label of the owning category (carried for layout convenience).
  final String categoryLabel;

  /// Label of the inner bar within its category. For grouped charts
  /// this is the `BarGroup.label` (e.g. "North"). For legacy ungrouped
  /// charts (single-bar-per-category projection) this equals
  /// [categoryLabel].
  final String innerBarLabel;

  /// The original segment data (color, value, fill overrides).
  final BarSegment segment;

  /// Stacked-value range this segment occupies within its inner bar.
  final double cumulativeStart;
  final double cumulativeEnd;

  /// Final canvas-space rectangle for this segment.
  final Rect rect;
}

/// Computes the canvas rectangles for every segment of every bar in
/// every category of a bar chart, in a single pass.
///
/// The returned list is intentionally flat — consumers iterate it once
/// and read the index fields if they need to reason about category /
/// inner-bar / segment hierarchy.
///
/// Geometry rules:
///
/// - Outer x-axis slot width = `chartArea.width / categoryCount`.
/// - Each category's bars sit inside a centered "group zone" whose
///   width is `_resolveBarWidth(outerSlotWidth)` — i.e. `barWidthRatio`
///   is applied ONCE at the outer-slot level, carving out breathing
///   room around the group as a whole. This matches the pre-grouping
///   renderer for single-bar charts exactly.
/// - Inside the group zone, inner bars tile edge-to-edge with no gap
///   between siblings, so groupings read as coherent visual units.
///   A chart with `innerCount = 1` collapses to the legacy geometry
///   (one bar centered in its slot at `barWidthRatio` width).
/// - Stacked segments accumulate vertically using the frame's
///   `yToCanvas`, so negative-value semantics are inherited unchanged
///   (callers already enforce non-negative segment values).
/// - Zero-value segments are skipped (they would render as zero-height
///   rects and just add noise to hit testing).
List<BarRectSpec> computeBarSegmentRects({
  required ChartFrameLayout frame,
  required List<BarCategory> categories,
}) {
  if (categories.isEmpty) return const [];

  final chartArea = frame.chartArea;
  final categoryCount = categories.length;
  final outerSlotWidth = chartArea.width / categoryCount;

  final result = <BarRectSpec>[];

  for (int c = 0; c < categoryCount; c++) {
    final category = categories[c];
    final outerCenterX = chartArea.left + outerSlotWidth * (c + 0.5);

    // Inner subdivision.
    //
    // `barWidthRatio` is applied ONCE at the outer-slot level to carve
    // out a single "group zone" with breathing room around the whole
    // group (this matches the legacy visual — ungrouped bars also sit
    // narrower than their slot with gaps either side). The inner bars
    // then tile that group zone edge-to-edge with no gap between
    // siblings, so groupings read as coherent units instead of looking
    // indistinguishable from separate categories.
    //
    // For ungrouped charts (innerCount == 1), groupZoneWidth ==
    // _resolveBarWidth(outerSlotWidth) and that is also the single
    // inner bar's width — bit-identical to the pre-grouping renderer.
    final innerCount = category.bars.length;
    // Empty category — nothing to draw and no slots to subdivide.
    // Skip explicitly rather than relying on IEEE infinity + a
    // zero-iteration loop to produce correct behavior by accident.
    if (innerCount == 0) continue;
    final groupZoneWidth = _resolveBarWidth(outerSlotWidth);
    final innerBarWidth = groupZoneWidth / innerCount;
    final groupZoneLeft = outerCenterX - groupZoneWidth / 2;

    for (int b = 0; b < innerCount; b++) {
      final innerCenterX = groupZoneLeft + innerBarWidth * (b + 0.5);
      final bar = category.bars[b];

      double cumulative = 0.0;
      for (int s = 0; s < bar.segments.length; s++) {
        final seg = bar.segments[s];
        if (seg.value == 0) continue;

        final bottomY = frame.yToCanvas(cumulative);
        final start = cumulative;
        cumulative += seg.value;
        final topY = frame.yToCanvas(cumulative);

        result.add(
          BarRectSpec(
            categoryIndex: c,
            innerBarIndex: b,
            segmentIndex: s,
            categoryLabel: category.label,
            innerBarLabel: category.bars[b].label,
            segment: seg,
            cumulativeStart: start,
            cumulativeEnd: cumulative,
            rect: Rect.fromLTRB(
              innerCenterX - innerBarWidth / 2,
              topY,
              innerCenterX + innerBarWidth / 2,
              bottomY,
            ),
          ),
        );
      }
    }
  }

  return result;
}

/// Same width-clamping logic the bar painter has used since the package
/// shipped. Extracted here so the geometry helper is self-contained.
double _resolveBarWidth(double slotWidth) {
  return (slotWidth * barWidthRatio)
      .clamp(slotWidth >= barMinWidth ? barMinWidth : 0.0, barMaxWidth)
      .clamp(0.0, slotWidth);
}
