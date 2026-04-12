import 'package:flutter/material.dart';

import 'hand_drawn_toolkit_defaults.dart';
import 'hand_drawn_toolkit_helpers.dart';

/// Draws hand-drawn horizontal ruled lines at [lineHeight] intervals behind
/// child content, mimicking notebook paper.
///
/// For a [Text] widget with `style: TextStyle(fontSize: f, height: h)`,
/// pass `f * h` as [lineHeight] and the lines will align with text
/// baselines.
///
/// ```dart
/// HandDrawnNotebook(
///   lineHeight: 28.0,
///   lineColor: Colors.grey.shade300,
///   child: Text(
///     'Dear diary…',
///     style: TextStyle(fontSize: 16, height: 28.0 / 16),
///   ),
/// )
/// ```
///
/// ## Uniform vs unique lines
///
/// By default every ruled line uses the same [seed] and looks identical
/// ([uniformLines] = true). Set [uniformLines] to false to give each line
/// its own wobble pattern: line *n* (zero-indexed) uses `seed + n`, so the
/// result is unique per line but still deterministic for a given [seed].
///
/// ## Deterministic rendering
///
/// The line shapes are fully determined by [seed], [segments], and
/// [irregularity]. Identical parameters always produce the same ruled
/// lines, so the page won't shift during rebuilds or animations.
class HandDrawnNotebook extends StatelessWidget {
  /// Creates a notebook-paper background with hand-drawn ruled lines.
  const HandDrawnNotebook({
    required this.child,
    required this.lineHeight,
    this.lineColor = HandDrawnDefaults.notebookLineColor,
    this.strokeWidth = HandDrawnDefaults.notebookStrokeWidth,
    this.seed = HandDrawnDefaults.seed,
    this.uniformLines = true,
    this.irregularity = HandDrawnDefaults.notebookIrregularity,
    this.segments = HandDrawnDefaults.notebookSegments,
    super.key,
  }) : assert(lineHeight > 0, 'lineHeight must be positive');

  /// The content displayed on top of the ruled lines.
  final Widget child;

  /// Pixel height of one grid row. Must equal the wrapped text's
  /// `fontSize * TextStyle.height` for lines to align.
  final double lineHeight;

  /// The color of the ruled lines.
  final Color lineColor;

  /// The width of each ruled line stroke in logical pixels.
  final double strokeWidth;

  /// The base random seed for deterministic line generation.
  ///
  /// When [uniformLines] is true, every line uses this seed. When false,
  /// line *n* (zero-indexed) uses `seed + n`.
  final int seed;

  /// Whether every ruled line should look identical.
  ///
  /// When true, all lines share the same wobble pattern. When false, each
  /// line gets a unique pattern derived from [seed].
  final bool uniformLines;

  /// The roughness of the hand-drawn wobble on each ruled line.
  final double irregularity;

  /// The number of linear segments used to draw each ruled line.
  final int segments;

  @override
  Widget build(BuildContext context) {
    // Bottom padding extends the canvas past the last line so it is not
    // clipped at the widget edge.
    return CustomPaint(
      painter: _HandDrawnNotebookLinesPainter(
        lineHeight: lineHeight,
        lineColor: lineColor,
        strokeWidth: strokeWidth,
        seed: seed,
        uniformLines: uniformLines,
        irregularity: irregularity,
        segments: segments,
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: strokeWidth),
        child: SizedBox(width: double.infinity, child: child),
      ),
    );
  }
}

class _HandDrawnNotebookLinesPainter extends CustomPainter {
  _HandDrawnNotebookLinesPainter({
    required this.lineHeight,
    required this.lineColor,
    required this.strokeWidth,
    required this.seed,
    required this.uniformLines,
    required this.irregularity,
    required this.segments,
  }) {
    if (lineHeight <= 0) {
      throw ArgumentError.value(lineHeight, 'lineHeight', 'must be positive');
    }
  }

  final double lineHeight;
  final Color lineColor;
  final double strokeWidth;
  final int seed;
  final bool uniformLines;
  final double irregularity;
  final int segments;

  // ── Path caching ─────────────────────────────────────────────────────────

  List<Path>? _cachedPaths;
  Size? _lastSize;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height < 1) return;

    final paint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Use round() so that a single-line text whose rendered height is
    // very close to (but not exactly equal to) lineHeight still gets
    // its ruled line.
    final int lineCount = (size.height / lineHeight).round();
    if (lineCount < 1) return;

    if (_cachedPaths == null || _lastSize != size) {
      _buildPaths(size, lineCount);
      _lastSize = size;
    }

    // The line size uses height 0 so the path wobbles around y=0.
    // Canvas translation positions each line at its correct row.
    final paths = _cachedPaths!;
    for (int i = 0; i < lineCount; i++) {
      final y = (i + 1) * lineHeight;
      canvas.save();
      canvas.translate(0, y);
      canvas.drawPath(paths[uniformLines ? 0 : i], paint);
      canvas.restore();
    }
  }

  void _buildPaths(Size size, int lineCount) {
    final lineSize = Size(size.width, 0);

    if (uniformLines) {
      final helpers = HandDrawnHelpers(
        seed: seed,
        irregularity: irregularity,
        segments: segments,
      );
      _cachedPaths = [helpers.lineHorizontal(lineSize)];
    } else {
      _cachedPaths = List.generate(lineCount, (i) {
        final helpers = HandDrawnHelpers(
          seed: seed + i,
          irregularity: irregularity,
          segments: segments,
        );
        return helpers.lineHorizontal(lineSize);
      });
    }
  }

  @override
  bool shouldRepaint(covariant _HandDrawnNotebookLinesPainter old) {
    final paramsChanged =
        lineHeight != old.lineHeight ||
        lineColor != old.lineColor ||
        strokeWidth != old.strokeWidth ||
        seed != old.seed ||
        uniformLines != old.uniformLines ||
        irregularity != old.irregularity ||
        segments != old.segments;
    if (paramsChanged) {
      _cachedPaths = null;
    }
    return paramsChanged;
  }
}
