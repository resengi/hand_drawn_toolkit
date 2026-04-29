import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

void main() {
  group('HandDrawnStatusSquare', () {
    group('rendering', () {
      testWidgets('renders without error with only required params', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(const HandDrawnStatusSquare(color: Colors.black)),
        );

        expect(find.byType(HandDrawnStatusSquare), findsOneWidget);
      });

      testWidgets('contains a CustomPaint descendant', (tester) async {
        await tester.pumpWidget(
          testApp(const HandDrawnStatusSquare(color: Colors.black)),
        );

        final customPaintFinder = find.descendant(
          of: find.byType(HandDrawnStatusSquare),
          matching: find.byType(CustomPaint),
        );
        expect(customPaintFinder, findsOneWidget);
      });

      testWidgets('renders a SizedBox at the default size', (tester) async {
        await tester.pumpWidget(
          testApp(const HandDrawnStatusSquare(color: Colors.black)),
        );

        final sizedBoxFinder = find.descendant(
          of: find.byType(HandDrawnStatusSquare),
          matching: find.byType(SizedBox),
        );
        final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
        expect(sizedBox.width, HandDrawnDefaults.statusSquareSize);
        expect(sizedBox.height, HandDrawnDefaults.statusSquareSize);
      });

      testWidgets('applies scaleFactor correctly', (tester) async {
        await tester.pumpWidget(
          testApp(
            const HandDrawnStatusSquare(color: Colors.black, scaleFactor: 2.0),
          ),
        );

        final sizedBoxFinder = find.descendant(
          of: find.byType(HandDrawnStatusSquare),
          matching: find.byType(SizedBox),
        );
        final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
        expect(sizedBox.width, HandDrawnDefaults.statusSquareSize * 2.0);
        expect(sizedBox.height, HandDrawnDefaults.statusSquareSize * 2.0);
      });

      testWidgets('custom size is respected', (tester) async {
        await tester.pumpWidget(
          testApp(const HandDrawnStatusSquare(color: Colors.black, size: 20.0)),
        );

        final sizedBoxFinder = find.descendant(
          of: find.byType(HandDrawnStatusSquare),
          matching: find.byType(SizedBox),
        );
        final sizedBox = tester.widget<SizedBox>(sizedBoxFinder);
        expect(sizedBox.width, 20.0);
        expect(sizedBox.height, 20.0);
      });
    });

    group('tap behavior', () {
      testWidgets('no GestureDetector when onTap is null', (tester) async {
        await tester.pumpWidget(
          testApp(const HandDrawnStatusSquare(color: Colors.black)),
        );

        final detectorFinder = find.descendant(
          of: find.byType(HandDrawnStatusSquare),
          matching: find.byType(GestureDetector),
        );
        expect(detectorFinder, findsNothing);
      });

      testWidgets('GestureDetector present and fires when onTap provided', (
        tester,
      ) async {
        var tapped = false;
        await tester.pumpWidget(
          testApp(
            HandDrawnStatusSquare(
              color: Colors.black,
              onTap: () => tapped = true,
            ),
          ),
        );

        final detectorFinder = find.descendant(
          of: find.byType(HandDrawnStatusSquare),
          matching: find.byType(GestureDetector),
        );
        expect(detectorFinder, findsOneWidget);

        await tester.tap(find.byType(HandDrawnStatusSquare));
        expect(tapped, isTrue);
      });

      testWidgets('tap target includes Padding around the square', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(HandDrawnStatusSquare(color: Colors.black, onTap: () {})),
        );

        final paddingFinder = find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Padding),
        );
        expect(paddingFinder, findsOneWidget);

        final padding = tester.widget<Padding>(paddingFinder);
        expect(
          padding.padding,
          const EdgeInsets.all(HandDrawnDefaults.statusSquareTapPadding),
        );
      });

      testWidgets('custom tapPadding is applied', (tester) async {
        await tester.pumpWidget(
          testApp(
            HandDrawnStatusSquare(
              color: Colors.black,
              tapPadding: 12.0,
              onTap: () {},
            ),
          ),
        );

        final paddingFinder = find.descendant(
          of: find.byType(GestureDetector),
          matching: find.byType(Padding),
        );
        final padding = tester.widget<Padding>(paddingFinder);
        expect(padding.padding, const EdgeInsets.all(12.0));
      });
    });

    group('defaults', () {
      test('statusSquareSize is 14.0', () {
        expect(HandDrawnDefaults.statusSquareSize, 14.0);
      });

      test('statusSquareStrokeWidth is 1.5', () {
        expect(HandDrawnDefaults.statusSquareStrokeWidth, 1.5);
      });

      test('statusSquareIndicatorStrokeWidth is 2.0', () {
        expect(HandDrawnDefaults.statusSquareIndicatorStrokeWidth, 2.0);
      });

      test('statusSquareTapPadding is 6.0', () {
        expect(HandDrawnDefaults.statusSquareTapPadding, 6.0);
      });

      test('statusSquareIrregularity is 1.0', () {
        expect(HandDrawnDefaults.statusSquareIrregularity, 1.0);
      });

      test('statusSquareSegments is 6', () {
        expect(HandDrawnDefaults.statusSquareSegments, 6);
      });
    });
  });
}
