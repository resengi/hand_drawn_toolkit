# Hand Drawn Toolkit — Example

A demo app showcasing the `hand_drawn_toolkit` package. It renders a journal-style
page that exercises every major feature: containers, dividers, status squares,
text fields, notebooks, charts (bar, line, scatter), tables, interactive
hit-testing, and custom path building.

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
  showing uniform line mode
- **`HandDrawnBarChart`** with stacked segments, custom `fillAlpha` for prominent
  fills, and a custom `fillColor` on one segment
- **`HandDrawnLineChart`** with two series (Energy and Focus), categorical
  X labels, and auto-generated legend
- **`HandDrawnScatterPlot`** with variable dot sizes
- **`HandDrawnTable`** with a title, row dividers, highlighted rows, and
  mixed column alignment (flex and fixed width)
- **Interactive charts** — three separate demos using `LayoutBuilder`,
  `computeLayout()`, and `GestureDetector` to tap chart elements and display
  hit-test results, including exhaustive `switch` on the sealed
  `LineHitTestResult` hierarchy
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
3. **Mid-level painter** — `HandDrawnLinePainter` with a built-in helper
   (`lineHorizontal`) draws the title underline.
4. **Low-level path building** — a `buildPath` callback calls
   `smoothedOffsets()` directly to construct a custom diagonal line.

This layered approach mirrors how you would use the package in a real app:
- Reach for the convenience widgets first
- Use the painters with `computeLayout()` and `hitTest()` when you need
  interactive behavior on charts
- Drop down to the painter or raw helpers only when you need a shape the
  widgets don't cover