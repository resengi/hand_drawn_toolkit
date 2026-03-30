/// Default values used throughout the hand_drawn_toolkit package.
///
/// These constants provide sensible starting points for the painter and widget
/// parameters. Override them per-widget to fine-tune the hand-drawn aesthetic.
library;

/// Default configuration values for hand-drawn rendering.
abstract final class HandDrawnDefaults {
  // ── Stroke appearance ────────────────────────────────────────────────────

  /// Default stroke width in logical pixels.
  static const double strokeWidth = 2.0;

  /// Default stroke color opacity when used with [HandDrawnContainer.borderOpacity].
  static const double borderOpacity = 1.0;

  // ── Path generation ──────────────────────────────────────────────────────

  /// Controls the magnitude of random offset applied to each path segment
  /// point. Higher values produce a rougher, more hand-drawn look. Lower
  /// values approach a straight line.
  ///
  /// Typical range: 0.5 (subtle wobble) – 6.0 (very rough sketch).
  static const double irregularity = 3.5;

  /// The number of linear segments used to approximate each edge of a shape.
  /// More segments produce smoother jitter; fewer segments create a chunkier
  /// feel.
  static const int segments = 24;

  /// The default random seed. Using a fixed seed guarantees the same jitter
  /// pattern on every rebuild so the shape doesn't "dance" during animations
  /// or hot-reloads.
  static const int seed = 42;

  // ── Container defaults ─────────────────────────────────────────────────

  /// Default inner padding for [HandDrawnContainer].
  static const double containerPadding = 20.0;

  // ── Divider defaults ───────────────────────────────────────────────────

  /// Default thickness for [HandDrawnDivider].
  static const double dividerThickness = 1.5;

  /// Default irregularity for [HandDrawnDivider] (subtler than borders).
  static const double dividerIrregularity = 1.0;

  /// Default segment count for [HandDrawnDivider].
  static const int dividerSegments = 30;

  // ── StatusSquare defaults ──────────────────────────────────────────────

  /// Default side length for [HandDrawnStatusSquare] in logical pixels.
  static const double statusSquareSize = 14.0;

  /// Default border stroke width for [HandDrawnStatusSquare].
  static const double statusSquareStrokeWidth = 1.5;

  /// Default stroke width for the check / dash indicator drawn on top of
  /// the filled square.
  static const double statusSquareIndicatorStrokeWidth = 2.0;

  /// Default padding around the painted square that enlarges the tap target
  /// when [HandDrawnStatusSquare.onTap] is non-null.
  static const double statusSquareTapPadding = 6.0;

  /// Default irregularity for [HandDrawnStatusSquare]. Subtler than the
  /// container default because the square is small.
  static const double statusSquareIrregularity = 1.0;

  /// Default segment count for [HandDrawnStatusSquare]. Fewer segments than
  /// the container default for a chunkier feel at small sizes.
  static const int statusSquareSegments = 6;

  // ── TextField defaults ─────────────────────────────────────────────────

  /// Default font size for [HandDrawnTextField] when no custom [TextStyle]
  /// is provided.
  static const double textFieldFontSize = 16.0;

  /// Default corner radius of the [HandDrawnTextField] background container.
  static const double textFieldBorderRadius = 8.0;

  /// Default thickness of the [HandDrawnDivider] underline inside
  /// [HandDrawnTextField].
  static const double textFieldDividerThickness = 1.0;

  // ── Notebook defaults ──────────────────────────────────────────────────

  /// Default stroke width for [HandDrawnNotebook] ruled lines.
  static const double notebookStrokeWidth = 1.0;

  /// Default irregularity for [HandDrawnNotebook] ruled lines. Subtle
  /// wobble appropriate for full-width horizontal strokes.
  static const double notebookIrregularity = 1.0;

  /// Default segment count for [HandDrawnNotebook] ruled lines.
  static const int notebookSegments = 30;
}
