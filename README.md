# Hand Drawn Toolkit

A lightweight Flutter package for rendering hand-drawn, sketchy UI elements: containers, dividers, tables, charts, and more.

[![pub package](https://img.shields.io/pub/v/hand_drawn_toolkit.svg)](https://pub.dev/packages/hand_drawn_toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Publisher](https://img.shields.io/pub/publisher/hand_drawn_toolkit.svg)](https://pub.dev/publishers/resengi.io)

## Example

| Base | Notebook | Charts | Custom & Tip |
|:----:|:--------:|:------:|:------------:|
| ![Base example](https://raw.githubusercontent.com/resengi/hand_drawn_toolkit/main/assets/example_base.png) | ![Notebook example](https://raw.githubusercontent.com/resengi/hand_drawn_toolkit/main/assets/example_notebook.png) | ![Charts example](https://raw.githubusercontent.com/resengi/hand_drawn_toolkit/main/assets/example_charts.png) | ![Custom and tip example](https://raw.githubusercontent.com/resengi/hand_drawn_toolkit/main/assets/example_custom.png) |

## Features

- Realistic hand-drawn borders, dividers, and custom path shapes
- **Charts** — bar (stacked, grouped), line (multi-series + function-backed), and scatter plots with wobbly axes, grid lines, titles, legends, auto-thinning labels, and optional zero-crossing axes
- **Signed bar charts** — bar segments may be positive or negative; positive segments stack upward from the zero baseline, negative segments stack downward, and a single bar may mix the two
- **Rotated tick labels and configurable legends** — opt into diagonal or vertical X-axis labels via `ChartLabelConfig`, and choose between inline, external boxed, right-side, or fully suppressed legends via `ChartLegendConfig`. A standalone `HandDrawnLegend` widget composes legends outside the chart's layout.
- **Function-backed line series** — plot mathematical functions like `f(x) = x²` directly without manually generating point lists; sparse visible dots, dense smooth curves, and automatic discontinuity handling
- **Per-series fill toggle and plot-area clipping** — opt out of the line fill on a per-series basis, and clip data rendering to the plot area to keep stray geometry from bleeding into axes and labels
- **Tables** — column-aligned data tables with headers, row highlighting, titles, and optional row dividers
- **Chart interaction foundation** — layout computation and typed hit-testing so consumers can build tap, hover, and drag behaviors without the package owning any interaction logic
- Tappable status squares with check/dash indicators
- Text fields with hand-drawn underlines
- **Notebook entries** — `HandDrawnNotebook` publishes paper/ruling style, while `NotebookEntry` lays out flowing text, styled spans, and inline widgets onto ruled rows with wrapping, hard breaks, fit modes, min rows, and interactive children
- Smooth, organic wobble via 3-point moving average smoothing
- Fully customizable styling (irregularity, segments, stroke width)
- Deterministic seed-based generation — identical parameters always produce the same output
- Path caching in the low-level painter for efficient repaints
- Zero external dependencies — only the Flutter SDK

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  hand_drawn_toolkit: ^0.4.1
```

Then run:

```bash
flutter pub get
```

## Quick Start

```dart
import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';

// Sketchy container around any widget:
HandDrawnContainer(
  child: Text('Looks hand-drawn!'),
)

// Sketchy divider:
HandDrawnDivider()

// Tappable status square:
HandDrawnStatusSquare(
  color: Colors.green,
  isFilled: true,
  indicator: StatusIndicator.check,
  onTap: () => toggleStatus(),
)

// Text field with hand-drawn underline:
HandDrawnTextField(
  hintText: 'Write something…',
)

// Notebook paper with flowing ruled content:
HandDrawnNotebook(
  lineHeight: 28.0,
  child: DefaultTextStyle(
    style: const TextStyle(fontSize: 16, color: Colors.black87),
    child: NotebookEntry(
      children: const [
        'First line\nSecond line',
      ],
    ),
  ),
)

// Plot a mathematical function as a hand-drawn curve:
double square(double x) => x * x;

HandDrawnLineChart(
  data: LineChartData(
    series: const [],
    minX: -5, maxX: 5, minY: 0, maxY: 25,
    functionSeries: [
      FunctionSeriesData(
        name: 'f(x) = x²',
        color: Colors.blue,
        function: square,
        displayXs: [-4, -2, 0, 2, 4],
      ),
    ],
  ),
)
```

## Charts

The package supports three chart types with intentional restrictions:

- **Bar charts** are categorical on X and numeric on Y. Stacked bar segments may be positive, negative, or zero; positive segments accumulate upward from the data baseline of `0.0`, negative segments accumulate downward, and a single bar may mix the two. The `minY`/`maxY` parameters control the visible Y-range, not the stacking origin.
- **Line charts** are numeric on both axes and accept two kinds of series side by side: point-based `LineSeriesData` (consumer-supplied points) and function-based `FunctionSeriesData` (mathematical functions sampled across the x-domain). An optional `xLabels` list enables categorical X-axis display, but only when no `functionSeries` are present.
- **Scatter plots** are numeric on both axes. Each point may have a custom dot radius.

Each chart type has two APIs:

- A **widget** (`HandDrawnBarChart`, `HandDrawnLineChart`, `HandDrawnScatterPlot`) for simple embedding with built-in loading/empty states.
- A **painter** (`HandDrawnBarChartPainter`, `HandDrawnLineChartPainter`, `HandDrawnScatterPlotPainter`) for `CustomPaint` usage and interaction.

Widgets accept nullable data — passing `null` shows a loading indicator, and empty data shows a configurable empty message.

### Bar Chart

Stacked bar charts with categorical X-axis labels, auto-computed or explicit Y range, and an optional legend:

```dart
final data = BarChartData(
  title: 'Weekly Sales',
  yAxisLabel: 'Revenue',
  xAxisLabel: 'Day',
  bars: [
    BarGroup(label: 'Mon', segments: [
      BarSegment(category: 'Online', value: 120, color: Colors.blue),
      BarSegment(category: 'In-store', value: 80, color: Colors.orange),
    ]),
    BarGroup(label: 'Tue', segments: [
      BarSegment(category: 'Online', value: 90, color: Colors.blue),
      BarSegment(category: 'In-store', value: 110, color: Colors.orange),
    ]),
    BarGroup(label: 'Wed', segments: [
      BarSegment(category: 'Online', value: 150, color: Colors.blue),
      BarSegment(category: 'In-store', value: 60, color: Colors.orange),
    ]),
  ],
  legend: [
    LegendEntry(label: 'Online', color: Colors.blue),
    LegendEntry(label: 'In-store', color: Colors.orange),
  ],
);

// Widget usage — handles null (loading) and empty states automatically
HandDrawnBarChart(data: data, height: 240)

// Painter usage — for CustomPaint or interaction
CustomPaint(
  size: Size(400, 240),
  painter: HandDrawnBarChartPainter(data: data),
)
```

For a simple single-segment bar chart, provide one segment per group:

```dart
BarChartData(
  bars: [
    BarGroup(label: 'Q1', segments: [
      BarSegment(category: 'Revenue', value: 340, color: Colors.teal),
    ]),
    BarGroup(label: 'Q2', segments: [
      BarSegment(category: 'Revenue', value: 420, color: Colors.teal),
    ]),
  ],
  legend: [LegendEntry(label: 'Revenue', color: Colors.teal)],
)
```

For grouped bar charts (multiple bars per category), populate `categories` instead of `bars`:

```dart
BarChartData(
  bars: const [], // unused in grouped mode
  categories: [
    BarCategory(label: 'Q1', bars: [
      BarGroup(label: 'North', segments: [
        BarSegment(category: 'North', value: 42, color: Colors.blue),
      ]),
      BarGroup(label: 'South', segments: [
        BarSegment(category: 'South', value: 35, color: Colors.orange),
      ]),
    ]),
    // ...
  ],
  legend: [...],
)
```

To add headroom above bars (e.g. for value labels), override `maxY`:

```dart
BarChartData(
  maxY: 250,  // explicit ceiling above tallest bar
  bars: [...],
  legend: [...],
)
```

#### BarSegment Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `category` | `String` | required | Category identifier (used in legend and hit results) |
| `value` | `double` | required | Segment value (must be finite). Positive segments stack upward from `0`; negative segments stack downward |
| `color` | `Color` | required | Stroke color (also used as fill base when `fillColor` is null) |
| `fillColor` | `Color?` | `null` | Fill color. When null, falls back to `color` |
| `fillAlpha` | `double?` | `0.15` | Fill opacity. Use `0.0` for empty, `1.0` for solid |

#### Customizing Bar Fills

Each segment can have independent fill styling. Use `fillAlpha` to control opacity or `fillColor` for a completely different fill hue:

```dart
BarGroup(label: 'Mon', segments: [
  // Prominent fill (higher opacity)
  BarSegment(category: 'A', value: 30, color: Colors.blue, fillAlpha: 0.5),
  // Solid fill
  BarSegment(category: 'B', value: 20, color: Colors.red, fillAlpha: 1.0),
  // Empty (outline only)
  BarSegment(category: 'C', value: 15, color: Colors.green, fillAlpha: 0.0),
  // Custom fill color with default opacity
  BarSegment(category: 'D', value: 25, color: Colors.purple,
      fillColor: Colors.purple.shade100),
])
```

#### BarGroup Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `label` | `String` | required | X-axis label for this bar |
| `segments` | `List<BarSegment>` | required | Stacked segments, bottom to top |

#### BarChartData Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `bars` | `List<BarGroup>` | `[]` | Bar groups with labels and segments. Use categories instead for grouped charts. |
| `categories` | `List<BarCategory>` | `[]` | Grouped-bar categories (use instead of `bars` for grouped charts) |
| `legend` | `List<LegendEntry>` | `[]` | Legend entries |
| `title` | `String?` | `null` | Chart title above the chart area |
| `yAxisLabel` | `String?` | `null` | Rotated Y-axis title |
| `xAxisLabel` | `String?` | `null` | X-axis title below tick labels |
| `minY` | `double?` | auto | Y-axis minimum. `0` when all segments are non-negative; otherwise the smallest negative stack total |
| `maxY` | `double?` | auto | Y-axis maximum (defaults to the largest positive stack total across inner bars) |
| `yValueFormatter` | `AxisValueFormatter?` | `null` | Custom Y-axis label formatter |
| `axisDisplay` | `AxisDisplay` | `AxisDisplay.edge` | Edge-aligned vs zero-crossing X axis. The `vertical` setting is a no-op on bar charts (X is categorical) |

### Line Chart

Multi-series line charts with numeric positioning, optional categorical labels, and auto-generated legends:

```dart
final data = LineChartData(
  title: 'Temperature',
  xAxisLabel: 'Day',
  yAxisLabel: '°C',
  minX: 0, maxX: 6,
  minY: 0, maxY: 40,
  xLabels: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
  series: [
    LineSeriesData(
      name: 'High',
      color: Colors.red,
      points: [
        LinePoint(x: 0, y: 28), LinePoint(x: 1, y: 32),
        LinePoint(x: 2, y: 30), LinePoint(x: 3, y: 35),
        LinePoint(x: 4, y: 33), LinePoint(x: 5, y: 29),
        LinePoint(x: 6, y: 31),
      ],
    ),
    LineSeriesData(
      name: 'Low',
      color: Colors.blue,
      points: [
        LinePoint(x: 0, y: 18), LinePoint(x: 1, y: 20),
        LinePoint(x: 2, y: 17), LinePoint(x: 3, y: 22),
        LinePoint(x: 4, y: 21), LinePoint(x: 5, y: 19),
        LinePoint(x: 6, y: 20),
      ],
    ),
  ],
);

HandDrawnLineChart(data: data, height: 240)
```

**Categorical X-axis mode:** When `xLabels` is non-empty, the chart renders string labels instead of auto-generated numeric ticks. Points are still positioned by their numeric `x` values, so use consecutive integers (`0, 1, 2, …`) with a matching-length `xLabels` list for intuitive categorical behavior. Categorical mode is incompatible with `functionSeries` — function series require numeric x-mode.

**Multi-series legend:** When a chart has more than one logical series total (counting both `series` and `functionSeries`), a legend is auto-generated from the series names and colors. Single-series charts omit the legend.

**Per-series fill control:** Use `showFill: false` on a `LineSeriesData` (or `FunctionSeriesData`, see below) to render that series as a stroke-only line without the semi-transparent fill underneath. Useful for overlay series, oscillating curves, or any series where the fill would clutter the chart.

```dart
LineSeriesData(
  name: 'Net P/L',
  color: Colors.purple,
  showFill: false,  // stroke only, no fill below the line
  points: [...],
)
```

For custom axis formatting (e.g. currency or percentages):

```dart
LineChartData(
  yValueFormatter: (v) => '${v.toInt()}%',
  xValueFormatter: (v) => 'W${v.toInt()}',
  // ...
)
```

#### Function-Backed Series

`FunctionSeriesData` plots a Dart function across the chart's x-domain without requiring you to enumerate points manually. The chart samples the function densely to render a smooth curve, while only a sparse list of `displayXs` you provide are rendered as visible dots and made interactive via point hit-testing.

```dart
double parabola(double x) => x * x;

LineChartData(
  series: const [],
  minX: -5, maxX: 5, minY: 0, maxY: 25,
  functionSeries: [
    FunctionSeriesData(
      name: 'f(x) = x²',
      color: Colors.blue,
      function: parabola,
      displayXs: [-4, -2, 0, 2, 4],   // visible dots
      sampleCount: 120,                // smoothness of the underlying curve
    ),
  ],
)
```

**Discontinuities** are handled automatically. When `function(x)` returns a non-finite value (`NaN`, `±∞`), the resolver splits the curve into independent runs at that point — no false bridge is drawn across the gap. Each run renders, fills, and hit-tests independently, so a chart of `f(x) = 1/x` cleanly produces two curves with no spurious segment crossing the asymptote.

For asymptotic functions whose tails extend well outside the visible y-range, pair `FunctionSeriesData` with `clipToChartArea: true` on the chart widget (see [Plot-area clipping](#plot-area-clipping)) to keep the runaway tails contained.

**Equality caveat.** `FunctionSeriesData` holds a Dart closure in its `function` field. Closures compare equal by **identity**, not semantic equivalence — two inline `(x) => x * x` literals compare unequal. When stable equality matters (e.g. to avoid unnecessary repaints), prefer top-level or `static` function references over inline closures.

#### LinePoint Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `x` | `double` | required | Numeric X position |
| `y` | `double` | required | Numeric Y position |

#### LineSeriesData Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String` | required | Series name (used in auto-generated legend) |
| `points` | `List<LinePoint>` | required | Data points (should be sorted by x) |
| `color` | `Color` | required | Line, dot, and fill color |
| `showFill` | `bool` | `true` | When `false`, renders only the stroke (no fill below the line) |

#### FunctionSeriesData Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `name` | `String` | required | Series name (used in auto-generated legend) |
| `color` | `Color` | required | Stroke and dot color |
| `function` | `ChartFunction` (= `double Function(double x)`) | required | The function to plot. Non-finite returns split the curve. |
| `displayXs` | `List<double>` | `[]` | Sparse x-values to render as visible dots (empty = curve only). Out-of-range or non-finite-y values are silently skipped; duplicates and order are preserved. |
| `sampleCount` | `int` | `120` | Target number of uniform samples across `[minX, maxX]`. Must be ≥ 2. Higher = smoother curve. |
| `showFill` | `bool` | `true` | When `false`, renders only the stroke (no fill below the curve) |
| `wobbleAnchorStride` | `int` | `10` | Stride (in samples) between pinned wobble anchors. Smaller = tighter wobble; larger = more wobble freedom but more visible facets at anchors. Must be ≥ 1. |

#### LineChartData Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `series` | `List<LineSeriesData>` | required | Point-based series (pass `const []` for function-only charts) |
| `functionSeries` | `List<FunctionSeriesData>` | `[]` | Function-backed series. Cannot be combined with non-empty `xLabels`. |
| `minX` / `maxX` | `double` | required | X-axis range. Function series additionally require `minX < maxX`. |
| `minY` / `maxY` | `double` | required | Y-axis range |
| `xLabels` | `List<String>` | `[]` | Categorical X labels (replaces numeric ticks when non-empty). Cannot be combined with `functionSeries`. |
| `axisDisplay` | `AxisDisplay` | `AxisDisplay.edge` | Controls edge-aligned vs zero-crossing axis rendering |
| `title` | `String?` | `null` | Chart title |
| `yAxisLabel` | `String?` | `null` | Rotated Y-axis title |
| `xAxisLabel` | `String?` | `null` | X-axis title below tick labels |
| `yValueFormatter` | `AxisValueFormatter?` | `null` | Custom Y-axis label formatter |
| `xValueFormatter` | `AxisValueFormatter?` | `null` | Custom X-axis label formatter (numeric mode only) |

##### Validation contract

`LineChartData` is `const`-constructible and intentionally does **not** assert cross-field rules in its constructor. Construction is always cheap and never throws based on field combinations. The two cross-field rules:

- `functionSeries` cannot be combined with non-empty `xLabels`
- when `functionSeries` is non-empty, `minX < maxX` is required

are validated at first layout/paint by the internal resolver and throw `ArgumentError` with a descriptive message if violated. This means a misconfigured chart will throw the first time it is rendered (loud, early, before reaching production), but explicit empty-list inputs (e.g. `xLabels: []` on a function-only chart) are accepted as semantically valid.

### Scatter Plot

Scatter plots with optional per-point sizing:

```dart
final data = ScatterPlotData(
  title: 'Height vs Weight',
  xAxisLabel: 'Weight (kg)',
  yAxisLabel: 'Height (cm)',
  minX: 40, maxX: 100,
  minY: 140, maxY: 200,
  points: [
    ScatterPoint(x: 55, y: 160),
    ScatterPoint(x: 70, y: 175, size: 8),   // larger dot
    ScatterPoint(x: 85, y: 182),
    ScatterPoint(x: 62, y: 168),
  ],
);

HandDrawnScatterPlot(data: data, height: 240)
```

Each `ScatterPoint` can specify an optional `size` (dot radius in logical pixels). When omitted, the default radius of 5.0 is used.

#### ScatterPoint Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `x` | `double` | required | X position |
| `y` | `double` | required | Y position |
| `size` | `double?` | `5.0` | Dot radius in logical pixels (must be positive) |

#### ScatterPlotData Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `points` | `List<ScatterPoint>` | required | Data points |
| `minX` / `maxX` | `double` | required | X-axis range |
| `minY` / `maxY` | `double` | required | Y-axis range |
| `axisDisplay` | `AxisDisplay` | `AxisDisplay.edge` | Edge-aligned vs zero-crossing axis rendering |
| `title` | `String?` | `null` | Chart title |
| `yAxisLabel` | `String?` | `null` | Rotated Y-axis title |
| `xAxisLabel` | `String?` | `null` | X-axis title below tick labels |
| `yValueFormatter` | `AxisValueFormatter?` | `null` | Custom Y-axis label formatter |
| `xValueFormatter` | `AxisValueFormatter?` | `null` | Custom X-axis label formatter |
| `legend` | `List<LegendEntry>` | `[]` | Custom legend entries. Scatter plots don't auto-derive entries — supply them explicitly when a legend is needed |

### Plot-area clipping

All three chart widgets (`HandDrawnBarChart`, `HandDrawnLineChart`, `HandDrawnScatterPlot`) and their painters accept `clipToChartArea: bool` (default `false`). When set to `true`, data rendering is clipped to the chart's plot region — the area inside the axes, excluding title, axis labels, tick labels, and legend.

This is most useful for:

- **Function series with asymptotes** — `f(x) = 1/x` produces y-values far outside the declared `[minY, maxY]` near the discontinuity; clipping keeps the runaway tails inside the plot area.
- **Outlier scatter points** — points with extreme values can paint across axis labels without clipping.
- **Bar charts with values that exceed an explicit `maxY`** — rare, but clipping prevents overflow from rendering through the title.

Clipping is implemented inside the painter's `paint()` method around the call to `paintData(...)`, so axes, grid lines, labels, title, and legend (drawn outside `paintData`) remain unclipped regardless of the flag.

```dart
HandDrawnLineChart(
  data: discontinuousFunctionChart,
  clipToChartArea: true,
)
```

### Rotated X-axis labels

For long category names or wide numeric labels, opt into rotation via `ChartLabelConfig`. Four named presets cover the common cases:

```dart
HandDrawnBarChart(
  data: data,
  xLabelConfig: ChartLabelConfig.diagonalLeft,   // -45°
)

// Other presets:
ChartLabelConfig.horizontal     // 0° (default)
ChartLabelConfig.diagonalRight  // +45°
ChartLabelConfig.vertical       // -90°

// Or specify any angle:
const ChartLabelConfig(rotationDegrees: -30)
```

The X tick label band's reserved height grows automatically with rotation, so rotated labels never spill into the X-axis title band below them. Label thinning honors the rotated label's actual rectangle — vertical and diagonal rotations both let labels pack tighter than horizontal because their narrower dimension fronts the X axis.

`ChartLabelConfig.minVisibleGap` controls how aggressively dense labels are thinned (default `8.0`).

### Legend layout

Legend rendering is controlled by `ChartLegendConfig`. The default preserves the historical inline-bottom behavior; opt into external boxed legends or suppress the chart-managed legend entirely:

```dart
// Inline single row at the bottom (default — historical behavior).
HandDrawnLineChart(data: data)

// External boxed legend below the chart, wrapping as needed.
HandDrawnLineChart(
  data: data,
  legendConfig: ChartLegendConfig.externalBottomBoxed,
)

// External boxed legend on the right; the plot area shrinks to make room.
HandDrawnLineChart(
  data: data,
  legendConfig: ChartLegendConfig.externalRightBoxed,
)

// Suppress the chart-managed legend entirely (use with HandDrawnLegend).
HandDrawnLineChart(
  data: data,
  legendConfig: ChartLegendConfig.hidden,
)
```

The four named presets cover almost every use case. For full control, construct `ChartLegendConfig` directly with `position`, `boxed`, `wrap`, `padding`, `spacing`, `runSpacing`, and `reserveSpace`.

### Standalone `HandDrawnLegend` widget

When you want to position a legend independently of any chart — above two side-by-side charts, in a sidebar, between a chart and a tooltip layer — pair `ChartLegendConfig.hidden` on the chart with a standalone `HandDrawnLegend`:

```dart
Column(
  children: [
    HandDrawnLegend(entries: barData.legend),
    SizedBox(
      height: 240,
      child: HandDrawnBarChart(
        data: barData,
        legendConfig: ChartLegendConfig.hidden,
      ),
    ),
  ],
)
```

For line charts, where the legend is auto-derived from the series list, use `ChartLegendEntries.fromLineChartData(data)` so the standalone legend renders the exact same entries the chart would have:

```dart
HandDrawnLegend(entries: ChartLegendEntries.fromLineChartData(lineData))
```

`HandDrawnLegend` accepts the same `ChartLegendConfig` to control its layout (boxed/unboxed, wrap, position, padding). Defaults to `ChartLegendConfig.externalBottomBoxed` since standalone legends are most often placed in their own boxed container.

### Shared Chart Widget Properties

All chart widgets (`HandDrawnBarChart`, `HandDrawnLineChart`, `HandDrawnScatterPlot`) accept these common parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | nullable data type | required | Chart data (null = loading indicator) |
| `height` | `double` | `220` | Widget height |
| `seed` | `int` | `42` | Deterministic wobble seed |
| `axisColor` | `Color` | `Color(0xFF555555)` | Axis stroke color |
| `grid` | `GridConfig` | `GridConfig.standard` | Grid configuration. See `GridConfig` for color, stroke width, jitter ratio, sub-grid alpha, and on/off toggles per axis. |
| `labelStyle` | `TextStyle?` | `null` | Axis label text style |
| `irregularity` | `double` | `3.0` | Wobble magnitude |
| `segments` | `int` | `12` | Segments per wobbly edge |
| `yDivisions` | `int` | `4` | Number of horizontal grid lines |
| `xDivisions` | `int` | `4` | Vertical tick divisions (numeric X only) |
| `padding` | `EdgeInsets` | `left: 40, others: 12` | Outer padding (left gutter accommodates Y labels) |
| `titleStyle` | `TextStyle?` | `null` | Chart title style override |
| `legendStyle` | `TextStyle?` | `null` | Legend label style override |
| `axisStrokeWidth` | `double` | `1.5` | Axis line thickness |
| `xLabelConfig` | `ChartLabelConfig` | `ChartLabelConfig.horizontal` | X-axis label rotation and thinning sensitivity |
| `legendConfig` | `ChartLegendConfig` | `ChartLegendConfig.inlineBottom` | Legend visibility, position (bottom or right), boxed/unboxed, and wrapping behavior |
| `clipToChartArea` | `bool` | `false` | Clip data rendering to the plot area |
| `emptyStyle` | `TextStyle?` | `null` | Empty-state message style |

All three chart widgets also expose a `copyWith` method mirroring their constructor; one optional parameter per field, including `data` and `key`. It returns a new widget with the given fields replaced and the rest carried over, which is handy for threading shared styling through charts that differ only in data, swapping a single config at a width breakpoint, or re-rolling `seed`:

```dart
final base = HandDrawnLineChart(data: null, grid: GridConfig.horizontalOnly, seed: 7);
final filled = base.copyWith(data: temperatureData);
```

Following the `BarChartData.copyWith` convention, nullable fields cannot be cleared back to `null` via `copyWith` — construct the widget directly when you need that.

### Chart Layout Bands

The chart area is divided into vertical bands computed automatically:

1. **Title band** — optional chart title
2. **Chart area** — the main plotting region
3. **X tick label band** — categorical or numeric X labels
4. **X-axis title band** — optional axis title
5. **Legend band** — optional color legend (auto-generated for multi-series line charts, including function series)

When the legend is configured for the right-side position via `ChartLegendConfig.externalRightBoxed`, it carves out a column from the plot area's *width* instead of stacking below it. When labels are rotated via `ChartLabelConfig`, the X tick band's height grows to accommodate the rotated bounding boxes.

When labels are too dense for the available width, the chart automatically thins them — always showing the first and last, with evenly spaced labels in between.

## Chart Interaction

The package provides a **behavior-free interaction foundation** so consumers can build tap, hover, and drag features. The package provides layout computation and typed hit-testing; the consumer owns all behavior.

Each chart painter exposes a `computeLayout(Size)` method that returns an immutable layout snapshot. The layout object exposes a `hitTest(Offset)` method that returns a typed, nullable hit result.

### Usage Pattern

The recommended pattern is `LayoutBuilder` → `computeLayout` → `GestureDetector` → `hitTest`:

```dart
LayoutBuilder(
  builder: (context, constraints) {
    final size = Size(constraints.maxWidth, 240);
    final layout = painter.computeLayout(size);

    return GestureDetector(
      onTapDown: (details) {
        final hit = layout.hitTest(details.localPosition);
        if (hit != null) {
          // Consumer-owned behavior — show tooltip, navigate, etc.
        }
      },
      child: CustomPaint(size: size, painter: painter),
    );
  },
)
```

For hover or drag, call `hitTest()` from `onPanUpdate` or pointer move callbacks using the same layout object.

### Key Rules

- **Recompute when size changes** — layout objects are size-bound snapshots, valid only for the size they were computed for.
- **Use local coordinates** in the same coordinate space as the `CustomPaint`.
- **Layout objects are disposable** — they are cheap to create and not meant to be long-lived canonical state.
- **Double computation is expected** — `computeLayout()` in `LayoutBuilder` and the painter's internal layout during `paint()` may both run for the same frame. This is the intended tradeoff for API clarity and correctness.
- **Consumer caching is optional** — you may cache the layout if size and painter configuration are unchanged. Invalidate when either changes (the same conditions that trigger `shouldRepaint`).

### Bar Chart Interaction

```dart
final painter = HandDrawnBarChartPainter(data: barData);

// In LayoutBuilder:
final layout = painter.computeLayout(size);  // → BarChartLayout
final hit = layout.hitTest(localPosition);    // → BarHitTestResult?

if (hit != null) {
  final seg = hit.segment;
  print('Bar: ${seg.barLabel}');
  print('Category: ${seg.category}');
  print('Value: ${seg.value}');
  print('Cumulative range: ${seg.cumulativeStart}–${seg.cumulativeEnd}');
  print('Bounds: ${seg.bounds}');
}
```

When segments overlap (stacked bars), the topmost (last-painted) segment wins due to reverse paint order iteration. For grouped bars, `BarSegmentLayout` also exposes `innerBarIndex` and `innerBarLabel` so you can distinguish which bar within a category was hit.

### Scatter Plot Interaction

```dart
final painter = HandDrawnScatterPlotPainter(data: scatterData);

// In LayoutBuilder:
final layout = painter.computeLayout(size);  // → ScatterPlotLayout
final hit = layout.hitTest(localPosition, tolerance: 20);  // → ScatterHitTestResult?

if (hit != null) {
  print('Point ${hit.point.pointIndex}');
  print('Position: (${hit.point.rawPoint.x}, ${hit.point.rawPoint.y})');
  print('Distance: ${hit.distance}');
}
```

The effective hit radius is `max(visualRadius, tolerance)`, making small dots easy to tap on mobile. The default tolerance is 16 logical pixels.

### Line Chart Interaction

Line chart hit-testing is the most nuanced. Points are checked first; if none qualifies, segments are checked. The result is a sealed type for exhaustive pattern matching:

```dart
final painter = HandDrawnLineChartPainter(data: lineData);

// In LayoutBuilder:
final layout = painter.computeLayout(size);  // → LineChartLayout
final hit = layout.hitTest(
  localPosition,
  pointTolerance: 12,   // default
  lineTolerance: 16,    // default
);

if (hit != null) {
  switch (hit) {
    case LinePointHit(:final seriesName, :final pointIndex, :final point):
      print('Hit $seriesName point $pointIndex: (${point.x}, ${point.y})');
    case LineSegmentHit(:final seriesName, :final interpolatedX,
        :final interpolatedY, :final t):
      print('Hit $seriesName segment at ($interpolatedX, $interpolatedY)');
      print('Interpolation fraction: $t');
  }
}
```

All interpolation uses **logical geometry** (straight data segments), never the wobble/sketch path. This ensures hit results are stable and predictable regardless of rendering style.

#### Function-series interaction

When a series originates from `FunctionSeriesData`, the same hit-test API applies, with two semantic differences worth knowing:

- **Point hits target only the sparse `displayXs` dots.** A point hit on a function series gives you a `pointIndex` into the resolved `displayPoints` list (after out-of-range and non-finite filtering), not into the dense underlying sample set. This means dots stay sparse and tappable while the curve itself remains a continuous surface for segment hits.
- **Segment hits cover the whole sampled curve.** Tapping anywhere along the visible curve produces a `LineSegmentHit` with interpolated `interpolatedX` and `interpolatedY` values from the sampled polyline. For discontinuous functions, taps inside a discontinuity gap simply return `null` — no segment bridges the gap, so there is nothing to hit.

Series ordering for hit-test indices is: ordinary `series` first (in declaration order), then `functionSeries` (in declaration order). So `seriesIndex` values are stable and predictable in mixed charts.

## Tables

`HandDrawnTable` renders column-aligned data inside a `HandDrawnContainer` with `HandDrawnDivider` separators. Cells render with `maxLines: 1` and `softWrap: false` by default, with configurable overflow — making it ideal for compact, summary-style data. Both can be overridden per-table for wider content.

```dart
HandDrawnTable(
  title: 'Leaderboard',
  columns: [
    HandDrawnTableColumn(header: 'Player', flex: 3),
    HandDrawnTableColumn(header: 'Score', width: 60,
        alignment: Alignment.centerRight),
    HandDrawnTableColumn(header: 'Rank', width: 50,
        alignment: Alignment.center),
  ],
  rows: [
    HandDrawnTableRow(cells: ['Alice', '1,240', '#1'], highlight: true),
    HandDrawnTableRow(cells: ['Bob', '1,180', '#2']),
    HandDrawnTableRow(cells: ['Carol', '985', '#3']),
  ],
  rowDividers: TableDividerStyle(),
)
```

### Row Highlighting

Set `highlight: true` on a row to render it with a tinted background and emphasized text. The highlight color and intensity are configurable:

```dart
HandDrawnTable(
  highlightColor: Colors.amber,
  highlightAlpha: 0.12,
  columns: [...],
  rows: [
    HandDrawnTableRow(cells: ['Winner', '100'], highlight: true),
    HandDrawnTableRow(cells: ['Runner-up', '85']),
  ],
)
```

### Per-Row Styling

Override the text style for individual rows with `cellStyle`:

```dart
HandDrawnTableRow(
  cells: ['Deprecated', 'N/A'],
  cellStyle: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic),
)
```

### Horizontal Scrolling

For wide tables, enable horizontal scrolling. All columns must specify an explicit `width` in this mode:

```dart
HandDrawnTable(
  horizontalScroll: true,
  columns: [
    HandDrawnTableColumn(header: 'ID', width: 60),
    HandDrawnTableColumn(header: 'Description', width: 300),
    HandDrawnTableColumn(header: 'Status', width: 100),
  ],
  rows: [...],
)
```

### Column Dividers

Enable vertical dividers between columns for a true table-grid look:

```dart
HandDrawnTable(
  columns: [...],
  rows: [...],
  columnDividers: TableDividerStyle(),
)
```

Use non-uniform seeds for distinct wobble on each divider line:

```dart
HandDrawnTable(
  columns: [...],
  rows: [...],
  rowDividers: TableDividerStyle(seed: 50, uniform: false),
  columnDividers: TableDividerStyle(seed: 70, irregularity: 2.0),
)
```

Column dividers pair well with explicit column widths — consumers can build features like draggable column resizing by storing widths in state, overlaying gesture-handling strips at column boundaries, and rebuilding the table with updated widths on drag.

### Empty State

When `rows` is empty, the table displays a configurable message:

```dart
HandDrawnTable(
  columns: [...],
  rows: [],
  emptyMessage: 'No entries yet',
)
```

### HandDrawnTable Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `columns` | `List<HandDrawnTableColumn>` | required | Column definitions |
| `rows` | `List<HandDrawnTableRow>` | required | Row data |
| `title` | `String?` | `null` | Optional title above the table |
| `rowDividers` | `TableDividerStyle?` | `null` | Row divider config (null = no dividers) |
| `columnDividers` | `TableDividerStyle?` | `null` | Column divider config (null = no dividers) |
| `seed` | `int` | `42` | Random seed for the outer container border |
| `irregularity` | `double` | `3.5` | Wobble magnitude for the outer container border |
| `strokeWidth` | `double` | `2.0` | Stroke width for the outer container border |
| `strokeColor` | `Color` | `Color(0xFF000000)` | Stroke color for the outer container border |
| `backgroundColor` | `Color` | `Colors.white` | Background fill color |
| `highlightColor` | `Color` | green | Highlighted row tint and text color |
| `highlightAlpha` | `double` | `0.08` | Background tint opacity |
| `headerStyle` | `TextStyle?` | `null` | Column header text style |
| `cellStyle` | `TextStyle?` | `null` | Default cell text style |
| `titleStyle` | `TextStyle?` | `null` | Table title text style |
| `emptyStyle` | `TextStyle?` | `null` | Empty-state message style |
| `emptyMessage` | `String` | `'No data'` | Message shown when rows is empty |
| `padding` | `EdgeInsets` | `EdgeInsets.all(12)` | Inner container padding |
| `rowPadding` | `double` | `6.0` | Vertical spacing between rows |
| `titleBottomPadding` | `double` | `8.0` | Space between title and header |
| `textOverflow` | `TextOverflow` | `ellipsis` | How overflowing text is handled |
| `cellMaxLines` | `int` | `1` | Maximum number of lines per cell. Pair with `softWrap: true` to wrap long content. |
| `softWrap` | `bool` | `false` | Whether cell text wraps at soft break points. Has no effect when `cellMaxLines` is `1`. |
| `horizontalScroll` | `bool` | `false` | Enable horizontal scrolling |

`HandDrawnTable` also exposes a `copyWith` method mirroring its constructor (one optional parameter per field, including `columns`, `rows`, and `key`) returning a new table with the given fields replaced and the rest carried over. As with the chart widgets and `BarChartData.copyWith`, nullable fields cannot be cleared back to `null` via `copyWith`; construct the table directly when you need that.

### HandDrawnTableColumn Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `header` | `String` | required | Column header text |
| `flex` | `int` | `1` | Flex factor (used when `width` is null) |
| `width` | `double?` | `null` | Fixed width (overrides `flex`) |
| `alignment` | `Alignment` | `centerLeft` | Cell content alignment |

### HandDrawnTableRow Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `cells` | `List<String>` | required | Cell values, one per column |
| `cellStyle` | `TextStyle?` | `null` | Per-row style override |
| `highlight` | `bool` | `false` | Tinted background and emphasized text |

### TableDividerStyle Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `color` | `Color` | `HandDrawnDefaults.dividerColor` | Stroke color for the dividers |
| `seed` | `int` | `42` | Random seed for divider wobble |
| `irregularity` | `double` | `1.0` | Wobble magnitude |
| `thickness` | `double` | `1.5` | Stroke thickness of the dividers |
| `uniform` | `bool` | `true` | When true, all dividers share the same seed. When false, each gets `seed + 1`, `seed + 2`, etc. |

## Usage Guide

### HandDrawnContainer

Wraps a child widget with a hand-drawn rectangular border and solid background fill:

```dart
HandDrawnContainer(
  backgroundColor: Colors.white,
  strokeColor: Colors.black87,
  strokeWidth: 2.0,
  irregularity: 3.5,
  seed: 42,
  padding: EdgeInsets.all(20),
  child: Text('Sketchy!'),
)
```

### Animating the Border

Use `borderOpacity` to fade the border in or out — it multiplies the strokeColor's alpha, so values between `0.0` and `1.0` smoothly fade the existing stroke without changing its hue. Useful for entrance animations or interactive states:

```dart
HandDrawnContainer(
  borderOpacity: _animationController.value,
  child: MyContent(),
)
```

### Varying the Wobble Pattern

Each unique `seed` produces a different jitter pattern. Use this to give adjacent containers distinct borders:

```dart
for (int i = 0; i < items.length; i++)
  HandDrawnContainer(
    seed: i * 17 + 3,
    child: ListTile(title: Text(items[i])),
  )
```

### HandDrawnDivider

A drop-in sketchy replacement for Flutter's `Divider`, supporting both orientations:

```dart
// Horizontal (default)
Column(
  children: [
    Text('Section A'),
    HandDrawnDivider(),
    Text('Section B'),
  ],
)

// Vertical
Row(
  children: [
    Text('Left'),
    HandDrawnDivider(direction: Axis.vertical, height: 40),
    Text('Right'),
  ],
)
```

With indentation:

```dart
HandDrawnDivider(
  indent: 16,
  endIndent: 16,
  color: Colors.grey,
)
```

### HandDrawnStatusSquare

A tappable square with a hand-drawn border that can be empty, filled, and overlaid with a check or dash indicator. The widget is generic — it accepts primitive types rather than domain-specific enums, so you map your own status model at the call site:

```dart
HandDrawnStatusSquare(
  color: Colors.green,
  isFilled: true,
  indicator: StatusIndicator.check,
  indicatorColor: Colors.white,
  size: 18,
  onTap: () => toggleStatus(),
)
```

For a simple check/uncheck toggle:

```dart
HandDrawnStatusSquare(
  color: isChecked ? Colors.green : Colors.grey,
  isFilled: isChecked,
  indicator: isChecked ? StatusIndicator.check : StatusIndicator.none,
  onTap: () => setState(() => isChecked = !isChecked),
)
```

When `onTap` is provided, the square gets an enlarged tap target (controlled by `tapPadding`) for comfortable touch input. When null, the widget is display-only.

### HandDrawnTextField

A text field with a hand-drawn divider underline. All visual properties are parameterized with sensible defaults:

```dart
HandDrawnTextField(
  hintText: 'Enter a title…',
  backgroundColor: Colors.white,
  textColor: Colors.black87,
  hintColor: Colors.grey,
  dividerColor: Colors.grey.shade300,
  fontSize: 16.0,
  onChanged: (value) => print(value),
)
```

For a multiline field:

```dart
HandDrawnTextField(
  hintText: 'Write your thoughts…',
  maxLines: 4,
)
```

When a custom `style` is provided, it completely replaces the default text style built from `textColor` and `fontSize`. The hint style always uses `fontSize` and `hintColor` independently.

### HandDrawnNotebook and NotebookEntry

`HandDrawnNotebook` represents the paper. It optionally paints a `paperColor` and publishes a `NotebookStyle` through `NotebookScope` for descendants to read. The page itself does **not** draw rules; ruled content widgets such as `NotebookEntry` read the style and paint their own rules.

`NotebookEntry` is the primary notebook content widget. Give it one flowing run of mixed content (plain strings, styled `NotebookSpan`s, and inline widgets) and it lays that content onto fixed-height ruled rows. Text wraps to the available width, `\n` starts a hard new row, widgets remain whole and interactive, and the entry sizes itself to exactly the row count it needs.

```dart
HandDrawnNotebook(
  lineHeight: 28.0,
  lineColor: Colors.grey.shade300,
  uniformLines: false,
  child: DefaultTextStyle(
    style: const TextStyle(fontSize: 16, color: Colors.black87),
    child: NotebookEntry(
      children: [
        'Shopping list: ',
        HandDrawnStatusSquare(
          color: Colors.green,
          isFilled: true,
          indicator: StatusIndicator.check,
          size: 16,
        ),
        ' eggs, ',
        NotebookSpan(
          'whole milk',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        ', sourdough, basil, and parmesan.',
      ],
    ),
  ),
)
```

#### Hard Breaks and Minimum Rows

Embedded newlines start new ruled rows. Use `minRows` when you want extra blank ruled space below short content or an initially empty note:

```dart
NotebookEntry(
  minRows: 3,
  children: const [
    'Line one\nLine two\nLine three',
  ],
)
```

#### Oversized Content

By default, `NotebookEntry` uses `NotebookFit.scaleDown`: oversized text or widgets are scaled down so each piece fits within one row. Use `NotebookFit.clip` when you want content to keep its natural size and be cropped to the row instead:

```dart
NotebookEntry(
  fit: NotebookFit.clip,
  children: const [
    'A large status square is clipped to the row: ',
    HandDrawnStatusSquare(size: 44, color: Colors.green, isFilled: true),
  ],
)
```

#### Single-Line Horizontal Scrolling

Set `wrap: false` to lay content on one horizontal line. The entry is not scrollable by itself, so place it in a horizontal scroll view when the content may exceed the viewport:

```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: NotebookEntry(
    wrap: false,
    children: const [
      'This line keeps going to the right instead of wrapping.',
    ],
  ),
)
```

#### Style Resolution

Notebook ruling comes from the explicit `NotebookEntry(style: ...)`, then the nearest `NotebookScope` — for example one created by `HandDrawnNotebook` — then `const NotebookStyle()`. Plain text takes its base style from the ambient `DefaultTextStyle`; use `NotebookSpan` to override style for a text run.

#### Layout Notes

`NotebookEntry` wraps text to a finite width, so a wrapping entry cannot sit directly in an unbounded horizontal space such as a `Row` or horizontal scroll view. Constrain its width, or set `wrap: false` for scrollable single-line content.

The entry owns its height: it is always `rowCount * lineHeight`. Do not force it into a fixed height with `SizedBox(height: ...)` or `Expanded`; use `minRows` when you need a taller ruled block.

Inline widget children are laid out with unbounded constraints. Wrap width- or height-hungry widgets in `SizedBox` or `ConstrainedBox`.

### Using HandDrawnLinePainter

For full control, use the painter directly with `CustomPaint`. The `buildPath` callback receives a `HandDrawnHelpers` instance with methods for generating jittered paths:

```dart
CustomPaint(
  painter: HandDrawnLinePainter(
    color: Colors.black,
    strokeWidth: 2.0,
    irregularity: 3.5,
    buildPath: (size, helpers) => helpers.rectBorder(size),
  ),
  child: MyWidget(),
)
```

## How It Works

1. **Offset generation** — `smoothedOffsets()` creates random perpendicular offsets for each segment point. First and last points are pinned to zero so strokes start and end cleanly.

2. **Smoothing** — A 3-point moving average softens harsh spikes while preserving the organic feel, preventing the "angry zigzag" look that raw random offsets produce.

3. **Path assembly** — Built-in helpers (`lineHorizontal`, `lineVertical`, `rectBorder`) stitch smoothed offsets into Flutter `Path` objects. `rectBorder` uses four independent offset sets so irregularity varies around the perimeter.

4. **Caching** — `HandDrawnLinePainter` caches its generated path and only recomputes when the widget size or numeric generation parameters change. Note that `buildPath` shape changes are not detected automatically; see `HandDrawnLinePainter`'s class docs for the contract.

5. **Notebook layout** — `HandDrawnNotebook` publishes a `NotebookStyle` and optional paper fill. `NotebookEntry` consumes that style, lays mixed content into fixed-height rows, paints one hand-drawn rule per row, exposes painted text to semantics, and keeps inline widget children interactive through ordinary Flutter hit-testing.

6. **Determinism** — All randomness flows through `dart:math.Random(seed)`, so identical parameters always produce identical strokes.

7. **Chart geometry** — Chart layout is computed from a single canonical frame builder shared by both `paint()` and `computeLayout()`. Coordinate helpers are pure functions of immutable frame data, ensuring layout snapshots always match the rendered output. In debug, the frame builder asserts when the available height is insufficient for the configured title, axis, and legend bands; in release, the plot region is clamped so it can never invert.

8. **Function-series resolution** — A small internal resolver layer transforms `LineChartData` into a render-ready list of resolved series. Ordinary `LineSeriesData` passes through unchanged; `FunctionSeriesData` is uniformly sampled across `[minX, maxX]`, with non-finite samples splitting the curve into independent runs at each discontinuity. Sparse `displayPoints` are evaluated separately at the user-provided `displayXs`. The painter consumes resolved series uniformly — it doesn't need to know whether a series came from points or a function.

9. **Anchor-stride wobble for function curves** — Function curves use a different wobble strategy than ordinary line series. Rather than wobbling between every consecutive sample (which would over-pin a 120-vertex polyline), the painter walks the polyline in fixed strides, treating every Nth sample as a pinned anchor and wobbling the samples between anchors with a single coherent phase. Wobble amplitude is automatically capped relative to the anchor segment's length so short segments don't get overwhelmed by jitter.

10. **Interaction foundation** — Hit-testing uses logical (non-wobbly) geometry so results are stable regardless of rendering style. Point hits take priority over segment hits in line charts, and bar hit-testing iterates in reverse paint order so the topmost segment wins.

## Best Practices

**Tune irregularity to context** — borders look good at 2.0–4.0, while dividers, notebook lines, and chart grid lines work better at 0.5–1.5. The defaults reflect this (`3.5` for containers, `1.0` for dividers and notebook lines, `3.0` for chart axes).

**Use unique seeds for adjacent elements** to prevent identical wobble patterns lining up:

```dart
ListView.builder(
  itemBuilder: (context, index) => HandDrawnContainer(
    seed: index * 17 + 3,
    child: MyListItem(index),
  ),
)
```

**Increase left padding for formatted Y labels** — the default 40 px left padding suits short numeric labels. When using a `yValueFormatter` that produces longer strings (e.g. `"$1,234.56"`), increase the left padding to prevent clipping.

**Give charts enough vertical space** — the plot region shares height with optional title, X tick label, axis title, and legend bands. At very small heights these bands can squeeze the plot to zero. If you see debug asserts about insufficient vertical space, either increase the chart height or omit bands you don't need.

**Keep segment count reasonable** — 20–30 segments is the sweet spot for most use cases. Going above 50 adds computation without visible improvement at typical widget sizes.

**Recompute chart layouts when size changes** — `computeLayout()` returns a size-bound snapshot. Cache it if size and painter configuration are unchanged, but invalidate when either changes.

**Use `NotebookEntry` for ruled notebook content.** Plain text, `NotebookSpan`s, and inline widgets flow together on the notebook grid without manually setting `TextStyle.height`. Let entries size themselves to their rows, use `minRows` for extra blank space, and constrain wrapping entries to a finite width.

**Hoist function-series functions to top-level or static** — `FunctionSeriesData.function` is compared by closure identity. Two inline `(x) => x * x` literals compare unequal, which can defeat memoization and cause unnecessary repaints. Define the function once at top level (`double parabola(double x) => x * x;`) and pass the reference.

**Reach for `clipToChartArea` when data can leave the plot** — function series with asymptotes, scatter outliers, and any chart whose values can exceed the declared axis range benefit from `clipToChartArea: true`. The flag defaults to `false` so existing charts are unaffected; it's an opt-in safety net for the cases that need it.

**Rotate long category labels rather than crowding them.** For 8+ categories with multi-word labels, `ChartLabelConfig.diagonalLeft` (-45°) or `ChartLabelConfig.vertical` (-90°) keeps every label readable without thinning. The X tick band's reserved height adjusts automatically.

**Use external legends for charts with many series.** The default inline legend hard-truncates entries that don't fit on a single row. For 5+ series, switch to `ChartLegendConfig.externalBottomBoxed` (wraps to additional rows) or `ChartLegendConfig.externalRightBoxed` (vertical column).

## License

MIT License — see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.