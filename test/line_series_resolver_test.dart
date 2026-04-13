import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/src/charts/chart_data.dart';
import 'package:hand_drawn_toolkit/src/charts/line_series_resolver.dart';

void main() {
  group('resolveLineSeries — ordinary series passthrough', () {
    test('preserves points, single run, segmentedStroke mode', () {
      const data = LineChartData(
        series: [
          LineSeriesData(
            name: 'A',
            color: Colors.blue,
            points: [
              LinePoint(x: 0, y: 1),
              LinePoint(x: 1, y: 2),
              LinePoint(x: 2, y: 4),
            ],
          ),
        ],
        minX: 0,
        maxX: 2,
        minY: 0,
        maxY: 5,
      );

      final resolved = resolveLineSeries(data);
      expect(resolved.length, 1);
      expect(resolved[0].renderMode, ResolvedLineRenderMode.segmentedStroke);
      expect(resolved[0].pathRuns.length, 1);
      expect(resolved[0].pathRuns[0].length, 3);
      expect(resolved[0].displayPoints.length, 3);
      expect(resolved[0].displayPoints, resolved[0].pathRuns[0]);
    });
  });

  group('resolveLineSeries — function series', () {
    test('samples continuous function into single dense run', () {
      final data = LineChartData(
        series: const [],
        minX: -5,
        maxX: 5,
        minY: 0,
        maxY: 25,
        functionSeries: [
          FunctionSeriesData(
            name: 'x²',
            color: Colors.red,
            function: (x) => x * x,
            displayXs: const [-4, -2, 0, 2, 4],
            sampleCount: 10,
          ),
        ],
      );

      final resolved = resolveLineSeries(data);
      expect(resolved.length, 1);
      expect(resolved[0].renderMode, ResolvedLineRenderMode.continuousCurve);
      expect(resolved[0].pathRuns.length, 1);
      expect(resolved[0].pathRuns[0].length, 10);
      expect(resolved[0].displayPoints.length, 5);
      expect(resolved[0].displayPoints.first.x, -4);
      expect(resolved[0].displayPoints.first.y, 16);
    });

    test('splits 1/x into two runs and skips non-finite sample', () {
      final data = LineChartData(
        series: const [],
        minX: -1,
        maxX: 1,
        minY: -10,
        maxY: 10,
        functionSeries: [
          FunctionSeriesData(
            name: '1/x',
            color: Colors.green,
            function: (x) => 1 / x,
            sampleCount: 3, // samples at -1, 0, 1; middle is infinity
          ),
        ],
      );

      final resolved = resolveLineSeries(data);
      expect(resolved[0].pathRuns.length, 2);
      expect(resolved[0].pathRuns[0].single.x, -1);
      expect(resolved[0].pathRuns[1].single.x, 1);
    });

    test('all-NaN function yields empty pathRuns', () {
      final data = LineChartData(
        series: const [],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        functionSeries: [
          FunctionSeriesData(
            name: 'nan',
            color: Colors.black,
            function: (x) => double.nan,
            sampleCount: 5,
          ),
        ],
      );
      final resolved = resolveLineSeries(data);
      expect(resolved[0].pathRuns, isEmpty);
      expect(resolved[0].displayPoints, isEmpty);
    });

    test('displayXs: drops out-of-range + non-finite, preserves dupes+order', () {
      final data = LineChartData(
        series: const [],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
        functionSeries: [
          FunctionSeriesData(
            name: 'sq',
            color: Colors.black,
            function: (x) => x == 5 ? double.nan : x * x,
            // includes: out-of-range (-1, 99), non-finite (5), duplicate (3,3),
            // and a specific order that must be preserved
            displayXs: const [-1, 3, 99, 5, 3, 0],
            sampleCount: 5,
          ),
        ],
      );
      final dp = resolveLineSeries(data)[0].displayPoints;
      expect(dp.map((p) => p.x).toList(), [3, 3, 0]);
    });
  });

  group('resolveLineSeries — ordering contract', () {
    test('ordinary series first, function series after, declaration order', () {
      final data = LineChartData(
        series: const [
          LineSeriesData(name: 'A', color: Colors.blue, points: []),
          LineSeriesData(name: 'B', color: Colors.red, points: []),
        ],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        functionSeries: [
          FunctionSeriesData(
            name: 'F1',
            color: Colors.green,
            function: (x) => x,
          ),
          FunctionSeriesData(
            name: 'F2',
            color: Colors.orange,
            function: (x) => x * 2,
          ),
        ],
      );
      final names = resolveLineSeries(data).map((r) => r.name).toList();
      expect(names, ['A', 'B', 'F1', 'F2']);
    });
  });

  group('LineChartData assertions', () {
    test(
      'functionSeries + xLabels: construction succeeds, resolveLineSeries throws',
      () {
        final data = LineChartData(
          series: const [],
          minX: 0,
          maxX: 1,
          minY: 0,
          maxY: 1,
          xLabels: const ['a', 'b'],
          functionSeries: [
            FunctionSeriesData(
              name: 'f',
              color: Colors.black,
              function: (x) => x,
            ),
          ],
        );
        // Construction must not throw — the rule is enforced at use time.
        expect(data, isNotNull);
        expect(() => resolveLineSeries(data), throwsA(isA<ArgumentError>()));
      },
    );

    test(
      'minX >= maxX with functionSeries: construction succeeds, resolveLineSeries throws',
      () {
        final data = LineChartData(
          series: const [],
          minX: 1,
          maxX: 1,
          minY: 0,
          maxY: 1,
          functionSeries: [
            FunctionSeriesData(
              name: 'f',
              color: Colors.black,
              function: (x) => x,
            ),
          ],
        );
        expect(data, isNotNull);
        expect(() => resolveLineSeries(data), throwsA(isA<ArgumentError>()));
      },
    );

    test('FunctionSeriesData sampleCount < 2 throws', () {
      expect(
        () => FunctionSeriesData(
          name: 'f',
          color: Colors.black,
          function: (x) => x,
          sampleCount: 1,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('FunctionSeriesData wobbleAnchorStride < 1 throws', () {
      expect(
        () => FunctionSeriesData(
          name: 'f',
          color: Colors.black,
          function: (x) => x,
          wobbleAnchorStride: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('FunctionSeriesData wobbleAnchorStride defaults to 10', () {
      final f = FunctionSeriesData(
        name: 'f',
        color: Colors.black,
        function: (x) => x,
      );
      expect(f.wobbleAnchorStride, 10);
    });

    // ── Reviewer-flagged edge cases: explicit non-const empty lists ──
    //
    // The constructor uses `identical(x, const <T>[])` to detect default
    // empty lists in a const-eval-safe way. These tests verify that
    // passing a non-canonical empty list (e.g. `[]` rather than omitting
    // the parameter) is also accepted, since semantically the rule
    // "function series cannot combine with categorical xLabels" is
    // satisfied when either side is empty regardless of identity.

    test(
      'functionSeries with explicit non-const empty xLabels is accepted',
      () {
        final List<String> emptyLabels = []; // forced non-const
        final data = LineChartData(
          series: const [],
          minX: 0,
          maxX: 1,
          minY: 0,
          maxY: 1,
          xLabels: emptyLabels,
          functionSeries: [
            FunctionSeriesData(
              name: 'f',
              color: Colors.black,
              function: (x) => x,
            ),
          ],
        );
        // Construction must succeed AND resolver must not throw —
        // empty xLabels means there's nothing categorical to conflict.
        expect(data, isNotNull);
        expect(() => resolveLineSeries(data), returnsNormally);
      },
    );

    test(
      'real xLabels with explicit non-const empty functionSeries is accepted',
      () {
        final List<FunctionSeriesData> emptyFunctions = []; // forced non-const
        final data = LineChartData(
          series: const [],
          minX: 0,
          maxX: 2,
          minY: 0,
          maxY: 1,
          xLabels: const ['A', 'B', 'C'],
          functionSeries: emptyFunctions,
        );
        // No function series → categorical labels are perfectly fine.
        expect(data, isNotNull);
        expect(() => resolveLineSeries(data), returnsNormally);
      },
    );

    test('isEmpty is false when only functionSeries is populated', () {
      final data = LineChartData(
        series: const [],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        functionSeries: [
          FunctionSeriesData(
            name: 'f',
            color: Colors.black,
            function: (x) => x,
          ),
        ],
      );
      expect(data.isEmpty, isFalse);
    });
  });
}
