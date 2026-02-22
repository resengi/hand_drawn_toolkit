import 'package:flutter/material.dart';

import 'hand_drawn_line_painter.dart';
import 'hand_drawn_toolkit_defaults.dart';

/// A container widget with a hand-drawn rectangular border.
///
/// Wraps its [child] with a solid [backgroundColor] fill and renders a
/// jittered, sketchy border on top using [HandDrawnLinePainter]. The border
/// is drawn as a foreground overlay so it sits above the background and
/// child content.
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
    this.backgroundColor = Colors.white,
    this.strokeColor = Colors.black87,
    this.strokeWidth = HandDrawnDefaults.strokeWidth,
    this.irregularity = HandDrawnDefaults.irregularity,
    this.padding = const EdgeInsets.all(HandDrawnDefaults.containerPadding),
    this.borderOpacity = HandDrawnDefaults.borderOpacity,
    this.segments = HandDrawnDefaults.segments,
    this.seed = HandDrawnDefaults.seed,
  });

  /// The widget below this container in the tree.
  final Widget child;

  /// The solid fill color behind the child content.
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

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: HandDrawnLinePainter(
        color: strokeColor.withValues(alpha: borderOpacity),
        strokeWidth: strokeWidth,
        irregularity: irregularity,
        segments: segments,
        seed: seed,
        buildPath: (size, h) => h.rectBorder(size),
      ),
      child: Container(color: backgroundColor, padding: padding, child: child),
    );
  }
}
