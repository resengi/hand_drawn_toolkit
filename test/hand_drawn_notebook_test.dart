import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

void main() {
  group('HandDrawnNotebook', () {
    Widget buildApp({required Widget child}) {
      return MaterialApp(home: Scaffold(body: child));
    }

    group('rendering', () {
      testWidgets('renders without error with required params', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnNotebook(
              lineHeight: 28.0,
              child: Text('Hello'),
            ),
          ),
        );

        expect(find.byType(HandDrawnNotebook), findsOneWidget);
      });

      testWidgets('renders child content', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnNotebook(
              lineHeight: 28.0,
              child: Text('Notebook text'),
            ),
          ),
        );

        expect(find.text('Notebook text'), findsOneWidget);
      });

      testWidgets('uses CustomPaint with painter (not foregroundPainter)', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnNotebook(
              lineHeight: 28.0,
              child: SizedBox(height: 100),
            ),
          ),
        );

        final customPaintFinder = find.descendant(
          of: find.byType(HandDrawnNotebook),
          matching: find.byType(CustomPaint),
        );
        // Find the first CustomPaint — the one HandDrawnNotebook creates.
        final customPaint = tester.widget<CustomPaint>(customPaintFinder.first);
        expect(customPaint.painter, isNotNull);
        expect(customPaint.foregroundPainter, isNull);
      });

      testWidgets('inner SizedBox has width double.infinity', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnNotebook(
              lineHeight: 28.0,
              child: Text('Test'),
            ),
          ),
        );

        final sizedBoxFinder = find.descendant(
          of: find.byType(HandDrawnNotebook),
          matching: find.byType(SizedBox),
        );
        final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
        expect(sizedBox.width, double.infinity);
      });
    });

    group('bottom padding', () {
      testWidgets('default strokeWidth produces correct bottom padding', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnNotebook(
              lineHeight: 28.0,
              child: Text('Test'),
            ),
          ),
        );

        final paddingFinder = find.descendant(
          of: find.byType(HandDrawnNotebook),
          matching: find.byType(Padding),
        );
        final padding = tester.widget<Padding>(paddingFinder);
        expect(
          padding.padding,
          const EdgeInsets.only(bottom: HandDrawnDefaults.notebookStrokeWidth),
        );
      });

      testWidgets('custom strokeWidth changes bottom padding', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnNotebook(
              lineHeight: 28.0,
              strokeWidth: 2.5,
              child: Text('Test'),
            ),
          ),
        );

        final paddingFinder = find.descendant(
          of: find.byType(HandDrawnNotebook),
          matching: find.byType(Padding),
        );
        final padding = tester.widget<Padding>(paddingFinder);
        expect(padding.padding, const EdgeInsets.only(bottom: 2.5));
      });
    });

    group('parameter acceptance', () {
      testWidgets('accepts all optional parameters without error', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnNotebook(
              lineHeight: 32.0,
              lineColor: Colors.red,
              strokeWidth: 2.0,
              seed: 99,
              uniformLines: false,
              irregularity: 3.0,
              segments: 50,
              child: SizedBox(height: 200),
            ),
          ),
        );

        expect(find.byType(HandDrawnNotebook), findsOneWidget);
      });
    });

    group('defaults', () {
      test('notebookStrokeWidth is 1.0', () {
        expect(HandDrawnDefaults.notebookStrokeWidth, 1.0);
      });

      test('notebookIrregularity is 1.0', () {
        expect(HandDrawnDefaults.notebookIrregularity, 1.0);
      });

      test('notebookSegments is 30', () {
        expect(HandDrawnDefaults.notebookSegments, 30);
      });
    });
  });
}
