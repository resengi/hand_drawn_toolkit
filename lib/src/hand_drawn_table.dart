import 'dart:math' as math;

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

/// Configuration for hand-drawn dividers between table rows or columns.
///
/// Pass as [HandDrawnTable.rowDividers] or [HandDrawnTable.columnDividers].
/// Null means no dividers; non-null enables dividers with the given style.
///
/// When [uniform] is true (the default), all dividers share the same [seed]
/// and wobble pattern. When false, each divider gets a unique seed
/// (`seed + 1`, `seed + 2`, …) for distinct wobble on every line.
class TableDividerStyle {
  const TableDividerStyle({
    this.color = HandDrawnDefaults.dividerColor,
    this.seed = HandDrawnDefaults.seed,
    this.irregularity = HandDrawnDefaults.dividerIrregularity,
    this.thickness = HandDrawnDefaults.dividerThickness,
    this.uniform = true,
  });

  /// Stroke color for the dividers. Defaults to the package divider color.
  final Color color;

  /// Random seed for deterministic wobble.
  final int seed;

  /// Wobble magnitude for the dividers.
  final double irregularity;

  /// Stroke thickness of the dividers.
  final double thickness;

  /// When true, all dividers share the same wobble pattern. When false,
  /// each divider gets a unique seed for distinct character.
  final bool uniform;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableDividerStyle &&
          color == other.color &&
          seed == other.seed &&
          irregularity == other.irregularity &&
          thickness == other.thickness &&
          uniform == other.uniform;

  @override
  int get hashCode =>
      Object.hash(color, seed, irregularity, thickness, uniform);
}

/// A generic hand-drawn table widget.
///
/// Renders column headers and row data inside a [HandDrawnContainer] with
/// [HandDrawnDivider] separators.
///
/// ## Layout
///
/// This table is designed for compact, summary-style data. By default,
/// all cells render with a single line and [textOverflow]
/// (defaulting to [TextOverflow.ellipsis]) so long content is
/// truncated rather than wrapped. For multi-line cells, set
/// [cellMaxLines] and [softWrap] together. For wider content, use
/// explicit [HandDrawnTableColumn.width] values or enable
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
    this.highlightColor = HandDrawnDefaults.tableHighlightColor,
    this.highlightAlpha = HandDrawnDefaults.tableHighlightAlpha,
    this.headerStyle,
    this.cellStyle,
    this.titleStyle,
    this.emptyStyle,
    this.emptyMessage = 'No data',
    this.rowDividers,
    this.columnDividers,
    this.padding = const EdgeInsets.all(HandDrawnDefaults.tablePadding),
    this.rowPadding = HandDrawnDefaults.tableRowVerticalPadding,
    this.titleBottomPadding = HandDrawnDefaults.tableTitleBottomPadding,
    this.textOverflow = TextOverflow.ellipsis,
    this.cellMaxLines = 1,
    this.softWrap = false,
    this.horizontalScroll = false,
    this.seed = HandDrawnDefaults.seed,
    this.irregularity = HandDrawnDefaults.irregularity,
    this.strokeWidth = HandDrawnDefaults.strokeWidth,
    this.strokeColor = HandDrawnDefaults.containerStrokeColor,
    this.backgroundColor = HandDrawnDefaults.containerBackgroundColor,
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

  /// Row divider configuration.
  ///
  /// Null (default) disables dividers between data rows. The
  /// header-to-data divider is always drawn — with default styling
  /// when this is null, or with the configured styling when set.
  /// Provide a [TableDividerStyle] to enable dividers between data
  /// rows in addition to the header divider.
  final TableDividerStyle? rowDividers;

  /// Column divider configuration. Null (default) disables column dividers.
  /// Provide a [TableDividerStyle] to enable vertical dividers between columns.
  final TableDividerStyle? columnDividers;

  /// Inner padding of the table container.
  final EdgeInsets padding;

  /// Vertical padding between rows.
  final double rowPadding;

  /// Space between the title and the header row.
  final double titleBottomPadding;

  /// How overflowing cell text is handled. Defaults to [TextOverflow.ellipsis].
  final TextOverflow textOverflow;

  /// Maximum number of lines a cell may render. Defaults to `1`, which
  /// pairs with the default [textOverflow] of [TextOverflow.ellipsis]
  /// to truncate long content on a single line.
  ///
  /// Set higher (e.g. `2` or `3`) when cells contain content that
  /// benefits from wrapping. For wrapping to take effect, also set
  /// [softWrap] to `true`; otherwise the cell will hard-truncate at
  /// the available width without breaking words.
  final int cellMaxLines;

  /// Whether cell text wraps onto multiple lines at soft break points.
  /// Defaults to `false`, matching the compact summary-table aesthetic.
  ///
  /// Pair with [cellMaxLines] greater than `1` to render wrapped
  /// multi-line cells. Setting `softWrap: true` with `cellMaxLines: 1`
  /// has no visible effect — there is only one line to render.
  final bool softWrap;

  /// When true, the table body is wrapped in a horizontal [ScrollView].
  ///
  /// All columns must specify an explicit [HandDrawnTableColumn.width] when
  /// this is enabled; flex-only columns are not supported in scroll mode.
  final bool horizontalScroll;

  /// Random seed for the outer container border.
  final int seed;

  /// Wobble magnitude for the outer container border.
  final double irregularity;

  /// Stroke width for the outer container border.
  final double strokeWidth;

  /// Stroke color for the outer container border.
  final Color strokeColor;

  /// Background fill color for the outer container.
  final Color backgroundColor;

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

    // The grid (headers + data rows + dividers) is the unit that column
    // dividers overlay. The title sits above the grid as a sibling so the
    // overlaid vertical dividers cannot extend into the title's vertical
    // band.
    final grid = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (rows.isEmpty)
          Center(child: Text(emptyMessage, style: _emptyStyle))
        else ...[
          _buildRow([for (final col in columns) col.header], _headerStyle),
          _buildHeaderDivider(),
          for (int i = 0; i < rows.length; i++) ...[
            _buildDataRow(rows[i]),
            if (rowDividers != null && i < rows.length - 1) _buildRowDivider(i),
          ],
        ],
      ],
    );

    // Wrap grid with column divider overlay when enabled.
    Widget body;
    if (columnDividers != null && rows.isNotEmpty) {
      if (horizontalScroll) {
        // All columns have explicit widths — positions are known.
        body = SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SizedBox(
            width: totalWidth,
            child: _columnDividerStack(grid, _columnBoundaries(totalWidth)),
          ),
        );
      } else {
        // May have flex columns — resolve width at layout time.
        body = LayoutBuilder(
          builder: (context, constraints) {
            return _columnDividerStack(
              grid,
              _columnBoundaries(constraints.maxWidth),
            );
          },
        );
      }
    } else {
      body = horizontalScroll
          ? SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SizedBox(width: totalWidth, child: grid),
            )
          : grid;
    }

    // Title sits above the body so column dividers (when enabled) overlay
    // only the grid, not the title.
    final child = title == null
        ? body
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(bottom: titleBottomPadding),
                child: Text(title!, style: _titleStyle),
              ),
              body,
            ],
          );

    return HandDrawnContainer(
      padding: padding,
      seed: seed,
      irregularity: irregularity,
      strokeWidth: strokeWidth,
      strokeColor: strokeColor,
      backgroundColor: backgroundColor,
      child: child,
    );
  }

  // ── Divider builders ──────────────────────────────────────────────────

  HandDrawnDivider _buildHeaderDivider() {
    if (rowDividers == null) return const HandDrawnDivider();
    final config = rowDividers!;
    return HandDrawnDivider(
      color: config.color,
      seed: config.seed,
      irregularity: config.irregularity,
      thickness: config.thickness,
    );
  }

  HandDrawnDivider _buildRowDivider(int index) {
    final config = rowDividers!;
    return HandDrawnDivider(
      color: config.color,
      seed: config.uniform ? config.seed : config.seed + index + 1,
      irregularity: config.irregularity,
      thickness: config.thickness,
    );
  }

  // ── Column divider overlay ────────────────────────────────────────────

  Widget _columnDividerStack(Widget content, List<double> boundaries) {
    final config = columnDividers!;
    final thickness = config.thickness;
    final halfCross = dividerCrossAxisExtent(thickness) / 2;
    return IntrinsicHeight(
      child: Stack(
        children: [
          content,
          for (int i = 0; i < boundaries.length; i++)
            Positioned(
              left: boundaries[i] - halfCross,
              top: 0,
              bottom: 0,
              child: HandDrawnDivider(
                direction: Axis.vertical,
                height: double.infinity,
                color: config.color,
                thickness: thickness,
                seed: config.uniform ? config.seed : config.seed + i + 1,
                irregularity: config.irregularity,
              ),
            ),
        ],
      ),
    );
  }

  List<double> _columnBoundaries(double availableWidth) {
    double fixedTotal = 0;
    int totalFlex = 0;
    for (final col in columns) {
      if (col.width != null) {
        fixedTotal += col.width!;
      } else {
        totalFlex += col.flex;
      }
    }
    final flexSpace = math.max(0.0, availableWidth - fixedTotal);

    final boundaries = <double>[];
    double x = 0;
    for (int i = 0; i < columns.length - 1; i++) {
      x +=
          columns[i].width ??
          (totalFlex > 0 ? flexSpace * columns[i].flex / totalFlex : 0);
      boundaries.add(x);
    }
    return boundaries;
  }

  // ── Row builders ──────────────────────────────────────────────────────

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
    final hasColumnDividers = columnDividers != null;
    final children = <Widget>[];
    for (int i = 0; i < columns.length; i++) {
      Widget cell = Align(
        alignment: columns[i].alignment,
        child: Text(
          cells[i],
          style: style,
          maxLines: cellMaxLines,
          softWrap: softWrap,
          overflow: textOverflow,
        ),
      );
      if (hasColumnDividers) {
        cell = Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: tableColumnDividerCellPadding,
          ),
          child: cell,
        );
      }
      children.add(
        columns[i].width != null
            ? SizedBox(width: columns[i].width, child: cell)
            : Expanded(flex: columns[i].flex, child: cell),
      );
    }
    return Padding(
      padding: EdgeInsets.symmetric(vertical: rowPadding),
      child: Row(children: children),
    );
  }
}
