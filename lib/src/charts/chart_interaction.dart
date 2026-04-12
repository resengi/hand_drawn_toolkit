import 'dart:ui' show Offset, Rect, Size;

import '../hand_drawn_constants.dart';
import 'chart_data.dart';
import 'chart_geometry_utils.dart';

// ══════════════════════════════════════════════════════════════════════════════
// BAR CHART
// ══════════════════════════════════════════════════════════════════════════════

/// Immutable layout snapshot for a bar chart at a specific [size].
///
/// Obtain via `HandDrawnBarChartPainter.computeLayout(size)`.
/// Valid only for the [size] it was computed for — recompute when size changes.
///
/// See the package README for recommended `LayoutBuilder` usage patterns.
class BarChartLayout {
  const BarChartLayout({
    required this.size,
    required this.chartArea,
    required this.segments,
  });

  /// The size this layout was computed for.
  final Size size;

  /// The main plotting region.
  final Rect chartArea;

  /// All bar segments in paint order (bar-major, segment-minor).
  final List<BarSegmentLayout> segments;

  /// Returns the topmost segment hit at [localPosition], or `null` if none.
  ///
  /// Iterates in reverse paint order so the last-painted (topmost) segment
  /// wins when segments overlap.
  BarHitTestResult? hitTest(Offset localPosition) {
    for (int i = segments.length - 1; i >= 0; i--) {
      if (segments[i].bounds.contains(localPosition)) {
        return BarHitTestResult(segment: segments[i]);
      }
    }
    return null;
  }
}

/// Layout geometry for a single bar segment.
class BarSegmentLayout {
  const BarSegmentLayout({
    required this.barIndex,
    required this.segmentIndex,
    required this.barLabel,
    required this.category,
    required this.value,
    required this.cumulativeStart,
    required this.cumulativeEnd,
    required this.bounds,
  });

  /// Index of the bar group within the chart.
  final int barIndex;

  /// Index of this segment within its bar group.
  final int segmentIndex;

  /// The bar group's X-axis label.
  final String barLabel;

  /// The segment's category identifier.
  final String category;

  /// The segment's original data value.
  final double value;

  /// Cumulative value at the bottom of this segment.
  final double cumulativeStart;

  /// Cumulative value at the top of this segment.
  final double cumulativeEnd;

  /// The logical (non-wobbly) bounding rectangle of this segment.
  final Rect bounds;
}

/// Hit-test result for a bar chart.
class BarHitTestResult {
  const BarHitTestResult({required this.segment});

  /// The segment that was hit.
  final BarSegmentLayout segment;
}

// ══════════════════════════════════════════════════════════════════════════════
// SCATTER PLOT
// ══════════════════════════════════════════════════════════════════════════════

/// Immutable layout snapshot for a scatter plot at a specific [size].
///
/// Obtain via `HandDrawnScatterPlotPainter.computeLayout(size)`.
/// Valid only for the [size] it was computed for — recompute when size changes.
class ScatterPlotLayout {
  const ScatterPlotLayout({
    required this.size,
    required this.chartArea,
    required this.points,
  });

  /// The size this layout was computed for.
  final Size size;

  /// The main plotting region.
  final Rect chartArea;

  /// All scatter points in data order.
  final List<ScatterPointLayout> points;

  /// Returns the nearest point within [tolerance], or `null` if none qualifies.
  ///
  /// Uses touch-friendly logic: the effective hit radius is
  /// `max(visualRadius, tolerance)`.
  ScatterHitTestResult? hitTest(
    Offset localPosition, {
    double tolerance = scatterHitTestTolerance,
  }) {
    ScatterPointLayout? nearest;
    double nearestDist = double.infinity;

    for (final point in points) {
      final effectiveRadius = point.visualRadius > tolerance
          ? point.visualRadius
          : tolerance;
      final dist = distance(localPosition, point.center);
      if (dist <= effectiveRadius && dist < nearestDist) {
        nearestDist = dist;
        nearest = point;
      }
    }

    if (nearest == null) return null;
    return ScatterHitTestResult(point: nearest, distance: nearestDist);
  }
}

/// Layout geometry for a single scatter point.
class ScatterPointLayout {
  const ScatterPointLayout({
    required this.pointIndex,
    required this.rawPoint,
    required this.center,
    required this.visualRadius,
  });

  /// Index of this point in the data list.
  final int pointIndex;

  /// The original data point.
  final ScatterPoint rawPoint;

  /// Canvas position of the point center.
  final Offset center;

  /// Visual dot radius in logical pixels.
  final double visualRadius;
}

/// Hit-test result for a scatter plot.
class ScatterHitTestResult {
  const ScatterHitTestResult({required this.point, required this.distance});

  /// The point that was hit.
  final ScatterPointLayout point;

  /// Distance from the query position to the point center.
  final double distance;
}

// ══════════════════════════════════════════════════════════════════════════════
// LINE CHART
// ══════════════════════════════════════════════════════════════════════════════

/// Immutable layout snapshot for a line chart at a specific [size].
///
/// Obtain via `HandDrawnLineChartPainter.computeLayout(size)`.
/// Valid only for the [size] it was computed for — recompute when size changes.
class LineChartLayout {
  const LineChartLayout({
    required this.size,
    required this.chartArea,
    required this.points,
    required this.segments,
  });

  /// The size this layout was computed for.
  final Size size;

  /// The main plotting region.
  final Rect chartArea;

  /// All data points across all series.
  final List<LinePointLayout> points;

  /// All logical line segments across all series.
  final List<LineSegmentLayout> segments;

  /// Hit-tests against all series, returning the single nearest qualifying
  /// result.
  ///
  /// Priority: nearest qualifying **point** hit wins. If no point qualifies,
  /// the nearest qualifying **segment** hit wins.
  ///
  /// Returns `null` if nothing is within tolerance.
  LineHitTestResult? hitTest(
    Offset localPosition, {
    double pointTolerance = linePointHitTestTolerance,
    double lineTolerance = lineSegmentHitTestTolerance,
  }) {
    // 1. Search for nearest qualifying point across all series.
    LinePointLayout? nearestPoint;
    double nearestPointDist = double.infinity;

    for (final point in points) {
      final dist = distance(localPosition, point.center);
      if (dist <= pointTolerance && dist < nearestPointDist) {
        nearestPointDist = dist;
        nearestPoint = point;
      }
    }

    if (nearestPoint != null) {
      return LinePointHit(
        seriesIndex: nearestPoint.seriesIndex,
        seriesName: nearestPoint.seriesName,
        pointIndex: nearestPoint.pointIndex,
        point: nearestPoint.rawPoint,
        center: nearestPoint.center,
        distance: nearestPointDist,
      );
    }

    // 2. Search for nearest qualifying segment across all series.
    LineSegmentLayout? nearestSeg;
    double nearestSegDist = double.infinity;
    Offset nearestCanvasPoint = Offset.zero;
    double nearestT = 0;

    for (final seg in segments) {
      final result = nearestPointOnSegment(localPosition, seg.start, seg.end);
      final dist = distance(localPosition, result.nearest);
      if (dist <= lineTolerance && dist < nearestSegDist) {
        nearestSegDist = dist;
        nearestSeg = seg;
        nearestCanvasPoint = result.nearest;
        nearestT = result.t;
      }
    }

    if (nearestSeg != null) {
      return LineSegmentHit(
        seriesIndex: nearestSeg.seriesIndex,
        seriesName: nearestSeg.seriesName,
        segmentIndex: nearestSeg.segmentIndex,
        startPoint: nearestSeg.rawStartPoint,
        endPoint: nearestSeg.rawEndPoint,
        nearestCanvasPoint: nearestCanvasPoint,
        t: nearestT,
        interpolatedX: interpolateValue(
          nearestSeg.rawStartPoint.x,
          nearestSeg.rawEndPoint.x,
          nearestT,
        ),
        interpolatedY: interpolateValue(
          nearestSeg.rawStartPoint.y,
          nearestSeg.rawEndPoint.y,
          nearestT,
        ),
        distance: nearestSegDist,
      );
    }

    return null;
  }
}

/// Layout geometry for a single line chart data point.
class LinePointLayout {
  const LinePointLayout({
    required this.seriesIndex,
    required this.pointIndex,
    required this.rawPoint,
    required this.center,
    this.seriesName,
  });

  /// Index of the series this point belongs to.
  final int seriesIndex;

  /// Optional name of the series.
  final String? seriesName;

  /// Index of this point within its series.
  final int pointIndex;

  /// The original data point.
  final LinePoint rawPoint;

  /// Canvas position of the point center.
  final Offset center;
}

/// Layout geometry for a logical line segment between two consecutive points.
class LineSegmentLayout {
  const LineSegmentLayout({
    required this.seriesIndex,
    required this.segmentIndex,
    required this.rawStartPoint,
    required this.rawEndPoint,
    required this.start,
    required this.end,
    this.seriesName,
  });

  /// Index of the series this segment belongs to.
  final int seriesIndex;

  /// Optional name of the series.
  final String? seriesName;

  /// Index of this segment within its series (0 = first pair of points).
  final int segmentIndex;

  /// The data point at the start of this segment.
  final LinePoint rawStartPoint;

  /// The data point at the end of this segment.
  final LinePoint rawEndPoint;

  /// Canvas position of the segment start.
  final Offset start;

  /// Canvas position of the segment end.
  final Offset end;
}

/// Sealed base type for line chart hit-test results.
///
/// Use exhaustive `switch` to distinguish between [LinePointHit] and
/// [LineSegmentHit]:
///
/// ```dart
/// final hit = layout.hitTest(position);
/// if (hit != null) {
///   switch (hit) {
///     case LinePointHit(:final pointIndex):
///       // Handle point hit.
///     case LineSegmentHit(:final interpolatedX, :final interpolatedY):
///       // Handle segment hit.
///   }
/// }
/// ```
sealed class LineHitTestResult {
  /// Index of the series that was hit.
  int get seriesIndex;

  /// Optional name of the series that was hit.
  String? get seriesName;

  /// Distance from the query position to the hit geometry.
  double get distance;
}

/// A hit-test result indicating a data point was hit.
final class LinePointHit extends LineHitTestResult {
  LinePointHit({
    required this.seriesIndex,
    required this.seriesName,
    required this.pointIndex,
    required this.point,
    required this.center,
    required this.distance,
  });

  @override
  final int seriesIndex;

  @override
  final String? seriesName;

  /// Index of the hit point within its series.
  final int pointIndex;

  /// The original data point.
  final LinePoint point;

  /// Canvas position of the hit point.
  final Offset center;

  @override
  final double distance;
}

/// A hit-test result indicating a line segment was hit (between two points).
final class LineSegmentHit extends LineHitTestResult {
  LineSegmentHit({
    required this.seriesIndex,
    required this.seriesName,
    required this.segmentIndex,
    required this.startPoint,
    required this.endPoint,
    required this.nearestCanvasPoint,
    required this.t,
    required this.interpolatedX,
    required this.interpolatedY,
    required this.distance,
  });

  @override
  final int seriesIndex;

  @override
  final String? seriesName;

  /// Index of the hit segment within its series.
  final int segmentIndex;

  /// The data point at the start of the hit segment.
  final LinePoint startPoint;

  /// The data point at the end of the hit segment.
  final LinePoint endPoint;

  /// The nearest logical canvas point on the segment.
  final Offset nearestCanvasPoint;

  /// Interpolation fraction along the segment, in [0, 1].
  final double t;

  /// Interpolated raw X value at the hit position.
  final double interpolatedX;

  /// Interpolated raw Y value at the hit position.
  final double interpolatedY;

  @override
  final double distance;
}
