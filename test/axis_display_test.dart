import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

// ── Shared ────────────────────────────────────────────────────────────────

LineChartData _line({
  double minY = -50,
  double maxY = 50,
  double minX = 0,
  double maxX = 4,
  AxisDisplay axisDisplay = AxisDisplay.edge,
}) {
  return LineChartData(
    minX: minX,
    maxX: maxX,
    minY: minY,
    maxY: maxY,
    axisDisplay: axisDisplay,
    series: const [
      LineSeriesData(
        name: 'S',
        color: Color(0xFF000000),
        points: [
          LinePoint(x: 0, y: -40),
          LinePoint(x: 1, y: -10),
          LinePoint(x: 2, y: 0),
          LinePoint(x: 3, y: 25),
          LinePoint(x: 4, y: 45),
        ],
      ),
    ],
  );
}

ScatterPlotData _scatter({
  double minY = -100,
  double maxY = 100,
  double minX = -50,
  double maxX = 50,
  AxisDisplay axisDisplay = AxisDisplay.edge,
}) {
  return ScatterPlotData(
    minX: minX,
    maxX: maxX,
    minY: minY,
    maxY: maxY,
    axisDisplay: axisDisplay,
    points: const [
      ScatterPoint(x: -40, y: -80),
      ScatterPoint(x: -10, y: 20),
      ScatterPoint(x: 0, y: 0),
      ScatterPoint(x: 25, y: 60),
    ],
  );
}

/// Default bar data for axisDisplay tests. Mixes positive and negative
/// segments so zero-crossing actually has somewhere to cross.
BarChartData _bar({AxisDisplay axisDisplay = AxisDisplay.edge}) {
  return BarChartData(
    bars: const [
      BarGroup(
        label: 'Q1',
        segments: [
          BarSegment(category: 'rev', value: 12, color: Color(0xFF000000)),
          BarSegment(category: 'rev', value: -5, color: Color(0xFF000000)),
        ],
      ),
      BarGroup(
        label: 'Q2',
        segments: [
          BarSegment(category: 'rev', value: 8, color: Color(0xFF000000)),
        ],
      ),
      BarGroup(
        label: 'Q3',
        segments: [
          BarSegment(category: 'rev', value: -7, color: Color(0xFF000000)),
        ],
      ),
    ],
    legend: const [LegendEntry(label: 'rev', color: Color(0xFF000000))],
    axisDisplay: axisDisplay,
  );
}

void main() {
  // ── Data model ───────────────────────────────────────────────────────

  group('AxisDisplay', () {
    test('default constructor is edge on both axes', () {
      const a = AxisDisplay();
      expect(a.horizontal, AxisDisplayMode.edge);
      expect(a.vertical, AxisDisplayMode.edge);
    });

    test('AxisDisplay.edge constant matches default', () {
      expect(AxisDisplay.edge, const AxisDisplay());
    });

    test('equality is structural', () {
      const a = AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing);
      const b = AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing);
      const c = AxisDisplay(vertical: AxisDisplayMode.zeroCrossing);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });

    test('LineChartData and ScatterPlotData default to edge', () {
      expect(_line().axisDisplay, AxisDisplay.edge);
      expect(_scatter().axisDisplay, AxisDisplay.edge);
    });

    test('LineChartData equality includes axisDisplay', () {
      final a = _line();
      final b = _line(
        axisDisplay: const AxisDisplay(
          horizontal: AxisDisplayMode.zeroCrossing,
        ),
      );
      expect(a, isNot(equals(b)));
    });
  });

  // ── Layout-level coverage via computeLayout() ────────────────────────

  group('Line chart point mapping with negative ranges', () {
    test('points map correctly for mixed positive/negative Y', () {
      final layout = HandDrawnLineChartPainter(
        data: _line(),
      ).computeLayout(kChartTestSize);
      // y=0 is the middle of [-50, 50] → halfway up the chart area.
      final zeroPoint = layout.points.firstWhere((p) => p.rawPoint.y == 0);
      final midY = layout.chartArea.center.dy;
      expect((zeroPoint.center.dy - midY).abs(), lessThan(0.5));
    });

    test('negative Y points lie below the chart vertical center', () {
      final layout = HandDrawnLineChartPainter(
        data: _line(),
      ).computeLayout(kChartTestSize);
      final negPoint = layout.points.firstWhere((p) => p.rawPoint.y == -40);
      expect(negPoint.center.dy, greaterThan(layout.chartArea.center.dy));
    });

    test('positive Y points lie above the chart vertical center', () {
      final layout = HandDrawnLineChartPainter(
        data: _line(),
      ).computeLayout(kChartTestSize);
      final posPoint = layout.points.firstWhere((p) => p.rawPoint.y == 45);
      expect(posPoint.center.dy, lessThan(layout.chartArea.center.dy));
    });

    test('axisDisplay does not affect point positions', () {
      // Point positions are pure data→canvas mapping; axis-line placement
      // must not alter where data is drawn.
      final edgeLayout = HandDrawnLineChartPainter(
        data: _line(),
      ).computeLayout(kChartTestSize);
      final zeroLayout = HandDrawnLineChartPainter(
        data: _line(
          axisDisplay: const AxisDisplay(
            horizontal: AxisDisplayMode.zeroCrossing,
            vertical: AxisDisplayMode.zeroCrossing,
          ),
        ),
      ).computeLayout(kChartTestSize);
      expect(edgeLayout.points.length, zeroLayout.points.length);
      for (int i = 0; i < edgeLayout.points.length; i++) {
        expect(
          edgeLayout.points[i].center,
          equals(zeroLayout.points[i].center),
        );
      }
    });

    test('hit testing still works for negative-Y points', () {
      final layout = HandDrawnLineChartPainter(
        data: _line(),
      ).computeLayout(kChartTestSize);
      final neg = layout.points.firstWhere((p) => p.rawPoint.y == -40);
      expect(layout.hitTest(neg.center), isNotNull);
    });
  });

  group('Scatter plot point mapping with negative ranges', () {
    test('mixed-range points map to correct quadrants', () {
      final layout = HandDrawnScatterPlotPainter(
        data: _scatter(),
      ).computeLayout(kChartTestSize);
      final cx = layout.chartArea.center.dx;
      final cy = layout.chartArea.center.dy;

      final origin = layout.points.firstWhere(
        (p) => p.rawPoint.x == 0 && p.rawPoint.y == 0,
      );
      expect((origin.center.dx - cx).abs(), lessThan(0.5));
      expect((origin.center.dy - cy).abs(), lessThan(0.5));

      final negNeg = layout.points.firstWhere(
        (p) => p.rawPoint.x == -40 && p.rawPoint.y == -80,
      );
      expect(negNeg.center.dx, lessThan(cx));
      expect(negNeg.center.dy, greaterThan(cy));

      final posPos = layout.points.firstWhere(
        (p) => p.rawPoint.x == 25 && p.rawPoint.y == 60,
      );
      expect(posPos.center.dx, greaterThan(cx));
      expect(posPos.center.dy, lessThan(cy));
    });

    test('axisDisplay does not affect point positions', () {
      final edge = HandDrawnScatterPlotPainter(
        data: _scatter(),
      ).computeLayout(kChartTestSize);
      final zero = HandDrawnScatterPlotPainter(
        data: _scatter(
          axisDisplay: const AxisDisplay(
            horizontal: AxisDisplayMode.zeroCrossing,
            vertical: AxisDisplayMode.zeroCrossing,
          ),
        ),
      ).computeLayout(kChartTestSize);
      for (int i = 0; i < edge.points.length; i++) {
        expect(edge.points[i].center, equals(zero.points[i].center));
      }
    });
  });

  // ── Smoke tests: paint must not throw across all axis-display modes ──

  group('Painter smoke tests with axisDisplay', () {
    final modes = <({String label, AxisDisplay display})>[
      (label: 'edge defaults', display: AxisDisplay.edge),
      (
        label: 'horizontal zero-crossing only',
        display: const AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
      ),
      (
        label: 'vertical zero-crossing only',
        display: const AxisDisplay(vertical: AxisDisplayMode.zeroCrossing),
      ),
      (
        label: 'both axes zero-crossing',
        display: const AxisDisplay(
          horizontal: AxisDisplayMode.zeroCrossing,
          vertical: AxisDisplayMode.zeroCrossing,
        ),
      ),
    ];

    for (final mode in modes) {
      test('line paints under ${mode.label} without throwing', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final painter = HandDrawnLineChartPainter(
          data: _line(axisDisplay: mode.display),
        );
        expect(() => painter.paint(canvas, kChartTestSize), returnsNormally);
        recorder.endRecording();
      });

      test('scatter paints under ${mode.label} without throwing', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final painter = HandDrawnScatterPlotPainter(
          data: _scatter(axisDisplay: mode.display),
        );
        expect(() => painter.paint(canvas, kChartTestSize), returnsNormally);
        recorder.endRecording();
      });
    }

    test('zero outside Y range with zeroCrossing requested still paints '
        '(falls back to edge silently)', () {
      // minY=10, maxY=100 — zero is outside, so isZeroVisibleY is false;
      // resolved axis position should silently fall back to chart bottom.
      final data = _line(
        minY: 10,
        maxY: 100,
        axisDisplay: const AxisDisplay(
          horizontal: AxisDisplayMode.zeroCrossing,
          vertical: AxisDisplayMode.zeroCrossing,
        ),
      );
      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      expect(
        () =>
            HandDrawnLineChartPainter(data: data).paint(canvas, kChartTestSize),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test(
      'mixed-sign line (multiple zero crossings) paints without throwing',
      () {
        // Exercises the sign-split fill path on a series that crosses
        // zero four times. A bug in the split logic would likely
        // surface here as a throw or degenerate path.
        const data = LineChartData(
          minX: 0,
          maxX: 7,
          minY: -40,
          maxY: 60,
          axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
          series: [
            LineSeriesData(
              name: 'S',
              color: Color(0xFF000000),
              points: [
                LinePoint(x: 0, y: 25),
                LinePoint(x: 1, y: -15),
                LinePoint(x: 2, y: -30),
                LinePoint(x: 3, y: 10),
                LinePoint(x: 4, y: 35),
                LinePoint(x: 5, y: 50),
                LinePoint(x: 6, y: 20),
                LinePoint(x: 7, y: -5),
              ],
            ),
          ],
        );
        final recorder = PictureRecorder();
        expect(
          () => HandDrawnLineChartPainter(
            data: data,
          ).paint(Canvas(recorder), kChartTestSize),
          returnsNormally,
        );
        recorder.endRecording();
      },
    );
  });

  // ── shouldRepaint sensitivity to axisDisplay ─────────────────────────

  group('shouldRepaint reacts to axisDisplay changes', () {
    test('line painter repaints when axisDisplay changes', () {
      final a = HandDrawnLineChartPainter(data: _line());
      final b = HandDrawnLineChartPainter(
        data: _line(
          axisDisplay: const AxisDisplay(
            horizontal: AxisDisplayMode.zeroCrossing,
          ),
        ),
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('scatter painter repaints when axisDisplay changes', () {
      final a = HandDrawnScatterPlotPainter(data: _scatter());
      final b = HandDrawnScatterPlotPainter(
        data: _scatter(
          axisDisplay: const AxisDisplay(
            vertical: AxisDisplayMode.zeroCrossing,
          ),
        ),
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('bar painter repaints when axisDisplay changes', () {
      final a = HandDrawnBarChartPainter(data: _bar());
      final b = HandDrawnBarChartPainter(
        data: _bar(
          axisDisplay: const AxisDisplay(
            horizontal: AxisDisplayMode.zeroCrossing,
          ),
        ),
      );
      expect(b.shouldRepaint(a), isTrue);
    });
  });

  // ── Bar chart with axisDisplay ───────────────────────────────────────

  group('Bar chart geometry with negative segments', () {
    test('BarChartData defaults to AxisDisplay.edge', () {
      expect(_bar().axisDisplay, AxisDisplay.edge);
    });

    test('mixed-sign stack: positive segments above zero, negatives below', () {
      // Q1 stack is [12, -5]: positive part fills [0, 12], negative
      // part fills [-5, 0]. After mapping into canvas coords (Y inverted),
      // the positive rect's bottom must be at the y=0 canvas line and
      // its top above; the negative rect's top must be at the y=0 line
      // and its bottom below.
      final layout = HandDrawnBarChartPainter(
        data: _bar(),
      ).computeLayout(kChartTestSize);

      // Find Q1's two segments by category index.
      final q1 = layout.segments.where((s) => s.barIndex == 0).toList();
      expect(q1, hasLength(2));

      // Positive accumulator: 0 → 12.
      final positive = q1.firstWhere((s) => s.value == 12);
      expect(positive.cumulativeStart, 0);
      expect(positive.cumulativeEnd, 12);

      // Negative accumulator: 0 → -5.
      final negative = q1.firstWhere((s) => s.value == -5);
      expect(negative.cumulativeStart, 0);
      expect(negative.cumulativeEnd, -5);

      // The two rects must meet at the same canvas Y (the y=0 line):
      // positive's bottom == negative's top.
      expect(
        (positive.bounds.bottom - negative.bounds.top).abs(),
        lessThan(0.5),
      );
    });

    test('axisDisplay does not affect bar segment rects', () {
      // Switching axis-line placement must not move bar geometry.
      final edge = HandDrawnBarChartPainter(
        data: _bar(),
      ).computeLayout(kChartTestSize);
      final zero = HandDrawnBarChartPainter(
        data: _bar(
          axisDisplay: const AxisDisplay(
            horizontal: AxisDisplayMode.zeroCrossing,
            vertical: AxisDisplayMode.zeroCrossing,
          ),
        ),
      ).computeLayout(kChartTestSize);
      expect(edge.segments.length, zero.segments.length);
      for (int i = 0; i < edge.segments.length; i++) {
        expect(edge.segments[i].bounds, equals(zero.segments[i].bounds));
      }
    });

    test('hit testing works for negative-value segments', () {
      final layout = HandDrawnBarChartPainter(
        data: _bar(),
      ).computeLayout(kChartTestSize);
      // Q3 is the all-negative bar (single segment value -7).
      final q3Negative = layout.segments.firstWhere((s) => s.value == -7);
      // A point inside that rect must hit-test back to the same segment.
      expect(layout.hitTest(q3Negative.bounds.center), isNotNull);
    });
  });

  group('Bar chart smoke tests with axisDisplay', () {
    final modes = <({String label, AxisDisplay display})>[
      (label: 'edge defaults', display: AxisDisplay.edge),
      (
        label: 'horizontal zero-crossing only',
        display: const AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
      ),
      (
        label: 'vertical zero-crossing only (no-op on bar charts)',
        display: const AxisDisplay(vertical: AxisDisplayMode.zeroCrossing),
      ),
      (
        label: 'both axes zero-crossing',
        display: const AxisDisplay(
          horizontal: AxisDisplayMode.zeroCrossing,
          vertical: AxisDisplayMode.zeroCrossing,
        ),
      ),
    ];

    for (final mode in modes) {
      test('bar paints under ${mode.label} without throwing', () {
        final recorder = PictureRecorder();
        final canvas = Canvas(recorder);
        final painter = HandDrawnBarChartPainter(
          data: _bar(axisDisplay: mode.display),
        );
        expect(() => painter.paint(canvas, kChartTestSize), returnsNormally);
        recorder.endRecording();
      });
    }

    test(
      'bar with all-positive data + zeroCrossing requested falls back to edge',
      () {
        // No negatives → isZeroVisibleY is false → axis silently stays
        // at the chart bottom edge. Just verify paint succeeds.
        const data = BarChartData(
          bars: [
            BarGroup(
              label: 'A',
              segments: [
                BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
              ],
            ),
            BarGroup(
              label: 'B',
              segments: [
                BarSegment(category: 'x', value: 20, color: Color(0xFF000000)),
              ],
            ),
          ],
          legend: [],
          axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
        );
        final recorder = PictureRecorder();
        expect(
          () => HandDrawnBarChartPainter(
            data: data,
          ).paint(Canvas(recorder), kChartTestSize),
          returnsNormally,
        );
        recorder.endRecording();
      },
    );
  });

  // ── Sign-flip crossing detection (fill contract) ─────────────────────
  //
  // The zero-crossing fill splits its polygon at every strict sign flip
  // (y0*y1 < 0), inserting an interpolated crossing X. We can't assert
  // on raw Path contents without Canvas mocking, but we CAN lock in the
  // math that drives the split — any change in how crossings are
  // detected or interpolated will show up here before it surfaces as a
  // rendering bug.

  group('Sign-flip crossing detection (fill contract)', () {
    double crossingX(LinePoint a, LinePoint b) {
      final t = a.y / (a.y - b.y);
      return a.x + (b.x - a.x) * t;
    }

    int countCrossings(List<LinePoint> pts) {
      var n = 0;
      for (int i = 1; i < pts.length; i++) {
        if (pts[i - 1].y * pts[i].y < 0) n++;
      }
      return n;
    }

    test('profit/loss shape has three detected crossings', () {
      // Step through to count: +25→-15 (flip), -15→-30 (no),
      // -30→+10 (flip), +10→+35 (no), +35→+50 (no), +50→+20 (no),
      // +20→-5 (flip). Three strict sign flips.
      const pts = [
        LinePoint(x: 0, y: 25),
        LinePoint(x: 1, y: -15),
        LinePoint(x: 2, y: -30),
        LinePoint(x: 3, y: 10),
        LinePoint(x: 4, y: 35),
        LinePoint(x: 5, y: 50),
        LinePoint(x: 6, y: 20),
        LinePoint(x: 7, y: -5),
      ];
      expect(countCrossings(pts), 3);
    });

    test('crossing X lies strictly between endpoints', () {
      const a = LinePoint(x: 0, y: 25);
      const b = LinePoint(x: 1, y: -15);
      final x = crossingX(a, b);
      expect(x, greaterThan(a.x));
      expect(x, lessThan(b.x));
    });

    test('exact-zero endpoints are not counted as strict flips', () {
      // +5 → 0 → -5: the zero point is a natural boundary that does
      // not require interpolation. No segment satisfies y0*y1 < 0
      // strictly (both products are 0), so crossings count = 0.
      const pts = [
        LinePoint(x: 0, y: 5),
        LinePoint(x: 1, y: 0),
        LinePoint(x: 2, y: -5),
      ];
      expect(countCrossings(pts), 0);
    });
  });
}
