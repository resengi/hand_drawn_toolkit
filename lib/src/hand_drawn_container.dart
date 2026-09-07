import 'package:flutter/material.dart';

import 'hand_drawn_line_painter.dart';
import 'hand_drawn_toolkit_defaults.dart';
import 'hand_drawn_toolkit_helpers.dart';

/// A container widget with a hand-drawn rectangular border.
///
/// Wraps its [child] with a [backgroundColor] fill painted by a
/// [HandDrawnFillPainter] and a jittered, sketchy border painted on top by a
/// [HandDrawnLinePainter]. Both painters generate the same border path, so
/// the fill can follow the wobble exactly. The border is drawn as a
/// foreground overlay so it sits above the background and child content.
///
/// ```dart
/// HandDrawnContainer(
///   backgroundColor: Colors.white,
///   strokeColor: Colors.black87,
///   irregularity: 3.5,
///   padding: EdgeInsets.all(20),
///   child: Text('Sketchy!'),
/// )
/// ```
///
/// ## Controlling the look
///
/// | Parameter       | Effect                                           |
/// |-----------------|--------------------------------------------------|
/// | [irregularity]  | Roughness of the border (0 = straight, 6 = wild) |
/// | [segments]      | Smoothness of jitter (more = smoother wobble)     |
/// | [seed]          | Change the specific wobble pattern                |
/// | [borderOpacity] | Fade the border in/out without changing color      |
/// | [fillExtent]    | How far the background extends toward the border  |
///
/// ## Background fill extent
///
/// [fillExtent] selects how the background relates to the wobbly border; see
/// [HandDrawnFillExtent]. The default, [HandDrawnFillExtent.standardShape],
/// fills the container's full layout box. In the stroke-relative modes the
/// background silhouette follows the wobble, which is visible when the border
/// is translucent or faded out via [borderOpacity].
///
/// ## Deterministic rendering
///
/// The border shape is fully determined by [seed], [segments], and
/// [irregularity]. Identical parameters always produce the same border, so
/// the shape won't shift during rebuilds or animations. To get a different
/// wobble pattern, change the [seed].
class HandDrawnContainer extends StatelessWidget {
  /// Creates a container with a hand-drawn border.
  const HandDrawnContainer({
    required this.child,
    super.key,
    this.backgroundColor = HandDrawnDefaults.containerBackgroundColor,
    this.strokeColor = HandDrawnDefaults.containerStrokeColor,
    this.strokeWidth = HandDrawnDefaults.strokeWidth,
    this.irregularity = HandDrawnDefaults.irregularity,
    this.padding = const EdgeInsets.all(HandDrawnDefaults.containerPadding),
    this.borderOpacity = HandDrawnDefaults.borderOpacity,
    this.segments = HandDrawnDefaults.segments,
    this.seed = HandDrawnDefaults.seed,
    this.fillExtent = HandDrawnDefaults.containerFillExtent,
  }) : assert(borderOpacity >= 0 && borderOpacity <= 1);

  /// The widget below this container in the tree.
  final Widget child;

  /// The fill color behind the child content.
  final Color backgroundColor;

  /// The color of the hand-drawn border stroke.
  final Color strokeColor;

  /// The width of the border stroke in logical pixels.
  final double strokeWidth;

  /// The roughness of the hand-drawn effect.
  ///
  /// See [HandDrawnDefaults.irregularity] for typical values.
  final double irregularity;

  /// Inner padding between the border and [child].
  final EdgeInsets padding;

  /// Opacity multiplier applied to the border stroke.
  ///
  /// Useful for animating the border in/out without changing [strokeColor].
  /// A value of `0.0` hides the border; `1.0` shows it at full opacity.
  final double borderOpacity;

  /// The number of linear segments per edge.
  ///
  /// See [HandDrawnHelpers.segments] for details.
  final int segments;

  /// The random seed for deterministic border generation.
  ///
  /// See [HandDrawnHelpers.seed] for details.
  final int seed;

  /// How far [backgroundColor] extends relative to the border stroke.
  ///
  /// See [HandDrawnFillExtent]. For [HandDrawnFillExtent.standardShape] the
  /// background fills the container's full layout box.
  final HandDrawnFillExtent fillExtent;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: HandDrawnFillPainter(
        color: backgroundColor,
        strokeWidth: strokeWidth,
        extent: fillExtent,
        irregularity: irregularity,
        segments: segments,
        seed: seed,
        buildPath: _rectBorder,
        inset: (strokeWidth / 2).ceilToDouble(),
      ),
      foregroundPainter: HandDrawnLinePainter(
        color: strokeColor.withValues(alpha: strokeColor.a * borderOpacity),
        strokeWidth: strokeWidth,
        irregularity: irregularity,
        segments: segments,
        seed: seed,
        buildPath: _rectBorder,
        inset: (strokeWidth / 2).ceilToDouble(),
      ),
      child: Padding(padding: padding, child: child),
    );
  }

  // Static so both painters hold the same reference across rebuilds.
  static Path _rectBorder(Size size, HandDrawnHelpers h) => h.rectBorder(size);
}
