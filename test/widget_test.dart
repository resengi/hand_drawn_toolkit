import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

/// Finds [CustomPaint] widgets that use a [HandDrawnLinePainter] as either
/// their `painter` or `foregroundPainter`. This avoids collisions with
/// framework-internal [CustomPaint] widgets from [Scaffold], [Material], etc.
Finder findHandDrawnPaint() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        (widget.painter is HandDrawnLinePainter ||
            widget.foregroundPainter is HandDrawnLinePainter),
  );
}

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

      // Find the Container that is a descendant of HandDrawnContainer.
      final containerFinder = find.descendant(
        of: find.byType(HandDrawnContainer),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder);
      expect(container.color, Colors.red);
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

      final containerFinder = find.descendant(
        of: find.byType(HandDrawnContainer),
        matching: find.byType(Container),
      );
      final container = tester.widget<Container>(containerFinder);
      expect(container.padding, customPadding);
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
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HandDrawnDivider())),
      );

      final customPaint = tester.widget<CustomPaint>(findHandDrawnPaint());
      final painter = customPaint.painter! as HandDrawnLinePainter;

      expect(painter.strokeWidth, HandDrawnDefaults.dividerThickness);
      expect(painter.irregularity, HandDrawnDefaults.dividerIrregularity);
      expect(painter.segments, HandDrawnDefaults.dividerSegments);
    });
  });
}
