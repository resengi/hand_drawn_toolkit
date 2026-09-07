import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

void main() {
  group('HandDrawnContainer', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HandDrawnContainer(child: Text('Hello'))),
        ),
      );

      expect(find.text('Hello'), findsOneWidget);
    });

    testWidgets('applies background color', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandDrawnContainer(
              backgroundColor: Colors.red,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(findHandDrawnPaint());
      final painter = customPaint.painter! as HandDrawnFillPainter;
      expect(painter.color, Colors.red);
    });

    testWidgets('fills the layout box by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandDrawnContainer(child: SizedBox(width: 100, height: 100)),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(findHandDrawnPaint());
      final painter = customPaint.painter! as HandDrawnFillPainter;
      expect(painter.extent, HandDrawnFillExtent.standardShape);
    });

    testWidgets('passes fill parameters to the fill painter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandDrawnContainer(
              fillExtent: HandDrawnFillExtent.strokeInnerEdge,
              strokeWidth: 4.0,
              irregularity: 5.0,
              segments: 30,
              seed: 99,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(findHandDrawnPaint());
      final painter = customPaint.painter! as HandDrawnFillPainter;
      expect(painter.extent, HandDrawnFillExtent.strokeInnerEdge);
      expect(painter.strokeWidth, 4.0);
      expect(painter.irregularity, 5.0);
      expect(painter.segments, 30);
      expect(painter.seed, 99);
    });

    testWidgets('fill and border painters share one path definition', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandDrawnContainer(
              fillExtent: HandDrawnFillExtent.strokeCenter,
              irregularity: 5.0,
              segments: 30,
              seed: 99,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(findHandDrawnPaint());
      final fill = customPaint.painter! as HandDrawnFillPainter;
      final border = customPaint.foregroundPainter! as HandDrawnLinePainter;
      expect(fill.buildPath, border.buildPath);
      expect(fill.inset, border.inset);
      expect(fill.seed, border.seed);
      expect(fill.segments, border.segments);
      expect(fill.irregularity, border.irregularity);
    });

    testWidgets('uses a CustomPaint with foregroundPainter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandDrawnContainer(child: SizedBox(width: 100, height: 100)),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(findHandDrawnPaint());
      expect(customPaint.foregroundPainter, isA<HandDrawnLinePainter>());
    });

    testWidgets('applies custom padding', (tester) async {
      const customPadding = EdgeInsets.all(8);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandDrawnContainer(
              padding: customPadding,
              child: SizedBox(width: 50, height: 50),
            ),
          ),
        ),
      );

      final paddingFinder = find.descendant(
        of: find.byType(HandDrawnContainer),
        matching: find.byType(Padding),
      );
      final padding = tester.widget<Padding>(paddingFinder);
      expect(padding.padding, customPadding);
    });

    testWidgets('passes parameters to painter', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandDrawnContainer(
              strokeWidth: 4.0,
              irregularity: 5.0,
              segments: 30,
              seed: 99,
              borderOpacity: 0.5,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(findHandDrawnPaint());
      final painter = customPaint.foregroundPainter! as HandDrawnLinePainter;

      expect(painter.strokeWidth, 4.0);
      expect(painter.irregularity, 5.0);
      expect(painter.segments, 30);
      expect(painter.seed, 99);
    });

    testWidgets('borderOpacity multiplies strokeColor alpha', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandDrawnContainer(
              strokeColor: Color(0x80000000), // alpha 0.5
              borderOpacity: 0.5,
              child: SizedBox(width: 100, height: 100),
            ),
          ),
        ),
      );

      final customPaint = tester.widget<CustomPaint>(findHandDrawnPaint());
      final painter = customPaint.foregroundPainter! as HandDrawnLinePainter;
      // 0.5 (strokeColor alpha) * 0.5 (borderOpacity) = 0.25
      expect(painter.color.a, closeTo(0.25, 0.01));
    });

    testWidgets('equivalent rebuilds do not repaint either painter', (
      tester,
    ) async {
      // A runtime value keeps the container non-const, so each build below
      // constructs a distinct instance with equal fields.
      final seed = tester.binding.hashCode & 0xff;
      Widget container() => MaterialApp(
        home: Scaffold(
          body: HandDrawnContainer(
            seed: seed,
            child: const SizedBox(width: 100, height: 100),
          ),
        ),
      );

      await tester.pumpWidget(container());
      var paint = tester.widget<CustomPaint>(findHandDrawnPaint());
      final oldFill = paint.painter! as HandDrawnFillPainter;
      final oldBorder = paint.foregroundPainter! as HandDrawnLinePainter;

      await tester.pumpWidget(container());
      paint = tester.widget<CustomPaint>(findHandDrawnPaint());
      final newFill = paint.painter! as HandDrawnFillPainter;
      final newBorder = paint.foregroundPainter! as HandDrawnLinePainter;

      expect(newFill.shouldRepaint(oldFill), isFalse);
      expect(newBorder.shouldRepaint(oldBorder), isFalse);
    });
  });

  group('HandDrawnDivider', () {
    testWidgets('renders a horizontal divider by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: Center(child: HandDrawnDivider())),
        ),
      );

      expect(findHandDrawnPaint(), findsOneWidget);
    });

    testWidgets('renders a vertical divider', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                height: 100,
                child: HandDrawnDivider(direction: Axis.vertical, height: 100),
              ),
            ),
          ),
        ),
      );

      expect(findHandDrawnPaint(), findsOneWidget);
    });

    testWidgets('applies indent and endIndent for horizontal', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HandDrawnDivider(indent: 16, endIndent: 16)),
        ),
      );

      final paddingFinder = find.descendant(
        of: find.byType(HandDrawnDivider),
        matching: find.byType(Padding),
      );
      final padding = tester.widget<Padding>(paddingFinder);
      expect(padding.padding, const EdgeInsets.only(left: 16, right: 16));
    });

    testWidgets('applies indent and endIndent for vertical', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              height: 200,
              child: HandDrawnDivider(
                direction: Axis.vertical,
                height: 200,
                indent: 10,
                endIndent: 10,
              ),
            ),
          ),
        ),
      );

      final paddingFinder = find.descendant(
        of: find.byType(HandDrawnDivider),
        matching: find.byType(Padding),
      );
      final padding = tester.widget<Padding>(paddingFinder);
      expect(padding.padding, const EdgeInsets.only(top: 10, bottom: 10));
    });

    testWidgets('uses default HandDrawnDefaults for divider', (tester) async {
      await tester.pumpWidget(testApp(const HandDrawnDivider()));

      final customPaint = tester.widget<CustomPaint>(findHandDrawnPaint());
      final painter = customPaint.painter! as HandDrawnLinePainter;

      expect(painter.strokeWidth, HandDrawnDefaults.dividerThickness);
      expect(painter.irregularity, HandDrawnDefaults.dividerIrregularity);
      expect(painter.segments, HandDrawnDefaults.dividerSegments);
    });
  });
}
