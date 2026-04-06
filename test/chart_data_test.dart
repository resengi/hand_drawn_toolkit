import 'dart:ui' show Color;

import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

void main() {
  // ── BarChartData ─────────────────────────────────────────────────────

  group('BarChartData', () {
    test('isEmpty is true when bars list is empty', () {
      const data = BarChartData(bars: [], legend: []);
      expect(data.isEmpty, isTrue);
    });

    test('isEmpty is false when bars are present', () {
      const data = BarChartData(
        bars: [
          BarGroup(
            label: 'A',
            segments: [
              BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
            ],
          ),
        ],
        legend: [],
      );
      expect(data.isEmpty, isFalse);
    });

    test('minY and maxY default to null', () {
      const data = BarChartData(bars: [], legend: []);
      expect(data.minY, isNull);
      expect(data.maxY, isNull);
    });

    test('title and axis labels default to null', () {
      const data = BarChartData(bars: [], legend: []);
      expect(data.title, isNull);
      expect(data.yAxisLabel, isNull);
      expect(data.xAxisLabel, isNull);
    });

    test('yValueFormatter defaults to null', () {
      const data = BarChartData(bars: [], legend: []);
      expect(data.yValueFormatter, isNull);
    });
  });

  group('BarGroup', () {
    test('total sums all segment values', () {
      const group = BarGroup(
        label: 'Mon',
        segments: [
          BarSegment(category: 'a', value: 10, color: Color(0xFF000000)),
          BarSegment(category: 'b', value: 25, color: Color(0xFF000000)),
          BarSegment(category: 'c', value: 5, color: Color(0xFF000000)),
        ],
      );
      expect(group.total, 40.0);
    });

    test('total is zero with no segments', () {
      const group = BarGroup(label: 'Empty', segments: []);
      expect(group.total, 0.0);
    });

    test('total equals sum of segment values', () {
      const group = BarGroup(
        label: 'Test',
        segments: [
          BarSegment(category: 'a', value: 7.5, color: Color(0xFF000000)),
          BarSegment(category: 'b', value: 12.5, color: Color(0xFF000000)),
        ],
      );
      final expected = group.segments
          .map((s) => s.value)
          .reduce((a, b) => a + b);
      expect(group.total, expected);
    });
  });

  group('BarSegment input validation', () {
    test('accepts zero value without error', () {
      expect(
        () =>
            const BarSegment(category: 'x', value: 0, color: Color(0xFF000000)),
        returnsNormally,
      );
    });

    test('rejects negative value with assertion error', () {
      expect(
        () => BarSegment(
          category: 'x',
          value: -5,
          color: const Color(0xFF000000),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('accepts positive value without error', () {
      expect(
        () =>
            const BarSegment(category: 'x', value: 1, color: Color(0xFF000000)),
        returnsNormally,
      );
    });
  });

  // ── LineChartData ────────────────────────────────────────────────────

  group('LineChartData', () {
    test('isEmpty is true when all series have empty points', () {
      const data = LineChartData(
        series: [
          LineSeriesData(name: 'A', points: [], color: Color(0xFF000000)),
        ],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
      );
      expect(data.isEmpty, isTrue);
    });

    test('isEmpty is false when any series has points', () {
      const data = LineChartData(
        series: [
          LineSeriesData(name: 'A', points: [], color: Color(0xFF000000)),
          LineSeriesData(
            name: 'B',
            points: [LinePoint(x: 0, y: 5)],
            color: Color(0xFF000000),
          ),
        ],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
      );
      expect(data.isEmpty, isFalse);
    });

    test('xLabels defaults to empty list', () {
      const data = LineChartData(
        series: [],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
      );
      expect(data.xLabels, isEmpty);
    });

    test('accepts categorical xLabels', () {
      const data = LineChartData(
        series: [],
        xLabels: ['Mon', 'Tue', 'Wed'],
        minX: 0,
        maxX: 2,
        minY: 0,
        maxY: 100,
      );
      expect(data.xLabels, hasLength(3));
    });

    test('title, axis labels, and formatters default to null', () {
      const data = LineChartData(
        series: [],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
      );
      expect(data.title, isNull);
      expect(data.yAxisLabel, isNull);
      expect(data.xAxisLabel, isNull);
      expect(data.yValueFormatter, isNull);
      expect(data.xValueFormatter, isNull);
    });
  });

  // ── ScatterPlotData ──────────────────────────────────────────────────

  group('ScatterPlotData', () {
    test('isEmpty is true when points list is empty', () {
      const data = ScatterPlotData(
        points: [],
        xAxisLabel: 'X',
        yAxisLabel: 'Y',
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      expect(data.isEmpty, isTrue);
    });

    test('isEmpty is false when points are present', () {
      const data = ScatterPlotData(
        points: [ScatterPoint(x: 1, y: 2)],
        xAxisLabel: 'X',
        yAxisLabel: 'Y',
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      expect(data.isEmpty, isFalse);
    });

    test('ScatterPoint.size defaults to null', () {
      const p = ScatterPoint(x: 1, y: 2);
      expect(p.size, isNull);
    });

    test('ScatterPoint accepts custom size', () {
      const p = ScatterPoint(x: 1, y: 2, size: 8.0);
      expect(p.size, 8.0);
    });

    test('ScatterPoint accepts null size', () {
      expect(() => const ScatterPoint(x: 1, y: 2), returnsNormally);
    });

    test('ScatterPoint rejects negative size in debug mode', () {
      expect(
        () => ScatterPoint(x: 1, y: 2, size: -5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('ScatterPoint rejects zero size in debug mode', () {
      expect(
        () => ScatterPoint(x: 1, y: 2, size: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('formatters default to null', () {
      const data = ScatterPlotData(
        points: [],
        xAxisLabel: 'X',
        yAxisLabel: 'Y',
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      expect(data.yValueFormatter, isNull);
      expect(data.xValueFormatter, isNull);
    });

    test('axis labels default to null when omitted', () {
      const data = ScatterPlotData(
        points: [],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      expect(data.xAxisLabel, isNull);
      expect(data.yAxisLabel, isNull);
    });

    test('axis labels can be provided', () {
      const data = ScatterPlotData(
        points: [],
        xAxisLabel: 'Weight',
        yAxisLabel: 'Height',
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      expect(data.xAxisLabel, 'Weight');
      expect(data.yAxisLabel, 'Height');
    });
  });

  // ── LinePoint ────────────────────────────────────────────────────────

  group('LinePoint', () {
    test('stores x and y values', () {
      const p = LinePoint(x: 3.5, y: 7.2);
      expect(p.x, 3.5);
      expect(p.y, 7.2);
    });
  });

  // ── LegendEntry ──────────────────────────────────────────────────────

  group('LegendEntry', () {
    test('stores label and color', () {
      const entry = LegendEntry(label: 'Series A', color: Color(0xFFFF0000));
      expect(entry.label, 'Series A');
      expect(entry.color, const Color(0xFFFF0000));
    });
  });

  // ── LegendEntry equality ─────────────────────────────────────────────

  group('LegendEntry equality', () {
    test('equal when label and color match', () {
      const a = LegendEntry(label: 'Sales', color: Color(0xFF0000FF));
      const b = LegendEntry(label: 'Sales', color: Color(0xFF0000FF));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when label differs', () {
      const a = LegendEntry(label: 'Sales', color: Color(0xFF0000FF));
      const b = LegendEntry(label: 'Revenue', color: Color(0xFF0000FF));
      expect(a, isNot(equals(b)));
    });

    test('not equal when color differs', () {
      const a = LegendEntry(label: 'Sales', color: Color(0xFF0000FF));
      const b = LegendEntry(label: 'Sales', color: Color(0xFFFF0000));
      expect(a, isNot(equals(b)));
    });
  });

  // ── Model equality (Step 3.4) ────────────────────────────────────────

  group('BarSegment equality', () {
    test('equal when all fields match', () {
      const a = BarSegment(category: 'x', value: 10, color: Color(0xFF000000));
      const b = BarSegment(category: 'x', value: 10, color: Color(0xFF000000));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when value differs', () {
      const a = BarSegment(category: 'x', value: 10, color: Color(0xFF000000));
      const b = BarSegment(category: 'x', value: 20, color: Color(0xFF000000));
      expect(a, isNot(equals(b)));
    });
  });

  group('BarGroup equality', () {
    test('equal when label and segments match', () {
      const a = BarGroup(
        label: 'A',
        segments: [
          BarSegment(category: 'x', value: 5, color: Color(0xFF000000)),
        ],
      );
      const b = BarGroup(
        label: 'A',
        segments: [
          BarSegment(category: 'x', value: 5, color: Color(0xFF000000)),
        ],
      );
      expect(a, equals(b));
    });

    test('not equal when segments differ', () {
      const a = BarGroup(
        label: 'A',
        segments: [
          BarSegment(category: 'x', value: 5, color: Color(0xFF000000)),
        ],
      );
      const b = BarGroup(
        label: 'A',
        segments: [
          BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
        ],
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('LinePoint equality', () {
    test('equal when x and y match', () {
      const a = LinePoint(x: 1, y: 2);
      const b = LinePoint(x: 1, y: 2);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when y differs', () {
      const a = LinePoint(x: 1, y: 2);
      const b = LinePoint(x: 1, y: 3);
      expect(a, isNot(equals(b)));
    });
  });

  group('ScatterPoint equality', () {
    test('equal when all fields match', () {
      const a = ScatterPoint(x: 1, y: 2, size: 5);
      const b = ScatterPoint(x: 1, y: 2, size: 5);
      expect(a, equals(b));
    });

    test('equal when size is both null', () {
      const a = ScatterPoint(x: 1, y: 2);
      const b = ScatterPoint(x: 1, y: 2);
      expect(a, equals(b));
    });

    test('not equal when size differs', () {
      const a = ScatterPoint(x: 1, y: 2, size: 5);
      const b = ScatterPoint(x: 1, y: 2, size: 10);
      expect(a, isNot(equals(b)));
    });
  });

  group('BarChartData equality', () {
    test('equal when all fields match', () {
      const a = BarChartData(
        bars: [
          BarGroup(
            label: 'A',
            segments: [
              BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
            ],
          ),
        ],
        legend: [LegendEntry(label: 'X', color: Color(0xFF000000))],
        title: 'Chart',
      );
      const b = BarChartData(
        bars: [
          BarGroup(
            label: 'A',
            segments: [
              BarSegment(category: 'x', value: 10, color: Color(0xFF000000)),
            ],
          ),
        ],
        legend: [LegendEntry(label: 'X', color: Color(0xFF000000))],
        title: 'Chart',
      );
      expect(a, equals(b));
    });

    test('not equal when title differs', () {
      const a = BarChartData(bars: [], legend: [], title: 'A');
      const b = BarChartData(bars: [], legend: [], title: 'B');
      expect(a, isNot(equals(b)));
    });
  });

  group('LineChartData equality', () {
    test('equal when all fields match', () {
      const a = LineChartData(
        series: [],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
      );
      const b = LineChartData(
        series: [],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
      );
      expect(a, equals(b));
    });

    test('not equal when range differs', () {
      const a = LineChartData(
        series: [],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
      );
      const b = LineChartData(
        series: [],
        minX: 0,
        maxX: 20,
        minY: 0,
        maxY: 100,
      );
      expect(a, isNot(equals(b)));
    });
  });

  group('ScatterPlotData equality', () {
    test('equal when all fields match', () {
      const a = ScatterPlotData(
        points: [ScatterPoint(x: 1, y: 2)],
        xAxisLabel: 'X',
        yAxisLabel: 'Y',
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      const b = ScatterPlotData(
        points: [ScatterPoint(x: 1, y: 2)],
        xAxisLabel: 'X',
        yAxisLabel: 'Y',
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      expect(a, equals(b));
    });

    test('not equal when points differ', () {
      const a = ScatterPlotData(
        points: [ScatterPoint(x: 1, y: 2)],
        xAxisLabel: 'X',
        yAxisLabel: 'Y',
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      const b = ScatterPlotData(
        points: [ScatterPoint(x: 3, y: 4)],
        xAxisLabel: 'X',
        yAxisLabel: 'Y',
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      expect(a, isNot(equals(b)));
    });

    test('equal when both have null axis labels', () {
      const a = ScatterPlotData(
        points: [ScatterPoint(x: 1, y: 2)],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      const b = ScatterPlotData(
        points: [ScatterPoint(x: 1, y: 2)],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when one has axis labels and the other does not', () {
      const a = ScatterPlotData(
        points: [ScatterPoint(x: 1, y: 2)],
        xAxisLabel: 'X',
        yAxisLabel: 'Y',
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      const b = ScatterPlotData(
        points: [ScatterPoint(x: 1, y: 2)],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 10,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
