import 'package:flutter/material.dart';

import 'hand_drawn_toolkit_defaults.dart';
import 'hand_drawn_toolkit_helpers.dart';
import 'status_indicator.dart';

/// A hand-drawn square that can be empty, filled, and overlaid with a
/// status indicator (checkmark or dash).
///
/// This is a generic status control — it knows nothing about domain-specific
/// enums like "completed" or "skipped". The consumer maps their own status
/// model to [color], [isFilled], and [indicator] at the call site.
///
/// ```dart
/// HandDrawnStatusSquare(
///   color: Colors.green,
///   isFilled: true,
///   indicator: StatusIndicator.check,
///   onTap: () => toggleStatus(),
/// )
/// ```
///
/// When [onTap] is provided the square becomes interactive with an enlarged
/// tap target for comfortable touch input. When null the widget is
/// display-only.
///
/// ## Deterministic rendering
///
/// The border shape is fully determined by [seed], [segments], and
/// [irregularity]. Identical parameters always produce the same border.
class HandDrawnStatusSquare extends StatelessWidget {
  /// Creates a hand-drawn status square.
  const HandDrawnStatusSquare({
    required this.color,
    this.isFilled = false,
    this.indicator = StatusIndicator.none,
    this.indicatorColor = Colors.white,
    this.size = HandDrawnDefaults.statusSquareSize,
    this.scaleFactor = 1.0,
    this.onTap,
    this.tapPadding = HandDrawnDefaults.statusSquareTapPadding,
    this.seed = HandDrawnDefaults.seed,
    this.irregularity = HandDrawnDefaults.statusSquareIrregularity,
    this.segments = HandDrawnDefaults.statusSquareSegments,
    this.strokeWidth = HandDrawnDefaults.statusSquareStrokeWidth,
    this.indicatorStrokeWidth =
        HandDrawnDefaults.statusSquareIndicatorStrokeWidth,
    super.key,
  });

  /// The color used for both the border stroke and the fill (when
  /// [isFilled] is true).
  final Color color;

  /// Whether the square is filled with [color].
  ///
  /// When false, only the outline is drawn.
  final bool isFilled;

  /// The indicator drawn on top of the filled square.
  final StatusIndicator indicator;

  /// The color of the [indicator] stroke.
  final Color indicatorColor;

  /// The side length of the painted square in logical pixels.
  final double size;

  /// A multiplier applied to [size] for accessibility scaling.
  ///
  /// Consumers with a layout scale factor can pass it here rather than
  /// manually multiplying [size].
  final double scaleFactor;

  /// When non-null, the square becomes tappable with an enlarged hit area
  /// surrounding the painted square.
  final VoidCallback? onTap;

  /// The padding added around the square to enlarge the tap target when
  /// [onTap] is non-null.
  final double tapPadding;

  /// The random seed for deterministic border generation.
  final int seed;

  /// The roughness of the hand-drawn border.
  final double irregularity;

  /// The number of linear segments per edge.
  final int segments;

  /// The width of the border stroke in logical pixels.
  final double strokeWidth;

  /// The width of the indicator (check / dash) stroke in logical pixels.
  final double indicatorStrokeWidth;

  @override
  Widget build(BuildContext context) {
    final scaledSize = size * scaleFactor;
    final square = SizedBox(
      width: scaledSize,
      height: scaledSize,
      child: CustomPaint(
        painter: _StatusSquarePainter(
          color: color,
          isFilled: isFilled,
          indicator: indicator,
          indicatorColor: indicatorColor,
          seed: seed,
          irregularity: irregularity,
          segments: segments,
          strokeWidth: strokeWidth,
          indicatorStrokeWidth: indicatorStrokeWidth,
        ),
      ),
    );

    if (onTap == null) return square;

    // Expand the tap target beyond the small painted square while keeping
    // the visual size unchanged.
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(padding: EdgeInsets.all(tapPadding), child: square),
    );
  }
}

class _StatusSquarePainter extends CustomPainter {
  _StatusSquarePainter({
    required this.color,
    required this.isFilled,
    required this.indicator,
    required this.indicatorColor,
    required this.seed,
    required this.irregularity,
    required this.segments,
    required this.strokeWidth,
    required this.indicatorStrokeWidth,
  });

  final Color color;
  final bool isFilled;
  final StatusIndicator indicator;
  final Color indicatorColor;
  final int seed;
  final double irregularity;
  final int segments;
  final double strokeWidth;
  final double indicatorStrokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final helper = HandDrawnHelpers(
      seed: seed,
      irregularity: irregularity,
      segments: segments,
    );

    // Inset the drawing area so the stroke doesn't clip at the edges.
    final inset = (strokeWidth / 2).ceilToDouble();
    canvas.save();
    canvas.translate(inset, inset);
    final boxPath = helper.rectBorder(
      Size(size.width - inset * 2, size.height - inset * 2),
    );

    // Fill first so the outline draws on top, preserving the hand-drawn
    // silhouette.
    if (isFilled) {
      final fillPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      canvas.drawPath(boxPath, fillPaint);
    }

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawPath(boxPath, borderPaint);

    // Draw the status indicator on top of the filled square.
    if (indicator != StatusIndicator.none) {
      final w = size.width - inset * 2;
      final h = size.height - inset * 2;
      final indicatorPaint = Paint()
        ..color = indicatorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = indicatorStrokeWidth
        ..strokeCap = StrokeCap.round;

      if (indicator == StatusIndicator.check) {
        final check = Path()
          ..moveTo(w * 0.2, h * 0.5)
          ..lineTo(w * 0.4, h * 0.72)
          ..lineTo(w * 0.8, h * 0.25);
        canvas.drawPath(check, indicatorPaint);
      } else if (indicator == StatusIndicator.dash) {
        canvas.drawLine(
          Offset(w * 0.2, h * 0.5),
          Offset(w * 0.8, h * 0.5),
          indicatorPaint,
        );
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _StatusSquarePainter old) =>
      color != old.color ||
      isFilled != old.isFilled ||
      indicator != old.indicator ||
      indicatorColor != old.indicatorColor ||
      seed != old.seed ||
      irregularity != old.irregularity ||
      segments != old.segments ||
      strokeWidth != old.strokeWidth ||
      indicatorStrokeWidth != old.indicatorStrokeWidth;
}
