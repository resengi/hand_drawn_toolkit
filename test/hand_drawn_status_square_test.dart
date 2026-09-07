import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

/// The square's own painter, from the pumped widget.
CustomPainter _painter(WidgetTester tester) {
  return tester
      .widget<CustomPaint>(
        find.descendant(
          of: find.byType(HandDrawnStatusSquare),
          matching: find.byType(CustomPaint),
        ),
      )
      .painter!;
}

/// Rasterizes the square's painter at [size]×[size].
Future<ByteData> _rasterizeSquare(WidgetTester tester, int size) {
  final painter = _painter(tester);
  final canvasSize = Size(size.toDouble(), size.toDouble());
  return rasterize((canvas) => painter.paint(canvas, canvasSize), size, size);
}

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

    group('fill extent', () {
      // A 40px square with an 8px stroke: the border is inset by 4, so the
      // stroke band spans 0…8 from each edge with its centerline at 4.
      // Pixel (6, 20) lies in the band's inner half.
      const size = 40;
      const translucentRed = Color(0x80FF0000);

      testWidgets('defaults to strokeCenter', (tester) async {
        await tester.pumpWidget(
          testApp(const HandDrawnStatusSquare(color: Colors.black)),
        );

        final square = tester.widget<HandDrawnStatusSquare>(
          find.byType(HandDrawnStatusSquare),
        );
        expect(square.fillExtent, HandDrawnFillExtent.strokeCenter);
      });

      testWidgets('strokeCenter fills under the inner half of the stroke', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(
            const HandDrawnStatusSquare(
              color: translucentRed,
              isFilled: true,
              irregularity: 0,
              size: 40,
              strokeWidth: 8,
            ),
          ),
        );

        await tester.runAsync(() async {
          final pixels = await _rasterizeSquare(tester, size);
          // Half-alpha fill under a half-alpha stroke.
          expect(alphaAt(pixels, size, 6, 20), closeTo(0.75, 0.03));
        });
      });

      testWidgets('strokeInnerEdge stops the fill at the inner edge', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(
            const HandDrawnStatusSquare(
              color: translucentRed,
              isFilled: true,
              irregularity: 0,
              size: 40,
              strokeWidth: 8,
              fillExtent: HandDrawnFillExtent.strokeInnerEdge,
            ),
          ),
        );

        await tester.runAsync(() async {
          final pixels = await _rasterizeSquare(tester, size);
          // Only the half-alpha stroke covers the band.
          expect(alphaAt(pixels, size, 6, 20), closeTo(0.5, 0.03));
        });
      });

      testWidgets('a change to fillExtent alone triggers a repaint', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(
            const HandDrawnStatusSquare(
              color: Colors.black,
              fillExtent: HandDrawnFillExtent.strokeCenter,
            ),
          ),
        );
        final before = _painter(tester);

        await tester.pumpWidget(
          testApp(
            const HandDrawnStatusSquare(
              color: Colors.black,
              fillExtent: HandDrawnFillExtent.strokeOuterEdge,
            ),
          ),
        );
        final after = _painter(tester);

        expect(after.shouldRepaint(before), isTrue);
      });

      testWidgets('the painter rejects invalid rendering parameters', (
        tester,
      ) async {
        // The widget's own checks are debug asserts that these values pass;
        // the painter's constructor is the release-safe boundary.
        await tester.pumpWidget(
          testApp(
            const HandDrawnStatusSquare(
              color: Colors.black,
              strokeWidth: double.infinity,
            ),
          ),
        );
        expect(tester.takeException(), isArgumentError);

        await tester.pumpWidget(
          testApp(
            const HandDrawnStatusSquare(
              color: Colors.black,
              irregularity: double.infinity,
            ),
          ),
        );
        expect(tester.takeException(), isArgumentError);
      });

      testWidgets('the indicator renders on an unfilled square', (
        tester,
      ) async {
        await tester.pumpWidget(
          testApp(
            const HandDrawnStatusSquare(
              color: Colors.red,
              isFilled: false,
              indicator: StatusIndicator.dash,
              indicatorColor: Color(0xFF00FF00),
              irregularity: 0,
              size: 40,
              strokeWidth: 8,
            ),
          ),
        );

        await tester.runAsync(() async {
          final pixels = await _rasterizeSquare(tester, size);
          // The dash runs horizontally through the square's center.
          expect(channelAt(pixels, size, 20, 20, 0), 0);
          expect(channelAt(pixels, size, 20, 20, 1), 255);
          expect(channelAt(pixels, size, 20, 20, 3), 255);
        });
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
