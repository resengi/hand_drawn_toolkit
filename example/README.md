# Hand Drawn Toolkit — Example

A demo app showcasing the `hand_drawn_toolkit` package. It renders a journal-style
page that exercises every major feature: containers, dividers, status squares,
text fields, notebooks, charts (bar, line, scatter, function-backed),
discontinuous functions, tables (including resizable columns), interactive
hit-testing across every chart variant, plot-area clipping, and custom path
building.

## Running the Example

Make sure you are in the example directory, then run:

```bash
flutter pub get
flutter run
```

## What It Demonstrates

- **`HandDrawnContainer`** with default and customized parameters (stroke color,
  irregularity, background fill, padding)
- **`HandDrawnDivider`** as a drop-in replacement for Flutter's `Divider`,
  including `indent` / `endIndent` support
- **`HandDrawnLinePainter`** used directly with `CustomPaint` for a title
  underline via `lineHorizontal`
- **`HandDrawnStatusSquare`** with tap-to-cycle state (empty → checked → dashed),
  embedded in a notebook grid
- **`HandDrawnTextField`** in single-line and multiline configurations
- **`HandDrawnNotebook`** with ruled lines and `NotebookRow` grid snapping,
  shown in both non-uniform (status-square section) and uniform
  (notebook section) line modes
- **`HandDrawnBarChart`** in three variants:
  - Simple single-segment bars (Daily Steps)
  - Stacked bars with multiple segments per bar (Weekly Activity)
  - Grouped bars with multi-bar categories, including a Q4 group that combines
    grouped + stacked layouts (Quarterly Revenue by Region)
- **`HandDrawnLineChart`** in five point-based variants:
  - Single-series with categorical X labels (Weekly Runs)
  - Multi-series with auto-generated legend (Mood Tracker)
  - Negative-Y with a zero-crossing horizontal axis and sign-split fill,
    using `showFill: false` for a stroke-only series (Monthly Profit / Loss)
  - Negative-X with a zero-crossing vertical axis (Population Density)
  - Four-quadrant chart with both axes zero-crossing and `showFill: false`
    on the path series, plus a custom sub-grid (Pendulum Position)
- **`HandDrawnLineChart` with `FunctionSeriesData`** — three function-backed
  variants demonstrating the function-plotting API:
  - Single function: `f(x) = x²` with sparse visible dots at user-chosen
    x-values
  - Multiple functions on one chart with auto-generated legend (a parabola
    and a cubic, both four-quadrant)
  - Discontinuous function `f(x) = 1/x` with `clipToChartArea: true`,
    showing how non-finite evaluations split the curve into independent
    runs without bridging across the asymptote
- **`HandDrawnScatterPlot`** in four variants spanning all axis modes:
  positive-only, negative-Y with zero-crossing, negative-X with zero-crossing,
  and a four-quadrant variant with variable dot sizes
- **`HandDrawnTable`** with a title, row dividers, highlighted rows, and
  mixed column alignment (flex and fixed width)
- **Resizable table columns** built on top of `HandDrawnTable` with a
  `Stack` + drag handles, demonstrating how to extend the package's widgets
  with consumer-side interactivity
- **Interactive charts** — every static chart above has a corresponding
  interactive version (12 charts total: 3 bar, 5 ordinary line, 3 function,
  4 scatter) using `LayoutBuilder`, `computeLayout()`, and `GestureDetector`
  to tap chart elements and display hit-test results, including:
  - Bar segment hit-testing with grouped/inner labels
  - Sealed `LineHitTestResult` switching for point vs. segment hits, with
    automatic series-name reporting in multi-series and multi-function
    charts
  - Sparse point hits on function series (only `displayXs` dots are
    interactive) combined with full-curve segment hits
  - Discontinuity-aware hit testing — taps near the `1/x` asymptote fall
    through cleanly with no bridging segment
  - Scatter point hit-testing
- **`clipToChartArea`** on `HandDrawnLineChart` — used on the discontinuous
  function chart to keep the asymptotic tails contained within the plot area
- **Custom path building** using `smoothedOffsets()` to draw a diagonal line,
  demonstrating the lowest-level API
- **Unique seeds on adjacent items** so each component card has a distinct wobble
  pattern
- **Parameter tuning** across contexts: subtler irregularity for small cards,
  rougher strokes for the callout box

## How It Works

The example is a single stateful page built with a `Column` inside a
`SingleChildScrollView`. Each section uses a different layer of the
package API:

1. **High-level widgets** — `HandDrawnContainer`, `HandDrawnDivider`,
   `HandDrawnStatusSquare`, `HandDrawnTextField`, `HandDrawnNotebook`,
   `HandDrawnBarChart`, `HandDrawnLineChart`, `HandDrawnScatterPlot`,
   and `HandDrawnTable` cover most use cases out of the box.
2. **Painter + interaction** — `HandDrawnBarChartPainter`,
   `HandDrawnLineChartPainter`, and `HandDrawnScatterPlotPainter` are used
   with `CustomPaint` inside `LayoutBuilder` and `GestureDetector` to
   demonstrate `computeLayout()` and `hitTest()` for consumer-owned
   tap behavior.
3. **Stateful composition** — `_ResizableTableDemo` wraps `HandDrawnTable`
   in a `Stack` with drag handles to show how to layer interactivity on
   top of a high-level widget without modifying the package.
4. **Mid-level painter** — `HandDrawnLinePainter` with a built-in helper
   (`lineHorizontal`) draws the title underline.
5. **Low-level path building** — a `buildPath` callback calls
   `smoothedOffsets()` directly to construct a custom diagonal line.

This layered approach mirrors how you would use the package in a real app:
- Reach for the convenience widgets first
- Use the painters with `computeLayout()` and `hitTest()` when you need
  interactive behavior on charts
- Layer your own widgets on top (à la `_ResizableTableDemo`) when you need
  to extend a high-level widget without forking it
- Drop down to the painter or raw helpers only when you need a shape the
  widgets don't cover

## Notes on Function Series

The function-chart examples illustrate two API patterns worth noting:

- **Top-level function references over inline closures.** `_parabola`,
  `_cubic`, and `_reciprocal` are top-level functions, not inline
  `(x) => ...` closures. This keeps `FunctionSeriesData` equality stable
  across widget rebuilds — Dart compares closures by identity, so two
  inline `(x) => x * x` literals would be `!=` even if semantically
  identical, defeating memoization.
- **`series: const []` for function-only charts.** `LineChartData.series`
  is a required parameter; charts that only use `functionSeries` still
  need to pass an explicit empty `series` list.