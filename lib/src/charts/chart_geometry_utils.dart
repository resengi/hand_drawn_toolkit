import 'dart:math' as math;
import 'dart:ui' show Offset;

/// Squared distance between two points.
///
/// Avoids the square-root cost when only relative comparisons are needed.
double distanceSquared(Offset a, Offset b) {
  final dx = a.dx - b.dx;
  final dy = a.dy - b.dy;
  return dx * dx + dy * dy;
}

/// Euclidean distance between two points.
double distance(Offset a, Offset b) => math.sqrt(distanceSquared(a, b));

/// Returns the nearest point on the line segment [start]→[end] to [point],
/// and the clamped interpolation fraction `t` in [0, 1].
///
/// When `t == 0` the nearest point is [start]; when `t == 1` it is [end].
({Offset nearest, double t}) nearestPointOnSegment(
  Offset point,
  Offset start,
  Offset end,
) {
  final dx = end.dx - start.dx;
  final dy = end.dy - start.dy;
  final lengthSq = dx * dx + dy * dy;

  if (lengthSq == 0) {
    // Degenerate segment (start == end).
    return (nearest: start, t: 0.0);
  }

  // Project point onto the infinite line, then clamp to [0, 1].
  final t =
      (((point.dx - start.dx) * dx + (point.dy - start.dy) * dy) / lengthSq)
          .clamp(0.0, 1.0);

  final nearest = Offset(start.dx + t * dx, start.dy + t * dy);
  return (nearest: nearest, t: t);
}

/// Linearly interpolates a raw data value given endpoints and fraction `t`.
double interpolateValue(double startValue, double endValue, double t) {
  return startValue + (endValue - startValue) * t;
}
