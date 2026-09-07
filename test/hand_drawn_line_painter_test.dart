import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

/// Shared default [buildPath] callback for test factories.
///
/// A top-level function is a stable reference, so painters built with it
/// compare equal on `buildPath`; an anonymous closure is a new object per
/// invocation.
Path _defaultBuildPath(Size size, HandDrawnHelpers h) => h.rectBorder(size);

Path _horizontalPath(Size size, HandDrawnHelpers h) => h.lineHorizontal(size);

Path _otherRectPath(Size size, HandDrawnHelpers h) => h.rectBorder(size);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HandDrawnLinePainter', () {
    HandDrawnLinePainter createPainter({
      Color color = Colors.black,
      double strokeWidth = 2.0,
      double irregularity = 3.0,
      int seed = 42,
      int segments = 24,
      double inset = 0,
      Path Function(Size, HandDrawnHelpers)? buildPath,
    }) {
      return HandDrawnLinePainter(
        color: color,
        strokeWidth: strokeWidth,
        irregularity: irregularity,
        seed: seed,
        segments: segments,
        inset: inset,
        buildPath: buildPath ?? _defaultBuildPath,
      );
    }

    group('shouldRepaint', () {
      test('returns false for identical parameters', () {
        final p1 = createPainter();
        final p2 = createPainter();

        expect(p1.shouldRepaint(p2), isFalse);
      });

      test('returns true when color changes', () {
        final p1 = createPainter();
        final p2 = createPainter(color: Colors.red);

        expect(p2.shouldRepaint(p1), isTrue);
      });

      test('returns true when strokeWidth changes', () {
        final p1 = createPainter();
        final p2 = createPainter(strokeWidth: 3.0);

        expect(p2.shouldRepaint(p1), isTrue);
      });

      test('returns true when irregularity changes', () {
        final p1 = createPainter();
        final p2 = createPainter(irregularity: 5.0);

        expect(p2.shouldRepaint(p1), isTrue);
      });

      test('returns true when seed changes', () {
        final p1 = createPainter();
        final p2 = createPainter(seed: 99);

        expect(p2.shouldRepaint(p1), isTrue);
      });

      test('returns true when segments changes', () {
        final p1 = createPainter();
        final p2 = createPainter(segments: 48);

        expect(p2.shouldRepaint(p1), isTrue);
      });

      test('returns true when inset changes', () {
        final p1 = createPainter();
        final p2 = createPainter(inset: 1);

        expect(p2.shouldRepaint(p1), isTrue);
      });

      test('returns true when buildPath differs', () {
        final p1 = createPainter(buildPath: _defaultBuildPath);
        final p2 = createPainter(buildPath: _horizontalPath);

        expect(p2.shouldRepaint(p1), isTrue);
      });

      test('returns false when buildPath is the same reference', () {
        final p1 = createPainter(buildPath: _defaultBuildPath);
        final p2 = createPainter(buildPath: _defaultBuildPath);

        expect(p2.shouldRepaint(p1), isFalse);
      });
    });

    group('validation', () {
      test('rejects a non-positive strokeWidth', () {
        expect(() => createPainter(strokeWidth: 0), throwsArgumentError);
        expect(() => createPainter(strokeWidth: -1), throwsArgumentError);
      });

      test('rejects a non-finite strokeWidth', () {
        expect(
          () => createPainter(strokeWidth: double.nan),
          throwsArgumentError,
        );
        expect(
          () => createPainter(strokeWidth: double.infinity),
          throwsArgumentError,
        );
      });

      test('rejects invalid generation parameters', () {
        expect(() => createPainter(segments: 0), throwsArgumentError);
        expect(() => createPainter(irregularity: -1), throwsArgumentError);
        expect(
          () => createPainter(irregularity: double.nan),
          throwsArgumentError,
        );
      });

      test('rejects a negative or non-finite inset', () {
        expect(() => createPainter(inset: -1), throwsArgumentError);
        expect(() => createPainter(inset: double.nan), throwsArgumentError);
      });
    });

    group('paint', () {
      test('can be used in a CustomPaint widget', () {
        // Smoke test: the painter can be instantiated and rendered
        // without throwing.
        final painter = createPainter();
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);

        // Should not throw.
        painter.paint(canvas, const Size(200, 100));

        final picture = recorder.endRecording();
        expect(picture, isNotNull);
      });

      test('uses the buildPath callback', () {
        var callCount = 0;
        final painter = createPainter(
          buildPath: (size, h) {
            callCount++;
            return h.lineHorizontal(size);
          },
        );

        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        painter.paint(canvas, const Size(200, 100));

        expect(callCount, 1);
      });

      test('caches path across identical-size paints', () {
        var callCount = 0;
        final painter = createPainter(
          buildPath: (size, h) {
            callCount++;
            return h.lineHorizontal(size);
          },
        );

        final recorder1 = PictureRecorder();
        painter.paint(Canvas(recorder1), const Size(200, 100));
        recorder1.endRecording();

        final recorder2 = PictureRecorder();
        painter.paint(Canvas(recorder2), const Size(200, 100));
        recorder2.endRecording();

        // buildPath should only be called once due to caching.
        expect(callCount, 1);
      });

      test('recomputes path when size changes', () {
        var callCount = 0;
        final painter = createPainter(
          buildPath: (size, h) {
            callCount++;
            return h.lineHorizontal(size);
          },
        );

        final recorder1 = PictureRecorder();
        painter.paint(Canvas(recorder1), const Size(200, 100));
        recorder1.endRecording();

        final recorder2 = PictureRecorder();
        painter.paint(Canvas(recorder2), const Size(300, 100));
        recorder2.endRecording();

        expect(callCount, 2);
      });
    });

    group('defaults', () {
      test('uses HandDrawnDefaults values', () {
        final painter = HandDrawnLinePainter(
          color: Colors.black,
          buildPath: (size, h) => h.rectBorder(size),
        );

        expect(painter.strokeWidth, HandDrawnDefaults.strokeWidth);
        expect(painter.irregularity, HandDrawnDefaults.irregularity);
        expect(painter.seed, HandDrawnDefaults.seed);
        expect(painter.segments, HandDrawnDefaults.segments);
      });
    });

    test('inset deflates and shifts the path', () async {
      final painter = createPainter(
        color: const Color(0xFFFF0000),
        irregularity: 0,
        inset: 10,
      );
      final pixels = await rasterize(
        (canvas) => painter.paint(canvas, const Size(100, 100)),
        100,
        100,
      );

      // A 2px stroke centered on x = 10 covers pixel 10 and not pixel 5.
      expect(alphaAt(pixels, 100, 10, 50), 1);
      expect(alphaAt(pixels, 100, 5, 50), 0);
    });
  });

  group('HandDrawnFillPainter', () {
    HandDrawnFillPainter createPainter({
      Color color = Colors.black,
      double strokeWidth = 2.0,
      HandDrawnFillExtent extent = HandDrawnFillExtent.strokeCenter,
      double irregularity = 3.0,
      int seed = 42,
      int segments = 24,
      Path Function(Size, HandDrawnHelpers) buildPath = _defaultBuildPath,
    }) {
      return HandDrawnFillPainter(
        color: color,
        strokeWidth: strokeWidth,
        extent: extent,
        irregularity: irregularity,
        seed: seed,
        segments: segments,
        buildPath: buildPath,
      );
    }

    group('shouldRepaint', () {
      test('returns false for identical parameters', () {
        expect(createPainter().shouldRepaint(createPainter()), isFalse);
      });

      test('returns true when a fill field changes', () {
        final p1 = createPainter();

        expect(createPainter(color: Colors.red).shouldRepaint(p1), isTrue);
        expect(
          createPainter(
            extent: HandDrawnFillExtent.strokeOuterEdge,
          ).shouldRepaint(p1),
          isTrue,
        );
        expect(createPainter(strokeWidth: 3.0).shouldRepaint(p1), isTrue);
      });

      test('returns true when a generation parameter changes', () {
        final p1 = createPainter();

        expect(createPainter(irregularity: 5.0).shouldRepaint(p1), isTrue);
        expect(createPainter(seed: 99).shouldRepaint(p1), isTrue);
        expect(createPainter(segments: 48).shouldRepaint(p1), isTrue);
      });

      test('returns true when buildPath differs', () {
        final p1 = createPainter(buildPath: _defaultBuildPath);
        final p2 = createPainter(buildPath: _otherRectPath);

        expect(p2.shouldRepaint(p1), isTrue);
      });
    });

    group('paint', () {
      test('standardShape fills the full canvas', () async {
        final painter = createPainter(
          color: const Color(0xFFFF0000),
          extent: HandDrawnFillExtent.standardShape,
          irregularity: 0,
        );
        final pixels = await rasterize(
          (canvas) => painter.paint(canvas, const Size(100, 100)),
          100,
          100,
        );

        expect(alphaAt(pixels, 100, 1, 1), 1);
        expect(alphaAt(pixels, 100, 50, 50), 1);
        expect(alphaAt(pixels, 100, 98, 98), 1);
      });
    });

    group('defaults', () {
      test('uses HandDrawnDefaults values and strokeCenter', () {
        final painter = HandDrawnFillPainter(
          color: Colors.black,
          strokeWidth: 2.0,
          buildPath: _defaultBuildPath,
        );

        expect(painter.extent, HandDrawnFillExtent.strokeCenter);
        expect(painter.irregularity, HandDrawnDefaults.irregularity);
        expect(painter.seed, HandDrawnDefaults.seed);
        expect(painter.segments, HandDrawnDefaults.segments);
      });
    });

    group('validation', () {
      test('rejects a non-finite or non-positive strokeWidth', () {
        expect(() => createPainter(strokeWidth: 0), throwsArgumentError);
        expect(
          () => createPainter(strokeWidth: double.nan),
          throwsArgumentError,
        );
      });

      test('rejects invalid generation parameters', () {
        expect(() => createPainter(segments: 0), throwsArgumentError);
        expect(
          () => createPainter(irregularity: double.nan),
          throwsArgumentError,
        );
      });
    });
  });
}
