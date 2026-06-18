import 'package:flutter/widgets.dart';

import 'hand_drawn_toolkit_defaults.dart';

/// An immutable description of notebook ruling: how the hand-drawn rules look
/// and how far apart they sit.
///
/// A [NotebookStyle] carries ruling values only. It performs no painting,
/// layout, or widget building — it exists to bundle these values, validate
/// them, and support comparison and overriding via [copyWith] and value
/// equality.
///
/// [lineHeight] is the row height: the vertical distance from one rule to the
/// next, and the unit content is laid onto. Every other property describes the
/// appearance of the hand-drawn rules.
///
/// ```dart
/// const style = NotebookStyle(lineHeight: 32, lineColor: Color(0xFFBDBDBD));
/// final bolder = style.copyWith(strokeWidth: 2.0);
/// ```
@immutable
class NotebookStyle {
  /// Creates a notebook ruling style.
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
  }) : assert(lineHeight > 0, 'lineHeight must be positive'),
       assert(strokeWidth > 0, 'strokeWidth must be positive'),
       assert(segments > 0, 'segments must be positive'),
       assert(irregularity >= 0, 'irregularity must be non-negative');

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

  /// Returns a copy of this style with the given fields replaced.
  NotebookStyle copyWith({
    double? lineHeight,
    Color? lineColor,
    double? strokeWidth,
    int? seed,
    bool? uniformLines,
    double? irregularity,
    int? segments,
  }) {
    return NotebookStyle(
      lineHeight: lineHeight ?? this.lineHeight,
      lineColor: lineColor ?? this.lineColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      seed: seed ?? this.seed,
      uniformLines: uniformLines ?? this.uniformLines,
      irregularity: irregularity ?? this.irregularity,
      segments: segments ?? this.segments,
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
        other.segments == segments;
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
  );
}

/// Publishes a [NotebookStyle] to descendant widgets.
///
/// Descendants read the nearest enclosing style with [maybeOf] or [of], so they
/// can resolve ruling without being passed a style explicitly. The scope holds
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
