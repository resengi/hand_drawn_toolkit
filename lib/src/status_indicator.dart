/// The indicator drawn over a [HandDrawnStatusSquare].
///
/// Consumers map their own domain-specific status type to one of these
/// values at the call site:
///
/// ```dart
/// StatusIndicator indicatorFor(MyStatus status) => switch (status) {
///   MyStatus.done    => StatusIndicator.check,
///   MyStatus.skipped => StatusIndicator.dash,
///   _                => StatusIndicator.none,
/// };
/// ```
enum StatusIndicator {
  /// No indicator — only the outline (and optional fill) is shown.
  none,

  /// A small checkmark drawn over the square.
  check,

  /// A horizontal dash drawn over the square.
  dash,
}
