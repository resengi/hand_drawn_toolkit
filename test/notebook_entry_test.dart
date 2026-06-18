import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

/// Default row height used across these tests (matches `NotebookStyle()`).
const double _lineHeight = 28.0;

/// The height a scaled-down widget settles at: scaleDown fits an oversized
/// widget to this fraction of the row, leaving a little margin above and below
/// (mirrors the implementation's content-band fraction).
const double _scaleDownBand = _lineHeight * 0.8;

/// A long run of text that wraps onto several rows at any reasonable font.
const String _longText =
    'Lorem ipsum dolor sit amet consectetur adipiscing elit sed do eiusmod '
    'tempor incididunt ut labore et dolore magna aliqua enim ad minim veniam';

/// A short run that still wraps at a large font, used to compare span styling
/// without the wrapped height approaching the test surface bounds.
const String _mergeText = 'Lorem ipsum dolor sit amet now ok go';

/// A medium run used to compare text fit modes: at a large font it wraps onto
/// several rows under clip, and onto fewer under scaleDown.
const String _scaleText = 'Lorem ipsum dolor sit amet consectetur adipi elit';

/// Wraps [child] with a direction, an ambient text style, and a bounded width,
/// pinned to the top-left so child coordinates are easy to reason about.
Widget _host({
  required Widget child,
  TextDirection direction = TextDirection.ltr,
  double width = 300,
  TextStyle textStyle = const TextStyle(fontSize: 14, color: Color(0xFF202020)),
  TextScaler? mediaTextScaler,
}) {
  Widget tree = Directionality(
    textDirection: direction,
    child: DefaultTextStyle(
      style: textStyle,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: child),
      ),
    ),
  );
  if (mediaTextScaler != null) {
    tree = MediaQuery(
      data: MediaQueryData(textScaler: mediaTextScaler),
      child: tree,
    );
  }
  return tree;
}

SizedBox _box(Key key, double w, double h) =>
    SizedBox(key: key, width: w, height: h);

void main() {
  group('text rows', () {
    testWidgets('short text occupies a single row', (tester) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const ['Hi'])),
      );
      expect(tester.getSize(find.byType(NotebookEntry)).height, _lineHeight);
    });

    testWidgets('long text wraps onto multiple rows', (tester) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const [_longText])),
      );
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        greaterThan(_lineHeight),
      );
    });

    testWidgets('an embedded newline starts a new row', (tester) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const ['a\nb\nc'])),
      );
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        3 * _lineHeight,
      );
    });

    testWidgets('a standalone newline element is a hard break', (tester) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const ['a', '\n', 'b'])),
      );
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        2 * _lineHeight,
      );
    });

    testWidgets('consecutive newlines leave blank rows', (tester) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const ['a\n\nb'])),
      );
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        3 * _lineHeight,
      );
    });

    testWidgets('an empty string contributes nothing', (tester) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const ['', 'Hi', ''])),
      );
      expect(tester.getSize(find.byType(NotebookEntry)).height, _lineHeight);
    });
  });

  group('minRows', () {
    testWidgets('floors the row count for an empty entry', (tester) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const [], minRows: 3)),
      );
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        3 * _lineHeight,
      );
    });

    testWidgets('floors the row count for short content', (tester) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const ['Hi'], minRows: 3)),
      );
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        3 * _lineHeight,
      );
    });

    testWidgets('does not shrink content below the rows it needs', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const ['a\nb\nc'], minRows: 1)),
      );
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        3 * _lineHeight,
      );
    });

    test('rejects minRows below one', () {
      expect(
        () => NotebookEntry(children: const ['Hi'], minRows: 0),
        throwsAssertionError,
      );
    });
  });

  group('content validation', () {
    test('throws on an unsupported child type', () {
      expect(
        () => NotebookEntry(children: const [42]),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('widget children', () {
    testWidgets('a small widget shares the row with following text', (
      tester,
    ) async {
      const key = ValueKey('box');
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: [_box(key, 20, 20), ' label'])),
      );
      expect(tester.getSize(find.byType(NotebookEntry)).height, _lineHeight);
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('a widget that does not fit moves to the next row', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          child: NotebookEntry(
            children: [
              _box(const ValueKey('a'), 200, 20),
              _box(const ValueKey('b'), 200, 20),
            ],
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        2 * _lineHeight,
      );
    });

    testWidgets('an over-wide widget keeps its width and the entry clips', (
      tester,
    ) async {
      const key = ValueKey('wide');
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: [_box(key, 400, 20)])),
      );
      expect(tester.getSize(find.byType(NotebookEntry)).width, 300);
      expect(tester.getSize(find.byType(NotebookEntry)).height, _lineHeight);
      expect(tester.getSize(find.byKey(key)), const Size(400, 20));
    });

    testWidgets('the real widget is rendered exactly once', (tester) async {
      const key = ValueKey('once');
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: [_box(key, 20, 20)])),
      );
      expect(find.byKey(key), findsOneWidget);
    });

    testWidgets('an interactive child remains tappable', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _host(
          child: NotebookEntry(
            children: [
              HandDrawnStatusSquare(
                color: const Color(0xFF2E7D32),
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      );
      await tester.tap(find.byType(HandDrawnStatusSquare));
      expect(tapped, isTrue);
    });
  });

  group('fit', () {
    testWidgets('scaleDown shrinks a tall widget to one row', (tester) async {
      const key = ValueKey('tall');
      await tester.pumpWidget(
        _host(
          child: NotebookEntry(
            children: [_box(key, 56, 56)],
            fit: NotebookFit.scaleDown,
          ),
        ),
      );
      // The entry is one row tall and the child keeps its natural layout size,
      // but it is painted scaled down to the row's content band (56 -> 22.4),
      // leaving a little space above and below rather than filling the row.
      expect(tester.getSize(find.byType(NotebookEntry)).height, _lineHeight);
      expect(tester.getSize(find.byKey(key)), const Size(56, 56));
      final rect = tester.getRect(find.byKey(key));
      expect(rect.width, moreOrLessEquals(_scaleDownBand, epsilon: 0.01));
      expect(rect.height, moreOrLessEquals(_scaleDownBand, epsilon: 0.01));
    });

    testWidgets('scaleDownContentFraction sets how much of the row a scaled '
        'widget fills', (tester) async {
      const key = ValueKey('tall');
      await tester.pumpWidget(
        _host(
          child: NotebookEntry(
            children: [_box(key, 56, 56)],
            fit: NotebookFit.scaleDown,
            scaleDownContentFraction: 0.5,
          ),
        ),
      );
      // 56 -> 14 (0.5 * 28), overriding the default band.
      expect(
        tester.getRect(find.byKey(key)).height,
        moreOrLessEquals(_lineHeight * 0.5, epsilon: 0.01),
      );
    });

    test('scaleDownContentFraction must be in the range (0, 1]', () {
      expect(
        () => NotebookEntry(children: const ['x'], scaleDownContentFraction: 0),
        throwsAssertionError,
      );
      expect(
        () =>
            NotebookEntry(children: const ['x'], scaleDownContentFraction: 1.5),
        throwsAssertionError,
      );
    });

    testWidgets('clip keeps a tall widget at natural size on one row', (
      tester,
    ) async {
      const key = ValueKey('tallclip');
      await tester.pumpWidget(
        _host(
          child: NotebookEntry(
            children: [_box(key, 56, 56)],
            fit: NotebookFit.clip,
          ),
        ),
      );
      expect(tester.getSize(find.byType(NotebookEntry)).height, _lineHeight);
      expect(tester.getSize(find.byKey(key)), const Size(56, 56));
      expect(
        tester.getRect(find.byKey(key)).height,
        moreOrLessEquals(56, epsilon: 0.01),
      );
    });

    testWidgets(
      'scaleDown shrinks large text so it needs fewer rows than clip',
      (tester) async {
        const big = TextStyle(fontSize: 56, color: Color(0xFF000000));
        await tester.pumpWidget(
          _host(
            textStyle: big,
            child: NotebookEntry(
              children: const [_scaleText],
              fit: NotebookFit.clip,
            ),
          ),
        );
        final clipHeight = tester.getSize(find.byType(NotebookEntry)).height;

        await tester.pumpWidget(
          _host(
            textStyle: big,
            child: NotebookEntry(
              children: const [_scaleText],
              fit: NotebookFit.scaleDown,
            ),
          ),
        );
        final scaleHeight = tester.getSize(find.byType(NotebookEntry)).height;

        // Reduced font fits more per line, so scaleDown uses fewer rows.
        expect(scaleHeight, lessThan(clipHeight));
      },
    );
  });

  group('vertical placement', () {
    Future<double> topOffset(
      WidgetTester tester,
      TextAlignVertical align,
    ) async {
      const key = ValueKey('v');
      await tester.pumpWidget(
        _host(
          child: NotebookEntry(
            children: [_box(key, 20, 20)],
            textAlignVertical: align,
          ),
        ),
      );
      return tester.getTopLeft(find.byKey(key)).dy -
          tester.getTopLeft(find.byType(NotebookEntry)).dy;
    }

    testWidgets('top places the line at the row top', (tester) async {
      expect(
        await topOffset(tester, TextAlignVertical.top),
        moreOrLessEquals(0, epsilon: 0.01),
      );
    });

    testWidgets('center places the line in the row middle', (tester) async {
      // (28 - 20) / 2 = 4
      expect(
        await topOffset(tester, TextAlignVertical.center),
        moreOrLessEquals(4, epsilon: 0.01),
      );
    });

    testWidgets('bottom places the line at the row bottom', (tester) async {
      // 28 - 20 = 8
      expect(
        await topOffset(tester, TextAlignVertical.bottom),
        moreOrLessEquals(8, epsilon: 0.01),
      );
    });

    testWidgets('pieces on a row center against each other', (tester) async {
      const tallKey = ValueKey('tall');
      const shortKey = ValueKey('short');
      await tester.pumpWidget(
        _host(
          child: NotebookEntry(
            children: [_box(tallKey, 20, 20), _box(shortKey, 10, 10)],
          ),
        ),
      );
      final entryTop = tester.getTopLeft(find.byType(NotebookEntry)).dy;
      final tallCenter =
          tester.getTopLeft(find.byKey(tallKey)).dy - entryTop + 20 / 2;
      final shortCenter =
          tester.getTopLeft(find.byKey(shortKey)).dy - entryTop + 10 / 2;
      expect(shortCenter, moreOrLessEquals(tallCenter, epsilon: 0.01));
    });
  });

  group('direction', () {
    testWidgets('LTR places the leading widget on the left', (tester) async {
      const key = ValueKey('lead');
      await tester.pumpWidget(
        _host(
          direction: TextDirection.ltr,
          child: NotebookEntry(children: [_box(key, 20, 20), 'x']),
        ),
      );
      final dx =
          tester.getTopLeft(find.byKey(key)).dx -
          tester.getTopLeft(find.byType(NotebookEntry)).dx;
      expect(dx, moreOrLessEquals(0, epsilon: 0.01));
    });

    testWidgets('RTL places the leading widget on the right', (tester) async {
      const key = ValueKey('lead');
      await tester.pumpWidget(
        _host(
          direction: TextDirection.rtl,
          child: NotebookEntry(children: [_box(key, 20, 20), 'x']),
        ),
      );
      // Entry width 300, box width 20, leading offset 0 -> x = 300 - 20.
      final dx =
          tester.getTopLeft(find.byKey(key)).dx -
          tester.getTopLeft(find.byType(NotebookEntry)).dx;
      expect(dx, moreOrLessEquals(280, epsilon: 0.01));
    });

    testWidgets('throws when no direction is available', (tester) async {
      await tester.pumpWidget(
        DefaultTextStyle(
          style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 300,
              child: NotebookEntry(children: const ['Hi']),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });
  });

  group('horizontal flow (wrap: false)', () {
    testWidgets('unbounded width while wrapping throws', (tester) async {
      await tester.pumpWidget(
        _host(
          child: OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            alignment: Alignment.topLeft,
            child: NotebookEntry(children: const ['Hi']),
          ),
        ),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('wrap:false lays long text on a single row', (tester) async {
      await tester.pumpWidget(
        _host(
          child: OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            alignment: Alignment.topLeft,
            child: NotebookEntry(children: const [_longText], wrap: false),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(NotebookEntry)).height, _lineHeight);
    });

    testWidgets('wrap:false still honors hard breaks', (tester) async {
      await tester.pumpWidget(
        _host(
          child: OverflowBox(
            minWidth: 0,
            maxWidth: double.infinity,
            minHeight: 0,
            maxHeight: double.infinity,
            alignment: Alignment.topLeft,
            child: NotebookEntry(children: const ['a\nb'], wrap: false),
          ),
        ),
      );
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        2 * _lineHeight,
      );
    });
  });

  group('content-driven height', () {
    testWidgets('a forced external height is unsupported', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: DefaultTextStyle(
            style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 300,
                height: 200,
                child: NotebookEntry(children: const ['Hi']),
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isA<FlutterError>());
    });

    testWidgets('a loose height larger than the content is allowed', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const ['Hi'])),
      );
      expect(tester.takeException(), isNull);
      expect(tester.getSize(find.byType(NotebookEntry)).height, _lineHeight);
    });
  });

  group('style resolution', () {
    testWidgets('an entry inherits line height from an enclosing scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          child: const NotebookScope(
            style: NotebookStyle(lineHeight: 40),
            child: _EntryProbe(),
          ),
        ),
      );
      expect(tester.getSize(find.byType(NotebookEntry)).height, 40);
    });

    testWidgets('an explicit style overrides an enclosing scope', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          child: NotebookScope(
            style: const NotebookStyle(lineHeight: 40),
            child: NotebookEntry(
              children: const ['Hi'],
              style: const NotebookStyle(lineHeight: 50),
            ),
          ),
        ),
      );
      expect(tester.getSize(find.byType(NotebookEntry)).height, 50);
    });

    testWidgets('with no scope an entry falls back to the default ruling', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const ['Hi'])),
      );
      expect(tester.getSize(find.byType(NotebookEntry)).height, _lineHeight);
    });

    testWidgets('HandDrawnNotebook publishes line height to its entries', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          child: const HandDrawnNotebook(lineHeight: 40, child: _EntryProbe()),
        ),
      );
      expect(tester.getSize(find.byType(NotebookEntry)).height, 40);
    });
  });

  group('span styling', () {
    testWidgets('a span without a font size inherits the ambient size', (
      tester,
    ) async {
      const big = TextStyle(fontSize: 40, color: Color(0xFF000000));
      await tester.pumpWidget(
        _host(
          textStyle: big,
          child: NotebookEntry(
            children: const [_mergeText],
            fit: NotebookFit.clip,
          ),
        ),
      );
      final plainHeight = tester.getSize(find.byType(NotebookEntry)).height;

      await tester.pumpWidget(
        _host(
          textStyle: big,
          child: NotebookEntry(
            children: const [
              NotebookSpan(
                _mergeText,
                style: TextStyle(color: Color(0xFFD32F2F)),
              ),
            ],
            fit: NotebookFit.clip,
          ),
        ),
      );
      final spanHeight = tester.getSize(find.byType(NotebookEntry)).height;

      // Same wrap behavior => the span kept the ambient font size (merge, not
      // replace); a smaller font would have produced a different row count.
      expect(spanHeight, plainHeight);
    });
  });

  group('mixed content', () {
    testWidgets('text continues after a widget across rows', (tester) async {
      const key = ValueKey('lead');
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: [_box(key, 20, 20), _longText])),
      );
      final entryTop = tester.getTopLeft(find.byType(NotebookEntry)).dy;
      final boxTop = tester.getTopLeft(find.byKey(key)).dy - entryTop;
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        greaterThan(_lineHeight),
      );
      // The leading widget sits on the first row.
      expect(boxTop, lessThan(_lineHeight));
    });
  });

  group('text wrapping edge cases', () {
    testWidgets('a long unbroken word wraps instead of clipping', (
      tester,
    ) async {
      final word = 'A' * 200;
      await tester.pumpWidget(_host(child: NotebookEntry(children: [word])));
      expect(tester.takeException(), isNull);
      // A 200-character token cannot fit one 300px row, so it must wrap.
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        greaterThan(_lineHeight),
      );
    });

    testWidgets('runs of whitespace around a wrap lay out cleanly', (
      tester,
    ) async {
      const spaced =
          'alpha     beta     gamma     delta     epsilon     zeta     eta';
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const [spaced])),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        greaterThan(_lineHeight),
      );
    });

    testWidgets('emoji and grapheme clusters lay out without error', (
      tester,
    ) async {
      const emoji =
          'team 👍🏽 family 👨‍👩‍👧‍👦 wave 👋 grapheme cluster test done';
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const [emoji])),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        greaterThanOrEqualTo(_lineHeight),
      );
    });

    testWidgets('RTL text wraps onto multiple rows', (tester) async {
      const rtl =
          'لوريم إيبسوم دولار سيت أميت كونسيكتيتور أديبيسسينغ إيليت سيد دو '
          'إيوسمود تيمبور إنسيديدونت أوت لابوري إت دولوري ماجنا أليكوا';
      await tester.pumpWidget(
        _host(
          direction: TextDirection.rtl,
          child: NotebookEntry(children: const [rtl]),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        greaterThan(_lineHeight),
      );
    });

    testWidgets('mixed LTR and RTL runs lay out without error', (tester) async {
      const mixed = 'Hello مرحبا world عالم this نص is مختلط mixed content now';
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const [mixed])),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        greaterThanOrEqualTo(_lineHeight),
      );
    });

    testWidgets('text after a nearly full row wraps to the next row', (
      tester,
    ) async {
      const key = ValueKey('wide');
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: [_box(key, 290, 20), _longText])),
      );
      expect(tester.takeException(), isNull);
      expect(find.byKey(key), findsOneWidget);
      // Only ~10px remains on the first row, so the text flows onto later rows.
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        greaterThan(_lineHeight),
      );
    });

    testWidgets('text after an oversized widget wraps to the next row', (
      tester,
    ) async {
      const key = ValueKey('over');
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: [_box(key, 400, 20), _longText])),
      );
      expect(tester.takeException(), isNull);
      // The widget keeps its natural width and the text starts past it.
      expect(tester.getSize(find.byKey(key)).width, 400);
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        greaterThan(_lineHeight),
      );
    });
  });

  group('hit-testing respects row clipping', () {
    testWidgets('a clipped tall widget is not tappable outside its row', (
      tester,
    ) async {
      var taps = 0;
      const key = ValueKey('tall');
      await tester.pumpWidget(
        _host(
          child: NotebookEntry(
            fit: NotebookFit.clip,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => taps++,
                child: _box(key, 56, 56),
              ),
              '\n',
              'next row',
            ],
          ),
        ),
      );
      // Row 0 holds the tall widget; row 1 holds the text.
      expect(
        tester.getSize(find.byType(NotebookEntry)).height,
        2 * _lineHeight,
      );
      final topLeft = tester.getTopLeft(find.byType(NotebookEntry));

      // Inside the visible row-0 slice: the widget receives the tap.
      await tester.tapAt(topLeft + const Offset(20, 14));
      expect(taps, 1);

      // In row 1, where the widget would reach if it were not clipped to its
      // row: the tap must not land on it.
      await tester.tapAt(topLeft + const Offset(20, 35));
      expect(taps, 1);
    });
  });

  group('ambient text scaling', () {
    testWidgets('clip honors a larger accessibility text scale', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 20, color: Color(0xFF000000));
      await tester.pumpWidget(
        _host(
          textStyle: style,
          child: NotebookEntry(
            children: const [_scaleText],
            fit: NotebookFit.clip,
          ),
        ),
      );
      final base = tester.getSize(find.byType(NotebookEntry)).height;

      await tester.pumpWidget(
        _host(
          textStyle: style,
          mediaTextScaler: const TextScaler.linear(2),
          child: NotebookEntry(
            children: const [_scaleText],
            fit: NotebookFit.clip,
          ),
        ),
      );
      final scaled = tester.getSize(find.byType(NotebookEntry)).height;

      // Larger text occupies more rows: accessibility scaling is respected.
      expect(scaled, greaterThan(base));
    });

    testWidgets('scaleDown caps at the row regardless of text scale', (
      tester,
    ) async {
      const style = TextStyle(fontSize: 40, color: Color(0xFF000000));
      await tester.pumpWidget(
        _host(
          textStyle: style,
          child: NotebookEntry(
            children: const [_scaleText],
            fit: NotebookFit.scaleDown,
          ),
        ),
      );
      final base = tester.getSize(find.byType(NotebookEntry)).height;

      await tester.pumpWidget(
        _host(
          textStyle: style,
          mediaTextScaler: const TextScaler.linear(3),
          child: NotebookEntry(
            children: const [_scaleText],
            fit: NotebookFit.scaleDown,
          ),
        ),
      );
      final scaled = tester.getSize(find.byType(NotebookEntry)).height;

      // Each line is capped to fit the row, so the layout is unchanged.
      expect(scaled, base);
    });
  });

  group('status square and text matrix', () {
    const green = Color(0xFF2E7D32);

    Future<({Size entry, Size squareSize, Rect squareRect})> layout(
      WidgetTester tester, {
      required double square,
      required String text,
      required double fontSize,
      required NotebookFit fit,
    }) async {
      const key = ValueKey('sq');
      await tester.pumpWidget(
        _host(
          textStyle: TextStyle(
            fontSize: fontSize,
            color: const Color(0xFF000000),
          ),
          child: NotebookEntry(
            fit: fit,
            children: [
              HandDrawnStatusSquare(key: key, color: green, size: square),
              text,
            ],
          ),
        ),
      );
      return (
        entry: tester.getSize(find.byType(NotebookEntry)),
        squareSize: tester.getSize(find.byKey(key)),
        squareRect: tester.getRect(find.byKey(key)),
      );
    }

    testWidgets('small square, short text fills one row', (tester) async {
      final r = await layout(
        tester,
        square: 14,
        text: 'Hi',
        fontSize: 14,
        fit: NotebookFit.scaleDown,
      );
      expect(find.byType(HandDrawnStatusSquare), findsOneWidget);
      expect(r.entry.height, _lineHeight);
      expect(r.squareSize, const Size(14, 14));
    });

    testWidgets('small square, long text wraps', (tester) async {
      final r = await layout(
        tester,
        square: 14,
        text: _scaleText,
        fontSize: 14,
        fit: NotebookFit.scaleDown,
      );
      expect(find.byType(HandDrawnStatusSquare), findsOneWidget);
      expect(r.entry.height, greaterThan(_lineHeight));
      expect(r.squareRect.top, lessThan(_lineHeight)); // square sits on row 0
    });

    testWidgets('large square, short small text, clip keeps natural size', (
      tester,
    ) async {
      final r = await layout(
        tester,
        square: 56,
        text: 'Hi',
        fontSize: 14,
        fit: NotebookFit.clip,
      );
      expect(r.entry.height, _lineHeight);
      expect(r.squareSize.height, 56);
    });

    testWidgets('large square, short small text, scaleDown fits the row', (
      tester,
    ) async {
      final r = await layout(
        tester,
        square: 56,
        text: 'Hi',
        fontSize: 14,
        fit: NotebookFit.scaleDown,
      );
      expect(r.entry.height, _lineHeight);
      expect(
        r.squareRect.height,
        moreOrLessEquals(_scaleDownBand, epsilon: 0.01),
      );
    });

    testWidgets('large square, short large text, clip stays one row', (
      tester,
    ) async {
      final r = await layout(
        tester,
        square: 56,
        text: 'Hi',
        fontSize: 40,
        fit: NotebookFit.clip,
      );
      expect(r.entry.height, _lineHeight);
      expect(r.squareSize.height, 56);
    });

    testWidgets('large square, short large text, scaleDown stays one row', (
      tester,
    ) async {
      final r = await layout(
        tester,
        square: 56,
        text: 'Hi',
        fontSize: 40,
        fit: NotebookFit.scaleDown,
      );
      expect(r.entry.height, _lineHeight);
      expect(
        r.squareRect.height,
        moreOrLessEquals(_scaleDownBand, epsilon: 0.01),
      );
    });

    testWidgets('large square, long small text, clip wraps', (tester) async {
      final r = await layout(
        tester,
        square: 56,
        text: _scaleText,
        fontSize: 14,
        fit: NotebookFit.clip,
      );
      expect(r.entry.height, greaterThan(_lineHeight));
      expect(r.squareSize.height, 56);
    });

    testWidgets('large square, long small text, scaleDown wraps', (
      tester,
    ) async {
      final r = await layout(
        tester,
        square: 56,
        text: _scaleText,
        fontSize: 14,
        fit: NotebookFit.scaleDown,
      );
      expect(r.entry.height, greaterThan(_lineHeight));
      expect(
        r.squareRect.height,
        moreOrLessEquals(_scaleDownBand, epsilon: 0.01),
      );
    });

    testWidgets('large square, long large text, clip wraps', (tester) async {
      final r = await layout(
        tester,
        square: 56,
        text: _scaleText,
        fontSize: 40,
        fit: NotebookFit.clip,
      );
      expect(r.entry.height, greaterThan(_lineHeight));
      expect(r.squareSize.height, 56);
    });

    testWidgets('large square, long large text, scaleDown wraps', (
      tester,
    ) async {
      final r = await layout(
        tester,
        square: 56,
        text: _scaleText,
        fontSize: 40,
        fit: NotebookFit.scaleDown,
      );
      expect(r.entry.height, greaterThan(_lineHeight));
      expect(
        r.squareRect.height,
        moreOrLessEquals(_scaleDownBand, epsilon: 0.01),
      );
    });
  });

  group('semantics', () {
    testWidgets('exposes its text to the semantics tree', (tester) async {
      final handle = tester.ensureSemantics();
      await tester.pumpWidget(
        _host(child: NotebookEntry(children: const ['Hello notebook'])),
      );
      expect(find.bySemanticsLabel('Hello notebook'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a text label coexists with an interactive child', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      var tapped = false;
      await tester.pumpWidget(
        _host(
          child: NotebookEntry(
            children: [
              'note',
              HandDrawnStatusSquare(
                color: const Color(0xFF2E7D32),
                onTap: () => tapped = true,
              ),
            ],
          ),
        ),
      );
      // The painted text is exposed as a label...
      expect(find.bySemanticsLabel('note'), findsOneWidget);
      // ...and the interactive child still responds to a tap.
      await tester.tap(find.byType(HandDrawnStatusSquare));
      expect(tapped, isTrue);
      handle.dispose();
    });
  });
}

/// A fixed short entry used where the surrounding scope must supply the ruling.
class _EntryProbe extends StatelessWidget {
  const _EntryProbe();

  @override
  Widget build(BuildContext context) => NotebookEntry(children: const ['Hi']);
}
