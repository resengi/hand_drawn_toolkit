import 'dart:ui' show Color;

import 'package:flutter/painting.dart' show EdgeInsets;
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

    test('accepts negative finite value without error', () {
      expect(
        () => const BarSegment(
          category: 'x',
          value: -5,
          color: Color(0xFF000000),
        ),
        returnsNormally,
      );
    });

    test('rejects NaN value with assertion error', () {
      expect(
        () => BarSegment(
          category: 'x',
          value: double.nan,
          color: const Color(0xFF000000),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects positive infinity with assertion error', () {
      expect(
        () => BarSegment(
          category: 'x',
          value: double.infinity,
          color: const Color(0xFF000000),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects negative infinity with assertion error', () {
      expect(
        () => BarSegment(
          category: 'x',
          value: double.negativeInfinity,
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

    test('debug-asserts on invalid fillAlpha (NaN and out-of-range)', () {
      // IEEE 754 comparisons against NaN are always false — `NaN >= 0`
      // is false, so the conjunction `(fa >= 0 && fa <= 1)` fails and
      // the disjunction with `null` also fails, firing the assert.
      expect(
        () => BarSegment(
          category: 'x',
          value: 1,
          color: const Color(0xFF000000),
          fillAlpha: double.nan,
        ),
        throwsA(isA<AssertionError>()),
      );
      // Out-of-range fails the conjunction directly.
      expect(
        () => BarSegment(
          category: 'x',
          value: 1,
          color: const Color(0xFF000000),
          fillAlpha: 1.5,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => BarSegment(
          category: 'x',
          value: 1,
          color: const Color(0xFF000000),
          fillAlpha: -0.1,
        ),
        throwsA(isA<AssertionError>()),
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

    test('LinePoint asserts on non-finite x', () {
      expect(
        () => LinePoint(x: double.nan, y: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => LinePoint(x: double.infinity, y: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => LinePoint(x: double.negativeInfinity, y: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('LinePoint asserts on non-finite y', () {
      expect(
        () => LinePoint(x: 0, y: double.nan),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => LinePoint(x: 0, y: double.infinity),
        throwsA(isA<AssertionError>()),
      );
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

  // ── Model equality ───────────────────────────────────────────────────

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

    test('equal when fillColor and fillAlpha both null', () {
      const a = BarSegment(category: 'x', value: 10, color: Color(0xFF000000));
      const b = BarSegment(category: 'x', value: 10, color: Color(0xFF000000));
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('equal when fillColor and fillAlpha match', () {
      const a = BarSegment(
        category: 'x',
        value: 10,
        color: Color(0xFF000000),
        fillColor: Color(0xFFFF0000),
        fillAlpha: 0.5,
      );
      const b = BarSegment(
        category: 'x',
        value: 10,
        color: Color(0xFF000000),
        fillColor: Color(0xFFFF0000),
        fillAlpha: 0.5,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('not equal when fillColor differs', () {
      const a = BarSegment(
        category: 'x',
        value: 10,
        color: Color(0xFF000000),
        fillColor: Color(0xFFFF0000),
      );
      const b = BarSegment(
        category: 'x',
        value: 10,
        color: Color(0xFF000000),
        fillColor: Color(0xFF00FF00),
      );
      expect(a, isNot(equals(b)));
    });

    test('not equal when fillAlpha differs', () {
      const a = BarSegment(
        category: 'x',
        value: 10,
        color: Color(0xFF000000),
        fillAlpha: 0.3,
      );
      const b = BarSegment(
        category: 'x',
        value: 10,
        color: Color(0xFF000000),
        fillAlpha: 0.8,
      );
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

  group('ScatterPoint', () {
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

    test('ScatterPoint asserts on non-finite x', () {
      expect(
        () => ScatterPoint(x: double.nan, y: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ScatterPoint(x: double.infinity, y: 0),
        throwsA(isA<AssertionError>()),
      );
    });

    test('ScatterPoint asserts on non-finite y', () {
      expect(
        () => ScatterPoint(x: 0, y: double.nan),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ScatterPoint(x: 0, y: double.negativeInfinity),
        throwsA(isA<AssertionError>()),
      );
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

    test('not equal when axisDisplay differs', () {
      const a = BarChartData(bars: [], legend: []);
      const b = BarChartData(
        bars: [],
        legend: [],
        axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
      );
      expect(a, isNot(equals(b)));
    });

    test('equal when axisDisplay matches', () {
      const a = BarChartData(
        bars: [],
        legend: [],
        axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
      );
      const b = BarChartData(
        bars: [],
        legend: [],
        axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('default axisDisplay is edge', () {
      const a = BarChartData(bars: [], legend: []);
      expect(a.axisDisplay, AxisDisplay.edge);
    });
  });

  group('ChartLabelConfig', () {
    test(
      'default constructor is horizontal with the standard thinning gap',
      () {
        const c = ChartLabelConfig();
        expect(c.rotationDegrees, 0);
        expect(c.isRotated, isFalse);
        // rotationRadians is exactly 0 for the unrotated default.
        expect(c.rotationRadians, 0);
      },
    );

    test('ChartLabelConfig.horizontal matches the default constructor', () {
      expect(ChartLabelConfig.horizontal, const ChartLabelConfig());
    });

    test('named presets carry the documented angles', () {
      expect(ChartLabelConfig.diagonalLeft.rotationDegrees, -45);
      expect(ChartLabelConfig.diagonalRight.rotationDegrees, 45);
      expect(ChartLabelConfig.vertical.rotationDegrees, -90);
    });

    test('isRotated is true for any non-zero rotation', () {
      expect(const ChartLabelConfig(rotationDegrees: 0).isRotated, isFalse);
      expect(const ChartLabelConfig(rotationDegrees: -1).isRotated, isTrue);
      expect(const ChartLabelConfig(rotationDegrees: 90).isRotated, isTrue);
    });

    test('rotationRadians converts degrees correctly', () {
      // -90° → -π/2; 45° → π/4. Using closeTo for floating-point safety.
      expect(
        ChartLabelConfig.vertical.rotationRadians,
        closeTo(-1.5707963267948966, 1e-9),
      );
      expect(
        ChartLabelConfig.diagonalRight.rotationRadians,
        closeTo(0.7853981633974483, 1e-9),
      );
    });

    test('equality is structural', () {
      const a = ChartLabelConfig(rotationDegrees: -45, minVisibleGap: 12);
      const b = ChartLabelConfig(rotationDegrees: -45, minVisibleGap: 12);
      const c = ChartLabelConfig(rotationDegrees: -30, minVisibleGap: 12);
      const d = ChartLabelConfig(rotationDegrees: -45, minVisibleGap: 8);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
      expect(a, isNot(equals(d)));
    });

    test('rejects non-finite rotationDegrees', () {
      expect(
        () => ChartLabelConfig(rotationDegrees: double.nan),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ChartLabelConfig(rotationDegrees: double.infinity),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ChartLabelConfig(rotationDegrees: double.negativeInfinity),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects negative or non-finite minVisibleGap', () {
      expect(
        () => ChartLabelConfig(minVisibleGap: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ChartLabelConfig(minVisibleGap: double.nan),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ChartLabelConfig(minVisibleGap: double.infinity),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ChartLegendConfig', () {
    test('default constructor matches inline-bottom historical behavior', () {
      const c = ChartLegendConfig();
      expect(c.visible, isTrue);
      expect(c.position, ChartLegendPosition.bottom);
      expect(c.boxed, isFalse);
      expect(c.reserveSpace, isTrue);
      expect(c.wrap, isFalse);
    });

    test('inlineBottom preset is the historical default exactly', () {
      const a = ChartLegendConfig.inlineBottom;
      expect(a.visible, isTrue);
      expect(a.position, ChartLegendPosition.bottom);
      expect(a.boxed, isFalse);
      expect(a.wrap, isFalse);
      expect(a.reserveSpace, isTrue);
    });

    test('externalBottomBoxed preset wraps a boxed bottom row', () {
      const a = ChartLegendConfig.externalBottomBoxed;
      expect(a.visible, isTrue);
      expect(a.position, ChartLegendPosition.bottom);
      expect(a.boxed, isTrue);
      expect(a.wrap, isTrue);
      expect(a.reserveSpace, isTrue);
    });

    test('externalRightBoxed preset is a boxed right column', () {
      const a = ChartLegendConfig.externalRightBoxed;
      expect(a.position, ChartLegendPosition.right);
      expect(a.boxed, isTrue);
      expect(a.wrap, isTrue);
      expect(a.reserveSpace, isTrue);
    });

    test('hidden preset suppresses everything', () {
      const a = ChartLegendConfig.hidden;
      expect(a.visible, isFalse);
      expect(a.reserveSpace, isFalse);
      expect(a.boxed, isFalse);
      expect(a.wrap, isFalse);
    });

    test('equality is structural across all eight fields', () {
      const a = ChartLegendConfig(
        visible: true,
        position: ChartLegendPosition.right,
        boxed: true,
        reserveSpace: true,
        wrap: true,
        padding: EdgeInsets.all(10),
        spacing: 14,
        runSpacing: 6,
      );
      const b = ChartLegendConfig(
        visible: true,
        position: ChartLegendPosition.right,
        boxed: true,
        reserveSpace: true,
        wrap: true,
        padding: EdgeInsets.all(10),
        spacing: 14,
        runSpacing: 6,
      );
      // Each "differs by one field" partner should fail equality.
      const cVisible = ChartLegendConfig(
        visible: false,
        position: ChartLegendPosition.right,
        boxed: true,
        reserveSpace: true,
        wrap: true,
        padding: EdgeInsets.all(10),
        spacing: 14,
        runSpacing: 6,
      );
      const cPos = ChartLegendConfig(
        position: ChartLegendPosition.bottom,
        boxed: true,
        reserveSpace: true,
        wrap: true,
        padding: EdgeInsets.all(10),
        spacing: 14,
        runSpacing: 6,
      );
      const cPadding = ChartLegendConfig(
        position: ChartLegendPosition.right,
        boxed: true,
        reserveSpace: true,
        wrap: true,
        padding: EdgeInsets.all(8),
        spacing: 14,
        runSpacing: 6,
      );
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(cVisible)));
      expect(a, isNot(equals(cPos)));
      expect(a, isNot(equals(cPadding)));
    });

    test('rejects negative or non-finite spacing', () {
      expect(
        () => ChartLegendConfig(spacing: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ChartLegendConfig(spacing: double.nan),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ChartLegendConfig(spacing: double.infinity),
        throwsA(isA<AssertionError>()),
      );
    });

    test('rejects negative or non-finite runSpacing', () {
      expect(
        () => ChartLegendConfig(runSpacing: -1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => ChartLegendConfig(runSpacing: double.infinity),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('ChartLegendEntries.fromLineChartData', () {
    test('returns explicit legend when one is provided', () {
      const explicit = [LegendEntry(label: 'A', color: Color(0xFF000000))];
      const data = LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        series: [
          LineSeriesData(
            name: 'S',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 0)],
          ),
        ],
        legend: explicit,
      );
      expect(ChartLegendEntries.fromLineChartData(data), equals(explicit));
    });

    test('returns empty when total series count is 1 or 0', () {
      const oneSeries = LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        series: [
          LineSeriesData(
            name: 'S',
            color: Color(0xFF000000),
            points: [LinePoint(x: 0, y: 0)],
          ),
        ],
      );
      expect(ChartLegendEntries.fromLineChartData(oneSeries), isEmpty);
    });

    test('auto-generates entries from multiple series', () {
      const data = LineChartData(
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        series: [
          LineSeriesData(
            name: 'A',
            color: Color(0xFFAA0000),
            points: [LinePoint(x: 0, y: 0)],
          ),
          LineSeriesData(
            name: 'B',
            color: Color(0xFF00BB00),
            points: [LinePoint(x: 0, y: 0)],
          ),
        ],
      );
      final entries = ChartLegendEntries.fromLineChartData(data);
      expect(entries, hasLength(2));
      expect(entries[0].label, 'A');
      expect(entries[1].label, 'B');
      expect(entries[0].color, const Color(0xFFAA0000));
      expect(entries[1].color, const Color(0xFF00BB00));
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

  // ── Function series integration with LineChartData ───────────────────

  group('LineChartData + FunctionSeriesData', () {
    double sq(double x) => x * x;

    test('isEmpty is false for function-only chart', () {
      final data = LineChartData(
        series: const [],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        functionSeries: [
          FunctionSeriesData(
            name: 'f',
            color: const Color(0xFF000000),
            function: sq,
          ),
        ],
      );
      expect(data.isEmpty, isFalse);
    });

    test('isEmpty is true only when both lists are effectively empty', () {
      const data = LineChartData(
        series: [],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
      );
      expect(data.isEmpty, isTrue);
    });

    test('equality includes functionSeries', () {
      final a = LineChartData(
        series: const [],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        functionSeries: [
          FunctionSeriesData(
            name: 'f',
            color: const Color(0xFF000000),
            function: sq,
          ),
        ],
      );
      final b = LineChartData(
        series: const [],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        functionSeries: [
          FunctionSeriesData(
            name: 'f',
            color: const Color(0xFF000000),
            function: sq,
          ),
        ],
      );
      // Same top-level function reference → FunctionSeriesData equal,
      // which makes the two LineChartData values equal.
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test(
      'inline closures make FunctionSeriesData unequal (documented caveat)',
      () {
        final a = LineChartData(
          series: const [],
          minX: 0,
          maxX: 1,
          minY: 0,
          maxY: 1,
          functionSeries: [
            FunctionSeriesData(
              name: 'f',
              color: const Color(0xFF000000),
              function: (x) => x * x,
            ),
          ],
        );
        final b = LineChartData(
          series: const [],
          minX: 0,
          maxX: 1,
          minY: 0,
          maxY: 1,
          functionSeries: [
            FunctionSeriesData(
              name: 'f',
              color: const Color(0xFF000000),
              function: (x) => x * x,
            ),
          ],
        );
        // Two distinct inline closures compare by identity in Dart → unequal.
        expect(a, isNot(equals(b)));
      },
    );
  });

  // ── copyWith ─────────────────────────────────────────────────────────

  group('copyWith', () {
    test('ChartLabelConfig.copyWith round-trips and overrides', () {
      const c = ChartLabelConfig(rotationDegrees: -45, minVisibleGap: 8);
      // Round trip
      expect(c.copyWith(), equals(c));
      // Single-field override
      final rotated = c.copyWith(rotationDegrees: 30);
      expect(rotated.rotationDegrees, 30);
      expect(rotated.minVisibleGap, c.minVisibleGap);
    });

    test('ChartLegendConfig.copyWith round-trips and overrides', () {
      const c = ChartLegendConfig.inlineBottom;
      expect(c.copyWith(), equals(c));
      final boxed = c.copyWith(boxed: true, wrap: true);
      expect(boxed.boxed, isTrue);
      expect(boxed.wrap, isTrue);
      expect(boxed.position, c.position);
      expect(boxed.visible, c.visible);
    });

    test('BarChartData.copyWith round-trips and overrides', () {
      const original = BarChartData(
        bars: [
          BarGroup(
            label: 'A',
            segments: [
              BarSegment(category: 'x', value: 5, color: Color(0xFF000000)),
            ],
          ),
        ],
        legend: [],
        title: 'Original',
        axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
      );
      // Round trip
      expect(original.copyWith(), equals(original));
      // Title override preserves everything else
      final renamed = original.copyWith(title: 'Renamed');
      expect(renamed.title, 'Renamed');
      expect(renamed.bars, original.bars);
      expect(renamed.legend, original.legend);
      expect(
        renamed.axisDisplay,
        const AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
      );
    });

    test('LineChartData.copyWith round-trips and overrides', () {
      const original = LineChartData(
        series: [],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
        title: 'Original',
        axisDisplay: AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
        legend: [LegendEntry(label: 'A', color: Color(0xFF000000))],
      );
      expect(original.copyWith(), equals(original));
      final widerY = original.copyWith(maxY: 200);
      expect(widerY.maxY, 200);
      expect(widerY.minY, original.minY);
      expect(widerY.title, original.title);
      expect(
        widerY.axisDisplay,
        const AxisDisplay(horizontal: AxisDisplayMode.zeroCrossing),
      );
      expect(widerY.legend, original.legend);

      // Override legend specifically.
      const replacement = [LegendEntry(label: 'B', color: Color(0xFFFF0000))];
      final relegended = original.copyWith(legend: replacement);
      expect(relegended.legend, replacement);
      expect(relegended.title, original.title);
    });

    test('ScatterPlotData.copyWith round-trips and overrides', () {
      const original = ScatterPlotData(
        points: [],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
        xAxisLabel: 'time',
        legend: [LegendEntry(label: 'A', color: Color(0xFF000000))],
      );
      expect(original.copyWith(), equals(original));
      final relabeled = original.copyWith(xAxisLabel: 'epoch');
      expect(relabeled.xAxisLabel, 'epoch');
      expect(relabeled.minX, original.minX);
      expect(relabeled.maxX, original.maxX);
      expect(relabeled.legend, original.legend);

      // Override legend specifically.
      const replacement = [LegendEntry(label: 'B', color: Color(0xFFFF0000))];
      final relegended = original.copyWith(legend: replacement);
      expect(relegended.legend, replacement);
      expect(relegended.xAxisLabel, original.xAxisLabel);
    });
  });
}
