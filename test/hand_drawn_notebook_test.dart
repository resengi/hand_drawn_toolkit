import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

void main() {
  group('HandDrawnNotebook', () {
    group('content', () {
      testWidgets('renders its child', (tester) async {
        await tester.pumpWidget(
          testApp(const HandDrawnNotebook(child: Text('Paper content'))),
        );

        expect(find.text('Paper content'), findsOneWidget);
      });

      testWidgets('accepts all parameters without error', (tester) async {
        await tester.pumpWidget(
          testApp(
            const HandDrawnNotebook(
              lineHeight: 32,
              lineColor: Color(0xFF112233),
              strokeWidth: 2,
              seed: 9,
              uniformLines: false,
              irregularity: 3,
              segments: 40,
              paperColor: Color(0xFFEFEFEF),
              child: SizedBox(height: 80),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        expect(find.byType(HandDrawnNotebook), findsOneWidget);
      });
    });

    group('paper', () {
      testWidgets('paints paper with the default color', (tester) async {
        await tester.pumpWidget(
          const HandDrawnNotebook(child: SizedBox(height: 50)),
        );

        final coloredBox = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(HandDrawnNotebook),
            matching: find.byType(ColoredBox),
          ),
        );
        expect(coloredBox.color, const Color(0xFFFCFAF5));
      });

      testWidgets('paints paper with a custom color', (tester) async {
        await tester.pumpWidget(
          const HandDrawnNotebook(
            paperColor: Color(0xFF010203),
            child: SizedBox(height: 50),
          ),
        );

        final coloredBox = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(HandDrawnNotebook),
            matching: find.byType(ColoredBox),
          ),
        );
        expect(coloredBox.color, const Color(0xFF010203));
      });

      testWidgets('paints no paper when paperColor is null', (tester) async {
        await tester.pumpWidget(
          const HandDrawnNotebook(
            paperColor: null,
            child: SizedBox(height: 50),
          ),
        );

        expect(
          find.descendant(
            of: find.byType(HandDrawnNotebook),
            matching: find.byType(ColoredBox),
          ),
          findsNothing,
        );
      });

      testWidgets('paints no ruled lines', (tester) async {
        await tester.pumpWidget(
          const HandDrawnNotebook(child: SizedBox(height: 100)),
        );

        expect(
          find.descendant(
            of: find.byType(HandDrawnNotebook),
            matching: find.byType(CustomPaint),
          ),
          findsNothing,
        );
      });
    });

    group('published style', () {
      testWidgets('publishes the default style when no parameters are given', (
        tester,
      ) async {
        NotebookStyle? captured;
        await tester.pumpWidget(
          HandDrawnNotebook(
            child: Builder(
              builder: (context) {
                captured = NotebookScope.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(captured, const NotebookStyle());
      });

      testWidgets('publishes a style assembled from its parameters', (
        tester,
      ) async {
        NotebookStyle? captured;
        await tester.pumpWidget(
          HandDrawnNotebook(
            lineHeight: 30,
            lineColor: const Color(0xFF112233),
            strokeWidth: 2,
            seed: 7,
            uniformLines: false,
            irregularity: 3,
            segments: 40,
            child: Builder(
              builder: (context) {
                captured = NotebookScope.maybeOf(context);
                return const SizedBox();
              },
            ),
          ),
        );

        expect(
          captured,
          const NotebookStyle(
            lineHeight: 30,
            lineColor: Color(0xFF112233),
            strokeWidth: 2,
            seed: 7,
            uniformLines: false,
            irregularity: 3,
            segments: 40,
          ),
        );
      });
    });

    group('parameter validation', () {
      test('asserts on non-positive lineHeight', () {
        expect(
          () => HandDrawnNotebook(lineHeight: 0, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      test('asserts on non-positive strokeWidth', () {
        expect(
          () => HandDrawnNotebook(strokeWidth: 0, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      test('asserts on non-positive segments', () {
        expect(
          () => HandDrawnNotebook(segments: 0, child: const SizedBox()),
          throwsAssertionError,
        );
      });

      test('asserts on negative irregularity', () {
        expect(
          () => HandDrawnNotebook(irregularity: -1, child: const SizedBox()),
          throwsAssertionError,
        );
      });
    });
  });
}
