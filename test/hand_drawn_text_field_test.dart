import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

/// Finds [CustomPaint] widgets that use a [HandDrawnLinePainter] as either
/// their `painter` or `foregroundPainter`. Duplicated from `widget_test.dart`
/// to keep test files independent.
Finder findHandDrawnPaint() {
  return find.byWidgetPredicate(
    (widget) =>
        widget is CustomPaint &&
        (widget.painter is HandDrawnLinePainter ||
            widget.foregroundPainter is HandDrawnLinePainter),
  );
}

void main() {
  group('HandDrawnTextField', () {
    Widget buildApp({required Widget child}) {
      return MaterialApp(home: Scaffold(body: child));
    }

    group('rendering', () {
      testWidgets('renders without error with no params', (tester) async {
        await tester.pumpWidget(buildApp(child: const HandDrawnTextField()));

        expect(find.byType(HandDrawnTextField), findsOneWidget);
      });

      testWidgets('contains a TextField descendant', (tester) async {
        await tester.pumpWidget(buildApp(child: const HandDrawnTextField()));

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        expect(textFieldFinder, findsOneWidget);
      });

      testWidgets('contains a HandDrawnDivider descendant', (tester) async {
        await tester.pumpWidget(buildApp(child: const HandDrawnTextField()));

        // The HandDrawnDivider internally uses a HandDrawnLinePainter.
        expect(findHandDrawnPaint(), findsOneWidget);
      });

      testWidgets('applies the correct backgroundColor', (tester) async {
        const testColor = Color(0xFFAABBCC);
        await tester.pumpWidget(
          buildApp(child: const HandDrawnTextField(backgroundColor: testColor)),
        );

        final containerFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(Container),
        );
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.color, testColor);
      });

      testWidgets('applies the correct borderRadius', (tester) async {
        await tester.pumpWidget(
          buildApp(child: const HandDrawnTextField(borderRadius: 12.0)),
        );

        final containerFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(Container),
        );
        final container = tester.widget<Container>(containerFinder);
        final decoration = container.decoration! as BoxDecoration;
        expect(decoration.borderRadius, BorderRadius.circular(12.0));
      });
    });

    group('text styling', () {
      testWidgets('uses textColor and fontSize when no style provided', (
        tester,
      ) async {
        const testColor = Color(0xFF112233);
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnTextField(
              textColor: testColor,
              fontSize: 20.0,
            ),
          ),
        );

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.style!.color, testColor);
        expect(textField.style!.fontSize, 20.0);
      });

      testWidgets('custom style overrides textColor and fontSize', (
        tester,
      ) async {
        const customStyle = TextStyle(
          fontSize: 24.0,
          color: Colors.red,
          fontWeight: FontWeight.bold,
        );
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnTextField(
              style: customStyle,
              textColor: Colors.blue, // Should be ignored.
              fontSize: 12.0, // Should be ignored.
            ),
          ),
        );

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.style, customStyle);
      });

      testWidgets('hintColor is applied to the hint style', (tester) async {
        const testHintColor = Color(0xFF445566);
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnTextField(
              hintText: 'Placeholder',
              hintColor: testHintColor,
            ),
          ),
        );

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.decoration!.hintStyle!.color, testHintColor);
      });

      testWidgets('fontSize applies to both text style and hint style', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(child: const HandDrawnTextField(fontSize: 18.0)),
        );

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.style!.fontSize, 18.0);
        expect(textField.decoration!.hintStyle!.fontSize, 18.0);
      });

      testWidgets('hintText appears in the InputDecoration', (tester) async {
        await tester.pumpWidget(
          buildApp(child: const HandDrawnTextField(hintText: 'Type here')),
        );

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.decoration!.hintText, 'Type here');
      });
    });

    group('divider configuration', () {
      testWidgets('passes dividerColor to HandDrawnDivider', (tester) async {
        const testColor = Color(0xFFDDEEFF);
        await tester.pumpWidget(
          buildApp(child: const HandDrawnTextField(dividerColor: testColor)),
        );

        final dividerFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(HandDrawnDivider),
        );
        final divider = tester.widget<HandDrawnDivider>(dividerFinder);
        expect(divider.color, testColor);
      });

      testWidgets('passes dividerThickness to HandDrawnDivider', (
        tester,
      ) async {
        await tester.pumpWidget(
          buildApp(child: const HandDrawnTextField(dividerThickness: 2.5)),
        );

        final dividerFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(HandDrawnDivider),
        );
        final divider = tester.widget<HandDrawnDivider>(dividerFinder);
        expect(divider.thickness, 2.5);
      });

      testWidgets('passes seed to HandDrawnDivider', (tester) async {
        await tester.pumpWidget(
          buildApp(child: const HandDrawnTextField(seed: 99)),
        );

        final dividerFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(HandDrawnDivider),
        );
        final divider = tester.widget<HandDrawnDivider>(dividerFinder);
        expect(divider.seed, 99);
      });
    });

    group('TextField passthrough', () {
      testWidgets('forwards controller', (tester) async {
        final controller = TextEditingController(text: 'initial');
        await tester.pumpWidget(
          buildApp(child: HandDrawnTextField(controller: controller)),
        );

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.controller, controller);
      });

      testWidgets('forwards focusNode', (tester) async {
        final focusNode = FocusNode();
        await tester.pumpWidget(
          buildApp(child: HandDrawnTextField(focusNode: focusNode)),
        );

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.focusNode, focusNode);
      });

      testWidgets('forwards maxLines with default of 1', (tester) async {
        await tester.pumpWidget(buildApp(child: const HandDrawnTextField()));

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.maxLines, 1);
      });

      testWidgets('forwards autofocus with default of false', (tester) async {
        await tester.pumpWidget(buildApp(child: const HandDrawnTextField()));

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.autofocus, isFalse);
      });

      testWidgets('forwards textCapitalization', (tester) async {
        await tester.pumpWidget(
          buildApp(
            child: const HandDrawnTextField(
              textCapitalization: TextCapitalization.words,
            ),
          ),
        );

        final textFieldFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(TextField),
        );
        final textField = tester.widget<TextField>(textFieldFinder);
        expect(textField.textCapitalization, TextCapitalization.words);
      });

      testWidgets('onChanged fires when text changes', (tester) async {
        String? changed;
        await tester.pumpWidget(
          buildApp(child: HandDrawnTextField(onChanged: (v) => changed = v)),
        );

        await tester.enterText(find.byType(TextField), 'hello');
        expect(changed, 'hello');
      });

      testWidgets('onSubmitted fires on submission', (tester) async {
        String? submitted;
        await tester.pumpWidget(
          buildApp(
            child: HandDrawnTextField(onSubmitted: (v) => submitted = v),
          ),
        );

        await tester.enterText(find.byType(TextField), 'done');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        expect(submitted, 'done');
      });
    });

    group('padding', () {
      testWidgets('uses default padding', (tester) async {
        await tester.pumpWidget(buildApp(child: const HandDrawnTextField()));

        final containerFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(Container),
        );
        final container = tester.widget<Container>(containerFinder);
        expect(
          container.padding,
          const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        );
      });

      testWidgets('custom padding is applied', (tester) async {
        const customPadding = EdgeInsets.all(16);
        await tester.pumpWidget(
          buildApp(child: const HandDrawnTextField(padding: customPadding)),
        );

        final containerFinder = find.descendant(
          of: find.byType(HandDrawnTextField),
          matching: find.byType(Container),
        );
        final container = tester.widget<Container>(containerFinder);
        expect(container.padding, customPadding);
      });
    });

    group('defaults', () {
      test('textFieldFontSize is 16.0', () {
        expect(HandDrawnDefaults.textFieldFontSize, 16.0);
      });

      test('textFieldBorderRadius is 8.0', () {
        expect(HandDrawnDefaults.textFieldBorderRadius, 8.0);
      });

      test('textFieldDividerThickness is 1.0', () {
        expect(HandDrawnDefaults.textFieldDividerThickness, 1.0);
      });
    });
  });

  // ── TextField passthroughs ──────────────────────────────────────────

  group('HandDrawnTextField passthroughs', () {
    testWidgets('enabled: false produces disabled TextField', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HandDrawnTextField(enabled: false)),
        ),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.enabled, isFalse);
    });

    testWidgets('readOnly: true produces read-only TextField', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HandDrawnTextField(readOnly: true)),
        ),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.readOnly, isTrue);
    });

    testWidgets('keyboardType is forwarded', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: HandDrawnTextField(keyboardType: TextInputType.number),
          ),
        ),
      );
      final tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.keyboardType, TextInputType.number);
    });
  });
}
