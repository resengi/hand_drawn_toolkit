import 'dart:math' as math;
import 'dart:ui';

/// Generates jittered [Path] objects that simulate hand-drawn strokes.
///
/// Each helper method produces a [Path] sized to a given [Size]. The jitter is
/// deterministic — controlled by [seed] — so repeated calls with the same
/// parameters always produce the same path. This prevents visual "dancing"
/// during widget rebuilds.
///
/// The smoothing algorithm works in two passes:
///  1. Generate raw random offsets along the path.
///  2. Apply a 3-point moving average to soften harsh spikes while preserving
///     the organic feel.
///
/// ```dart
/// final helpers = HandDrawnHelpers(
///   seed: 42,
///   segments: 24,
///   irregularity: 3.5,
/// );
/// final path = helpers.rectBorder(Size(200, 100));
/// ```
class HandDrawnHelpers {
  /// Creates a new [HandDrawnHelpers] instance.
  ///
  /// - [seed]: Random seed for deterministic jitter reproduction.
  /// - [segments]: Number of linear segments per edge. More segments yield
  ///   smoother wobble; fewer segments produce a chunkier look.
  /// - [irregularity]: Maximum pixel offset applied to each segment point.
  ///   Higher values create rougher strokes.
  HandDrawnHelpers({
    required this.seed,
    required this.segments,
    required this.irregularity,
  }) : _rand = math.Random(seed);

  /// The random seed used for deterministic path generation.
  final int seed;

  /// The number of linear segments per edge.
  final int segments;

  /// The magnitude of random offset per point, in logical pixels.
  final double irregularity;

  final math.Random _rand;

  /// Generates smoothed random offsets for a polyline with `segments + 1`
  /// points.
  ///
  /// The first and last offsets are always zero so strokes begin and end at
  /// their intended positions. Interior points are randomly jittered and then
  /// smoothed with a 3-point moving average.
  ///
  /// This is the foundation of all path-building methods and can be used
  /// directly for custom path shapes.
  List<double> smoothedOffsets() {
    final n = segments + 1;
    final raw = List<double>.filled(n, 0);
    for (int i = 1; i < segments; i++) {
      raw[i] = (_rand.nextDouble() - 0.5) * irregularity;
    }
    // 3-point moving average for organic smoothing.
    final smooth = List<double>.from(raw);
    for (int i = 1; i < segments; i++) {
      smooth[i] = (raw[i - 1] + raw[i] + raw[i + 1]) / 3.0;
    }
    return smooth;
  }

  /// Builds a horizontal hand-drawn line across [size].width, centered
  /// vertically at `size.height / 2`.
  ///
  /// The line starts at the left edge and ends exactly at the right edge; only
  /// the interior points are jittered.
  ///
  /// Useful for dividers, underlines, and separators.
  Path lineHorizontal(Size size) {
    final offs = smoothedOffsets();
    final y0 = size.height / 2;
    final dx = size.width / segments;
    final p = Path()..moveTo(0, y0 + offs[0]);
    for (int i = 1; i <= segments; i++) {
      p.lineTo(dx * i, i == segments ? y0 : y0 + offs[i]);
    }
    return p;
  }

  /// Builds a vertical hand-drawn line across [size].height, centered
  /// horizontally at `size.width / 2`.
  ///
  /// The line starts at the top edge and ends exactly at the bottom edge; only
  /// the interior points are jittered.
  ///
  /// Useful for vertical separators and side accents.
  Path lineVertical(Size size) {
    final offs = smoothedOffsets();
    final x0 = size.width / 2;
    final dy = size.height / segments;
    final p = Path()..moveTo(x0 + offs[0], 0);
    for (int i = 1; i <= segments; i++) {
      p.lineTo(i == segments ? x0 : x0 + offs[i], dy * i);
    }
    return p;
  }

  /// Builds a closed hand-drawn rectangle border by stitching four
  /// independently jittered edges.
  ///
  /// Each edge (top, right, bottom, left) uses its own set of smoothed random
  /// offsets, so the irregularity varies around the perimeter — just like a
  /// real pen stroke. The path is closed so it can be used with both stroke
  /// and fill painting styles.
  ///
  /// The border traces around the full [size], with jitter applied
  /// perpendicular to each edge.
  Path rectBorder(Size size) {
    final top = smoothedOffsets();
    final right = smoothedOffsets();
    final bottom = smoothedOffsets();
    final left = smoothedOffsets();
    final p = Path()..moveTo(0, top[0]);

    // Top edge: left → right, jitter along Y.
    final dx = size.width / segments;
    for (int i = 1; i <= segments; i++) {
      p.lineTo(dx * i, top[i]);
    }
    // Right edge: top → bottom, jitter along X.
    final dy = size.height / segments;
    for (int i = 1; i <= segments; i++) {
      p.lineTo(size.width + right[i], dy * i);
    }
    // Bottom edge: right → left, jitter along Y.
    for (int i = 1; i <= segments; i++) {
      p.lineTo(size.width - dx * i, size.height + bottom[i]);
    }
    // Left edge: bottom → top, jitter along X.
    for (int i = 1; i <= segments; i++) {
      p.lineTo(left[i], size.height - dy * i);
    }
    p.close();
    return p;
  }
}
