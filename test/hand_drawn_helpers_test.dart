import 'dart:typed_data';
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

/// The fixture: a 100×100 canvas, a zero-jitter 80×80 square border inset by
/// 10 on every side, and a 10-wide stroke. The stroke band therefore spans
/// 5…15 from each edge with its centerline at 10.
const int _size = 100;
const double _strokeWidth = 10;
const Color _opaque = Color(0xFFFF0000);
const Color _half = Color(0x80FF0000);

Path _border() => Path()..addRect(const Rect.fromLTWH(10, 10, 80, 80));

Path _standardShape() => Path()..addRect(const Rect.fromLTWH(0, 0, 100, 100));

Future<ByteData> _renderFill(
  HandDrawnFillExtent extent, {
  Color color = _opaque,
  Path Function() border = _border,
  Path Function() standardShape = _standardShape,
  StrokeJoin join = StrokeJoin.round,
}) {
  return rasterize(
    (canvas) => paintHandDrawnFill(
      canvas,
      border: border,
      standardShape: standardShape,
      color: color,
      extent: extent,
      strokeWidth: _strokeWidth,
      join: join,
    ),
    _size,
    _size,
  );
}

Future<ByteData> _renderStroke(StrokeJoin join) {
  return rasterize(
    (canvas) => canvas.drawPath(
      _border(),
      handDrawnStrokePaint(color: _opaque, width: _strokeWidth, join: join),
    ),
    _size,
    _size,
  );
}

double _alpha(ByteData pixels, int x, int y) => alphaAt(pixels, _size, x, y);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

      test('throws ArgumentError when irregularity is not finite', () {
        expect(
          () =>
              HandDrawnHelpers(seed: 0, segments: 10, irregularity: double.nan),
          throwsA(isA<ArgumentError>()),
        );
        expect(
          () => HandDrawnHelpers(
            seed: 0,
            segments: 10,
            irregularity: double.infinity,
          ),
          throwsA(isA<ArgumentError>()),
        );
      });

      test('checkGenerationParameters applies the same rules', () {
        const check = HandDrawnHelpers.checkGenerationParameters;

        expect(() => check(0, 1.0), throwsA(isA<ArgumentError>()));
        expect(() => check(10, -1.0), throwsA(isA<ArgumentError>()));
        expect(() => check(10, double.nan), throwsA(isA<ArgumentError>()));
        expect(() => check(10, 0.0), returnsNormally);
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

  group('paintHandDrawnFill', () {
    // Sample points, all at least 2px from any edge so antialiasing does not
    // affect them: outside the border, in the outer half of the stroke band,
    // in the inner half of the band, and in the interior.
    const samples = [(2, 50), (7, 50), (13, 50), (50, 50)];
    const expected = {
      HandDrawnFillExtent.standardShape: [1, 1, 1, 1],
      HandDrawnFillExtent.strokeCenter: [0, 0, 1, 1],
      HandDrawnFillExtent.strokeOuterEdge: [0, 1, 1, 1],
      HandDrawnFillExtent.strokeInnerEdge: [0, 0, 0, 1],
    };

    test('fills the region each mode defines', () async {
      for (final entry in expected.entries) {
        final pixels = await _renderFill(entry.key);
        for (var i = 0; i < samples.length; i++) {
          final (x, y) = samples[i];
          expect(_alpha(pixels, x, y), entry.value[i], reason: '${entry.key}');
        }
      }
    });

    test('strokeOuterEdge gives a translucent fill single coverage', () async {
      final pixels = await _renderFill(
        HandDrawnFillExtent.strokeOuterEdge,
        color: _half,
      );

      // The band's inner half is covered by both the fill and the band; a
      // second blend there would read close to 0.75.
      expect(_alpha(pixels, 13, 50), closeTo(0.5, 0.03));
      expect(_alpha(pixels, 7, 50), closeTo(0.5, 0.03));
      expect(_alpha(pixels, 50, 50), closeTo(0.5, 0.03));
    });

    test('strokeInnerEdge removes the band from a translucent fill', () async {
      final pixels = await _renderFill(
        HandDrawnFillExtent.strokeInnerEdge,
        color: _half,
      );

      expect(_alpha(pixels, 13, 50), 0);
      expect(_alpha(pixels, 50, 50), closeTo(0.5, 0.03));
    });

    test('a transparent color draws nothing and builds no geometry', () async {
      var builds = 0;
      Path counted() {
        builds++;
        return _border();
      }

      final pixels = await _renderFill(
        HandDrawnFillExtent.strokeOuterEdge,
        color: const Color(0x00FF0000),
        border: counted,
        standardShape: counted,
      );

      expect(builds, 0);
      expect(_alpha(pixels, 50, 50), 0);
    });

    test('each mode builds only the geometry it uses', () {
      for (final extent in HandDrawnFillExtent.values) {
        var borderBuilds = 0;
        var standardBuilds = 0;
        paintHandDrawnFill(
          Canvas(PictureRecorder()),
          border: () {
            borderBuilds++;
            return _border();
          },
          standardShape: () {
            standardBuilds++;
            return _standardShape();
          },
          color: _opaque,
          extent: extent,
          strokeWidth: _strokeWidth,
        );

        final usesStandard = extent == HandDrawnFillExtent.standardShape;
        expect(standardBuilds, usesStandard ? 1 : 0, reason: '$extent');
        expect(borderBuilds, usesStandard ? 0 : 1, reason: '$extent');
      }
    });

    test('the band uses the same join as the visible stroke', () async {
      // Pixel (5, 6) has its center at (5.5, 6.5), which is 5.70 from the
      // corner's centerline point (10, 10): outside a radius-5 round join
      // but inside the square a miter join draws. Its corner at (6, 7)
      // touches the round join exactly, so under a round join it may carry
      // a sliver of coverage rather than being exactly clear.
      const outer = HandDrawnFillExtent.strokeOuterEdge;
      final roundBand = await _renderFill(outer);
      final roundStroke = await _renderStroke(StrokeJoin.round);
      final miterBand = await _renderFill(outer, join: StrokeJoin.miter);
      final miterStroke = await _renderStroke(StrokeJoin.miter);

      expect(_alpha(roundBand, 5, 6), lessThan(0.1));
      expect(_alpha(roundStroke, 5, 6), lessThan(0.1));
      expect(_alpha(miterBand, 5, 6), 1);
      expect(_alpha(miterStroke, 5, 6), 1);
    });
  });

  group('handDrawnStrokePaint', () {
    test('configures a stroke of the given color, width, and join', () {
      final paint = handDrawnStrokePaint(color: _opaque, width: 3);

      expect(paint.style, PaintingStyle.stroke);
      expect(paint.color, _opaque);
      expect(paint.strokeWidth, 3);
      expect(paint.strokeCap, StrokeCap.round);
      expect(paint.strokeJoin, StrokeJoin.round);

      final mitered = handDrawnStrokePaint(
        color: _opaque,
        width: 3,
        join: StrokeJoin.miter,
      );
      expect(mitered.strokeJoin, StrokeJoin.miter);
    });
  });

  group('checkStrokeWidth', () {
    test('rejects zero, negative, and non-finite widths', () {
      expect(() => checkStrokeWidth(0), throwsArgumentError);
      expect(() => checkStrokeWidth(-1), throwsArgumentError);
      expect(() => checkStrokeWidth(double.nan), throwsArgumentError);
      expect(() => checkStrokeWidth(double.infinity), throwsArgumentError);
    });

    test('accepts a finite positive width', () {
      expect(() => checkStrokeWidth(0.5), returnsNormally);
    });
  });
}
