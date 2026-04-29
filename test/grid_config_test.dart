import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

import 'test_utils.dart';

// ── Shared ────────────────────────────────────────────────────────────────

LineChartData _line() {
  return const LineChartData(
    minX: 0,
    maxX: 10,
    minY: 0,
    maxY: 100,
    series: [
      LineSeriesData(
        name: 'S',
        color: Color(0xFF000000),
        points: [
          LinePoint(x: 0, y: 10),
          LinePoint(x: 5, y: 50),
          LinePoint(x: 10, y: 80),
        ],
      ),
    ],
  );
}

ScatterPlotData _scatter() {
  return const ScatterPlotData(
    minX: 0,
    maxX: 10,
    minY: 0,
    maxY: 100,
    points: [
      ScatterPoint(x: 1, y: 20),
      ScatterPoint(x: 5, y: 50),
      ScatterPoint(x: 9, y: 80),
    ],
  );
}

BarChartData _bar() {
  return const BarChartData(
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
}

void _paint(CustomPainter p) {
  final recorder = PictureRecorder();
  p.paint(Canvas(recorder), kChartTestSize);
  recorder.endRecording();
}

void main() {
  // ── GridConfig data model ─────────────────────────────────────────────

  group('GridConfig defaults', () {
    test('no-arg constructor uses the package-default color and width', () {
      const cfg = GridConfig();
      expect(cfg.showHorizontal, isTrue);
      expect(cfg.showVertical, isTrue);
      expect(cfg.horizontalSubGridLinesBetweenTicks, 0);
      expect(cfg.verticalSubGridLinesBetweenTicks, 0);
      expect(cfg.subGridAlphaMultiplier, 0.6);
    });

    test('standard preset equals default constructor', () {
      expect(GridConfig.standard, equals(const GridConfig()));
    });

    test('none preset hides both grids', () {
      expect(GridConfig.none.showHorizontal, isFalse);
      expect(GridConfig.none.showVertical, isFalse);
    });

    test('horizontalOnly preset shows horizontal, hides vertical', () {
      expect(GridConfig.horizontalOnly.showHorizontal, isTrue);
      expect(GridConfig.horizontalOnly.showVertical, isFalse);
    });

    test('verticalOnly preset hides horizontal, shows vertical', () {
      expect(GridConfig.verticalOnly.showHorizontal, isFalse);
      expect(GridConfig.verticalOnly.showVertical, isTrue);
    });
  });

  group('GridConfig equality', () {
    test('two default configs are equal and hash to the same value', () {
      const a = GridConfig();
      const b = GridConfig();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('differing any field breaks equality', () {
      const base = GridConfig();
      expect(base, isNot(equals(const GridConfig(showHorizontal: false))));
      expect(base, isNot(equals(const GridConfig(showVertical: false))));
      expect(
        base,
        isNot(equals(const GridConfig(horizontalSubGridLinesBetweenTicks: 2))),
      );
      expect(
        base,
        isNot(equals(const GridConfig(verticalSubGridLinesBetweenTicks: 2))),
      );
      expect(
        base,
        isNot(equals(const GridConfig(subGridAlphaMultiplier: 0.3))),
      );
      expect(base, isNot(equals(const GridConfig(strokeWidth: 2.5))));
      expect(base, isNot(equals(const GridConfig(jitterRatio: 0.1))));
      expect(base, isNot(equals(const GridConfig(color: Color(0xFF112233)))));
    });
  });

  group('GridConfig assertions', () {
    test('negative horizontalSubGridLinesBetweenTicks throws', () {
      expect(
        () => GridConfig(horizontalSubGridLinesBetweenTicks: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('negative verticalSubGridLinesBetweenTicks throws', () {
      expect(
        () => GridConfig(verticalSubGridLinesBetweenTicks: -1),
        throwsA(isA<AssertionError>()),
      );
    });

    test('subGridAlphaMultiplier outside [0, 1] throws', () {
      expect(
        () => GridConfig(subGridAlphaMultiplier: -0.1),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GridConfig(subGridAlphaMultiplier: 1.5),
        throwsA(isA<AssertionError>()),
      );
    });

    test('zero sub-grid count is valid (the feature-off value)', () {
      expect(
        () => const GridConfig(
          horizontalSubGridLinesBetweenTicks: 0,
          verticalSubGridLinesBetweenTicks: 0,
        ),
        returnsNormally,
      );
    });

    test('alpha multiplier at boundaries is valid', () {
      expect(
        () => const GridConfig(subGridAlphaMultiplier: 0),
        returnsNormally,
      );
      expect(
        () => const GridConfig(subGridAlphaMultiplier: 1),
        returnsNormally,
      );
    });
  });

  // ── Painter behavior ─────────────────────────────────────────────────

  group('Painter shouldRepaint reacts to grid changes', () {
    test('line painter repaints when grid differs', () {
      final a = HandDrawnLineChartPainter(data: _line());
      final b = HandDrawnLineChartPainter(
        data: _line(),
        grid: GridConfig.horizontalOnly,
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('scatter painter repaints when grid differs', () {
      final a = HandDrawnScatterPlotPainter(data: _scatter());
      final b = HandDrawnScatterPlotPainter(
        data: _scatter(),
        grid: const GridConfig(subGridAlphaMultiplier: 0.3),
      );
      expect(b.shouldRepaint(a), isTrue);
    });

    test('bar painter repaints when grid differs', () {
      final a = HandDrawnBarChartPainter(data: _bar());
      final b = HandDrawnBarChartPainter(data: _bar(), grid: GridConfig.none);
      expect(b.shouldRepaint(a), isTrue);
    });

    test('painter does NOT repaint when grid is the same', () {
      final a = HandDrawnLineChartPainter(
        data: _line(),
        grid: GridConfig.horizontalOnly,
      );
      final b = HandDrawnLineChartPainter(
        data: _line(),
        grid: GridConfig.horizontalOnly,
      );
      expect(b.shouldRepaint(a), isFalse);
    });
  });

  group('Painter smoke tests across grid configurations', () {
    final configs = <({String label, GridConfig config})>[
      (label: 'standard', config: GridConfig.standard),
      (label: 'none', config: GridConfig.none),
      (label: 'horizontalOnly', config: GridConfig.horizontalOnly),
      (label: 'verticalOnly', config: GridConfig.verticalOnly),
      (
        label: 'sub-grid horizontal',
        config: const GridConfig(horizontalSubGridLinesBetweenTicks: 3),
      ),
      (
        label: 'sub-grid vertical',
        config: const GridConfig(verticalSubGridLinesBetweenTicks: 3),
      ),
      (
        label: 'sub-grid both',
        config: const GridConfig(
          horizontalSubGridLinesBetweenTicks: 4,
          verticalSubGridLinesBetweenTicks: 4,
        ),
      ),
      (
        label: 'sub-grid with reduced alpha',
        config: const GridConfig(
          horizontalSubGridLinesBetweenTicks: 2,
          verticalSubGridLinesBetweenTicks: 2,
          subGridAlphaMultiplier: 0.2,
        ),
      ),
    ];

    for (final c in configs) {
      test('line painter paints cleanly — ${c.label}', () {
        expect(
          () =>
              _paint(HandDrawnLineChartPainter(data: _line(), grid: c.config)),
          returnsNormally,
        );
      });

      test('scatter painter paints cleanly — ${c.label}', () {
        expect(
          () => _paint(
            HandDrawnScatterPlotPainter(data: _scatter(), grid: c.config),
          ),
          returnsNormally,
        );
      });

      test('bar painter paints cleanly — ${c.label}', () {
        // Bar charts ignore vertical-grid config (no numeric X), but the
        // painter should still accept any grid without crashing.
        expect(
          () => _paint(HandDrawnBarChartPainter(data: _bar(), grid: c.config)),
          returnsNormally,
        );
      });
    }
  });
}
