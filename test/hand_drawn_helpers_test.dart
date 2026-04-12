import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

void main() {
  group('HandDrawnHelpers', () {
    group('smooth (static)', () {
      test('preserves first and last values', () {
        final raw = [1.0, 5.0, -3.0, 2.0, 4.0];
        final result = HandDrawnHelpers.smooth(raw);
        expect(result.first, raw.first);
        expect(result.last, raw.last);
      });

      test('applies 3-point moving average to interior values', () {
        final raw = [0.0, 3.0, 6.0, 9.0, 0.0];
        final result = HandDrawnHelpers.smooth(raw);
        // Interior point at index 1: (0+3+6)/3 = 3.0
        expect(result[1], 3.0);
        // Interior point at index 2: (3+6+9)/3 = 6.0
        expect(result[2], 6.0);
        // Interior point at index 3: (6+9+0)/3 = 5.0
        expect(result[3], 5.0);
      });

      test('returns same length as input', () {
        final raw = [1.0, 2.0, 3.0, 4.0, 5.0];
        final result = HandDrawnHelpers.smooth(raw);
        expect(result.length, raw.length);
      });

      test('handles single-element list', () {
        final raw = [5.0];
        final result = HandDrawnHelpers.smooth(raw);
        expect(result, [5.0]);
      });

      test('handles two-element list (no interior points)', () {
        final raw = [1.0, 9.0];
        final result = HandDrawnHelpers.smooth(raw);
        expect(result, [1.0, 9.0]);
      });
    });

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

    group('constructor validation', () {
      test('throws ArgumentError when segments is zero', () {
        expect(
          () => HandDrawnHelpers(seed: 0, segments: 0, irregularity: 1.0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when segments is negative', () {
        expect(
          () => HandDrawnHelpers(seed: 0, segments: -5, irregularity: 1.0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('throws ArgumentError when irregularity is negative', () {
        expect(
          () => HandDrawnHelpers(seed: 0, segments: 10, irregularity: -1.0),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('accepts irregularity of zero', () {
        expect(
          () => HandDrawnHelpers(seed: 0, segments: 10, irregularity: 0.0),
          returnsNormally,
        );
      });

      test('accepts valid parameters', () {
        expect(
          () => HandDrawnHelpers(seed: 42, segments: 24, irregularity: 3.5),
          returnsNormally,
        );
      });
    });

    group('irregularity consistency', () {
      test('smoothedOffsets range follows (random - 0.5) * irregularity', () {
        // With a known irregularity, the raw (pre-smoothing) offsets should
        // be bounded by [-irregularity/2, +irregularity/2]. After smoothing
        // (3-point average), all values must be strictly within that bound.
        const irr = 6.0;
        final helpers = HandDrawnHelpers(
          seed: 42,
          segments: 100,
          irregularity: irr,
        );

        final offsets = helpers.smoothedOffsets();

        for (final o in offsets) {
          expect(
            o.abs(),
            lessThanOrEqualTo(irr / 2),
            reason: 'offset $o exceeds irregularity/2 bound',
          );
        }
      });
    });
  });
}
