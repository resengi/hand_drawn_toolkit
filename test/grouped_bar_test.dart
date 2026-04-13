import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

const _color = Color(0xFF6B9BD2);

BarSegment _seg(double v, [String cat = 'cat']) =>
    BarSegment(category: cat, value: v, color: _color);

BarGroup _bar(String label, List<double> values) =>
    BarGroup(label: label, segments: values.map(_seg).toList());

BarChartData _legacy({int n = 3}) => BarChartData(
  bars: List.generate(n, (i) => _bar('B$i', [(i + 1) * 10.0])),
  legend: const [LegendEntry(label: 'cat', color: _color)],
);

BarChartData _grouped({int categoryCount = 2, int innerCount = 2}) {
  return BarChartData(
    bars: const [],
    legend: const [LegendEntry(label: 'cat', color: _color)],
    categories: List.generate(categoryCount, (c) {
      return BarCategory(
        label: 'C$c',
        bars: List.generate(
          innerCount,
          (b) => _bar('inner-$c-$b', [10.0 + c * 5 + b * 7]),
        ),
      );
    }),
  );
}

HandDrawnBarChartPainter _painter(BarChartData data) =>
    HandDrawnBarChartPainter(data: data);

void main() {
  // ── Backward-compat (regression) ─────────────────────────────────────

  group('Legacy bars input — backward compat', () {
    test('every layout segment has innerBarIndex == 0', () {
      final layout = _painter(_legacy(n: 4)).computeLayout(kChartTestSize);
      for (final s in layout.segments) {
        expect(s.innerBarIndex, 0);
      }
    });

    test('one segment per legacy bar (no zero values)', () {
      final layout = _painter(_legacy(n: 4)).computeLayout(kChartTestSize);
      expect(layout.segments, hasLength(4));
    });

    test('barIndex covers 0..N-1 in order', () {
      final layout = _painter(_legacy(n: 4)).computeLayout(kChartTestSize);
      expect(layout.segments.map((s) => s.barIndex).toList(), [0, 1, 2, 3]);
    });
  });

  // ── Grouped geometry ─────────────────────────────────────────────────

  group('Grouped geometry', () {
    test('segments per category equals sum of inner-bar segment counts', () {
      final layout = _painter(
        _grouped(categoryCount: 3, innerCount: 2),
      ).computeLayout(kChartTestSize);
      // Each inner bar has 1 segment → 3 categories * 2 inner bars = 6.
      expect(layout.segments, hasLength(6));
    });

    test('innerBarIndex covers 0..N-1 within each category', () {
      final layout = _painter(
        _grouped(categoryCount: 2, innerCount: 3),
      ).computeLayout(kChartTestSize);
      for (int c = 0; c < 2; c++) {
        final inCat =
            layout.segments
                .where((s) => s.barIndex == c)
                .map((s) => s.innerBarIndex)
                .toList()
              ..sort();
        expect(inCat, [0, 1, 2]);
      }
    });

    test('inner bars sit inside their outer slot bounds', () {
      final layout = _painter(
        _grouped(categoryCount: 3, innerCount: 2),
      ).computeLayout(kChartTestSize);
      final outerSlotWidth = layout.chartArea.width / 3;
      for (final s in layout.segments) {
        final outerLeft = layout.chartArea.left + outerSlotWidth * s.barIndex;
        final outerRight = outerLeft + outerSlotWidth;
        expect(s.bounds.left, greaterThanOrEqualTo(outerLeft - 0.01));
        expect(s.bounds.right, lessThanOrEqualTo(outerRight + 0.01));
      }
    });

    test('inner bars are centered within outer slot', () {
      final layout = _painter(
        _grouped(categoryCount: 1, innerCount: 4),
      ).computeLayout(kChartTestSize);
      // Average of inner bar centers should equal the outer slot center
      // (which is the chart area's horizontal center for a single category).
      final centers = layout.segments.map((s) => s.bounds.center.dx).toList();
      final avg = centers.reduce((a, b) => a + b) / centers.length;
      expect((avg - layout.chartArea.center.dx).abs(), lessThan(0.5));
    });

    test('single inner bar collapses to outer slot center (legacy parity)', () {
      final grouped = _painter(
        _grouped(categoryCount: 3, innerCount: 1),
      ).computeLayout(kChartTestSize);
      final legacy = _painter(
        BarChartData(
          bars: List.generate(3, (i) => _bar('inner-$i-0', [10.0 + i * 5])),
          legend: const [LegendEntry(label: 'cat', color: _color)],
        ),
      ).computeLayout(kChartTestSize);
      // Single-inner-bar grouped charts must produce identical X centers
      // to the legacy projection — this is the geometry contract.
      for (int i = 0; i < 3; i++) {
        expect(
          (grouped.segments[i].bounds.center.dx -
                  legacy.segments[i].bounds.center.dx)
              .abs(),
          lessThan(0.01),
        );
      }
    });

    test('sibling inner bars touch edge-to-edge within a category', () {
      // The key visual property of grouped bars: siblings in one
      // category have no gap between them (so the grouping reads as a
      // coherent unit), while the gap-to-next-category is preserved by
      // the outer-slot breathing room.
      final layout = _painter(
        _grouped(categoryCount: 2, innerCount: 3),
      ).computeLayout(kChartTestSize);
      // Segments come out in (category, inner, segment) order, so two
      // adjacent segments with the same barIndex and consecutive
      // innerBarIndex values should touch.
      for (int c = 0; c < 2; c++) {
        final inCat = layout.segments.where((s) => s.barIndex == c).toList()
          ..sort((a, b) => a.innerBarIndex.compareTo(b.innerBarIndex));
        for (int i = 0; i < inCat.length - 1; i++) {
          expect(
            (inCat[i + 1].bounds.left - inCat[i].bounds.right).abs(),
            lessThan(0.5),
            reason:
                'inner bar ${i + 1} should touch inner bar $i in '
                'category $c',
          );
        }
      }
    });
  });

  // ── Scaling: max NOT sum across siblings ─────────────────────────────

  group('Y-axis scaling for grouped bars', () {
    test('default maxY equals max(inner bar total) across all categories', () {
      // Inner totals: c0/b0=10, c0/b1=17, c1/b0=15, c1/b1=22 → max=22.
      // Sum-based scaling would give 27 in c0 (10+17) or 37 in c1 (15+22).
      final data = _grouped(categoryCount: 2, innerCount: 2);
      final layout = _painter(data).computeLayout(kChartTestSize);

      // The tallest inner bar's segment top should reach the chart top
      // (within rounding). Find the segment for value 22 — it is the
      // top segment of category 1, inner bar 1.
      final tallest = layout.segments.firstWhere(
        (s) => s.barIndex == 1 && s.innerBarIndex == 1,
      );
      expect(tallest.value, 22);
      expect((tallest.bounds.top - layout.chartArea.top).abs(), lessThan(0.5));
    });

    test('legacy maxY default unchanged: max(BarGroup.total)', () {
      // Bars 10, 20, 30 → max should be 30 → tallest segment top at chart top.
      final layout = _painter(_legacy(n: 3)).computeLayout(kChartTestSize);
      final tallest = layout.segments.firstWhere((s) => s.value == 30);
      expect((tallest.bounds.top - layout.chartArea.top).abs(), lessThan(0.5));
    });

    test('explicit maxY overrides default for grouped charts', () {
      final base = _grouped(categoryCount: 2, innerCount: 2);
      final overridden = BarChartData(
        bars: base.bars,
        categories: base.categories,
        legend: base.legend,
        maxY: 100,
      );
      final layout = _painter(overridden).computeLayout(kChartTestSize);
      // With maxY=100 and tallest value=22, top segment should sit well
      // below the chart top.
      final tallest = layout.segments.firstWhere((s) => s.value == 22);
      expect(
        tallest.bounds.top,
        greaterThan(layout.chartArea.top + layout.chartArea.height * 0.5),
      );
    });
  });

  // ── Hit testing carries grouped identity ─────────────────────────────

  group('Hit testing on grouped bars', () {
    test('hit returns correct categoryIndex/innerBarIndex/segmentIndex', () {
      final layout = _painter(
        _grouped(categoryCount: 3, innerCount: 2),
      ).computeLayout(kChartTestSize);
      // Pick a target segment and hit-test its center.
      final target = layout.segments.firstWhere(
        (s) => s.barIndex == 2 && s.innerBarIndex == 1,
      );
      final hit = layout.hitTest(target.bounds.center);
      expect(hit, isNotNull);
      expect(hit!.segment.barIndex, 2);
      expect(hit.segment.innerBarIndex, 1);
      expect(hit.segment.segmentIndex, 0);
    });

    test('grouped chart — innerBarLabel carries the inner BarGroup label', () {
      // Use explicit distinctive labels here rather than _grouped()'s
      // 'inner-c-b' pattern, so the assertions read clearly.
      final data = BarChartData(
        bars: const [],
        legend: const [LegendEntry(label: 'cat', color: _color)],
        categories: [
          BarCategory(
            label: 'Q1',
            bars: [
              _bar('North', [10]),
              _bar('South', [20]),
            ],
          ),
        ],
      );
      final layout = _painter(data).computeLayout(kChartTestSize);
      final north = layout.segments.firstWhere((s) => s.innerBarIndex == 0);
      final south = layout.segments.firstWhere((s) => s.innerBarIndex == 1);
      expect(north.innerBarLabel, 'North');
      expect(south.innerBarLabel, 'South');
      expect(
        north.barLabel,
        'Q1',
        reason: 'barLabel should still carry the outer category label',
      );
    });

    test('legacy chart — innerBarLabel equals barLabel', () {
      // For legacy (ungrouped) charts, the inner and outer labels are
      // the same value — BarGroup.label is both the X-axis tick label
      // and the bar's own label.
      final layout = _painter(_legacy(n: 3)).computeLayout(kChartTestSize);
      for (final s in layout.segments) {
        expect(
          s.innerBarLabel,
          equals(s.barLabel),
          reason: 'Legacy bars: inner == outer label',
        );
      }
    });
  });

  // ── Edge cases ───────────────────────────────────────────────────────

  group('Edge cases', () {
    test('zero-value segments are skipped', () {
      final data = BarChartData(
        bars: [
          _bar('B', [0, 10, 0, 5]),
        ],
        legend: const [LegendEntry(label: 'cat', color: _color)],
      );
      final layout = _painter(data).computeLayout(kChartTestSize);
      // Only the two non-zero segments should produce rects.
      expect(layout.segments, hasLength(2));
      expect(layout.segments.map((s) => s.value).toList(), [10, 5]);
    });

    test('uneven inner-bar counts across categories render without crash', () {
      final data = BarChartData(
        bars: const [],
        legend: const [LegendEntry(label: 'cat', color: _color)],
        categories: [
          BarCategory(
            label: 'A',
            bars: [
              _bar('a0', [10]),
            ],
          ),
          BarCategory(
            label: 'B',
            bars: [
              _bar('b0', [12]),
              _bar('b1', [8]),
              _bar('b2', [15]),
            ],
          ),
        ],
      );
      final layout = _painter(data).computeLayout(kChartTestSize);
      // 1 + 3 inner bars → 4 segments.
      expect(layout.segments, hasLength(4));

      // Smoke: paint must not throw.
      final recorder = PictureRecorder();
      expect(
        () => _painter(data).paint(Canvas(recorder), kChartTestSize),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test('empty bars and categories → empty layout, no-op paint', () {
      const data = BarChartData(bars: [], legend: []);
      final painter = _painter(data);
      final layout = painter.computeLayout(kChartTestSize);
      expect(layout.segments, isEmpty);

      final recorder = PictureRecorder();
      expect(
        () => painter.paint(Canvas(recorder), kChartTestSize),
        returnsNormally,
      );
      recorder.endRecording();
    });

    test('grouped paint smoke test across 2x3 grid', () {
      final recorder = PictureRecorder();
      expect(
        () => _painter(
          _grouped(categoryCount: 2, innerCount: 3),
        ).paint(Canvas(recorder), kChartTestSize),
        returnsNormally,
      );
      recorder.endRecording();
    });
  });
}
