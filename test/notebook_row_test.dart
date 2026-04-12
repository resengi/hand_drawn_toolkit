import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

void main() {
  group('NotebookRow', () {
    Widget buildApp({required Widget child}) {
      return MaterialApp(home: Scaffold(body: child));
    }

    group('layout', () {
      testWidgets('renders child content', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const NotebookRow(
              lineHeight: 28.0,
              child: Text('Row content'),
            ),
          ),
        );

        expect(find.text('Row content'), findsOneWidget);
      });

      testWidgets('height equals lineHeight when rowSpan is 1', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const NotebookRow(lineHeight: 28.0, child: Text('Test')),
          ),
        );

        final sizedBoxFinder = find.descendant(
          of: find.byType(NotebookRow),
          matching: find.byType(SizedBox),
        );
        final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
        expect(sizedBox.height, 28.0);
      });

      testWidgets('rowSpan multiplies the height', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const NotebookRow(
              lineHeight: 28.0,
              rowSpan: 3,
              child: Text('Test'),
            ),
          ),
        );

        final sizedBoxFinder = find.descendant(
          of: find.byType(NotebookRow),
          matching: find.byType(SizedBox),
        );
        final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
        expect(sizedBox.height, 84.0);
      });

      testWidgets('child is center-left aligned', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const NotebookRow(lineHeight: 28.0, child: Text('Test')),
          ),
        );

        final alignFinder = find.descendant(
          of: find.byType(NotebookRow),
          matching: find.byType(Align),
        );
        final align = tester.widget<Align>(alignFinder);
        expect(align.alignment, Alignment.centerLeft);
      });
    });

    group('padding', () {
      testWidgets('no Padding widget when padding is null', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const NotebookRow(lineHeight: 28.0, child: Text('Test')),
          ),
        );

        final paddingFinder = find.descendant(
          of: find.byType(NotebookRow),
          matching: find.byType(Padding),
        );
        expect(paddingFinder, findsNothing);
      });

      testWidgets('Padding widget present when padding is provided', (
        tester,
      ) async {
        const edgeInsets = EdgeInsets.symmetric(horizontal: 16);
        await tester.pumpWidget(
          buildApp(
            child: const NotebookRow(
              lineHeight: 28.0,
              padding: edgeInsets,
              child: Text('Test'),
            ),
          ),
        );

        final paddingFinder = find.descendant(
          of: find.byType(NotebookRow),
          matching: find.byType(Padding),
        );
        expect(paddingFinder, findsOneWidget);
        final padding = tester.widget<Padding>(paddingFinder);
        expect(padding.padding, edgeInsets);
      });
      // Vertical padding breaks the row-height contract. The assertion must
      // cover both EdgeInsets and EdgeInsetsDirectional; a type-specific
      // check would let directional vertical padding slip through.
      testWidgets('asserts on EdgeInsets with vertical padding', (
        tester,
      ) async {
        final errors = await captureFlutterErrors(() async {
          await tester.pumpWidget(
            buildApp(
              child: const NotebookRow(
                lineHeight: 28.0,
                padding: EdgeInsets.only(bottom: 4),
                child: Text('Test'),
              ),
            ),
          );
        });

        expect(
          errors.any((e) => e.exception.toString().contains('horizontal-only')),
          isTrue,
        );
      });

      testWidgets('asserts on EdgeInsetsDirectional with vertical padding', (
        tester,
      ) async {
        final errors = await captureFlutterErrors(() async {
          await tester.pumpWidget(
            buildApp(
              child: const NotebookRow(
                lineHeight: 28.0,
                padding: EdgeInsetsDirectional.only(top: 8),
                child: Text('Test'),
              ),
            ),
          );
        });

        expect(
          errors.any((e) => e.exception.toString().contains('horizontal-only')),
          isTrue,
        );
      });

      testWidgets('accepts horizontal-only EdgeInsetsDirectional', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(
            child: const NotebookRow(
              lineHeight: 28.0,
              padding: EdgeInsetsDirectional.only(start: 16, end: 16),
              child: Text('Test'),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    });
  });

  group('NotebookSnappedBlock', () {
    Widget buildApp({required Widget child}) {
      return MaterialApp(home: Scaffold(body: child));
    }

    group('layout', () {
      testWidgets('renders child content', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const NotebookSnappedBlock(
              lineHeight: 28.0,
              child: Text('Block content'),
            ),
          ),
        );

        expect(find.text('Block content'), findsOneWidget);
      });

      testWidgets('uses ConstrainedBox with correct minHeight', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const NotebookSnappedBlock(
              lineHeight: 28.0,
              minRows: 3,
              child: SizedBox(height: 10),
            ),
          ),
        );

        final constrainedFinder = find.descendant(
          of: find.byType(NotebookSnappedBlock),
          matching: find.byType(ConstrainedBox),
        );
        final constrained = tester.widget<ConstrainedBox>(constrainedFinder);
        expect(constrained.constraints.minHeight, 84.0);
      });

      testWidgets('default minRows is 1', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const NotebookSnappedBlock(
              lineHeight: 28.0,
              child: SizedBox(height: 10),
            ),
          ),
        );

        final constrainedFinder = find.descendant(
          of: find.byType(NotebookSnappedBlock),
          matching: find.byType(ConstrainedBox),
        );
        final constrained = tester.widget<ConstrainedBox>(constrainedFinder);
        expect(constrained.constraints.minHeight, 28.0);
      });
    });

    group('padding', () {
      testWidgets('no Padding widget when padding is null', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const NotebookSnappedBlock(
              lineHeight: 28.0,
              child: Text('Test'),
            ),
          ),
        );

        final paddingFinder = find.descendant(
          of: find.byType(NotebookSnappedBlock),
          matching: find.byType(Padding),
        );
        expect(paddingFinder, findsNothing);
      });

      testWidgets('Padding widget present when padding is provided', (
        tester,
      ) async {
        const edgeInsets = EdgeInsets.symmetric(horizontal: 12);
        await tester.pumpWidget(
          buildApp(
            child: const NotebookSnappedBlock(
              lineHeight: 28.0,
              padding: edgeInsets,
              child: Text('Test'),
            ),
          ),
        );

        final paddingFinder = find.descendant(
          of: find.byType(NotebookSnappedBlock),
          matching: find.byType(Padding),
        );
        expect(paddingFinder, findsOneWidget);
        final padding = tester.widget<Padding>(paddingFinder);
        expect(padding.padding, edgeInsets);
      });
    });
  });

  group('snapHeightToRows', () {
    test('snaps up to next row', () {
      expect(snapHeightToRows(33.0, 32.0), 64.0);
    });

    test('exact fit is unchanged', () {
      expect(snapHeightToRows(64.0, 32.0), 64.0);
    });

    test('zero returns zero', () {
      expect(snapHeightToRows(0.0, 32.0), 0.0);
    });

    test('negative returns zero', () {
      expect(snapHeightToRows(-5.0, 32.0), 0.0);
    });

    test('small fraction snaps to one row', () {
      expect(snapHeightToRows(0.1, 32.0), 32.0);
    });
  });

  group('rowsForHeight', () {
    test('partial row rounds up', () {
      expect(rowsForHeight(33.0, 32.0), 2);
    });

    test('exact fit returns correct count', () {
      expect(rowsForHeight(64.0, 32.0), 2);
    });

    test('zero returns zero', () {
      expect(rowsForHeight(0.0, 32.0), 0);
    });

    test('negative returns zero', () {
      expect(rowsForHeight(-5.0, 32.0), 0);
    });

    test('throws ArgumentError when rowHeight is zero', () {
      expect(() => rowsForHeight(100.0, 0.0), throwsA(isA<ArgumentError>()));
    });

    test('throws ArgumentError when rowHeight is negative', () {
      expect(() => rowsForHeight(100.0, -10.0), throwsA(isA<ArgumentError>()));
    });
  });

  group('snapHeightToRows validation', () {
    test('throws ArgumentError when rowHeight is zero', () {
      expect(() => snapHeightToRows(100.0, 0.0), throwsA(isA<ArgumentError>()));
    });

    test('throws ArgumentError when rowHeight is negative', () {
      expect(
        () => snapHeightToRows(100.0, -10.0),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('accepts valid rowHeight', () {
      expect(() => snapHeightToRows(100.0, 32.0), returnsNormally);
    });
  });
}
