import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

// Top-level functions used across tests so closure identity is stable.
double _xSquared(double x) => x * x;
double _oneOverX(double x) => 1 / x;

HandDrawnLineChartPainter _painterFor(LineChartData data) {
  return HandDrawnLineChartPainter(data: data);
}

void main() {
  const size = Size(400, 300);

  group('Function-series layout: points', () {
    test('pointIndex indexes into displayPoints for function series', () {
      const data = LineChartData(
        series: [],
        minX: -5,
        maxX: 5,
        minY: 0,
        maxY: 25,
        functionSeries: [
          FunctionSeriesData(
            name: 'x²',
            color: Colors.blue,
            function: _xSquared,
            displayXs: [-4, -2, 0, 2, 4],
            sampleCount: 40,
          ),
        ],
      );

      final layout = _painterFor(data).computeLayout(size);

      // Exactly five visible points despite 40 internal samples.
      expect(layout.points, hasLength(5));

      for (var i = 0; i < layout.points.length; i++) {
        expect(layout.points[i].pointIndex, i);
        expect(layout.points[i].seriesIndex, 0);
      }
      // Values track displayXs order.
      expect(layout.points[0].rawPoint.x, -4);
      expect(layout.points[4].rawPoint.x, 4);
    });

    test('displayXs filtering is reflected in layout point count', () {
      // Two in range, one out of range, one non-finite → 2 layout points.
      final data = LineChartData(
        series: const [],
        minX: 0,
        maxX: 10,
        minY: 0,
        maxY: 100,
        functionSeries: [
          FunctionSeriesData(
            name: 'f',
            color: Colors.red,
            function: (x) => x == 5 ? double.nan : x * x,
            displayXs: const [-1, 3, 99, 5, 7],
            sampleCount: 20,
          ),
        ],
      );
      final layout = _painterFor(data).computeLayout(size);
      expect(layout.points, hasLength(2));
      expect(layout.points.map((p) => p.rawPoint.x), [3, 7]);
    });
  });

  group('Function-series layout: segments', () {
    test('segments span the whole curve, sourced from pathRuns', () {
      const data = LineChartData(
        series: [],
        minX: -5,
        maxX: 5,
        minY: 0,
        maxY: 25,
        functionSeries: [
          FunctionSeriesData(
            name: 'x²',
            color: Colors.blue,
            function: _xSquared,
            displayXs: [-4, 0, 4],
            sampleCount: 40,
          ),
        ],
      );

      final layout = _painterFor(data).computeLayout(size);

      // Continuous curve → one run of 40 samples → 39 segments.
      expect(layout.segments, hasLength(39));
      expect(layout.segments.first.seriesIndex, 0);
    });

    test('discontinuity produces a gap in segment stream, not a bridge', () {
      // 1/x sampled symmetrically around zero. With sampleCount=5 the samples
      // are at -2, -1, 0, 1, 2 → infinity at x=0 → run splits.
      const data = LineChartData(
        series: [],
        minX: -2,
        maxX: 2,
        minY: -10,
        maxY: 10,
        functionSeries: [
          FunctionSeriesData(
            name: '1/x',
            color: Colors.green,
            function: _oneOverX,
            sampleCount: 5,
          ),
        ],
      );

      final layout = _painterFor(data).computeLayout(size);

      // Run 1: [-2, -1] → 1 segment. Run 2: [1, 2] → 1 segment. Total 2.
      expect(layout.segments, hasLength(2));

      // No segment bridges across x=0. Verify by checking that no segment
      // has a start x ≤ 0 and end x ≥ 0 simultaneously.
      for (final s in layout.segments) {
        final xa = s.rawStartPoint.x;
        final xb = s.rawEndPoint.x;
        expect(
          (xa <= 0 && xb >= 0) || (xa >= 0 && xb <= 0),
          isFalse,
          reason: 'segment $xa → $xb bridges discontinuity',
        );
      }
    });
  });

  group('Function-series layout: ordering contract', () {
    test('ordinary series indices come before function series indices', () {
      const data = LineChartData(
        series: [
          LineSeriesData(
            name: 'A',
            color: Colors.red,
            points: [LinePoint(x: 0, y: 0), LinePoint(x: 1, y: 1)],
          ),
        ],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        functionSeries: [
          FunctionSeriesData(
            name: 'F',
            color: Colors.green,
            function: _xSquared,
            displayXs: [0, 0.5, 1],
            sampleCount: 10,
          ),
        ],
      );

      final layout = _painterFor(data).computeLayout(size);

      // Ordinary series first (seriesIndex 0), function after (seriesIndex 1).
      final ordinary = layout.points.where((p) => p.seriesIndex == 0).toList();
      final func = layout.points.where((p) => p.seriesIndex == 1).toList();
      expect(ordinary.map((p) => p.seriesName), everyElement('A'));
      expect(func.map((p) => p.seriesName), everyElement('F'));
    });
  });

  group('Legend gating with function series', () {
    testWidgets('single function-only series → no legend', (tester) async {
      const data = LineChartData(
        series: [],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        functionSeries: [
          FunctionSeriesData(
            name: 'F',
            color: Colors.green,
            function: _xSquared,
          ),
        ],
      );
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 300,
            child: HandDrawnLineChart(data: data),
          ),
        ),
      );
      final painter = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is HandDrawnLineChartPainter,
        ),
      );
      final p = painter.painter as HandDrawnLineChartPainter;
      expect(p.legend, isEmpty);
    });

    testWidgets('1 ordinary + 1 function → legend has 2 entries in order', (
      tester,
    ) async {
      const data = LineChartData(
        series: [
          LineSeriesData(
            name: 'Ordinary',
            color: Colors.red,
            points: [LinePoint(x: 0, y: 0), LinePoint(x: 1, y: 1)],
          ),
        ],
        minX: 0,
        maxX: 1,
        minY: 0,
        maxY: 1,
        functionSeries: [
          FunctionSeriesData(
            name: 'Function',
            color: Colors.green,
            function: _xSquared,
          ),
        ],
      );
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 400,
            height: 300,
            child: HandDrawnLineChart(data: data),
          ),
        ),
      );
      final painter = tester.widget<CustomPaint>(
        find.byWidgetPredicate(
          (w) => w is CustomPaint && w.painter is HandDrawnLineChartPainter,
        ),
      );
      final p = painter.painter as HandDrawnLineChartPainter;
      expect(p.legend, hasLength(2));
      expect(p.legend[0].label, 'Ordinary');
      expect(p.legend[1].label, 'Function');
    });
  });
}
