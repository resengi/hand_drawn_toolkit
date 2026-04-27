import 'dart:math' as math;
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
/// - Stacked segments accumulate vertically using two **independent**
///   accumulators per inner bar — positive segments stack upward from
///   the data baseline `0.0`, negative segments stack downward from
///   the same baseline. A segment's rect spans from the appropriate
///   accumulator's pre-add value (its `cumulativeStart`) to its
///   post-add value (its `cumulativeEnd`); whichever side of zero the
///   segment lives on, that side's accumulator advances and the other
///   stays put. Mixing signs in a single stack therefore produces a
///   bar with two visual halves growing out of the zero line.
/// - Zero-value segments still produce a (zero-height) layout entry,
///   so segment indices, hit-test metadata, and any introspection of
///   the layout output remain stable across data shapes that contain
///   zero placeholders. They will be unhittable in practice because
///   `Rect.contains` excludes the bottom edge.
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

    // Inner subdivision — see class-level comment for the geometry
    // rationale (group zone = one barWidthRatio carve-out per category;
    // inner bars tile that zone edge-to-edge).
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

      // Two independent stacks per inner bar. Positive segments
      // accumulate upward from zero into [positiveCumulative];
      // negative segments accumulate downward into [negativeCumulative].
      // A zero-value segment doesn't move either accumulator but still
      // produces a layout entry below to preserve segment indices.
      double positiveCumulative = 0.0;
      double negativeCumulative = 0.0;

      for (int s = 0; s < bar.segments.length; s++) {
        final seg = bar.segments[s];
        final value = seg.value;

        final double dataStart;
        final double dataEnd;
        if (value > 0) {
          dataStart = positiveCumulative;
          positiveCumulative += value;
          dataEnd = positiveCumulative;
        } else if (value < 0) {
          dataStart = negativeCumulative;
          negativeCumulative += value;
          dataEnd = negativeCumulative;
        } else {
          // Zero-value segment: park it at whichever accumulator the
          // stack has been growing into (positive by default for an
          // all-zero stack). The choice is arbitrary because the rect
          // has zero height regardless — this just keeps the layout
          // metadata in a sensible place.
          final anchor = negativeCumulative != 0 && positiveCumulative == 0
              ? negativeCumulative
              : positiveCumulative;
          dataStart = anchor;
          dataEnd = anchor;
        }

        final startY = frame.yToCanvas(dataStart);
        final endY = frame.yToCanvas(dataEnd);

        result.add(
          BarRectSpec(
            categoryIndex: c,
            innerBarIndex: b,
            segmentIndex: s,
            categoryLabel: category.label,
            innerBarLabel: category.bars[b].label,
            segment: seg,
            cumulativeStart: dataStart,
            cumulativeEnd: dataEnd,
            rect: Rect.fromLTRB(
              innerCenterX - innerBarWidth / 2,
              math.min(startY, endY),
              innerCenterX + innerBarWidth / 2,
              math.max(startY, endY),
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
