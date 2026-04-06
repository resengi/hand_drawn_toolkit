import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

Widget _wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

const _columns = [
  HandDrawnTableColumn(header: 'Name', flex: 3),
  HandDrawnTableColumn(header: 'Score', width: 60),
];

const _rows = [
  HandDrawnTableRow(cells: ['Alice', '42']),
  HandDrawnTableRow(cells: ['Bob', '38']),
  HandDrawnTableRow(cells: ['Carol', '45'], highlight: true),
];

void main() {
  // ── Empty state ──────────────────────────────────────────────────────

  group('HandDrawnTable empty state', () {
    testWidgets('shows default empty message when rows are empty', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: [])),
      );
      expect(find.text('No data'), findsOneWidget);
    });

    testWidgets('shows custom empty message', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: [],
            emptyMessage: 'Nothing here',
          ),
        ),
      );
      expect(find.text('Nothing here'), findsOneWidget);
    });

    testWidgets('wraps empty message in HandDrawnContainer', (tester) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: [])),
      );
      expect(find.byType(HandDrawnContainer), findsOneWidget);
    });

    testWidgets('shows title in empty state when title is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(columns: _columns, rows: [], title: 'My Table'),
        ),
      );
      expect(find.text('My Table'), findsOneWidget);
      expect(find.text('No data'), findsOneWidget);
    });

    testWidgets('empty state uses same padding as populated state', (
      tester,
    ) async {
      const customPadding = EdgeInsets.all(24);
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: [],
            padding: customPadding,
          ),
        ),
      );
      // The HandDrawnContainer should receive the custom padding.
      final container = tester.widget<HandDrawnContainer>(
        find.byType(HandDrawnContainer),
      );
      expect(container.padding, customPadding);
    });
  });

  // ── Rendering with data ──────────────────────────────────────────────

  group('HandDrawnTable with data', () {
    testWidgets('renders all cell values', (tester) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('38'), findsOneWidget);
      expect(find.text('Carol'), findsOneWidget);
      expect(find.text('45'), findsOneWidget);
    });

    testWidgets('renders column headers', (tester) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
    });

    testWidgets('renders header divider', (tester) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      expect(find.byType(HandDrawnDivider), findsAtLeastNWidgets(1));
    });
  });

  // ── Title ────────────────────────────────────────────────────────────

  group('HandDrawnTable title', () {
    testWidgets('renders title when provided', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            title: 'Leaderboard',
          ),
        ),
      );
      expect(find.text('Leaderboard'), findsOneWidget);
    });

    testWidgets('does not render title when null', (tester) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      // Only cell texts and headers should be present, no title widget.
      expect(find.text('Leaderboard'), findsNothing);
    });
  });

  // ── Row dividers ─────────────────────────────────────────────────────

  group('HandDrawnTable row dividers', () {
    testWidgets('shows no row dividers by default', (tester) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      // Only the header divider should exist.
      expect(find.byType(HandDrawnDivider), findsOneWidget);
    });

    testWidgets('shows row dividers when enabled', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            showRowDividers: true,
          ),
        ),
      );
      // Header divider + 2 row dividers (between 3 rows) = 3.
      expect(find.byType(HandDrawnDivider), findsNWidgets(3));
    });

    testWidgets('no row divider after the last row', (tester) async {
      const singleRow = [
        HandDrawnTableRow(cells: ['A', '1']),
      ];
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: singleRow,
            showRowDividers: true,
          ),
        ),
      );
      // Only header divider, no row divider for a single row.
      expect(find.byType(HandDrawnDivider), findsOneWidget);
    });
  });

  // ── Highlighted rows ─────────────────────────────────────────────────

  group('HandDrawnTable highlighting', () {
    testWidgets('highlighted row gets tinted background Container', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: _rows)),
      );

      // Find Container widgets that are descendants of HandDrawnTable.
      // The highlighted row (Carol) should have a Container with a color.
      final containers = find.descendant(
        of: find.byType(HandDrawnTable),
        matching: find.byType(Container),
      );

      bool foundTintedContainer = false;
      for (final element in containers.evaluate()) {
        final container = element.widget as Container;
        if (container.color != null && container.color!.a > 0) {
          foundTintedContainer = true;
          break;
        }
      }
      expect(foundTintedContainer, isTrue);
    });

    testWidgets('highlighted row text uses highlight color', (tester) async {
      const highlightColor = Color(0xFF6BAF7A);
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: [
              HandDrawnTableRow(cells: ['Test', '99'], highlight: true),
            ],
            highlightColor: highlightColor,
          ),
        ),
      );

      // Find text widget for 'Test' and verify its style.
      final textWidget = tester.widget<Text>(find.text('Test'));
      expect(textWidget.style?.color, highlightColor);
      expect(textWidget.style?.fontWeight, FontWeight.w700);
    });
  });

  // ── Row count assertion ──────────────────────────────────────────────

  group('HandDrawnTable row validation', () {
    testWidgets('throws ArgumentError when row cell count mismatches columns', (
      tester,
    ) async {
      final mismatchedRows = [
        const HandDrawnTableRow(cells: ['Only one cell']),
      ];

      await tester.pumpWidget(
        _wrap(HandDrawnTable(columns: _columns, rows: mismatchedRows)),
      );

      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('error message includes expected and actual counts', (
      tester,
    ) async {
      final mismatchedRows = [
        const HandDrawnTableRow(cells: ['One']),
      ];

      await tester.pumpWidget(
        _wrap(HandDrawnTable(columns: _columns, rows: mismatchedRows)),
      );

      final error = tester.takeException();
      expect(error, isA<ArgumentError>());
      expect(
        (error as ArgumentError).message,
        contains('Expected ${_columns.length}'),
      );
    });
  });

  // ── Header styling ───────────────────────────────────────────────────

  group('HandDrawnTable header styling', () {
    testWidgets('header text uses letter spacing for differentiation', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: _rows)),
      );

      final nameHeader = tester.widget<Text>(find.text('Name'));
      expect(nameHeader.style?.letterSpacing, isNotNull);
      expect(nameHeader.style?.letterSpacing, greaterThan(0));
    });

    testWidgets('accepts custom header style', (tester) async {
      const customStyle = TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF000000),
      );

      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            headerStyle: customStyle,
          ),
        ),
      );

      final nameHeader = tester.widget<Text>(find.text('Name'));
      expect(nameHeader.style?.fontSize, 16);
    });
  });

  // ── Custom cell style ────────────────────────────────────────────────

  group('HandDrawnTable custom cell style', () {
    testWidgets('per-row cellStyle overrides default', (tester) async {
      const customStyle = TextStyle(fontSize: 20, color: Color(0xFFFF0000));
      final rows = [
        const HandDrawnTableRow(cells: ['Styled', '1'], cellStyle: customStyle),
      ];

      await tester.pumpWidget(
        _wrap(HandDrawnTable(columns: _columns, rows: rows)),
      );

      final text = tester.widget<Text>(find.text('Styled'));
      expect(text.style?.fontSize, 20);
      expect(text.style?.color, const Color(0xFFFF0000));
    });
  });

  // ── Column configuration ─────────────────────────────────────────────

  group('HandDrawnTable column configuration', () {
    testWidgets('fixed-width column renders with SizedBox', (tester) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: _rows)),
      );

      // The 'Score' column has width: 60, so its cell should be in a SizedBox.
      final sizedBoxes = find.descendant(
        of: find.byType(HandDrawnTable),
        matching: find.byType(SizedBox),
      );
      expect(sizedBoxes, findsWidgets);
    });

    testWidgets('flex column renders with Expanded', (tester) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: _rows)),
      );

      final expandedWidgets = find.descendant(
        of: find.byType(HandDrawnTable),
        matching: find.byType(Expanded),
      );
      expect(expandedWidgets, findsWidgets);
    });
  });

  // ── Extended configurability (Groups 4, 5) ───────────────────────────

  group('HandDrawnTable extended configurability', () {
    testWidgets('accepts custom padding', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            padding: EdgeInsets.all(24),
          ),
        ),
      );
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('accepts custom rowPadding', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(columns: _columns, rows: _rows, rowPadding: 12),
        ),
      );
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('accepts custom titleStyle', (tester) async {
      const style = TextStyle(fontSize: 20, color: Color(0xFFFF0000));
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            title: 'Styled Title',
            titleStyle: style,
          ),
        ),
      );
      final titleText = tester.widget<Text>(find.text('Styled Title'));
      expect(titleText.style?.fontSize, 20);
      expect(titleText.style?.color, const Color(0xFFFF0000));
    });

    testWidgets('accepts custom highlightAlpha', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: [
              HandDrawnTableRow(cells: ['Test', '1'], highlight: true),
            ],
            highlightAlpha: 0.2,
          ),
        ),
      );
      expect(find.text('Test'), findsOneWidget);
    });

    testWidgets('accepts custom emptyStyle', (tester) async {
      const style = TextStyle(fontSize: 18, color: Color(0xFFFF0000));
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(columns: _columns, rows: [], emptyStyle: style),
        ),
      );
      final emptyText = tester.widget<Text>(find.text('No data'));
      expect(emptyText.style?.fontSize, 18);
    });

    testWidgets('accepts custom titleBottomPadding', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            title: 'Spaced Title',
            titleBottomPadding: 20,
          ),
        ),
      );
      expect(find.text('Spaced Title'), findsOneWidget);
    });
  });

  // ── Text overflow configurability (Step 3.1) ────────────────────────

  group('HandDrawnTable text overflow', () {
    testWidgets('uses ellipsis by default', (tester) async {
      await tester.pumpWidget(
        _wrap(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      final texts = tester.widgetList<Text>(find.byType(Text));
      final cellTexts = texts.where((t) => t.overflow == TextOverflow.ellipsis);
      expect(cellTexts, isNotEmpty);
    });

    testWidgets('respects custom textOverflow', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            textOverflow: TextOverflow.clip,
          ),
        ),
      );
      final texts = tester.widgetList<Text>(find.byType(Text));
      final clipTexts = texts.where((t) => t.overflow == TextOverflow.clip);
      expect(clipTexts, isNotEmpty);
    });
  });

  // ── Horizontal scrolling (Step 3.3) ─────────────────────────────────

  group('HandDrawnTable horizontal scroll', () {
    testWidgets('wraps content in SingleChildScrollView when enabled', (
      tester,
    ) async {
      const fixedColumns = [
        HandDrawnTableColumn(header: 'A', width: 100),
        HandDrawnTableColumn(header: 'B', width: 100),
      ];
      const fixedRows = [
        HandDrawnTableRow(cells: ['1', '2']),
      ];
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: fixedColumns,
            rows: fixedRows,
            horizontalScroll: true,
          ),
        ),
      );
      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('throws when flex column used with horizontalScroll', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            horizontalScroll: true,
          ),
        ),
      );
      expect(tester.takeException(), isA<ArgumentError>());
    });

    testWidgets('does not use IntrinsicWidth in scroll mode', (tester) async {
      const fixedColumns = [
        HandDrawnTableColumn(header: 'A', width: 100),
        HandDrawnTableColumn(header: 'B', width: 150),
      ];
      const fixedRows = [
        HandDrawnTableRow(cells: ['1', '2']),
      ];
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: fixedColumns,
            rows: fixedRows,
            horizontalScroll: true,
          ),
        ),
      );
      expect(
        find.descendant(
          of: find.byType(HandDrawnTable),
          matching: find.byType(IntrinsicWidth),
        ),
        findsNothing,
      );
    });

    testWidgets('scroll content width equals sum of column widths', (
      tester,
    ) async {
      const fixedColumns = [
        HandDrawnTableColumn(header: 'A', width: 100),
        HandDrawnTableColumn(header: 'B', width: 150),
        HandDrawnTableColumn(header: 'C', width: 200),
      ];
      const fixedRows = [
        HandDrawnTableRow(cells: ['1', '2', '3']),
      ];
      await tester.pumpWidget(
        _wrap(
          const HandDrawnTable(
            columns: fixedColumns,
            rows: fixedRows,
            horizontalScroll: true,
          ),
        ),
      );
      // Walk from SingleChildScrollView to its direct SizedBox child.
      final sizedBox = tester.widget<SizedBox>(
        find
            .descendant(
              of: find.byType(SingleChildScrollView),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.width, 450.0); // 100 + 150 + 200
    });
  });
}
