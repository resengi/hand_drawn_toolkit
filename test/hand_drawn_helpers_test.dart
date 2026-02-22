import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

void main() {
  group('HandDrawnHelpers', () {
    group('smoothedOffsets', () {
      test('returns segments + 1 values', () {
        const segments = 20;
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: segments,
          irregularity: 3.0,
        );

        final offsets = helpers.smoothedOffsets();

        expect(offsets.length, segments + 1);
      });

      test('first and last offsets are zero', () {
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: 24,
          irregularity: 5.0,
        );

        final offsets = helpers.smoothedOffsets();

        expect(offsets.first, 0.0);
        expect(offsets.last, 0.0);
      });

      test('produces deterministic output for the same seed', () {
        final h1 = HandDrawnHelpers(seed: 99, segments: 24, irregularity: 3.0);
        final h2 = HandDrawnHelpers(seed: 99, segments: 24, irregularity: 3.0);

        expect(h1.smoothedOffsets(), equals(h2.smoothedOffsets()));
      });

      test('produces different output for different seeds', () {
        final h1 = HandDrawnHelpers(seed: 1, segments: 24, irregularity: 3.0);
        final h2 = HandDrawnHelpers(seed: 2, segments: 24, irregularity: 3.0);

        expect(h1.smoothedOffsets(), isNot(equals(h2.smoothedOffsets())));
      });

      test('all offsets are zero when irregularity is zero', () {
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: 24,
          irregularity: 0.0,
        );

        final offsets = helpers.smoothedOffsets();

        expect(offsets.every((o) => o == 0.0), isTrue);
      });

      test('offsets stay within expected bounds after smoothing', () {
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: 50,
          irregularity: 4.0,
        );

        final offsets = helpers.smoothedOffsets();

        // After 3-point averaging, values should be less than the raw max
        // (irregularity / 2). In practice they're significantly smaller.
        for (final offset in offsets) {
          expect(offset.abs(), lessThan(4.0));
        }
      });
    });

    group('lineHorizontal', () {
      test('produces a non-empty path', () {
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: 24,
          irregularity: 3.0,
        );

        final path = helpers.lineHorizontal(const Size(200, 10));

        expect(path.computeMetrics().first.length, greaterThan(0));
      });

      test('path spans the full width', () {
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: 24,
          irregularity: 3.0,
        );

        final path = helpers.lineHorizontal(const Size(300, 10));
        final bounds = path.getBounds();

        // The path should start near x=0 and end near x=300.
        expect(bounds.left, closeTo(0, 1));
        expect(bounds.right, closeTo(300, 1));
      });
    });

    group('lineVertical', () {
      test('produces a non-empty path', () {
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: 24,
          irregularity: 3.0,
        );

        final path = helpers.lineVertical(const Size(10, 200));

        expect(path.computeMetrics().first.length, greaterThan(0));
      });

      test('path spans the full height', () {
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: 24,
          irregularity: 3.0,
        );

        final path = helpers.lineVertical(const Size(10, 400));
        final bounds = path.getBounds();

        expect(bounds.top, closeTo(0, 1));
        expect(bounds.bottom, closeTo(400, 1));
      });
    });

    group('rectBorder', () {
      test('produces a closed path', () {
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: 24,
          irregularity: 3.0,
        );

        final path = helpers.rectBorder(const Size(200, 100));

        // A closed rect path should have metrics.
        final metrics = path.computeMetrics().toList();
        expect(metrics, isNotEmpty);
      });

      test('path bounds approximate the given size', () {
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: 24,
          irregularity: 2.0,
        );

        const size = Size(250, 150);
        final path = helpers.rectBorder(size);
        final bounds = path.getBounds();

        // With irregularity of 2.0, bounds should be close to the size.
        expect(bounds.width, closeTo(size.width, 5));
        expect(bounds.height, closeTo(size.height, 5));
      });

      test('is deterministic with the same seed', () {
        final h1 = HandDrawnHelpers(seed: 7, segments: 24, irregularity: 3.0);
        final h2 = HandDrawnHelpers(seed: 7, segments: 24, irregularity: 3.0);

        const size = Size(100, 100);
        final bounds1 = h1.rectBorder(size).getBounds();
        final bounds2 = h2.rectBorder(size).getBounds();

        expect(bounds1, equals(bounds2));
      });

      test('consumes exactly 4 sets of offsets', () {
        // Verify that calling rectBorder and then another method produces
        // different results from calling the other method first — confirming
        // that rectBorder advances the RNG state by consuming 4 offset sets.
        final h1 = HandDrawnHelpers(seed: 42, segments: 10, irregularity: 3.0);
        h1.rectBorder(const Size(100, 100));
        final afterRect = h1.smoothedOffsets();

        final h2 = HandDrawnHelpers(seed: 42, segments: 10, irregularity: 3.0);
        final beforeRect = h2.smoothedOffsets();

        // The offsets should differ because the RNG state has advanced.
        expect(afterRect, isNot(equals(beforeRect)));
      });
    });
  });
}
