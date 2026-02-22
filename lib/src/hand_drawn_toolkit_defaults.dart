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

  // ── Widget defaults ──────────────────────────────────────────────────────

  /// Default inner padding for [HandDrawnContainer].
  static const double containerPadding = 20.0;

  /// Default thickness for [HandDrawnDivider].
  static const double dividerThickness = 1.5;

  /// Default irregularity for [HandDrawnDivider] (subtler than borders).
  static const double dividerIrregularity = 1.0;

  /// Default segment count for [HandDrawnDivider].
  static const int dividerSegments = 30;
}
