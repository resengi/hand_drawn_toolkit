import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

void main() {
  group('HandDrawnLinePainter', () {
    HandDrawnLinePainter createPainter({
      Color color = Colors.black,
      double strokeWidth = 2.0,
      double irregularity = 3.0,
      int seed = 42,
      int segments = 24,
      Path Function(Size, HandDrawnHelpers)? buildPath,
    }) {
      return HandDrawnLinePainter(
        color: color,
        strokeWidth: strokeWidth,
        irregularity: irregularity,
        seed: seed,
        segments: segments,
        buildPath: buildPath ?? (size, h) => h.rectBorder(size),
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
  });
}
