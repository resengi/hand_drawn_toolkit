import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

void main() {
  group('NotebookStyle', () {
    test('has sensible defaults', () {
      const style = NotebookStyle();
      expect(style.lineHeight, 28.0);
      expect(style.lineColor, HandDrawnDefaults.notebookLineColor);
      expect(style.strokeWidth, HandDrawnDefaults.notebookStrokeWidth);
      expect(style.seed, HandDrawnDefaults.seed);
      expect(style.uniformLines, isTrue);
      expect(style.irregularity, HandDrawnDefaults.notebookIrregularity);
      expect(style.segments, HandDrawnDefaults.notebookSegments);
    });

    group('validation', () {
      test('asserts on non-positive lineHeight', () {
        expect(() => NotebookStyle(lineHeight: 0), throwsAssertionError);
      });

      test('asserts on non-positive strokeWidth', () {
        expect(() => NotebookStyle(strokeWidth: 0), throwsAssertionError);
      });

      test('asserts on non-positive segments', () {
        expect(() => NotebookStyle(segments: 0), throwsAssertionError);
      });

      test('asserts on negative irregularity', () {
        expect(() => NotebookStyle(irregularity: -1), throwsAssertionError);
      });
    });

    group('copyWith', () {
      test('replaces only the given fields', () {
        const original = NotebookStyle(lineHeight: 20, seed: 5);
        final updated = original.copyWith(lineHeight: 40);

        expect(updated.lineHeight, 40);
        expect(updated.seed, 5);
        expect(updated.lineColor, original.lineColor);
        expect(updated.strokeWidth, original.strokeWidth);
        expect(updated.uniformLines, original.uniformLines);
        expect(updated.irregularity, original.irregularity);
        expect(updated.segments, original.segments);
      });

      test('with no arguments equals the original', () {
        const original = NotebookStyle(lineHeight: 22, uniformLines: false);
        expect(original.copyWith(), original);
      });
    });

    group('equality', () {
      test('styles with identical values are equal', () {
        expect(
          const NotebookStyle(lineHeight: 30),
          const NotebookStyle(lineHeight: 30),
        );
      });

      test('styles with different values are not equal', () {
        expect(
          const NotebookStyle(lineHeight: 30),
          isNot(const NotebookStyle(lineHeight: 31)),
        );
      });

      test('equal styles have equal hashCodes', () {
        expect(
          const NotebookStyle(lineHeight: 30).hashCode,
          const NotebookStyle(lineHeight: 30).hashCode,
        );
      });
    });
  });

  group('NotebookScope', () {
    testWidgets('maybeOf returns the published style', (tester) async {
      NotebookStyle? captured;
      await tester.pumpWidget(
        NotebookScope(
          style: const NotebookStyle(lineHeight: 32),
          child: Builder(
            builder: (context) {
              captured = NotebookScope.maybeOf(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, const NotebookStyle(lineHeight: 32));
    });

    testWidgets('maybeOf returns null when no scope is present', (
      tester,
    ) async {
      NotebookStyle? captured;
      var built = false;
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            built = true;
            captured = NotebookScope.maybeOf(context);
            return const SizedBox();
          },
        ),
      );

      expect(built, isTrue);
      expect(captured, isNull);
    });

    testWidgets('of returns the published style', (tester) async {
      NotebookStyle? captured;
      await tester.pumpWidget(
        NotebookScope(
          style: const NotebookStyle(lineHeight: 24),
          child: Builder(
            builder: (context) {
              captured = NotebookScope.of(context);
              return const SizedBox();
            },
          ),
        ),
      );

      expect(captured, const NotebookStyle(lineHeight: 24));
    });

    testWidgets('of throws when no scope is present', (tester) async {
      await tester.pumpWidget(
        Builder(
          builder: (context) {
            NotebookScope.of(context);
            return const SizedBox();
          },
        ),
      );

      expect(tester.takeException(), isA<FlutterError>());
    });

    test('updateShouldNotify is true when the style changes', () {
      const oldScope = NotebookScope(
        style: NotebookStyle(lineHeight: 20),
        child: SizedBox(),
      );
      const newScope = NotebookScope(
        style: NotebookStyle(lineHeight: 30),
        child: SizedBox(),
      );

      expect(newScope.updateShouldNotify(oldScope), isTrue);
    });

    test('updateShouldNotify is false when the style is unchanged', () {
      const oldScope = NotebookScope(
        style: NotebookStyle(lineHeight: 20),
        child: SizedBox(),
      );
      const newScope = NotebookScope(
        style: NotebookStyle(lineHeight: 20),
        child: SizedBox(),
      );

      expect(newScope.updateShouldNotify(oldScope), isFalse);
    });
  });
}
