import 'package:flutter/widgets.dart';

import 'hand_drawn_toolkit_defaults.dart';

/// An immutable description of notebook ruling and margins: how the
/// hand-drawn rules look, how far apart they sit, and where content may be
/// written between the page edges.
///
/// A [NotebookStyle] carries these values only. It performs no painting,
/// layout, or widget building — it exists to bundle the values, validate
/// them, and support comparison and overriding via [copyWith] and value
/// equality.
///
/// [lineHeight] is the row height: the vertical distance from one rule to the
/// next, and the unit content is laid onto. [leadingMargin] and
/// [trailingMargin] bound where content is written on each row; the rules are
/// unaffected by them and span the full width beneath. Every other property
/// describes the appearance of the hand-drawn rules.
///
/// ```dart
/// const style = NotebookStyle(lineHeight: 32, leadingMargin: 24);
/// final bolder = style.copyWith(strokeWidth: 2.0);
/// ```
@immutable
class NotebookStyle {
  /// Creates a notebook style.
  ///
  /// All properties have defaults, so `const NotebookStyle()` is a valid,
  /// fully-specified style.
  const NotebookStyle({
    this.lineHeight = HandDrawnDefaults.notebookLineHeight,
    this.lineColor = HandDrawnDefaults.notebookLineColor,
    this.strokeWidth = HandDrawnDefaults.notebookStrokeWidth,
    this.seed = HandDrawnDefaults.seed,
    this.uniformLines = true,
    this.irregularity = HandDrawnDefaults.notebookIrregularity,
    this.segments = HandDrawnDefaults.notebookSegments,
    this.leadingMargin = HandDrawnDefaults.notebookLeadingMargin,
    this.trailingMargin = HandDrawnDefaults.notebookTrailingMargin,
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

  /// The row height: the vertical distance between consecutive rules, in
  /// logical pixels.
  final double lineHeight;

  /// The color of the ruled lines.
  final Color lineColor;

  /// The width of each ruled line stroke in logical pixels.
  final double strokeWidth;

  /// The base random seed for deterministic line generation.
  ///
  /// When [uniformLines] is true, every line uses this seed. When false, the
  /// line at row index *n* uses `seed + n`.
  final int seed;

  /// Whether every ruled line should look identical.
  ///
  /// When true, all lines share the same wobble pattern. When false, each line
  /// gets a unique pattern derived from [seed].
  final bool uniformLines;

  /// The roughness of the hand-drawn wobble on each ruled line.
  final double irregularity;

  /// The number of linear segments used to draw each ruled line.
  final int segments;

  /// The distance from the leading edge at which content begins, in logical
  /// pixels.
  ///
  /// Content on every row starts at this offset (an entry's indent is added
  /// on top of it), while the rules span the full width beneath the margin.
  /// Direction-aware: under a right-to-left text direction the leading edge
  /// is the right edge.
  final double leadingMargin;

  /// The distance from the trailing edge before which content wraps, in
  /// logical pixels.
  ///
  /// Content wraps rather than crossing this margin, while the rules span the
  /// full width beneath it. It has no effect on an entry laid out on a single
  /// line (`wrap: false`), where nothing wraps. Direction-aware: under a
  /// right-to-left text direction the trailing edge is the left edge.
  final double trailingMargin;

  /// Returns a copy of this style with the given fields replaced.
  NotebookStyle copyWith({
    double? lineHeight,
    Color? lineColor,
    double? strokeWidth,
    int? seed,
    bool? uniformLines,
    double? irregularity,
    int? segments,
    double? leadingMargin,
    double? trailingMargin,
  }) {
    return NotebookStyle(
      lineHeight: lineHeight ?? this.lineHeight,
      lineColor: lineColor ?? this.lineColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      seed: seed ?? this.seed,
      uniformLines: uniformLines ?? this.uniformLines,
      irregularity: irregularity ?? this.irregularity,
      segments: segments ?? this.segments,
      leadingMargin: leadingMargin ?? this.leadingMargin,
      trailingMargin: trailingMargin ?? this.trailingMargin,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotebookStyle &&
        other.lineHeight == lineHeight &&
        other.lineColor == lineColor &&
        other.strokeWidth == strokeWidth &&
        other.seed == seed &&
        other.uniformLines == uniformLines &&
        other.irregularity == irregularity &&
        other.segments == segments &&
        other.leadingMargin == leadingMargin &&
        other.trailingMargin == trailingMargin;
  }

  @override
  int get hashCode => Object.hash(
    lineHeight,
    lineColor,
    strokeWidth,
    seed,
    uniformLines,
    irregularity,
    segments,
    leadingMargin,
    trailingMargin,
  );
}

/// Publishes a [NotebookStyle] to descendant widgets.
///
/// Descendants read the nearest enclosing style with [maybeOf] or [of], so they
/// can resolve the style without being passed one explicitly. The scope holds
/// a single [NotebookStyle] and notifies dependents when that style changes by
/// value.
class NotebookScope extends InheritedWidget {
  /// Creates a scope that publishes [style] to [child] and its descendants.
  const NotebookScope({required this.style, required super.child, super.key});

  /// The style published to descendants.
  final NotebookStyle style;

  /// Returns the nearest enclosing [NotebookStyle], or null if there is none.
  static NotebookStyle? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NotebookScope>()?.style;
  }

  /// Returns the nearest enclosing [NotebookStyle].
  ///
  /// Throws a [FlutterError] if no [NotebookScope] is found in [context]. Use
  /// [maybeOf] when the absence of a scope is acceptable.
  static NotebookStyle of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<NotebookScope>();
    if (scope == null) {
      throw FlutterError(
        'NotebookScope.of() was called with a context that does not contain a '
        'NotebookScope.\n'
        'No NotebookScope ancestor could be found starting from the context '
        'that was passed to NotebookScope.of().',
      );
    }
    return scope.style;
  }

  @override
  bool updateShouldNotify(NotebookScope oldWidget) => style != oldWidget.style;
}
