import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'hand_drawn_toolkit_helpers.dart';
import 'notebook_style.dart';

/// Sub-pixel slack used when deciding whether content fits the remaining
/// width on a row. Keeps rounding noise from forcing a spurious wrap.
const double _kWidthTolerance = 0.5;

/// Slack used when checking the content-driven height against the incoming
/// height constraint, in logical pixels.
const double _kHeightTolerance = 0.01;

/// The default for [NotebookEntry.scaleDownContentFraction]: the fraction of a
/// row's height that a scaled-down *widget* may occupy. Fitting an oversized
/// widget to this fraction (rather than the full row) leaves a little space
/// above and below it, so a box-filling widget reads as smaller instead of
/// touching both rules. Text is exempt — its line metrics already include
/// leading.
const double _kScaleDownContentFraction = 0.8;

/// Splits a line's height leading evenly above and below the text so glyphs sit
/// centered in their line box. Flutter's default proportional distribution
/// parks glyphs low in a tall line box (e.g. one inflated by a large `height`
/// multiplier); centering them keeps inline widgets — which are centered on
/// their own box — aligned to the visible text rather than to the line box.
const TextHeightBehavior _kEvenLeading = TextHeightBehavior(
  leadingDistribution: TextLeadingDistribution.even,
);

/// How a [NotebookEntry] fits a piece of content that is taller than one row.
///
/// Applied per piece: one piece's handling never affects another's. Width never
/// triggers either mode — an over-wide widget is clipped horizontally instead.
enum NotebookFit {
  /// Keep the content at its natural size; the row clips whatever crosses its
  /// rule. This is the only mode in which vertical clipping happens.
  clip,

  /// Shrink an oversized piece uniformly until it fits one row, never
  /// enlarging it. The factor comes from height alone. A widget is scaled to
  /// leave a little space above and below it within the row, so a box-filling
  /// widget reads as smaller rather than touching both rules; text is scaled to
  /// the full row height, since its own line metrics already provide that
  /// breathing room. Because the piece is scaled to fit, nothing is clipped
  /// vertically.
  scaleDown,
}

/// A run of text with an optional style, for use inside [NotebookEntry.children].
///
/// Pass a [NotebookSpan] when a stretch of text needs a style different from the
/// ambient [DefaultTextStyle]. The [style] is layered over the ambient style
/// (it overrides only the fields it sets); fields it leaves unset are inherited.
/// A plain `String` in the children list is equivalent to a [NotebookSpan] with
/// no [style]. Embedded newlines split the text into runs separated by hard
/// breaks, exactly like a plain string.
@immutable
class NotebookSpan {
  /// Creates a styled text run carrying [text] and an optional [style].
  const NotebookSpan(this.text, {this.style});

  /// The text of this run.
  final String text;

  /// The style layered over the ambient [DefaultTextStyle], or null to use the
  /// ambient style unchanged.
  final TextStyle? style;

  @override
  bool operator ==(Object other) =>
      other is NotebookSpan && other.text == text && other.style == style;

  @override
  int get hashCode => Object.hash(text, style);
}

// ── Internal content pieces (not exported) ──────────────────────────────────

/// One normalized unit of content: a text run, a hard break, or a widget.
sealed class _Piece {
  const _Piece();
}

/// A run of text to lay out and paint, carrying an optional layered style.
class _TextPiece extends _Piece {
  const _TextPiece(this.text, this.style);

  final String text;
  final TextStyle? style;

  @override
  bool operator ==(Object other) =>
      other is _TextPiece && other.text == text && other.style == style;

  @override
  int get hashCode => Object.hash(text, style);
}

/// A hard line break: the next piece starts on a new row.
class _BreakPiece extends _Piece {
  const _BreakPiece();

  @override
  bool operator ==(Object other) => other is _BreakPiece;

  @override
  int get hashCode => runtimeType.hashCode;
}

/// A widget piece, referencing its child by index into the widget list.
class _WidgetPiece extends _Piece {
  const _WidgetPiece(this.childIndex);

  final int childIndex;

  @override
  bool operator ==(Object other) =>
      other is _WidgetPiece && other.childIndex == childIndex;

  @override
  int get hashCode => childIndex.hashCode;
}

/// The result of normalizing a [NotebookEntry.children] list: a flat sequence of
/// pieces plus the real widgets, in order.
class _NotebookContent {
  /// Normalizes [children] in a single pass.
  ///
  /// `String` and [NotebookSpan] become text runs (splitting on `'\n'` into
  /// runs separated by hard breaks); a `Widget` becomes a widget piece; `''`
  /// is a no-op; any other type throws.
  factory _NotebookContent.parse(List<Object> children) {
    final pieces = <_Piece>[];
    final widgets = <Widget>[];

    void appendText(String text, TextStyle? style) {
      final segments = text.split('\n');
      for (var i = 0; i < segments.length; i++) {
        if (i > 0) pieces.add(const _BreakPiece());
        final segment = segments[i];
        if (segment.isNotEmpty) pieces.add(_TextPiece(segment, style));
      }
    }

    for (final child in children) {
      if (child is String) {
        if (child.isEmpty) continue;
        appendText(child, null);
      } else if (child is NotebookSpan) {
        if (child.text.isEmpty) continue;
        appendText(child.text, child.style);
      } else if (child is Widget) {
        pieces.add(_WidgetPiece(widgets.length));
        widgets.add(child);
      } else {
        throw ArgumentError(
          'NotebookEntry children must be String, NotebookSpan, or Widget; '
          'got ${child.runtimeType}.',
        );
      }
    }

    return _NotebookContent(pieces, widgets);
  }
  _NotebookContent(this.pieces, this.widgets);

  final List<_Piece> pieces;
  final List<Widget> widgets;
}

/// A single self-contained card on ruled notebook paper.
///
/// Give it one flowing run of mixed content — plain text, styled [NotebookSpan]s,
/// and widgets — as [children]. It lays that content onto ruled **rows** of a
/// fixed height (the ruling's `lineHeight`), paints its own rules, and is
/// exactly as tall as the content requires.
///
/// The number of rows emerges from the content: text wraps to the available
/// width and continues on the next row; a `'\n'` (or an embedded newline)
/// starts a new row; widgets stay whole and move to the next row when they no
/// longer fit. The entry's height is its row count times the line height, and
/// [minRows] floors that count with empty ruled rows. The consumer never
/// supplies a height; the entry sizes itself to the rows it creates, and a
/// forced external height is unsupported.
///
/// Ruling (line height, color, wobble) comes from a [NotebookStyle], resolved
/// from the explicit [style], else an enclosing [NotebookScope], else
/// `const NotebookStyle()`. Plain text takes its base style from the ambient
/// [DefaultTextStyle].
///
/// ```dart
/// HandDrawnNotebook(
///   child: NotebookEntry(
///     children: [
///       HandDrawnStatusSquare(color: Colors.green),
///       ' Buy eggs, milk, and a very long list of groceries',
///     ],
///   ),
/// )
/// ```
///
/// Content that is taller than a row is handled per [fit]; the assembled line
/// is placed within its row by [textAlignVertical]. Flow direction comes from
/// [direction] (else the ambient [Directionality]). Set [wrap] to false to lay
/// the content on a single horizontal line for a horizontal scroll view.
///
/// Widget children must be self-sizing: they are laid out with unbounded
/// constraints, so wrap a width- or height-hungry widget (one that expands to
/// fill its parent) in a [SizedBox] or [ConstrainedBox].
class NotebookEntry extends MultiChildRenderObjectWidget {
  /// Creates a notebook entry from a run of mixed [children].
  ///
  /// Each element must be a `String`, a [NotebookSpan], or a `Widget`; any other
  /// type throws an [ArgumentError]. [minRows] must be at least 1.
  factory NotebookEntry({
    required List<Object> children,
    Key? key,
    NotebookStyle? style,
    NotebookFit fit = NotebookFit.scaleDown,
    double scaleDownContentFraction = _kScaleDownContentFraction,
    TextAlignVertical textAlignVertical = TextAlignVertical.center,
    int minRows = 1,
    bool wrap = true,
    TextDirection? direction,
  }) {
    assert(
      scaleDownContentFraction > 0 && scaleDownContentFraction <= 1,
      'scaleDownContentFraction must be in the range (0, 1].',
    );
    final content = _NotebookContent.parse(children);
    return NotebookEntry._(
      key: key,
      pieces: content.pieces,
      style: style,
      fit: fit,
      scaleDownContentFraction: scaleDownContentFraction,
      textAlignVertical: textAlignVertical,
      minRows: minRows,
      wrap: wrap,
      direction: direction,
      children: content.widgets,
    );
  }

  const NotebookEntry._({
    required List<_Piece> pieces,
    required this.style,
    required this.fit,
    required this.scaleDownContentFraction,
    required this.textAlignVertical,
    required this.minRows,
    required this.wrap,
    required this.direction,
    required super.children,
    super.key,
  }) : _pieces = pieces,
       assert(minRows >= 1, 'minRows must be at least 1');

  final List<_Piece> _pieces;

  /// The ruling style, or null to resolve from an enclosing [NotebookScope]
  /// (else `const NotebookStyle()`).
  final NotebookStyle? style;

  /// How content taller than one row is handled.
  final NotebookFit fit;

  /// Under [NotebookFit.scaleDown], the fraction of the row height an oversized
  /// *widget* is shrunk to occupy, leaving a little margin above and below so it
  /// reads as smaller rather than touching both rules. Must be in `(0, 1]`;
  /// `1.0` fills the row edge to edge. Has no effect on text, or under
  /// [NotebookFit.clip].
  final double scaleDownContentFraction;

  /// Where the assembled line sits within its row.
  final TextAlignVertical textAlignVertical;

  /// The minimum number of rows; extra rows are empty but ruled.
  final int minRows;

  /// Whether content wraps to new rows at the available width (the default).
  ///
  /// Set to false to lay all content on a single horizontal line; hard breaks
  /// (`'\n'`) still start new rows. The entry is not itself scrollable — place
  /// it in a horizontal scroll view (e.g. `SingleChildScrollView`) to scroll the
  /// overflow. In this mode the entry is as wide as its content and its rules
  /// span that width.
  final bool wrap;

  /// The flow direction, or null to use the ambient [Directionality].
  final TextDirection? direction;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final resolved = _resolveStyle(context);
    return _RenderNotebookEntry(
      pieces: _pieces,
      baseTextStyle: DefaultTextStyle.of(context).style,
      textDirection: _resolveDirection(context),
      textScaler: MediaQuery.textScalerOf(context),
      fit: fit,
      scaleDownContentFraction: scaleDownContentFraction,
      textAlignVertical: textAlignVertical,
      minRows: minRows,
      wrap: wrap,
      lineHeight: resolved.lineHeight,
      lineColor: resolved.lineColor,
      strokeWidth: resolved.strokeWidth,
      seed: resolved.seed,
      uniformLines: resolved.uniformLines,
      irregularity: resolved.irregularity,
      segments: resolved.segments,
    );
  }

  @override
  void updateRenderObject(BuildContext context, RenderObject renderObject) {
    final entry = renderObject as _RenderNotebookEntry;
    final resolved = _resolveStyle(context);

    entry
      ..pieces = _pieces
      ..baseTextStyle = DefaultTextStyle.of(context).style
      ..textDirection = _resolveDirection(context)
      ..textScaler = MediaQuery.textScalerOf(context)
      ..fit = fit
      ..scaleDownContentFraction = scaleDownContentFraction
      ..textAlignVertical = textAlignVertical
      ..minRows = minRows
      ..wrap = wrap
      ..lineHeight = resolved.lineHeight
      ..lineColor = resolved.lineColor
      ..strokeWidth = resolved.strokeWidth
      ..seed = resolved.seed
      ..uniformLines = resolved.uniformLines
      ..irregularity = resolved.irregularity
      ..segments = resolved.segments;
  }

  NotebookStyle _resolveStyle(BuildContext context) =>
      style ?? NotebookScope.maybeOf(context) ?? const NotebookStyle();

  TextDirection _resolveDirection(BuildContext context) {
    final resolved = direction ?? Directionality.maybeOf(context);
    if (resolved == null) {
      throw FlutterError(
        'NotebookEntry has no text direction.\n'
        'Provide one explicitly (NotebookEntry(direction: ...)), or ensure '
        'there is an ambient Directionality above this entry (an app built '
        'with MaterialApp or WidgetsApp provides one).',
      );
    }
    return resolved;
  }
}

/// Parent data for the entry's widget children: their placed offset and the
/// scale applied to them under [NotebookFit.scaleDown].
class _NotebookEntryParentData extends ContainerBoxParentData<RenderBox> {
  double scale = 1.0;
}

/// One laid-out fragment: either a text line (with its painter) or a widget
/// child, placed on a row at a start-relative leading offset.
class _Fragment {
  _Fragment.text({
    required this.painter,
    required this.row,
    required this.leadingOffset,
    required this.width,
    required this.height,
  }) : child = null,
       scale = 1.0;

  _Fragment.widget({
    required this.child,
    required this.scale,
    required this.row,
    required this.leadingOffset,
    required this.width,
    required this.height,
  }) : painter = null;

  // Exactly one of [painter] (text) / [child] (widget) is non-null. [scale] is
  // 1.0 for text and unscaled widgets. [row] is the row index; [leadingOffset]
  // is the distance from the row's leading edge; [width]/[height] are effective
  // (already scaled for widgets); [localOffset] is the absolute top-left within
  // the render box, set during placement.
  final TextPainter? painter;
  final RenderBox? child;
  final double scale;
  final int row;
  final double leadingOffset;
  final double width;
  final double height;
  Offset localOffset = Offset.zero;
}

class _RenderNotebookEntry extends RenderBox
    with ContainerRenderObjectMixin<RenderBox, _NotebookEntryParentData> {
  _RenderNotebookEntry({
    required List<_Piece> pieces,
    required TextStyle baseTextStyle,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required NotebookFit fit,
    required double scaleDownContentFraction,
    required TextAlignVertical textAlignVertical,
    required int minRows,
    required bool wrap,
    required double lineHeight,
    required Color lineColor,
    required double strokeWidth,
    required int seed,
    required bool uniformLines,
    required double irregularity,
    required int segments,
  }) : _pieces = pieces,
       _baseTextStyle = baseTextStyle,
       _textDirection = textDirection,
       _textScaler = textScaler,
       _fit = fit,
       _scaleDownContentFraction = scaleDownContentFraction,
       _textAlignVertical = textAlignVertical,
       _minRows = minRows,
       _wrap = wrap,
       _lineHeight = lineHeight,
       _lineColor = lineColor,
       _strokeWidth = strokeWidth,
       _seed = seed,
       _uniformLines = uniformLines,
       _irregularity = irregularity,
       _segments = segments;

  // ── Layout-affecting inputs (a change relays out) ─────────────────────────

  List<_Piece> _pieces;
  set pieces(List<_Piece> value) {
    if (listEquals(value, _pieces)) return;
    _pieces = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  TextStyle _baseTextStyle;
  set baseTextStyle(TextStyle value) {
    if (value == _baseTextStyle) return;
    _baseTextStyle = value;
    markNeedsLayout();
  }

  TextDirection _textDirection;
  set textDirection(TextDirection value) {
    if (value == _textDirection) return;
    _textDirection = value;
    markNeedsLayout();
    markNeedsSemanticsUpdate();
  }

  TextScaler _textScaler;
  set textScaler(TextScaler value) {
    if (value == _textScaler) return;
    _textScaler = value;
    markNeedsLayout();
  }

  NotebookFit _fit;
  set fit(NotebookFit value) {
    if (value == _fit) return;
    _fit = value;
    markNeedsLayout();
  }

  double _scaleDownContentFraction;
  set scaleDownContentFraction(double value) {
    if (value == _scaleDownContentFraction) return;
    _scaleDownContentFraction = value;
    markNeedsLayout();
  }

  TextAlignVertical _textAlignVertical;
  set textAlignVertical(TextAlignVertical value) {
    if (value == _textAlignVertical) return;
    _textAlignVertical = value;
    markNeedsLayout();
  }

  int _minRows;
  set minRows(int value) {
    if (value == _minRows) return;
    _minRows = value;
    markNeedsLayout();
  }

  bool _wrap;
  set wrap(bool value) {
    if (value == _wrap) return;
    _wrap = value;
    markNeedsLayout();
  }

  double _lineHeight;
  set lineHeight(double value) {
    if (value == _lineHeight) return;
    _lineHeight = value;
    markNeedsLayout();
  }

  // ── Paint-only inputs (a change repaints, no relayout) ────────────────────

  Color _lineColor;
  set lineColor(Color value) {
    if (value == _lineColor) return;
    _lineColor = value;
    markNeedsPaint();
  }

  double _strokeWidth;
  set strokeWidth(double value) {
    if (value == _strokeWidth) return;
    _strokeWidth = value;
    markNeedsPaint();
  }

  int _seed;
  set seed(int value) {
    if (value == _seed) return;
    _seed = value;
    markNeedsPaint();
  }

  bool _uniformLines;
  set uniformLines(bool value) {
    if (value == _uniformLines) return;
    _uniformLines = value;
    markNeedsPaint();
  }

  double _irregularity;
  set irregularity(double value) {
    if (value == _irregularity) return;
    _irregularity = value;
    markNeedsPaint();
  }

  int _segments;
  set segments(int value) {
    if (value == _segments) return;
    _segments = value;
    markNeedsPaint();
  }

  // ── Layout state ──────────────────────────────────────────────────────────

  final List<_Fragment> _fragments = <_Fragment>[];
  int _rowCount = 0;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _NotebookEntryParentData) {
      child.parentData = _NotebookEntryParentData();
    }
  }

  void _disposeFragments() {
    for (final fragment in _fragments) {
      fragment.painter?.dispose();
    }
    _fragments.clear();
  }

  @override
  void dispose() {
    _disposeFragments();
    super.dispose();
  }

  @override
  void performLayout() {
    final constraints = this.constraints;

    if (_wrap && !constraints.hasBoundedWidth) {
      // Adopt a fallback size before reporting, so the misuse surfaces as one
      // clean error instead of cascading "no size" assertions in the parent,
      // paint, and semantics phases.
      size = constraints.constrain(Size.zero);
      throw FlutterError(
        'NotebookEntry was given unbounded width.\n'
        'A NotebookEntry wraps its content to a finite width, so it cannot sit '
        'directly in an unbounded horizontal space (such as a Row or a '
        'horizontal scroll view) without a width constraint. Constrain its '
        'width, or set wrap: false and place the entry in a horizontal scroll '
        'view (e.g. SingleChildScrollView) to lay the content on a single line '
        'and scroll it.',
      );
    }

    final double rowWidth = constraints.hasBoundedWidth
        ? constraints.maxWidth
        : double.infinity;

    final children = <RenderBox>[];
    for (var child = firstChild; child != null; child = childAfter(child)) {
      children.add(child);
    }

    _disposeFragments();

    double cursor = 0;
    int row = 0;

    for (final piece in _pieces) {
      switch (piece) {
        case _BreakPiece():
          cursor = 0;
          row += 1;
        case _WidgetPiece(:final childIndex):
          final child = children[childIndex];
          child.layout(const BoxConstraints(), parentUsesSize: true);
          final natW = child.size.width;
          final natH = child.size.height;
          // Scale an oversized widget down to the row's content band, not the
          // full row, so it keeps a little space above and below rather than
          // touching both rules.
          final maxContentHeight = _lineHeight * _scaleDownContentFraction;
          final scale =
              (_fit == NotebookFit.scaleDown &&
                  natH > maxContentHeight &&
                  natH > 0)
              ? maxContentHeight / natH
              : 1.0;
          final effW = natW * scale;
          final effH = natH * scale;
          if (_wrap &&
              cursor > 0 &&
              cursor + effW > rowWidth + _kWidthTolerance) {
            cursor = 0;
            row += 1;
          }
          _fragments.add(
            _Fragment.widget(
              child: child,
              scale: scale,
              row: row,
              leadingOffset: cursor,
              width: effW,
              height: effH,
            ),
          );
          cursor += effW;
        case _TextPiece(:final text, :final style):
          final effStyle = style == null
              ? _baseTextStyle
              : _baseTextStyle.merge(style);
          final h0 = _measureLineHeight(text, effStyle);
          final TextScaler scaler = (_fit == NotebookFit.scaleDown && h0 > 0)
              ? _textScaler.clamp(maxScaleFactor: _lineHeight / h0)
              : _textScaler;

          var remaining = text;
          while (remaining.isNotEmpty) {
            double avail;
            if (!_wrap) {
              avail = double.infinity;
            } else if (cursor > 0) {
              avail = rowWidth - cursor;
              if (avail <= _kWidthTolerance) {
                cursor = 0;
                row += 1;
                avail = rowWidth;
              }
            } else {
              avail = rowWidth;
            }

            final line = _layoutLine(remaining, effStyle, scaler, avail);

            if (_wrap && cursor > 0 && line.width > avail + _kWidthTolerance) {
              // Even the minimal chunk overflows the remaining gap; wrap to a
              // fresh row and lay this text out again from the leading edge.
              line.painter.dispose();
              cursor = 0;
              row += 1;
              continue;
            }

            _fragments.add(
              _Fragment.text(
                painter: line.painter,
                row: row,
                leadingOffset: cursor,
                width: line.width,
                height: line.height,
              ),
            );

            remaining = line.rest;
            if (remaining.isEmpty) {
              cursor += line.width;
            } else {
              cursor = 0;
              row += 1;
            }
          }
      }
    }

    final int contentRows = _pieces.isEmpty ? 0 : row + 1;
    _rowCount = math.max(contentRows, _minRows);
    final double contentHeight = _rowCount * _lineHeight;

    double width;
    if (_wrap) {
      width = rowWidth;
    } else {
      double maxExtent = 0;
      for (final fragment in _fragments) {
        final extent = fragment.leadingOffset + fragment.width;
        if (extent > maxExtent) maxExtent = extent;
      }
      width = maxExtent;
    }

    // Adopt the content size before the guard below, so a forced-height misuse
    // is reported as a single error instead of cascading "no size" assertions.
    size = constraints.constrain(Size(width, contentHeight));

    if (contentHeight < constraints.minHeight - _kHeightTolerance ||
        contentHeight > constraints.maxHeight + _kHeightTolerance) {
      throw FlutterError.fromParts(<DiagnosticsNode>[
        ErrorSummary('NotebookEntry cannot be given a fixed height.'),
        ErrorDescription(
          'A NotebookEntry sizes itself to the rows it creates: its height is '
          'its row count times the line height. Here that content height is '
          '${contentHeight.toStringAsFixed(1)} '
          '(= $_rowCount rows x ${_lineHeight.toStringAsFixed(1)}), but the '
          'incoming constraints require a height in '
          '[${constraints.minHeight.toStringAsFixed(1)}, '
          '${constraints.maxHeight.toStringAsFixed(1)}].',
        ),
        ErrorHint(
          'Let the entry size to its content rather than forcing a height (for '
          'example with a SizedBox height, an Expanded, or any tight height '
          'constraint). Use minRows for a minimum row count.',
        ),
      ]);
    }

    _resolvePlacements(size.width);
  }

  /// Measures the unscaled single-line height of [text] in [style].
  double _measureLineHeight(String text, TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: _textDirection,
      maxLines: 1,
    )..layout();
    final height = painter.height;
    painter.dispose();
    return height;
  }

  /// Lays out the first visual line of [text] within [maxWidth] and returns its
  /// painter, its (trimmed) width and height, and the unconsumed remainder.
  ({TextPainter painter, double width, double height, String rest}) _layoutLine(
    String text,
    TextStyle style,
    TextScaler scaler,
    double maxWidth,
  ) {
    final probe = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: _textDirection,
      textScaler: scaler,
      textHeightBehavior: _kEvenLeading,
    )..layout(maxWidth: maxWidth);

    final metrics = probe.computeLineMetrics();
    final end = probe.getLineBoundary(const TextPosition(offset: 0)).end;
    probe.dispose();

    final String firstLine;
    final String rest;
    if (end <= 0 || end >= text.length) {
      firstLine = text;
      rest = '';
    } else {
      firstLine = text.substring(0, end);
      rest = text.substring(end);
    }

    final painter = TextPainter(
      text: TextSpan(text: firstLine, style: style),
      textDirection: _textDirection,
      textScaler: scaler,
      textHeightBehavior: _kEvenLeading,
    )..layout();

    final double width;
    final double height;
    if (metrics.isNotEmpty) {
      width = metrics.first.width;
      height = metrics.first.height;
    } else {
      width = painter.width;
      height = painter.height;
    }

    return (painter: painter, width: width, height: height, rest: rest);
  }

  /// Resolves every fragment's absolute offset: intra-row centering, then
  /// [textAlignVertical] placement, then the single direction flip on x.
  void _resolvePlacements(double width) {
    if (_fragments.isEmpty) return;

    final rowHeights = <int, double>{};
    for (final fragment in _fragments) {
      final current = rowHeights[fragment.row] ?? 0;
      if (fragment.height > current) rowHeights[fragment.row] = fragment.height;
    }

    final double t = (_textAlignVertical.y + 1.0) / 2.0;
    final bool ltr = _textDirection == TextDirection.ltr;

    for (final fragment in _fragments) {
      final double rowHeight = rowHeights[fragment.row] ?? fragment.height;
      final double available = _lineHeight - rowHeight;
      final double lineTopInRow = t * available;
      final double fragTop =
          fragment.row * _lineHeight +
          lineTopInRow +
          (rowHeight - fragment.height) / 2.0;
      final double absX = ltr
          ? fragment.leadingOffset
          : (width - fragment.leadingOffset - fragment.width);
      fragment.localOffset = Offset(absX, fragTop);

      final child = fragment.child;
      if (child != null) {
        final pd = child.parentData! as _NotebookEntryParentData;
        pd.offset = fragment.localOffset;
        pd.scale = fragment.scale;
      }
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    _paintRules(context.canvas, offset);

    final byRow = <int, List<_Fragment>>{};
    for (final fragment in _fragments) {
      (byRow[fragment.row] ??= <_Fragment>[]).add(fragment);
    }

    for (final entry in byRow.entries) {
      final rowRect = Rect.fromLTWH(
        0,
        entry.key * _lineHeight,
        size.width,
        _lineHeight,
      );
      context.pushClipRect(needsCompositing, offset, rowRect, (ctx, off) {
        for (final fragment in entry.value) {
          final painter = fragment.painter;
          if (painter != null) {
            painter.paint(ctx.canvas, off + fragment.localOffset);
          } else {
            final child = fragment.child!;
            if (fragment.scale == 1.0) {
              ctx.paintChild(child, off + fragment.localOffset);
            } else {
              ctx.pushTransform(
                needsCompositing,
                off + fragment.localOffset,
                Matrix4.diagonal3Values(fragment.scale, fragment.scale, 1.0),
                (innerCtx, innerOff) => innerCtx.paintChild(child, innerOff),
              );
            }
          }
        }
      });
    }
  }

  void _paintRules(Canvas canvas, Offset offset) {
    final paint = Paint()
      ..color = _lineColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var b = 0; b < _rowCount; b++) {
      final helpers = HandDrawnHelpers(
        seed: _uniformLines ? _seed : _seed + b,
        segments: _segments,
        irregularity: _irregularity,
      );
      final path = helpers.lineHorizontal(Size(size.width, 0));
      canvas.save();
      canvas.translate(offset.dx, offset.dy + (b + 1) * _lineHeight);
      canvas.drawPath(path, paint);
      canvas.restore();
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    for (var i = _fragments.length - 1; i >= 0; i--) {
      final fragment = _fragments[i];
      final child = fragment.child;
      if (child == null) continue;
      // A widget clipped to its row must not be hittable beyond that row.
      final rowRect = Rect.fromLTWH(
        0,
        fragment.row * _lineHeight,
        size.width,
        _lineHeight,
      );
      if (!rowRect.contains(position)) continue;
      final pd = child.parentData! as _NotebookEntryParentData;
      final transform = Matrix4.translationValues(
        pd.offset.dx,
        pd.offset.dy,
        0,
      );
      if (pd.scale != 1.0) {
        transform.multiply(Matrix4.diagonal3Values(pd.scale, pd.scale, 1.0));
      }
      final hit = result.addWithPaintTransform(
        transform: transform,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child.hitTest(result, position: transformed);
        },
      );
      if (hit) return true;
    }
    return false;
  }

  @override
  void applyPaintTransform(RenderBox child, Matrix4 transform) {
    final pd = child.parentData! as _NotebookEntryParentData;
    transform.multiply(
      Matrix4.translationValues(pd.offset.dx, pd.offset.dy, 0),
    );
    if (pd.scale != 1.0) {
      transform.multiply(Matrix4.diagonal3Values(pd.scale, pd.scale, 1.0));
    }
  }

  @override
  void describeSemanticsConfiguration(SemanticsConfiguration config) {
    super.describeSemanticsConfiguration(config);
    // Painted text is otherwise invisible to assistive technologies, so expose
    // it as one combined label in reading order. Widget children keep their own
    // semantic nodes (they are not merged here).
    final buffer = StringBuffer();
    for (final piece in _pieces) {
      if (piece is _TextPiece) {
        buffer.write(piece.text);
      } else if (piece is _BreakPiece) {
        buffer.write('\n');
      }
    }
    final label = buffer.toString();
    if (label.isNotEmpty) {
      config.label = label;
      config.textDirection = _textDirection;
    }
  }
}
