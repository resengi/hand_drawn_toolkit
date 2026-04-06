import 'package:flutter/material.dart';

import 'hand_drawn_constants.dart';
import 'hand_drawn_container.dart';
import 'hand_drawn_divider.dart';
import 'hand_drawn_toolkit_defaults.dart';

/// Definition of a single table column.
class HandDrawnTableColumn {
  const HandDrawnTableColumn({
    required this.header,
    this.flex = 1,
    this.width,
    this.alignment = Alignment.centerLeft,
  }) : assert(flex > 0),
       assert(width == null || width > 0);

  /// Column header text.
  final String header;

  /// Flex factor when [width] is null.
  final int flex;

  /// Fixed width. Overrides [flex] when set.
  final double? width;

  /// Alignment of cell content within the column.
  final Alignment alignment;
}

/// A single row of cell data.
///
/// Each row's [cells] list must contain exactly one value per column.
class HandDrawnTableRow {
  const HandDrawnTableRow({
    required this.cells,
    this.cellStyle,
    this.highlight = false,
  });

  /// Cell values, one per column.
  final List<String> cells;

  /// Optional per-row style override. Applied to all cells in this row.
  final TextStyle? cellStyle;

  /// When true, the row is rendered with a tinted background and
  /// emphasized text.
  final bool highlight;
}

/// A generic hand-drawn table widget.
///
/// Renders column headers and row data inside a [HandDrawnContainer] with
/// [HandDrawnDivider] separators.
///
/// ## Layout
///
/// This table is designed for compact, summary-style data. All cells render
/// with `maxLines: 1` and [textOverflow] (defaults to [TextOverflow.ellipsis]),
/// so long cell content is truncated rather than wrapped. For wider content,
/// use explicit [HandDrawnTableColumn.width] values or enable
/// [horizontalScroll].
///
/// ```dart
/// HandDrawnTable(
///   columns: [
///     HandDrawnTableColumn(header: 'Name', flex: 3),
///     HandDrawnTableColumn(header: 'Score', width: 60),
///   ],
///   rows: [
///     HandDrawnTableRow(cells: ['Alice', '42']),
///     HandDrawnTableRow(cells: ['Bob', '38'], highlight: true),
///   ],
/// )
/// ```
class HandDrawnTable extends StatelessWidget {
  const HandDrawnTable({
    required this.columns,
    required this.rows,
    this.title,
    this.highlightColor = tableHighlightColor,
    this.highlightAlpha = tableHighlightAlpha,
    this.headerStyle,
    this.cellStyle,
    this.titleStyle,
    this.emptyStyle,
    this.emptyMessage = 'No data',
    this.showRowDividers = false,
    this.padding = const EdgeInsets.all(defaultTablePadding),
    this.rowPadding = tableRowVerticalPadding,
    this.titleBottomPadding = tableTitleBottomPadding,
    this.textOverflow = TextOverflow.ellipsis,
    this.horizontalScroll = false,
    super.key,
  });

  /// Column definitions.
  final List<HandDrawnTableColumn> columns;

  /// Row data. Each row's [HandDrawnTableRow.cells] must have the same
  /// length as [columns].
  final List<HandDrawnTableRow> rows;

  /// Optional title above the table.
  final String? title;

  /// Color used for highlighted rows (both text emphasis and background tint).
  final Color highlightColor;

  /// Opacity of the highlight tint background.
  final double highlightAlpha;

  /// Style for column header text.
  final TextStyle? headerStyle;

  /// Default style for cell text.
  final TextStyle? cellStyle;

  /// Style for the table title.
  final TextStyle? titleStyle;

  /// Style for the empty-state message.
  final TextStyle? emptyStyle;

  /// Message shown when [rows] is empty.
  final String emptyMessage;

  /// When true, a [HandDrawnDivider] is drawn between each data row.
  final bool showRowDividers;

  /// Inner padding of the table container.
  final EdgeInsets padding;

  /// Vertical padding between rows.
  final double rowPadding;

  /// Space between the title and the header row.
  final double titleBottomPadding;

  /// How overflowing cell text is handled. Defaults to [TextOverflow.ellipsis].
  final TextOverflow textOverflow;

  /// When true, the table body is wrapped in a horizontal [ScrollView].
  ///
  /// All columns must specify an explicit [HandDrawnTableColumn.width] when
  /// this is enabled; flex-only columns are not supported in scroll mode.
  final bool horizontalScroll;

  TextStyle get _headerStyle =>
      headerStyle ??
      const TextStyle(
        fontSize: HandDrawnDefaults.tableHeaderFontSize,
        fontWeight: tableHeaderFontWeight,
        color: tableHeaderColor,
        letterSpacing: tableHeaderLetterSpacing,
      );

  TextStyle get _cellStyle =>
      cellStyle ??
      const TextStyle(
        fontSize: HandDrawnDefaults.tableCellFontSize,
        color: tableCellColor,
      );

  TextStyle get _titleStyle =>
      titleStyle ??
      const TextStyle(
        fontSize: HandDrawnDefaults.tableTitleFontSize,
        fontWeight: tableTitleFontWeight,
        color: tableTitleColor,
      );

  TextStyle get _emptyStyle =>
      emptyStyle ??
      const TextStyle(
        color: emptyMessageColor,
        fontSize: HandDrawnDefaults.tableCellFontSize,
      );

  @override
  Widget build(BuildContext context) {
    // Validate horizontal scroll constraint.
    double totalWidth = 0;
    if (horizontalScroll) {
      for (final col in columns) {
        if (col.width == null) {
          throw ArgumentError(
            'All columns must specify an explicit width when '
            'horizontalScroll is true. Column "${col.header}" uses flex.',
          );
        }
        totalWidth += col.width!;
      }
    }

    // Validate row/column consistency when data is present.
    if (rows.isNotEmpty) {
      for (final row in rows) {
        if (row.cells.length != columns.length) {
          throw ArgumentError(
            'Each HandDrawnTableRow must provide exactly one cell per column. '
            'Expected ${columns.length}, got ${row.cells.length}.',
          );
        }
      }
    }

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (title != null)
          Padding(
            padding: EdgeInsets.only(bottom: titleBottomPadding),
            child: Text(title!, style: _titleStyle),
          ),
        if (rows.isEmpty)
          Center(child: Text(emptyMessage, style: _emptyStyle))
        else ...[
          _buildRow([for (final col in columns) col.header], _headerStyle),
          const HandDrawnDivider(),
          for (int i = 0; i < rows.length; i++) ...[
            _buildDataRow(rows[i]),
            if (showRowDividers && i < rows.length - 1)
              HandDrawnDivider(seed: HandDrawnDefaults.seed + i),
          ],
        ],
      ],
    );

    return HandDrawnContainer(
      padding: padding,
      child: horizontalScroll
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: totalWidth, child: content),
            )
          : content,
    );
  }

  Widget _buildDataRow(HandDrawnTableRow row) {
    final style =
        row.cellStyle ??
        (row.highlight
            ? _cellStyle.copyWith(
                color: highlightColor,
                fontWeight: tableHighlightFontWeight,
              )
            : _cellStyle);

    final rowWidget = _buildRow(row.cells, style);

    if (row.highlight) {
      return Container(
        color: highlightColor.withValues(alpha: highlightAlpha),
        child: rowWidget,
      );
    }
    return rowWidget;
  }

  Widget _buildRow(List<String> cells, TextStyle style) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowPadding),
      child: Row(
        children: [
          for (int i = 0; i < columns.length; i++)
            columns[i].width != null
                ? SizedBox(
                    width: columns[i].width,
                    child: Align(
                      alignment: columns[i].alignment,
                      child: Text(
                        cells[i],
                        style: style,
                        maxLines: 1,
                        softWrap: false,
                        overflow: textOverflow,
                      ),
                    ),
                  )
                : Expanded(
                    flex: columns[i].flex,
                    child: Align(
                      alignment: columns[i].alignment,
                      child: Text(
                        cells[i],
                        style: style,
                        maxLines: 1,
                        softWrap: false,
                        overflow: textOverflow,
                      ),
                    ),
                  ),
        ],
      ),
    );
  }
}
