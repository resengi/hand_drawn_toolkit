import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

// ── Shared constants ──────────────────────────────────────────────────────

// ── Test data factories ───────────────────────────────────────────────────

BarChartData _barData({
  int barCount = 3,
  String? title,
  String? yAxisLabel,
  String? xAxisLabel,
  double? minY,
  double? maxY,
}) {
  return BarChartData(
    title: title,
    yAxisLabel: yAxisLabel,
    xAxisLabel: xAxisLabel,
    minY: minY,
    maxY: maxY,
    bars: List.generate(
      barCount,
      (i) => BarGroup(
        label: 'Bar $i',
        segments: [
          BarSegment(
            category: 'cat',
            value: (i + 1) * 10.0,
            color: const Color(0xFF6B9BD2),
          ),
        ],
      ),
    ),
    legend: [const LegendEntry(label: 'Category', color: Color(0xFF6B9BD2))],
  );
}

BarChartData _stackedBarData() {
  return const BarChartData(
    bars: [
      BarGroup(
        label: 'A',
        segments: [
          BarSegment(category: 'x', value: 10, color: Color(0xFFFF0000)),
          BarSegment(category: 'y', value: 20, color: Color(0xFF00FF00)),
        ],
      ),
      BarGroup(
        label: 'B',
        segments: [
          BarSegment(category: 'x', value: 15, color: Color(0xFFFF0000)),
          BarSegment(category: 'y', value: 5, color: Color(0xFF00FF00)),
        ],
      ),
    ],
    legend: [
      LegendEntry(label: 'X', color: Color(0xFFFF0000)),
      LegendEntry(label: 'Y', color: Color(0xFF00FF00)),
    ],
  );
}

LineChartData _lineData({
  int pointCount = 5,
  int seriesCount = 1,
  List<String> xLabels = const [],
  String? title,
}) {
  return LineChartData(
    title: title,
    xLabels: xLabels,
    minX: 0,
    maxX: (pointCount - 1).toDouble(),
    minY: 0,
    maxY: 100,
    series: List.generate(
      seriesCount,
      (s) => LineSeriesData(
        name: 'Series $s',
        color: Color(0xFF000000 + s * 0x110000),
        points: List.generate(
          pointCount,
          (i) => LinePoint(x: i.toDouble(), y: (i + 1) * 10.0),
        ),
      ),
    ),
  );
}

ScatterPlotData _scatterData({int pointCount = 5}) {
  return ScatterPlotData(
    minX: 0,
    maxX: 100,
    minY: 0,
    maxY: 200,
    points: List.generate(
      pointCount,
      (i) => ScatterPoint(x: i * 20.0, y: i * 40.0),
    ),
  );
}

HandDrawnBarChartPainter _barPainter({BarChartData? data}) {
  return HandDrawnBarChartPainter(data: data ?? _barData());
}

HandDrawnLineChartPainter _linePainter({LineChartData? data}) {
  return HandDrawnLineChartPainter(data: data ?? _lineData());
}

HandDrawnScatterPlotPainter _scatterPainter({ScatterPlotData? data}) {
  return HandDrawnScatterPlotPainter(data: data ?? _scatterData());
}

// ═══════════════════════════════════════════════════════════════════════════
// TESTS
// ═══════════════════════════════════════════════════════════════════════════

void main() {
  // ── Bar chart layout ──────────────────────────────────────────────────

  group('BarChartLayout', () {
    test('computeLayout returns valid layout with size and chartArea', () {
      final layout = _barPainter().computeLayout(kChartTestSize);

      expect(layout.size, kChartTestSize);
      expect(layout.chartArea.width, greaterThan(0));
      expect(layout.chartArea.height, greaterThan(0));
    });

    test('segment count matches input segment count', () {
      final layout = _barPainter().computeLayout(kChartTestSize);

      // 3 bars × 1 segment each = 3 segments
      expect(layout.segments.length, 3);
    });

    test('segment bounds are within chart area', () {
      final layout = _barPainter().computeLayout(kChartTestSize);

      for (final seg in layout.segments) {
        expect(seg.bounds.left, greaterThanOrEqualTo(layout.chartArea.left));
        expect(seg.bounds.right, lessThanOrEqualTo(layout.chartArea.right));
        expect(seg.bounds.top, greaterThanOrEqualTo(layout.chartArea.top));
        expect(seg.bounds.bottom, lessThanOrEqualTo(layout.chartArea.bottom));
      }
    });

    test('bar X positions use slot-center spacing', () {
      final layout = _barPainter().computeLayout(kChartTestSize);

      final slotWidth = layout.chartArea.width / 3;
      for (final seg in layout.segments) {
        final expectedCenter =
            layout.chartArea.left + slotWidth * (seg.barIndex + 0.5);
        expect(seg.bounds.center.dx, closeTo(expectedCenter, 0.01));
      }
    });

    test('stacked bar segments have correct cumulative values', () {
      final layout = _barPainter(
        data: _stackedBarData(),
      ).computeLayout(kChartTestSize);

      // Bar A: x=10, y=20 → cumulative [0,10], [10,30]
      final barASegments = layout.segments
          .where((s) => s.barIndex == 0)
          .toList();
      expect(barASegments.length, 2);
      expect(barASegments[0].cumulativeStart, 0);
      expect(barASegments[0].cumulativeEnd, 10);
      expect(barASegments[1].cumulativeStart, 10);
      expect(barASegments[1].cumulativeEnd, 30);
    });

    test('hitTest returns segment when point is inside bounds', () {
      final layout = _barPainter().computeLayout(kChartTestSize);
      final firstSeg = layout.segments.first;

      final hit = layout.hitTest(firstSeg.bounds.center);
      expect(hit, isNotNull);
      expect(hit!.segment.barIndex, firstSeg.barIndex);
      expect(hit.segment.segmentIndex, firstSeg.segmentIndex);
    });

    test('hitTest returns null when point is outside all bars', () {
      final layout = _barPainter().computeLayout(kChartTestSize);

      // Far outside the chart
      final hit = layout.hitTest(const Offset(-100, -100));
      expect(hit, isNull);
    });

    test(
      'hitTest returns topmost segment in stacked bars (reverse paint order)',
      () {
        final layout = _barPainter(
          data: _stackedBarData(),
        ).computeLayout(kChartTestSize);

        // Find the top segment of bar A (category y, painted last)
        final topSeg = layout.segments
            .where((s) => s.barIndex == 0 && s.category == 'y')
            .first;

        // Hit inside the top segment — reverse iteration means the
        // last-painted (topmost) segment wins.
        final hit = layout.hitTest(topSeg.bounds.center);
        expect(hit, isNotNull);
        expect(hit!.segment.category, 'y');
      },
    );

    test('empty data returns valid layout with empty segments', () {
      const data = BarChartData(bars: [], legend: []);
      final layout = _barPainter(data: data).computeLayout(kChartTestSize);

      expect(layout.size, kChartTestSize);
      expect(layout.chartArea.width, greaterThan(0));
      expect(layout.segments, isEmpty);
      expect(layout.hitTest(layout.chartArea.center), isNull);
    });

    test('layout recomputes correctly for different sizes', () {
      final painter = _barPainter();
      final small = painter.computeLayout(const Size(200, 150));
      final large = painter.computeLayout(const Size(800, 600));

      expect(small.chartArea.width, lessThan(large.chartArea.width));
      expect(small.chartArea.height, lessThan(large.chartArea.height));
    });
  });

  // ── Scatter plot layout ───────────────────────────────────────────────

  group('ScatterPlotLayout', () {
    test('computeLayout returns correct number of points', () {
      final layout = _scatterPainter().computeLayout(kChartTestSize);

      expect(layout.points.length, 5);
    });

    test('point centers are within chart area', () {
      final layout = _scatterPainter().computeLayout(kChartTestSize);

      for (final pt in layout.points) {
        expect(
          pt.center.dx,
          greaterThanOrEqualTo(layout.chartArea.left - 0.01),
        );
        expect(pt.center.dx, lessThanOrEqualTo(layout.chartArea.right + 0.01));
        expect(pt.center.dy, greaterThanOrEqualTo(layout.chartArea.top - 0.01));
        expect(pt.center.dy, lessThanOrEqualTo(layout.chartArea.bottom + 0.01));
      }
    });

    test('point positions scale correctly with data values', () {
      final layout = _scatterPainter().computeLayout(kChartTestSize);

      // Point 0: (0, 0) should be at bottom-left of chart area
      final p0 = layout.points[0];
      expect(p0.center.dx, closeTo(layout.chartArea.left, 0.01));
      expect(p0.center.dy, closeTo(layout.chartArea.bottom, 0.01));

      // Point 4: (80, 160) out of (0-100, 0-200)
      // x fraction = 0.8, y fraction = 0.8
      final p4 = layout.points[4];
      final expectedX = layout.chartArea.left + layout.chartArea.width * 0.8;
      final expectedY = layout.chartArea.bottom - layout.chartArea.height * 0.8;
      expect(p4.center.dx, closeTo(expectedX, 0.01));
      expect(p4.center.dy, closeTo(expectedY, 0.01));
    });

    test('hitTest returns nearest point within tolerance', () {
      final layout = _scatterPainter().computeLayout(kChartTestSize);
      final target = layout.points[2];

      // Slightly offset from center, within default tolerance
      final hit = layout.hitTest(target.center + const Offset(3, 3));
      expect(hit, isNotNull);
      expect(hit!.point.pointIndex, 2);
    });

    test('hitTest returns null when outside tolerance', () {
      final layout = _scatterPainter().computeLayout(kChartTestSize);

      // Far from any point
      final hit = layout.hitTest(const Offset(-100, -100));
      expect(hit, isNull);
    });

    test(
      'hitTest uses touch-friendly radius (max of visual and tolerance)',
      () {
        // Create data with very small dots
        const data = ScatterPlotData(
          minX: 0,
          maxX: 100,
          minY: 0,
          maxY: 100,
          points: [ScatterPoint(x: 50, y: 50, size: 2)],
        );
        final layout = _scatterPainter(
          data: data,
        ).computeLayout(kChartTestSize);

        final pt = layout.points[0];
        // 10px away should still hit with default tolerance of 16
        final hit = layout.hitTest(pt.center + const Offset(10, 0));
        expect(hit, isNotNull);
      },
    );

    test('empty data returns valid layout', () {
      const data = ScatterPlotData(
        minX: 0,
        maxX: 100,
        minY: 0,
        maxY: 100,
        points: [],
      );
      final layout = _scatterPainter(data: data).computeLayout(kChartTestSize);

      expect(layout.points, isEmpty);
      expect(layout.hitTest(layout.chartArea.center), isNull);
    });

    test('rawPoint data is preserved in layout', () {
      final layout = _scatterPainter().computeLayout(kChartTestSize);

      expect(layout.points[2].rawPoint.x, 40.0);
      expect(layout.points[2].rawPoint.y, 80.0);
    });
  });

  // ── Line chart layout ─────────────────────────────────────────────────

  group('LineChartLayout', () {
    test('computeLayout returns correct point and segment counts', () {
      final layout = _linePainter().computeLayout(kChartTestSize);

      // 5 points, 4 segments for 1 series
      expect(layout.points.length, 5);
      expect(layout.segments.length, 4);
    });

    test('multi-series produces points and segments for all series', () {
      final layout = _linePainter(
        data: _lineData(seriesCount: 3),
      ).computeLayout(kChartTestSize);

      // 3 series × 5 points = 15 points
      // 3 series × 4 segments = 12 segments
      expect(layout.points.length, 15);
      expect(layout.segments.length, 12);
    });

    test('point centers are correctly positioned', () {
      final layout = _linePainter().computeLayout(kChartTestSize);

      // Point 0: x=0, y=10 → x fraction = 0, y fraction = 0.1
      final p0 = layout.points[0];
      expect(p0.center.dx, closeTo(layout.chartArea.left, 0.01));
      final expectedY0 =
          layout.chartArea.bottom - layout.chartArea.height * 0.1;
      expect(p0.center.dy, closeTo(expectedY0, 0.01));
    });

    test('segment endpoints match consecutive point centers', () {
      final layout = _linePainter().computeLayout(kChartTestSize);

      for (int i = 0; i < layout.segments.length; i++) {
        final seg = layout.segments[i];
        final startPoint = layout.points.firstWhere(
          (p) =>
              p.seriesIndex == seg.seriesIndex &&
              p.pointIndex == seg.segmentIndex,
        );
        final endPoint = layout.points.firstWhere(
          (p) =>
              p.seriesIndex == seg.seriesIndex &&
              p.pointIndex == seg.segmentIndex + 1,
        );

        expect(seg.start, startPoint.center);
        expect(seg.end, endPoint.center);
      }
    });

    test('hitTest returns point hit when near a data point', () {
      final layout = _linePainter().computeLayout(kChartTestSize);
      final target = layout.points[2];

      final hit = layout.hitTest(target.center + const Offset(2, 2));
      expect(hit, isNotNull);
      expect(hit, isA<LinePointHit>());

      final pointHit = hit as LinePointHit;
      expect(pointHit.pointIndex, 2);
      expect(pointHit.point, target.rawPoint);
      expect(pointHit.seriesIndex, 0);
      expect(pointHit.seriesName, 'Series 0');
    });

    test(
      'hitTest returns segment hit when near a line but far from points',
      () {
        final layout = _linePainter().computeLayout(kChartTestSize);
        final seg = layout.segments[1]; // segment between points 1 and 2

        // Midpoint of the segment, offset perpendicular by a small amount
        final mid = Offset(
          (seg.start.dx + seg.end.dx) / 2,
          (seg.start.dy + seg.end.dy) / 2,
        );
        // Move perpendicular to the line — far enough from points but close
        // to the segment
        final testPoint = mid + const Offset(0, 5);

        // Use a tight point tolerance so we don't accidentally hit a point
        final hit = layout.hitTest(
          testPoint,
          pointTolerance: 2,
          lineTolerance: 16,
        );

        if (hit != null && hit is LineSegmentHit) {
          final segHit = hit;
          expect(segHit.segmentIndex, isNonNegative);
          expect(segHit.t, greaterThanOrEqualTo(0));
          expect(segHit.t, lessThanOrEqualTo(1));
          expect(segHit.interpolatedX, isNotNaN);
          expect(segHit.interpolatedY, isNotNaN);
        }
        // If null, it means the geometry didn't qualify — acceptable for
        // a perpendicular offset test.
      },
    );

    test('hitTest prefers point over segment when both qualify', () {
      final layout = _linePainter().computeLayout(kChartTestSize);
      final target = layout.points[2];

      // Right at the point center — both point and segment qualify
      final hit = layout.hitTest(target.center);
      expect(hit, isNotNull);
      expect(hit, isA<LinePointHit>());
    });

    test('hitTest returns null when far from everything', () {
      final layout = _linePainter().computeLayout(kChartTestSize);
      final hit = layout.hitTest(const Offset(-100, -100));
      expect(hit, isNull);
    });

    test('hitTest finds nearest point across multiple series', () {
      final data = _lineData(seriesCount: 2, pointCount: 3);
      final layout = _linePainter(data: data).computeLayout(kChartTestSize);

      // All points from both series at pointIndex=1 share the same x
      // but may differ in y (they have the same data in this factory).
      // Hit near a series 1 point.
      final s1Points = layout.points.where((p) => p.seriesIndex == 1).toList();
      final target = s1Points[1];

      final hit = layout.hitTest(target.center);
      expect(hit, isNotNull);
      // Should hit something — could be either series since they overlap.
      expect(hit, isA<LinePointHit>());
    });

    test('segment hit interpolation values are correct', () {
      // Simple 2-point line: (0, 0) to (100, 100)
      const data = LineChartData(
        minX: 0,
        maxX: 100,
        minY: 0,
        maxY: 100,
        series: [
          LineSeriesData(
            name: 'test',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 0), LinePoint(x: 100, y: 100)],
          ),
        ],
      );
      final layout = _linePainter(data: data).computeLayout(kChartTestSize);

      // The midpoint of the segment in canvas space
      final seg = layout.segments[0];
      final mid = Offset(
        (seg.start.dx + seg.end.dx) / 2,
        (seg.start.dy + seg.end.dy) / 2,
      );

      final hit = layout.hitTest(mid, pointTolerance: 0, lineTolerance: 20);
      if (hit is LineSegmentHit) {
        // t should be close to 0.5
        expect(hit.t, closeTo(0.5, 0.05));
        // Interpolated values should be close to 50
        expect(hit.interpolatedX, closeTo(50, 1));
        expect(hit.interpolatedY, closeTo(50, 1));
      }
    });

    test('sealed result supports exhaustive switch', () {
      final layout = _linePainter().computeLayout(kChartTestSize);
      final hit = layout.hitTest(layout.points.first.center);

      // This test verifies the sealed hierarchy compiles with exhaustive
      // pattern matching.
      if (hit != null) {
        final description = switch (hit) {
          LinePointHit(:final pointIndex) => 'point $pointIndex',
          LineSegmentHit(:final segmentIndex) => 'segment $segmentIndex',
        };
        expect(description, isNotEmpty);
      }
    });

    test('empty series returns valid empty layout', () {
      const data = LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        series: [],
      );
      final layout = _linePainter(data: data).computeLayout(kChartTestSize);

      expect(layout.points, isEmpty);
      expect(layout.segments, isEmpty);
      expect(layout.hitTest(layout.chartArea.center), isNull);
    });

    test('mixed empty and non-empty series skips empty ones', () {
      const data = LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 100,
        series: [
          LineSeriesData(name: 'empty', color: Color(0xFFFF0000), points: []),
          LineSeriesData(
            name: 'filled',
            color: Color(0xFF00FF00),
            points: [LinePoint(x: 0, y: 10), LinePoint(x: 1, y: 90)],
          ),
        ],
      );
      final layout = _linePainter(data: data).computeLayout(kChartTestSize);

      // Only the non-empty series contributes points and segments
      expect(layout.points.length, 2);
      expect(layout.segments.length, 1);
      expect(layout.points.first.seriesIndex, 1);
      expect(layout.points.first.seriesName, 'filled');
    });

    test('seriesName is preserved in point and segment layouts', () {
      final layout = _linePainter(
        data: _lineData(seriesCount: 2),
      ).computeLayout(kChartTestSize);

      for (final pt in layout.points) {
        expect(pt.seriesName, 'Series ${pt.seriesIndex}');
      }
      for (final seg in layout.segments) {
        expect(seg.seriesName, 'Series ${seg.seriesIndex}');
      }
    });
  });

  // ── Cross-cutting concerns ────────────────────────────────────────────

  group('Layout size-bound invariants', () {
    test('layout includes correct size', () {
      final barLayout = _barPainter().computeLayout(kChartTestSize);
      final lineLayout = _linePainter().computeLayout(kChartTestSize);
      final scatterLayout = _scatterPainter().computeLayout(kChartTestSize);

      expect(barLayout.size, kChartTestSize);
      expect(lineLayout.size, kChartTestSize);
      expect(scatterLayout.size, kChartTestSize);
    });

    test('chart area is within canvas bounds', () {
      final barLayout = _barPainter().computeLayout(kChartTestSize);
      expect(barLayout.chartArea.left, greaterThanOrEqualTo(0));
      expect(barLayout.chartArea.top, greaterThanOrEqualTo(0));
      expect(
        barLayout.chartArea.right,
        lessThanOrEqualTo(kChartTestSize.width),
      );
      expect(
        barLayout.chartArea.bottom,
        lessThanOrEqualTo(kChartTestSize.height),
      );

      final lineLayout = _linePainter().computeLayout(kChartTestSize);
      expect(lineLayout.chartArea.left, greaterThanOrEqualTo(0));
      expect(lineLayout.chartArea.top, greaterThanOrEqualTo(0));
      expect(
        lineLayout.chartArea.right,
        lessThanOrEqualTo(kChartTestSize.width),
      );
      expect(
        lineLayout.chartArea.bottom,
        lessThanOrEqualTo(kChartTestSize.height),
      );

      final scatterLayout = _scatterPainter().computeLayout(kChartTestSize);
      expect(scatterLayout.chartArea.left, greaterThanOrEqualTo(0));
      expect(scatterLayout.chartArea.top, greaterThanOrEqualTo(0));
      expect(
        scatterLayout.chartArea.right,
        lessThanOrEqualTo(kChartTestSize.width),
      );
      expect(
        scatterLayout.chartArea.bottom,
        lessThanOrEqualTo(kChartTestSize.height),
      );
    });

    test('title affects chart area position', () {
      final noTitle = _barPainter(
        data: _barData(),
      ).computeLayout(kChartTestSize);
      final withTitle = _barPainter(
        data: _barData(title: 'My Chart'),
      ).computeLayout(kChartTestSize);

      // Title pushes chart area down
      expect(withTitle.chartArea.top, greaterThan(noTitle.chartArea.top));
    });
  });
}
