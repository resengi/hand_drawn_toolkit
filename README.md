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
- **Charts** — bar (stacked), line (multi-series), and scatter plots with wobbly axes, grid lines, titles, legends, and auto-thinning labels
- **Tables** — column-aligned data tables with headers, row highlighting, titles, and optional row dividers
- **Chart interaction foundation** — layout computation and typed hit-testing so consumers can build tap, hover, and drag behaviors without the package owning any interaction logic
- Tappable status squares with check/dash indicators
- Text fields with hand-drawn underlines
- Notebook-paper ruled lines with grid-snapping layout primitives
- Smooth, organic wobble via 3-point moving average smoothing
- Fully customizable styling (irregularity, segments, stroke width)
- Deterministic seed-based generation — identical parameters always produce the same output
- Internal path caching for efficient repaints
- Zero external dependencies — only the Flutter SDK

## Installation

Add the package to your `pubspec.yaml`:

```yaml
dependencies:
  hand_drawn_toolkit: ^0.1.3
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

// Notebook paper with ruled lines:
HandDrawnNotebook(
  lineHeight: 28.0,
  child: Column(
    children: [
      NotebookRow(lineHeight: 28.0, child: Text('First line')),
      NotebookRow(lineHeight: 28.0, child: Text('Second line')),
    ],
  ),
)
```

## Charts

The package supports three chart types with intentional restrictions:

- **Bar charts** are categorical on X and numeric on Y. Stacked bar segments must have non-negative values and accumulate from a data baseline of `0.0`. The `minY`/`maxY` parameters control the visible Y-range, not the stacking origin.
- **Line charts** are numeric on both axes. Points should be sorted by X for coherent rendering. An optional `xLabels` list enables categorical X-axis display.
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
| `value` | `double` | required | Segment height value (must be non-negative) |
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
| `bars` | `List<BarGroup>` | required | Bar groups with labels and segments |
| `legend` | `List<LegendEntry>` | required | Legend entries |
| `title` | `String?` | `null` | Chart title above the chart area |
| `yAxisLabel` | `String?` | `null` | Rotated Y-axis title |
| `xAxisLabel` | `String?` | `null` | X-axis title below tick labels |
| `minY` | `double?` | `0` | Y-axis minimum |
| `maxY` | `double?` | auto | Y-axis maximum (defaults to tallest bar total) |
| `yValueFormatter` | `AxisValueFormatter?` | `null` | Custom Y-axis label formatter |

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

**Categorical X-axis mode:** When `xLabels` is non-empty, the chart renders string labels instead of auto-generated numeric ticks. Points are still positioned by their numeric `x` values, so use consecutive integers (`0, 1, 2, …`) with a matching-length `xLabels` list for intuitive categorical behavior.

**Multi-series legend:** When a chart has more than one series, a legend is auto-generated from the series names and colors. Single-series charts omit the legend.

For custom axis formatting (e.g. currency or percentages):

```dart
LineChartData(
  yValueFormatter: (v) => '${v.toInt()}%',
  xValueFormatter: (v) => 'W${v.toInt()}',
  // ...
)
```

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

#### LineChartData Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `series` | `List<LineSeriesData>` | required | Line series |
| `minX` / `maxX` | `double` | required | X-axis range |
| `minY` / `maxY` | `double` | required | Y-axis range |
| `xLabels` | `List<String>` | `[]` | Categorical X labels (replaces numeric ticks when non-empty) |
| `title` | `String?` | `null` | Chart title |
| `yAxisLabel` | `String?` | `null` | Rotated Y-axis title |
| `xAxisLabel` | `String?` | `null` | X-axis title below tick labels |
| `yValueFormatter` | `AxisValueFormatter?` | `null` | Custom Y-axis label formatter |
| `xValueFormatter` | `AxisValueFormatter?` | `null` | Custom X-axis label formatter (numeric mode only) |

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
| `title` | `String?` | `null` | Chart title |
| `yAxisLabel` | `String?` | `null` | Rotated Y-axis title |
| `xAxisLabel` | `String?` | `null` | X-axis title below tick labels |
| `yValueFormatter` | `AxisValueFormatter?` | `null` | Custom Y-axis label formatter |
| `xValueFormatter` | `AxisValueFormatter?` | `null` | Custom X-axis label formatter |

### Shared Chart Widget Properties

All chart widgets (`HandDrawnBarChart`, `HandDrawnLineChart`, `HandDrawnScatterPlot`) accept these common parameters:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `data` | nullable data type | required | Chart data (null = loading indicator) |
| `height` | `double` | `220` | Widget height |
| `seed` | `int` | `42` | Deterministic wobble seed |
| `axisColor` | `Color` | `Color(0xFF555555)` | Axis stroke color |
| `gridColor` | `Color` | `Color(0xFFDDDDDD)` | Grid line color |
| `labelStyle` | `TextStyle?` | `null` | Axis label text style |
| `irregularity` | `double` | `3.0` | Wobble magnitude |
| `segments` | `int` | `12` | Segments per wobbly edge |
| `yDivisions` | `int` | `4` | Number of horizontal grid lines |
| `xDivisions` | `int` | `4` | Vertical tick divisions (numeric X only) |
| `padding` | `EdgeInsets` | `left: 40, others: 12` | Outer padding (left gutter accommodates Y labels) |
| `titleStyle` | `TextStyle?` | `null` | Chart title style override |
| `legendStyle` | `TextStyle?` | `null` | Legend label style override |
| `axisStrokeWidth` | `double` | `1.5` | Axis line thickness |
| `gridStrokeWidth` | `double` | `0.5` | Grid line thickness |
| `gridJitterRatio` | `double` | `0.3` | Grid wobble relative to axis wobble |
| `emptyStyle` | `TextStyle?` | `null` | Empty-state message style |

### Chart Layout Bands

The chart area is divided into vertical bands computed automatically:

1. **Title band** — optional chart title
2. **Chart area** — the main plotting region
3. **X tick label band** — categorical or numeric X labels
4. **X-axis title band** — optional axis title
5. **Legend band** — optional color legend (auto-generated for multi-series line charts)

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

When segments overlap (stacked bars), the topmost (last-painted) segment wins due to reverse paint order iteration.

#### BarChartLayout Properties

| Property | Type | Description |
|----------|------|-------------|
| `size` | `Size` | The size this layout was computed for |
| `chartArea` | `Rect` | The main plotting region |
| `segments` | `List<BarSegmentLayout>` | All segments in paint order |

#### BarSegmentLayout Properties

| Property | Type | Description |
|----------|------|-------------|
| `barIndex` | `int` | Index of the bar group |
| `segmentIndex` | `int` | Index of the segment within its bar |
| `barLabel` | `String` | The bar group's X-axis label |
| `category` | `String` | The segment's category identifier |
| `value` | `double` | The segment's data value |
| `cumulativeStart` | `double` | Cumulative value at segment bottom |
| `cumulativeEnd` | `double` | Cumulative value at segment top |
| `bounds` | `Rect` | Logical bounding rectangle |

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

#### ScatterPlotLayout Properties

| Property | Type | Description |
|----------|------|-------------|
| `size` | `Size` | The size this layout was computed for |
| `chartArea` | `Rect` | The main plotting region |
| `points` | `List<ScatterPointLayout>` | All points in data order |

#### ScatterPointLayout Properties

| Property | Type | Description |
|----------|------|-------------|
| `pointIndex` | `int` | Index in the data list |
| `rawPoint` | `ScatterPoint` | The original data point |
| `center` | `Offset` | Canvas position |
| `visualRadius` | `double` | Dot radius in logical pixels |

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

#### LineChartLayout Properties

| Property | Type | Description |
|----------|------|-------------|
| `size` | `Size` | The size this layout was computed for |
| `chartArea` | `Rect` | The main plotting region |
| `points` | `List<LinePointLayout>` | All points across all series |
| `segments` | `List<LineSegmentLayout>` | All logical segments across all series |

#### LinePointLayout Properties

| Property | Type | Description |
|----------|------|-------------|
| `seriesIndex` | `int` | Index of the series |
| `seriesName` | `String?` | Name of the series |
| `pointIndex` | `int` | Index within the series |
| `rawPoint` | `LinePoint` | The original data point |
| `center` | `Offset` | Canvas position |

#### LineSegmentLayout Properties

| Property | Type | Description |
|----------|------|-------------|
| `seriesIndex` | `int` | Index of the series |
| `seriesName` | `String?` | Name of the series |
| `segmentIndex` | `int` | Index within the series |
| `rawStartPoint` | `LinePoint` | Data point at segment start |
| `rawEndPoint` | `LinePoint` | Data point at segment end |
| `start` | `Offset` | Canvas position of start |
| `end` | `Offset` | Canvas position of end |

#### LineHitTestResult Sealed Hierarchy

`LineHitTestResult` is a sealed class with two variants:

**`LinePointHit`** — a data point was hit:

| Property | Type | Description |
|----------|------|-------------|
| `seriesIndex` | `int` | Series that was hit |
| `seriesName` | `String?` | Series name |
| `pointIndex` | `int` | Point index within the series |
| `point` | `LinePoint` | The original data point |
| `center` | `Offset` | Canvas position |
| `distance` | `double` | Distance to the query position |

**`LineSegmentHit`** — a line segment was hit (between two points):

| Property | Type | Description |
|----------|------|-------------|
| `seriesIndex` | `int` | Series that was hit |
| `seriesName` | `String?` | Series name |
| `segmentIndex` | `int` | Segment index within the series |
| `startPoint` | `LinePoint` | Data point at segment start |
| `endPoint` | `LinePoint` | Data point at segment end |
| `nearestCanvasPoint` | `Offset` | Nearest point on the segment in canvas space |
| `t` | `double` | Interpolation fraction along the segment [0, 1] |
| `interpolatedX` | `double` | Interpolated raw X value at the hit position |
| `interpolatedY` | `double` | Interpolated raw Y value at the hit position |
| `distance` | `double` | Distance to the query position |

## Tables

`HandDrawnTable` renders column-aligned data inside a `HandDrawnContainer` with `HandDrawnDivider` separators. All cells render with `maxLines: 1` and configurable overflow, making it ideal for compact, summary-style data.

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
| `strokeColor` | `Color` | `Color(0xDD000000)` | Stroke color for the outer container border |
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
| `horizontalScroll` | `bool` | `false` | Enable horizontal scrolling |

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

Use `borderOpacity` to fade the border in or out without changing the stroke color — useful for entrance animations or interactive states:

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

### HandDrawnNotebook

Draws hand-drawn horizontal ruled lines behind child content, mimicking notebook paper. Pair it with `NotebookRow` to snap content to the line grid:

```dart
HandDrawnNotebook(
  lineHeight: 28.0,
  lineColor: Colors.grey.shade300,
  child: Column(
    children: [
      NotebookRow(
        lineHeight: 28.0,
        child: Text(
          'This text sits on the ruled line',
          style: TextStyle(fontSize: 16, height: 28.0 / 16),
        ),
      ),
    ],
  ),
)
```

For text to align with the ruled lines, the `TextStyle.height` must equal `lineHeight / fontSize`.

#### Uniform vs Unique Lines

By default, every ruled line uses the same seed and looks identical (`uniformLines: true`). Set it to false to give each line its own wobble pattern:

```dart
HandDrawnNotebook(
  lineHeight: 28.0,
  uniformLines: false,
  irregularity: 2.5,
  child: myContent,
)
```

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

4. **Caching** — `HandDrawnLinePainter` and `HandDrawnNotebook` cache generated paths and only recompute when the widget size or generation parameters change.

5. **Determinism** — All randomness flows through `dart:math.Random(seed)`, so identical parameters always produce identical strokes.

6. **Chart geometry** — Chart layout is computed from a single canonical frame builder shared by both `paint()` and `computeLayout()`. Coordinate helpers are pure functions of immutable frame data, ensuring layout snapshots always match the rendered output. In debug, the frame builder asserts when the available height is insufficient for the configured title, axis, and legend bands; in release, the plot region is clamped so it can never invert.

7. **Interaction foundation** — Hit-testing uses logical (non-wobbly) geometry so results are stable regardless of rendering style. Point hits take priority over segment hits in line charts, and bar hit-testing iterates in reverse paint order so the topmost segment wins.

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

**Align text to the notebook grid** by setting `TextStyle.height` to `lineHeight / fontSize`. This ensures each rendered text line occupies exactly one notebook row.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.