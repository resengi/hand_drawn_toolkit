import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';

import 'hand_drawn_toolkit_defaults.dart';
import 'hand_drawn_toolkit_helpers.dart';

/// Base class for painters that render a hand-drawn [Path].
///
/// Subclasses decide what to do with the path ([HandDrawnLinePainter]
/// strokes it, [HandDrawnFillPainter] fills it). This class owns how the
/// path is generated: the [buildPath] callback, the generation parameters
/// ([seed], [segments], [irregularity]), the per-instance path cache, and the
/// repaint decision for those inputs.
///
/// [pathFor] constructs a fresh [HandDrawnHelpers] for the painter's
/// parameters and passes it to [buildPath], so two painters with equal inputs
/// produce identical paths without sharing random state. The result is
/// cached and reused while [paint] is called at the same size on the same
/// instance.
///
/// [shouldRepaint] compares [buildPath] along with the numeric parameters.
/// An inline closure is a new object on every build and therefore repaints on
/// every rebuild; a static method, a top-level function, or a tear-off from
/// the same instance is a stable reference and does not.
abstract class HandDrawnPathPainter extends CustomPainter {
  /// Creates a hand-drawn path painter.
  ///
  /// Throws [ArgumentError] when [segments] is not positive or when
  /// [irregularity] is negative or not finite.
  HandDrawnPathPainter({
    required this.buildPath,
    this.irregularity = HandDrawnDefaults.irregularity,
    this.seed = HandDrawnDefaults.seed,
    this.segments = HandDrawnDefaults.segments,
    this.inset = 0,
  }) {
    HandDrawnHelpers.checkGenerationParameters(segments, irregularity);

    if (!inset.isFinite || inset < 0) {
      throw ArgumentError.value(
        inset,
        'inset',
        'must be finite and non-negative',
      );
    }
  }

  /// The magnitude of random jitter applied to path points. See
  /// [HandDrawnHelpers.irregularity].
  final double irregularity;

  /// The random seed for deterministic path generation.
  final int seed;

  /// The number of linear segments per edge. See
  /// [HandDrawnHelpers.segments].
  final int segments;

  /// The amount removed from each edge of the size passed to [buildPath];
  /// the resulting path is translated by the same amount in both axes.
  final double inset;

  /// Callback that builds the [Path], given the available [Size] after
  /// [inset] is removed from each edge and a [HandDrawnHelpers] configured
  /// with this painter's [seed], [segments], and [irregularity].
  final Path Function(Size size, HandDrawnHelpers helpers) buildPath;

  Path? _cachedPath;
  Size? _lastSize;

  /// Returns the path for [size], generating it on the first call for that
  /// size and reusing it afterwards.
  @protected
  Path pathFor(Size size) {
    if (_cachedPath == null || _lastSize != size) {
      final helpers = HandDrawnHelpers(
        seed: seed,
        segments: segments,
        irregularity: irregularity,
      );

      final inner = inset == 0
          ? size
          : Size(size.width - inset * 2, size.height - inset * 2);
      final path = buildPath(inner, helpers);
      _cachedPath = inset == 0 ? path : path.shift(Offset(inset, inset));

      _lastSize = size;
    }
    return _cachedPath!;
  }

  @override
  @mustCallSuper
  bool shouldRepaint(covariant HandDrawnPathPainter old) {
    return old.buildPath != buildPath ||
        old.irregularity != irregularity ||
        old.seed != seed ||
        old.segments != segments ||
        old.inset != inset;
  }
}

/// A [HandDrawnPathPainter] that strokes a hand-drawn path.
///
/// The path is defined by the [buildPath] callback, which receives the
/// available [Size] and a [HandDrawnHelpers] instance for generating jittered
/// paths. Path generation, caching, and the repaint decision for the
/// generation inputs are described on [HandDrawnPathPainter]. To fill the
/// same path, pair this painter with a [HandDrawnFillPainter] that receives
/// the same [buildPath], generation inputs, and [strokeWidth].
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
/// The stroke uses round caps and joins. [color] and [strokeWidth] affect
/// only the paint, not the generated path.
class HandDrawnLinePainter extends HandDrawnPathPainter {
  /// Creates a hand-drawn line painter.
  ///
  /// All parameters except [buildPath] have defaults from
  /// [HandDrawnDefaults].
  ///
  /// - [color]: The stroke color.
  /// - [strokeWidth]: The width of the stroke in logical pixels.
  /// - [irregularity]: How rough the hand-drawn effect appears.
  /// - [buildPath]: A callback that builds the [Path] to render, given the
  ///   available [Size] and a [HandDrawnHelpers] instance.
  /// - [seed]: Random seed for deterministic jitter.
  /// - [segments]: Number of linear segments per edge.
  ///
  /// Throws [ArgumentError] when [strokeWidth] is not a finite, positive
  /// number, when [segments] is not positive, or when [irregularity] is
  /// negative or not finite.
  HandDrawnLinePainter({
    required this.color,
    required super.buildPath,
    this.strokeWidth = HandDrawnDefaults.strokeWidth,
    super.irregularity,
    super.seed,
    super.segments,
    super.inset,
  }) {
    checkStrokeWidth(strokeWidth);
  }

  /// The color of the hand-drawn stroke.
  final Color color;

  /// The width of the stroke in logical pixels.
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      pathFor(size),
      handDrawnStrokePaint(color: color, width: strokeWidth),
    );
  }

  @override
  bool shouldRepaint(covariant HandDrawnLinePainter old) {
    return super.shouldRepaint(old) ||
        old.color != color ||
        old.strokeWidth != strokeWidth;
  }
}

/// A [HandDrawnPathPainter] that fills the region enclosed by a hand-drawn
/// path, according to a [HandDrawnFillExtent].
///
/// This painter draws no stroke. A visible matching outline comes from a
/// [HandDrawnLinePainter] given the same [buildPath], [seed], [segments],
/// [irregularity], and [strokeWidth]; [HandDrawnContainer] pairs the two as
/// its background and foreground painters. [buildPath] must produce a closed
/// path. For [HandDrawnFillExtent.standardShape] the fill is the painter's
/// full canvas rectangle.
///
/// ```dart
/// CustomPaint(
///   painter: HandDrawnFillPainter(
///     color: Colors.yellow,
///     strokeWidth: 2.0,
///     extent: HandDrawnFillExtent.strokeOuterEdge,
///     buildPath: (size, h) => h.rectBorder(size),
///   ),
///   foregroundPainter: HandDrawnLinePainter(
///     color: Colors.black,
///     strokeWidth: 2.0,
///     buildPath: (size, h) => h.rectBorder(size),
///   ),
///   child: child,
/// )
/// ```
class HandDrawnFillPainter extends HandDrawnPathPainter {
  /// Creates a hand-drawn fill painter.
  ///
  /// [strokeWidth] is the width of the stroke this fill is paired with; the
  /// edge modes use it to reproduce the stroke band. Throws [ArgumentError]
  /// when it is not a finite, positive number, or when [segments] or
  /// [irregularity] is invalid.
  HandDrawnFillPainter({
    required this.color,
    required this.strokeWidth,
    required super.buildPath,
    this.extent = HandDrawnFillExtent.strokeCenter,
    super.irregularity,
    super.seed,
    super.segments,
    super.inset,
  }) {
    checkStrokeWidth(strokeWidth);
  }

  /// The fill color.
  final Color color;

  /// The width of the stroke this fill is paired with.
  final double strokeWidth;

  /// How far the fill extends relative to the stroke.
  final HandDrawnFillExtent extent;

  @override
  void paint(Canvas canvas, Size size) {
    paintHandDrawnFill(
      canvas,
      border: () => pathFor(size),
      standardShape: () => Path()..addRect(Offset.zero & size),
      color: color,
      extent: extent,
      strokeWidth: strokeWidth,
    );
  }

  @override
  bool shouldRepaint(covariant HandDrawnFillPainter old) {
    return super.shouldRepaint(old) ||
        old.color != color ||
        old.strokeWidth != strokeWidth ||
        old.extent != extent;
  }
}
