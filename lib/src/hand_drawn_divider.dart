import 'package:flutter/material.dart';

import 'hand_drawn_line_painter.dart';
import 'hand_drawn_toolkit_defaults.dart';

/// A horizontal or vertical divider rendered with a hand-drawn, sketchy stroke.
///
/// Behaves like Flutter's built-in [Divider] but renders a jittered line
/// instead of a perfectly straight one.
///
/// ```dart
/// Column(
///   children: [
///     Text('Section A'),
///     HandDrawnDivider(color: Colors.grey),
///     Text('Section B'),
///   ],
/// )
/// ```
///
/// For a vertical divider, set [direction] to [Axis.vertical]:
///
/// ```dart
/// Row(
///   children: [
///     Text('Left'),
///     HandDrawnDivider(direction: Axis.vertical, height: 40),
///     Text('Right'),
///   ],
/// )
/// ```
class HandDrawnDivider extends StatelessWidget {
  /// Creates a hand-drawn divider.
  ///
  /// For horizontal dividers (the default), [width] determines the line length
  /// and defaults to `double.infinity`. For vertical dividers, [height]
  /// determines the line length.
  const HandDrawnDivider({
    super.key,
    this.direction = Axis.horizontal,
    this.color = Colors.black54,
    this.thickness = HandDrawnDefaults.dividerThickness,
    this.irregularity = HandDrawnDefaults.dividerIrregularity,
    this.segments = HandDrawnDefaults.dividerSegments,
    this.seed = HandDrawnDefaults.seed,
    this.width,
    this.height,
    this.indent = 0.0,
    this.endIndent = 0.0,
  });

  /// Whether this divider runs horizontally or vertically.
  final Axis direction;

  /// The color of the hand-drawn stroke.
  final Color color;

  /// The width of the stroke in logical pixels.
  final double thickness;

  /// The roughness of the hand-drawn wobble.
  ///
  /// Defaults to [HandDrawnDefaults.dividerIrregularity], which is subtler
  /// than the container border default.
  final double irregularity;

  /// The number of linear segments used to draw the line.
  final int segments;

  /// The random seed for deterministic stroke generation.
  final int seed;

  /// The length of the divider line for horizontal dividers.
  ///
  /// Defaults to `double.infinity` (fill available width).
  final double? width;

  /// The length of the divider line for vertical dividers.
  ///
  /// Required when [direction] is [Axis.vertical].
  final double? height;

  /// Empty space before the start of the divider stroke.
  final double indent;

  /// Empty space after the end of the divider stroke.
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    final isHorizontal = direction == Axis.horizontal;

    // The drawing area needs a small cross-axis extent to contain the
    // jittered stroke without clipping. We use thickness * 4 to give the
    // wobble comfortable room.
    final crossAxis = thickness * 4;

    return Padding(
      padding: isHorizontal
          ? EdgeInsets.only(left: indent, right: endIndent)
          : EdgeInsets.only(top: indent, bottom: endIndent),
      child: SizedBox(
        width: isHorizontal ? (width ?? double.infinity) : crossAxis,
        height: isHorizontal ? crossAxis : (height ?? double.infinity),
        child: CustomPaint(
          painter: HandDrawnLinePainter(
            color: color,
            strokeWidth: thickness,
            irregularity: irregularity,
            segments: segments,
            seed: seed,
            buildPath: (size, h) =>
                isHorizontal ? h.lineHorizontal(size) : h.lineVertical(size),
          ),
        ),
      ),
    );
  }
}
