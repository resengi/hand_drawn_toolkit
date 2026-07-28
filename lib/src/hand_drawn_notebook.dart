import 'package:flutter/widgets.dart';

import 'hand_drawn_toolkit_defaults.dart';
import 'notebook_style.dart';

/// Notebook paper: a colored page that publishes a [NotebookStyle] to the
/// notebook content placed on it.
///
/// [HandDrawnNotebook] does two things. It fills its area with [paperColor]
/// (pass null for no fill), and it publishes a [NotebookStyle] — assembled from
/// the ruling and margin parameters below — to its descendants through a
/// [NotebookScope]. The page itself draws no rules; content reads the
/// published style and paints its own.
///
/// Set the ruling and margins once here and they apply to every descendant
/// that reads them:
///
/// ```dart
/// HandDrawnNotebook(
///   lineHeight: 32,
///   lineColor: Color(0xFFBDBDBD),
///   leadingMargin: 24,
///   child: myNotebookContent,
/// )
/// ```
///
/// The page sizes itself to [child]. To cover a larger region, size the
/// notebook (for example with a surrounding [SizedBox] or by giving [child] a
/// size).
class HandDrawnNotebook extends StatelessWidget {
  /// Creates notebook paper that publishes a [NotebookStyle] to [child].
  const HandDrawnNotebook({
    required this.child,
    this.lineHeight = HandDrawnDefaults.notebookLineHeight,
    this.lineColor = HandDrawnDefaults.notebookLineColor,
    this.strokeWidth = HandDrawnDefaults.notebookStrokeWidth,
    this.seed = HandDrawnDefaults.seed,
    this.uniformLines = true,
    this.irregularity = HandDrawnDefaults.notebookIrregularity,
    this.segments = HandDrawnDefaults.notebookSegments,
    this.leadingMargin = HandDrawnDefaults.notebookLeadingMargin,
    this.trailingMargin = HandDrawnDefaults.notebookTrailingMargin,
    this.paperColor = const Color(0xFFFCFAF5),
    super.key,
  }) : assert(lineHeight > 0, 'lineHeight must be positive'),
       assert(strokeWidth > 0, 'strokeWidth must be positive'),
       assert(segments > 0, 'segments must be positive'),
       assert(irregularity >= 0, 'irregularity must be non-negative'),
       assert(
         leadingMargin >= 0 && leadingMargin < double.infinity,
         'leadingMargin must be non-negative and finite',
       ),
       assert(
         trailingMargin >= 0 && trailingMargin < double.infinity,
         'trailingMargin must be non-negative and finite',
       );

  /// The content placed on the page.
  final Widget child;

  /// The row height (rule spacing) published to descendants.
  final double lineHeight;

  /// The color of the ruled lines published to descendants.
  final Color lineColor;

  /// The width of each ruled line stroke in logical pixels.
  final double strokeWidth;

  /// The base random seed for deterministic line generation.
  final int seed;

  /// Whether every ruled line should look identical. When false, the line at
  /// row index *n* uses `seed + n`.
  final bool uniformLines;

  /// The roughness of the hand-drawn wobble on each ruled line.
  final double irregularity;

  /// The number of linear segments used to draw each ruled line.
  final int segments;

  /// The leading content margin published to descendants, in logical pixels.
  ///
  /// Content on the page begins this far in from the leading edge; the ruled
  /// lines are unaffected and span the full width beneath the margin.
  final double leadingMargin;

  /// The trailing content margin published to descendants, in logical pixels.
  ///
  /// Content on the page wraps before crossing this margin; the ruled lines
  /// are unaffected and span the full width beneath it.
  final double trailingMargin;

  /// The paper fill color. When null, no paper is painted.
  final Color? paperColor;

  @override
  Widget build(BuildContext context) {
    final style = NotebookStyle(
      lineHeight: lineHeight,
      lineColor: lineColor,
      strokeWidth: strokeWidth,
      seed: seed,
      uniformLines: uniformLines,
      irregularity: irregularity,
      segments: segments,
      leadingMargin: leadingMargin,
      trailingMargin: trailingMargin,
    );

    Widget result = NotebookScope(style: style, child: child);

    final paperColor = this.paperColor;
    if (paperColor != null) {
      result = ColoredBox(color: paperColor, child: result);
    }

    return result;
  }
}
