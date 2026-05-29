import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

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
        testApp(const HandDrawnTable(columns: _columns, rows: [])),
      );
      expect(find.text('No data'), findsOneWidget);
    });

    testWidgets('shows custom empty message', (tester) async {
      await tester.pumpWidget(
        testApp(
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
        testApp(const HandDrawnTable(columns: _columns, rows: [])),
      );
      expect(find.byType(HandDrawnContainer), findsOneWidget);
    });

    testWidgets('shows title in empty state when title is provided', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
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
        testApp(
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
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
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
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Score'), findsOneWidget);
    });

    testWidgets('renders header divider', (tester) async {
      await tester.pumpWidget(
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      expect(find.byType(HandDrawnDivider), findsAtLeastNWidgets(1));
    });
  });

  // ── Title ────────────────────────────────────────────────────────────

  group('HandDrawnTable title', () {
    testWidgets('renders title when provided', (tester) async {
      await tester.pumpWidget(
        testApp(
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
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      // Only cell texts and headers should be present, no title widget.
      expect(find.text('Leaderboard'), findsNothing);
    });
  });

  // ── Row dividers ─────────────────────────────────────────────────────

  group('HandDrawnTable row dividers', () {
    testWidgets('shows no row dividers by default', (tester) async {
      await tester.pumpWidget(
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      // Only the header divider should exist.
      expect(find.byType(HandDrawnDivider), findsOneWidget);
    });

    testWidgets('shows row dividers when enabled', (tester) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            rowDividers: TableDividerStyle(),
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
        testApp(
          const HandDrawnTable(
            columns: _columns,
            rows: singleRow,
            rowDividers: TableDividerStyle(),
          ),
        ),
      );
      // Only header divider, no row divider for a single row.
      expect(find.byType(HandDrawnDivider), findsOneWidget);
    });

    testWidgets('non-uniform row dividers have distinct seeds', (tester) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            rowDividers: TableDividerStyle(seed: 10, uniform: false),
          ),
        ),
      );
      final dividers = tester
          .widgetList<HandDrawnDivider>(find.byType(HandDrawnDivider))
          .toList();
      // Header divider + 2 row dividers = 3 total.
      expect(dividers.length, 3);
      // Header uses base seed; row dividers use seed + 1, seed + 2.
      expect(dividers[0].seed, 10); // header
      expect(dividers[1].seed, 11); // row divider 0
      expect(dividers[2].seed, 12); // row divider 1
    });
  });

  // ── Column dividers ─────────────────────────────────────────────────

  group('HandDrawnTable column dividers', () {
    testWidgets('shows no column dividers by default', (tester) async {
      await tester.pumpWidget(
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      final verticalDividers = find.byWidgetPredicate(
        (w) => w is HandDrawnDivider && w.direction == Axis.vertical,
      );
      expect(verticalDividers, findsNothing);
    });

    testWidgets('shows column dividers when enabled', (tester) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            columnDividers: TableDividerStyle(),
          ),
        ),
      );
      // 2 columns → 1 boundary → 1 vertical divider.
      final verticalDividers = find.byWidgetPredicate(
        (w) => w is HandDrawnDivider && w.direction == Axis.vertical,
      );
      expect(verticalDividers, findsOneWidget);
    });

    testWidgets('non-uniform column dividers have distinct seeds', (
      tester,
    ) async {
      const threeColumns = [
        HandDrawnTableColumn(header: 'A', flex: 1),
        HandDrawnTableColumn(header: 'B', flex: 1),
        HandDrawnTableColumn(header: 'C', flex: 1),
      ];
      const threeColRows = [
        HandDrawnTableRow(cells: ['1', '2', '3']),
      ];
      await tester.pumpWidget(
        testApp(
          const HandDrawnTable(
            columns: threeColumns,
            rows: threeColRows,
            columnDividers: TableDividerStyle(seed: 20, uniform: false),
          ),
        ),
      );
      final verticals = tester
          .widgetList<HandDrawnDivider>(
            find.byWidgetPredicate(
              (w) => w is HandDrawnDivider && w.direction == Axis.vertical,
            ),
          )
          .toList();
      // 3 columns → 2 boundaries with seeds 21, 22.
      expect(verticals.length, 2);
      expect(verticals[0].seed, 21);
      expect(verticals[1].seed, 22);
    });

    // A vertical divider's drawing area is wider than the ink line itself
    // so that the jittered stroke does not clip. If each divider is placed
    // with its left edge on the column boundary, the visible line sits
    // right of the boundary. Centering is correct when the spacing between
    // two adjacent dividers equals the width of the column between them,
    // regardless of the specific cross-axis padding used.
    testWidgets('vertical dividers are centered on column boundaries', (
      tester,
    ) async {
      const middleColumnWidth = 120.0;
      const columns = [
        HandDrawnTableColumn(header: 'A', width: 100),
        HandDrawnTableColumn(header: 'B', width: middleColumnWidth),
        HandDrawnTableColumn(header: 'C', width: 100),
      ];
      const rows = [
        HandDrawnTableRow(cells: ['1', '2', '3']),
      ];

      await tester.pumpWidget(
        testApp(
          const SizedBox(
            width: 600,
            child: HandDrawnTable(
              columns: columns,
              rows: rows,
              columnDividers: TableDividerStyle(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final dividerParents = tester
          .widgetList<Positioned>(find.byType(Positioned))
          .where((p) {
            return find
                .descendant(
                  of: find.byWidget(p),
                  matching: find.byType(HandDrawnDivider),
                )
                .evaluate()
                .isNotEmpty;
          })
          .toList();

      expect(
        dividerParents,
        hasLength(2),
        reason: 'Three columns yield two internal boundaries.',
      );

      // If both dividers are centered on their respective boundaries, the
      // spacing between their positions equals the middle column's width.
      // This holds regardless of the divider's cross-axis padding policy.
      final spacing = dividerParents[1].left! - dividerParents[0].left!;
      expect(spacing, closeTo(middleColumnWidth, 0.01));
    });

    testWidgets('vertical dividers do not extend into the title band', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const SizedBox(
            width: 400,
            child: HandDrawnTable(
              title: 'Leaderboard',
              columns: _columns,
              rows: _rows,
              columnDividers: TableDividerStyle(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final titleBottomY = tester.getBottomLeft(find.text('Leaderboard')).dy;

      final verticalDividers = tester.widgetList<HandDrawnDivider>(
        find.byWidgetPredicate(
          (w) => w is HandDrawnDivider && w.direction == Axis.vertical,
        ),
      );
      expect(verticalDividers, isNotEmpty);

      for (final divider in verticalDividers) {
        final dividerTopY = tester.getTopLeft(find.byWidget(divider)).dy;
        expect(
          dividerTopY,
          greaterThanOrEqualTo(titleBottomY),
          reason:
              'Column divider top ($dividerTopY) must sit at or below the '
              'title bottom ($titleBottomY).',
        );
      }
    });

    testWidgets('title and column dividers compose without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnTable(
            title: 'Quarterly Revenue Report 2024',
            columns: _columns,
            rows: _rows,
            columnDividers: TableDividerStyle(),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('Quarterly Revenue Report 2024'), findsOneWidget);
    });
  });

  // ── Divider color propagation ───────────────────────────────────────

  group('HandDrawnTable divider color', () {
    const customColor = Color(0xFFAA3344);

    testWidgets('row divider color propagates from TableDividerStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            rowDividers: TableDividerStyle(color: customColor),
          ),
        ),
      );
      // Header divider + N-1 row dividers — every one should carry the
      // configured color.
      final dividers = tester
          .widgetList<HandDrawnDivider>(find.byType(HandDrawnDivider))
          .toList();
      expect(dividers, isNotEmpty);
      for (final d in dividers) {
        expect(d.color, customColor);
      }
    });

    testWidgets('column divider color propagates from TableDividerStyle', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            columnDividers: TableDividerStyle(color: customColor),
          ),
        ),
      );
      final verticals = tester
          .widgetList<HandDrawnDivider>(
            find.byWidgetPredicate(
              (w) => w is HandDrawnDivider && w.direction == Axis.vertical,
            ),
          )
          .toList();
      expect(verticals, isNotEmpty);
      for (final d in verticals) {
        expect(d.color, customColor);
      }
    });
  });

  // ── Narrow-width layout (flex-space clamp) ──────────────────────────

  // When fixed-width columns together exceed the available width, the
  // remaining flex space would go negative. Without clamping, later
  // column boundaries march backward and produce invalid geometry.
  // The contract verified here is: no internal geometry failure occurs.
  // The Row inside may legitimately emit a rendering overflow warning,
  // which is the consumer's responsibility, not a package defect.
  //
  // Every captured error must be a framework render overflow (identified
  // by the stable "overflowed" wording Flutter uses for RenderFlex
  // overflow). Absence of errors is also acceptable — overflow is
  // permitted, not required.
  group('HandDrawnTable narrow-width layout', () {
    testWidgets('fixed widths exceeding available width produce no '
        'internal geometry errors', (tester) async {
      final errors = await captureFlutterErrors(() async {
        await tester.pumpWidget(
          testApp(
            const SizedBox(
              width: 100,
              child: HandDrawnTable(
                columns: [
                  HandDrawnTableColumn(header: 'X', width: 150),
                  HandDrawnTableColumn(header: 'Y', width: 150),
                ],
                rows: [
                  HandDrawnTableRow(cells: ['a', 'b']),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      for (final e in errors) {
        expect(
          e.exception.toString(),
          contains('overflowed'),
          reason: 'Unexpected non-overflow error:\n$e',
        );
      }
    });

    testWidgets('fixed column larger than width with flex sibling produces '
        'no internal geometry errors', (tester) async {
      final errors = await captureFlutterErrors(() async {
        await tester.pumpWidget(
          testApp(
            const SizedBox(
              width: 50,
              child: HandDrawnTable(
                columns: [
                  HandDrawnTableColumn(header: 'Fixed', width: 200),
                  HandDrawnTableColumn(header: 'Flex', flex: 1),
                ],
                rows: [
                  HandDrawnTableRow(cells: ['a', 'b']),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
      });

      for (final e in errors) {
        expect(
          e.exception.toString(),
          contains('overflowed'),
          reason: 'Unexpected non-overflow error:\n$e',
        );
      }
    });
  });

  // ── Container styling ───────────────────────────────────────────────

  group('HandDrawnTable container styling', () {
    testWidgets('forwards styling params to HandDrawnContainer', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            seed: 99,
            irregularity: 5.0,
            strokeWidth: 3.0,
            strokeColor: Color(0xFFFF0000),
            backgroundColor: Color(0xFF00FF00),
          ),
        ),
      );
      final container = tester.widget<HandDrawnContainer>(
        find.byType(HandDrawnContainer),
      );
      expect(container.seed, 99);
      expect(container.irregularity, 5.0);
      expect(container.strokeWidth, 3.0);
      expect(container.strokeColor, const Color(0xFFFF0000));
      expect(container.backgroundColor, const Color(0xFF00FF00));
    });
  });

  // ── Highlighted rows ─────────────────────────────────────────────────

  group('HandDrawnTable highlighting', () {
    testWidgets('highlighted row gets tinted background Container', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
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
        testApp(
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
        testApp(HandDrawnTable(columns: _columns, rows: mismatchedRows)),
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
        testApp(HandDrawnTable(columns: _columns, rows: mismatchedRows)),
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
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
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
        testApp(
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
        testApp(HandDrawnTable(columns: _columns, rows: rows)),
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
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
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
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
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
        testApp(
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
        testApp(
          const HandDrawnTable(columns: _columns, rows: _rows, rowPadding: 12),
        ),
      );
      expect(find.text('Alice'), findsOneWidget);
    });

    testWidgets('accepts custom titleStyle', (tester) async {
      const style = TextStyle(fontSize: 20, color: Color(0xFFFF0000));
      await tester.pumpWidget(
        testApp(
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
        testApp(
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
        testApp(
          const HandDrawnTable(columns: _columns, rows: [], emptyStyle: style),
        ),
      );
      final emptyText = tester.widget<Text>(find.text('No data'));
      expect(emptyText.style?.fontSize, 18);
    });

    testWidgets('accepts custom titleBottomPadding', (tester) async {
      await tester.pumpWidget(
        testApp(
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

  // ── Text overflow configurability ───────────────────────────────────

  group('HandDrawnTable text overflow', () {
    testWidgets('uses ellipsis by default', (tester) async {
      await tester.pumpWidget(
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      final texts = tester.widgetList<Text>(find.byType(Text));
      final cellTexts = texts.where((t) => t.overflow == TextOverflow.ellipsis);
      expect(cellTexts, isNotEmpty);
    });

    testWidgets('respects custom textOverflow', (tester) async {
      await tester.pumpWidget(
        testApp(
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

    testWidgets('cells default to single line, no soft wrap', (tester) async {
      await tester.pumpWidget(
        testApp(const HandDrawnTable(columns: _columns, rows: _rows)),
      );
      final cellTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.maxLines != null)
          .toList();
      expect(cellTexts, isNotEmpty);
      for (final t in cellTexts) {
        expect(t.maxLines, 1);
        expect(t.softWrap, isFalse);
      }
    });

    testWidgets('cells respect custom cellMaxLines and softWrap', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          const HandDrawnTable(
            columns: _columns,
            rows: _rows,
            cellMaxLines: 3,
            softWrap: true,
          ),
        ),
      );
      final cellTexts = tester
          .widgetList<Text>(find.byType(Text))
          .where((t) => t.maxLines == 3)
          .toList();
      expect(cellTexts, isNotEmpty);
      for (final t in cellTexts) {
        expect(t.softWrap, isTrue);
      }
    });
  });

  // ── Horizontal scrolling ────────────────────────────────────────────

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
        testApp(
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
        testApp(
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
        testApp(
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
        testApp(
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
