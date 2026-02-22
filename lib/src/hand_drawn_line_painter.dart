import 'package:flutter/rendering.dart';

import 'hand_drawn_toolkit_defaults.dart';
import 'hand_drawn_toolkit_helpers.dart';

/// A [CustomPainter] that renders a hand-drawn stroke path.
///
/// The path is defined by the [buildPath] callback, which receives the
/// available [Size] and a [HandDrawnHelpers] instance for generating jittered
/// paths. The painter caches the generated path and only recomputes it when
/// the size or generation parameters change.
///
/// ## Built-in path shapes
///
/// Use the helpers' convenience methods for common shapes:
///
/// ```dart
/// // Horizontal line
/// HandDrawnLinePainter(
///   color: Colors.black,
///   strokeWidth: 2.0,
///   irregularity: 3.5,
///   buildPath: (size, h) => h.lineHorizontal(size),
/// )
///
/// // Rectangle border
/// HandDrawnLinePainter(
///   color: Colors.black,
///   strokeWidth: 2.0,
///   irregularity: 3.5,
///   buildPath: (size, h) => h.rectBorder(size),
/// )
/// ```
///
/// ## Custom paths
///
/// For shapes not covered by the built-in helpers, use [HandDrawnHelpers.smoothedOffsets]
/// directly to generate jittered point sequences and build your own [Path]:
///
/// ```dart
/// HandDrawnLinePainter(
///   color: Colors.blue,
///   strokeWidth: 1.5,
///   irregularity: 2.0,
///   buildPath: (size, h) {
///     final offsets = h.smoothedOffsets();
///     final path = Path()..moveTo(0, size.height);
///     final dx = size.width / h.segments;
///     for (int i = 1; i <= h.segments; i++) {
///       final t = i / h.segments;
///       final y = size.height * (1 - t) + offsets[i];
///       path.lineTo(dx * i, y);
///     }
///     return path;
///   },
/// )
/// ```
///
/// ## Performance
///
/// The generated [Path] is cached internally and only recomputed when the
/// widget's size or any of the generation parameters ([color], [strokeWidth],
/// [irregularity], [seed], [segments]) change. This makes it safe to use in
/// frequently-rebuilding widget trees.
class HandDrawnLinePainter extends CustomPainter {
  /// Creates a hand-drawn line painter.
  ///
  /// All parameters except [buildPath] have sensible defaults from
  /// [HandDrawnDefaults].
  ///
  /// - [color]: The stroke color.
  /// - [strokeWidth]: The width of the stroke in logical pixels.
  /// - [irregularity]: How rough the hand-drawn effect appears.
  /// - [buildPath]: A callback that builds the [Path] to render, given the
  ///   available [Size] and a [HandDrawnHelpers] instance.
  /// - [seed]: Random seed for deterministic jitter.
  /// - [segments]: Number of linear segments per edge.
  HandDrawnLinePainter({
    required this.color,
    required this.buildPath,
    this.strokeWidth = HandDrawnDefaults.strokeWidth,
    this.irregularity = HandDrawnDefaults.irregularity,
    this.seed = HandDrawnDefaults.seed,
    this.segments = HandDrawnDefaults.segments,
  });

  /// The color of the hand-drawn stroke.
  final Color color;

  /// The width of the stroke in logical pixels.
  final double strokeWidth;

  /// The magnitude of random jitter applied to path points. See
  /// [HandDrawnHelpers.irregularity].
  final double irregularity;

  /// The random seed for deterministic path generation.
  final int seed;

  /// The number of linear segments per edge. See
  /// [HandDrawnHelpers.segments].
  final int segments;

  /// Callback that builds the stroke [Path].
  ///
  /// Receives the available [Size] and a [HandDrawnHelpers] instance
  /// pre-configured with this painter's [seed], [segments], and
  /// [irregularity].
  final Path Function(Size size, HandDrawnHelpers helpers) buildPath;

  // ── Path caching ─────────────────────────────────────────────────────────

  Path? _cachedPath;
  Size? _lastSize;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (_cachedPath == null || _lastSize != size) {
      final helpers = HandDrawnHelpers(
        seed: seed,
        segments: segments,
        irregularity: irregularity,
      );
      _cachedPath = buildPath(size, helpers);
      _lastSize = size;
    }

    canvas.drawPath(_cachedPath!, paint);
  }

  @override
  bool shouldRepaint(covariant HandDrawnLinePainter old) {
    final paramsChanged =
        old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.irregularity != irregularity ||
        old.seed != seed ||
        old.segments != segments;
    if (paramsChanged) {
      _cachedPath = null;
    }
    return paramsChanged;
  }
}
