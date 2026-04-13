import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

const _seg = BarSegment(category: 'cat', value: 10, color: Color(0xFF000000));
const _bar = BarGroup(label: 'A', segments: [_seg]);

void main() {
  group('BarCategory', () {
    test('accepts empty bars list (renders nothing for that category)', () {
      // BarCategory does not assert non-empty bars at construction —
      // the const constructor cannot, and the geometry helper handles
      // an empty inner-bars list by simply emitting no segment rects
      // for that category. This test pins that contract.
      const empty = BarCategory(label: 'X', bars: []);
      expect(empty.bars, isEmpty);
      expect(empty.label, 'X');
    });

    test('equality is structural', () {
      const a = BarCategory(label: 'X', bars: [_bar]);
      const b = BarCategory(label: 'X', bars: [_bar]);
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('BarChartData.categories / resolvedCategories', () {
    test('categories defaults to empty', () {
      const data = BarChartData(bars: [], legend: []);
      expect(data.categories, isEmpty);
    });

    test('resolvedCategories projects bars when categories is empty', () {
      const data = BarChartData(bars: [_bar], legend: []);
      final resolved = data.resolvedCategories;
      expect(resolved, hasLength(1));
      expect(resolved.single.label, 'A');
      expect(resolved.single.bars.single, _bar);
    });

    test('resolvedCategories prefers categories over bars when present', () {
      const cat = BarCategory(label: 'Q1', bars: [_bar, _bar]);
      const data = BarChartData(bars: [_bar], legend: [], categories: [cat]);
      expect(data.resolvedCategories, [cat]);
    });

    test('hasGroupedBars is false for legacy bars input', () {
      const data = BarChartData(bars: [_bar, _bar], legend: []);
      expect(data.hasGroupedBars, isFalse);
    });

    test('hasGroupedBars is false for single-inner-bar categories', () {
      const data = BarChartData(
        bars: [],
        legend: [],
        categories: [
          BarCategory(label: 'X', bars: [_bar]),
        ],
      );
      expect(data.hasGroupedBars, isFalse);
    });

    test('hasGroupedBars is true when any category has 2+ bars', () {
      const data = BarChartData(
        bars: [],
        legend: [],
        categories: [
          BarCategory(label: 'A', bars: [_bar]),
          BarCategory(label: 'B', bars: [_bar, _bar]),
        ],
      );
      expect(data.hasGroupedBars, isTrue);
    });

    test('equality includes categories', () {
      const a = BarChartData(bars: [], legend: []);
      const b = BarChartData(
        bars: [],
        legend: [],
        categories: [
          BarCategory(label: 'X', bars: [_bar]),
        ],
      );
      expect(a, isNot(equals(b)));
    });
  });
}
