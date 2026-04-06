import 'package:flutter/material.dart';

// ── Single-row container ────────────────────────────────────────────────────

/// A container that occupies exactly [rowSpan] notebook rows.
///
/// Use this for any element that must sit on the notebook grid:
/// task titles, label chips, status tags, control rows, checklist items, etc.
///
/// The child is vertically centered within the allocated row space by default.
///
/// ```dart
/// NotebookRow(
///   lineHeight: 28.0,
///   child: Text('Buy groceries'),
/// )
/// ```
class NotebookRow extends StatelessWidget {
  /// Creates a fixed-height container snapped to the notebook grid.
  const NotebookRow({
    required this.child,
    required this.lineHeight,
    this.rowSpan = 1,
    this.padding,
    super.key,
  }) : assert(lineHeight > 0, 'lineHeight must be positive'),
       assert(rowSpan > 0, 'rowSpan must be positive');

  /// The content to place inside the row.
  final Widget child;

  /// Pixel height of one notebook row.
  final double lineHeight;

  /// How many notebook rows this element occupies. Defaults to 1.
  final int rowSpan;

  /// Optional horizontal padding (vertical padding is not allowed because
  /// it would break the row height contract).
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    assert(
      padding == null ||
          padding is! EdgeInsets ||
          ((padding! as EdgeInsets).top == 0 &&
              (padding! as EdgeInsets).bottom == 0),
      'NotebookRow padding must be horizontal-only to preserve the row '
      'height contract',
    );
    Widget content = SizedBox(
      height: lineHeight * rowSpan,
      child: Align(alignment: Alignment.centerLeft, child: child),
    );
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return content;
  }
}

// ── Multi-row snapped block ─────────────────────────────────────────────────

/// Wraps dynamic-height content (e.g. multiline text, editors) and ensures
/// its total height is at least [minRows] notebook rows.
///
/// **Why this works without runtime height snapping:**
/// All notebook text content uses `TextStyle(height: notebookLineHeight / fontSize)`,
/// which makes each rendered text line exactly one notebook row.
/// A multiline `Text` or `TextField` with this style therefore always
/// produces a height that is already a whole-row multiple.
///
/// This widget enforces the minimum-row contract and serves as a clear
/// semantic marker in the widget tree — "this block lives on the notebook
/// grid." If a future content type breaks the text-height assumption,
/// measurement-based snapping can be added here without changing callers.
///
/// ```dart
/// NotebookSnappedBlock(
///   lineHeight: 28.0,
///   minRows: 3,
///   child: TextField(maxLines: null),
/// )
/// ```
class NotebookSnappedBlock extends StatelessWidget {
  /// Creates a dynamic-height container with a minimum row count constraint.
  const NotebookSnappedBlock({
    required this.child,
    required this.lineHeight,
    this.minRows = 1,
    this.padding,
    super.key,
  }) : assert(lineHeight > 0, 'lineHeight must be positive'),
       assert(minRows > 0, 'minRows must be positive');

  /// The dynamic-height content to wrap.
  final Widget child;

  /// Pixel height of one notebook row.
  final double lineHeight;

  /// Minimum number of rows this block should occupy, even if the content
  /// is shorter. Defaults to 1.
  final int minRows;

  /// Optional horizontal padding applied inside the constrained height.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    assert(
      padding == null ||
          padding is! EdgeInsets ||
          ((padding! as EdgeInsets).top == 0 &&
              (padding! as EdgeInsets).bottom == 0),
      'NotebookSnappedBlock padding must be horizontal-only to preserve the '
      'row height contract',
    );
    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: lineHeight * minRows),
      child: content,
    );
  }
}

// ── Helpers ─────────────────────────────────────────────────────────────────

/// Snaps [height] up to the nearest multiple of [rowHeight].
///
/// ```dart
/// snapHeightToRows(33.0, 32.0); // → 64.0  (2 rows)
/// snapHeightToRows(64.0, 32.0); // → 64.0  (exact)
/// snapHeightToRows(0.0, 32.0);  // → 0.0
/// ```
double snapHeightToRows(double height, double rowHeight) {
  if (rowHeight <= 0) {
    throw ArgumentError.value(rowHeight, 'rowHeight', 'must be positive');
  }
  if (height <= 0) return 0;
  return (height / rowHeight).ceil() * rowHeight;
}

/// Returns the number of whole notebook rows needed to contain [height].
int rowsForHeight(double height, double rowHeight) {
  if (rowHeight <= 0) {
    throw ArgumentError.value(rowHeight, 'rowHeight', 'must be positive');
  }
  if (height <= 0) return 0;
  return (height / rowHeight).ceil();
}
