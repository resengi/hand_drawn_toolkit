import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/painting.dart'
    show TextDirection, TextPainter, TextSpan, TextStyle;

/// How far a shape's fill extends relative to its hand-drawn stroke.
///
/// Used by every closed hand-drawn shape that has both a stroke and an inner
/// fill: [HandDrawnContainer] (and through it [HandDrawnTable] and a boxed
/// [HandDrawnLegend]), [HandDrawnStatusSquare], bar segments, and scatter
/// dots. Let *P* be the jittered path the stroke follows and *S* the shape's
/// un-jittered geometry.
///
/// | Mode              | Fill region                        | Cost            |
/// |-------------------|------------------------------------|-----------------|
/// | [standardShape]   | *S*; ignores the wobble            | one draw        |
/// | [strokeCenter]    | interior of *P*, to the centerline | one draw        |
/// | [strokeOuterEdge] | interior of *P* plus the band      | layer + 2 draws |
/// | [strokeInnerEdge] | interior of *P* minus the band     | layer + 2 draws |
///
/// *S* is the layout box for the container family, the inset square for the
/// status square, the segment rectangle for bars, and the exact circle for
/// scatter dots. With an opaque stroke the three stroke-relative modes look
/// the same wherever the stroke covers a pixel; they differ when the stroke
/// is translucent or hidden.
enum HandDrawnFillExtent {
  /// Fills the un-jittered geometry. Where the stroke wobbles inward, the
  /// fill shows outside it.
  standardShape,

  /// Fills the interior of the jittered path; the fill meets the stroke at
  /// its centerline.
  strokeCenter,

  /// Fills the interior plus the full stroke band; a translucent stroke
  /// blends uniformly over the fill color.
  strokeOuterEdge,

  /// Fills the interior minus the full stroke band; a translucent stroke
  /// blends uniformly over whatever is behind the shape.
  strokeInnerEdge,
}

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
  }) : _rand = math.Random(seed) {
    checkGenerationParameters(segments, irregularity);
  }

  /// Validates the path-generation parameters shared by every hand-drawn
  /// shape in the package.
  ///
  /// Throws [ArgumentError] when [segments] is not positive or when
  /// [irregularity] is negative or not finite. This is the single
  /// authoritative check for these two parameters; the constructor and the
  /// painters that generate wobbly geometry all call it rather than
  /// restating the rules.
  static void checkGenerationParameters(int segments, double irregularity) {
    if (segments <= 0) {
      throw ArgumentError.value(segments, 'segments', 'must be positive');
    }
    if (!irregularity.isFinite || irregularity < 0) {
      throw ArgumentError.value(
        irregularity,
        'irregularity',
        'must be finite and non-negative',
      );
    }
  }

  /// The random seed used for deterministic path generation.
  final int seed;

  /// The number of linear segments per edge.
  final int segments;

  /// The magnitude of random offset per point, in logical pixels.
  final double irregularity;

  final math.Random _rand;

  /// Applies a 3-point moving average to [raw] offsets, preserving the
  /// first and last values. This produces organic, pen-like wobble.
  ///
  /// This is the shared smoothing algorithm used by both the core helpers
  /// and the chart painters to ensure visual consistency across the package.
  static List<double> smooth(List<double> raw) {
    final smoothed = List<double>.from(raw);
    for (int i = 1; i < raw.length - 1; i++) {
      smoothed[i] = (raw[i - 1] + raw[i] + raw[i + 1]) / 3.0;
    }
    return smoothed;
  }

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
    return smooth(raw);
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

// ── Shared free helpers ─────────────────────────────────────────────────────

/// Validates a stroke width for the hand-drawn painters.
///
/// Throws [ArgumentError] when [strokeWidth] is not a finite, positive number.
/// This is the single authoritative check for stroke widths; every painter
/// that strokes or erases a hand-drawn band calls it at construction.
void checkStrokeWidth(double strokeWidth) {
  if (!strokeWidth.isFinite || strokeWidth <= 0) {
    throw ArgumentError.value(strokeWidth, 'strokeWidth', 'must be positive');
  }
}

/// The stroke [Paint] shared by hand-drawn paths.
///
/// [join] is how the stroke turns at each jittered vertex; round by default.
/// The fill routine reuses this exact configuration to add or remove the
/// stroke band, so a shape must pass the same [join] to [paintHandDrawnFill]
/// and to its visible stroke.
///
/// Returns a fresh mutable [Paint] so callers can set a blend mode.
Paint handDrawnStrokePaint({
  required Color color,
  required double width,
  StrokeJoin join = StrokeJoin.round,
}) {
  return Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = width
    ..strokeCap = StrokeCap.round
    ..strokeJoin = join;
}

/// Fills a closed hand-drawn shape according to [extent].
///
/// [border] builds the jittered closed path the visible stroke follows;
/// [standardShape] builds the shape's un-jittered geometry. Each mode builds
/// only the geometry it uses, and a fully transparent [color] builds none.
///
/// [strokeWidth] and [join] describe the visible stroke; the edge modes use
/// them to reproduce the stroke band exactly. The visible stroke itself is
/// not drawn here.
void paintHandDrawnFill(
  Canvas canvas, {
  required Path Function() border,
  required Path Function() standardShape,
  required Color color,
  required HandDrawnFillExtent extent,
  required double strokeWidth,
  StrokeJoin join = StrokeJoin.round,
}) {
  if (color.a == 0) return;
  final fill = Paint()
    ..color = color
    ..style = PaintingStyle.fill;

  if (extent == HandDrawnFillExtent.standardShape) {
    canvas.drawPath(standardShape(), fill);
    return;
  }
  final path = border();
  if (extent == HandDrawnFillExtent.strokeCenter) {
    canvas.drawPath(path, fill);
    return;
  }

  // Edge modes: fill inside a layer, then either replace the stroke band
  // with the fill color (outer edge) or erase it (inner edge). Inside the
  // layer, `src` replaces rather than blends, so a translucent color has
  // single coverage across the whole region; `clear` ignores the color.
  final band = extent == HandDrawnFillExtent.strokeOuterEdge
      ? BlendMode.src
      : BlendMode.clear;
  canvas.saveLayer(path.getBounds().inflate(strokeWidth), Paint());
  canvas.drawPath(path, fill);
  canvas.drawPath(
    path,
    handDrawnStrokePaint(color: color, width: strokeWidth, join: join)
      ..blendMode = band,
  );
  canvas.restore();
}

/// Lays out [text] in [style] with default LTR direction and returns
/// the resulting [TextPainter], ready for measurement or paint.
///
/// When [maxWidth] is finite, the text painter wraps onto multiple
/// lines as needed; the resulting `TextPainter.height` reflects the
/// wrapped height. The default `double.infinity` produces single-line,
/// unbounded layout for callers that don't need wrapping.
///
/// When [maxLines] and [ellipsis] are both provided, lines beyond the
/// limit are truncated and the truncation marker is appended. This
/// only takes effect under a finite [maxWidth] — without a width
/// constraint the painter has no notion of where to truncate.
TextPainter layoutText(
  String text,
  TextStyle style, {
  double maxWidth = double.infinity,
  int? maxLines,
  String? ellipsis,
}) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
    ellipsis: ellipsis,
  )..layout(maxWidth: maxWidth);
  return tp;
}
