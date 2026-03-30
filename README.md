# Hand Drawn Toolkit

A lightweight Flutter package for rendering hand-drawn, sketchy lines, borders, containers, and notebook-paper layouts with a natural, organic feel.

[![pub package](https://img.shields.io/pub/v/hand_drawn_toolkit.svg)](https://pub.dev/packages/hand_drawn_toolkit)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Publisher](https://img.shields.io/pub/publisher/hand_drawn_toolkit.svg)](https://pub.dev/publishers/resengi.io)

## Example

![Example UI with hand drawn elements](https://raw.githubusercontent.com/resengi/hand_drawn_toolkit/main/assets/example.png)

## Features

- Realistic hand-drawn borders, dividers, and custom path shapes
- Tappable status squares with check/dash indicators
- Text fields with hand-drawn underlines
- Notebook-paper ruled lines with grid-snapping layout primitives
- Smooth, organic wobble via 3-point moving average smoothing
- Fully customizable styling (irregularity, segments, stroke width)
- Deterministic seed-based generation — identical parameters always produce identical strokes
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

Use `scaleFactor` for accessibility scaling instead of manually multiplying the size:

```dart
HandDrawnStatusSquare(
  color: Colors.blue,
  scaleFactor: MediaQuery.textScaleFactorOf(context),
)
```

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
      NotebookRow(
        lineHeight: 28.0,
        child: Text(
          'So does this line',
          style: TextStyle(fontSize: 16, height: 28.0 / 16),
        ),
      ),
    ],
  ),
)
```

For text to align with the ruled lines, the `TextStyle.height` must equal `lineHeight / fontSize`.

#### Uniform vs Unique Lines

By default, every ruled line uses the same seed and looks identical (`uniformLines: true`). Set it to false to give each line its own wobble pattern — line *n* uses `seed + n`, so the result is unique per line but still deterministic:

```dart
// Every line has a different wobble
HandDrawnNotebook(
  lineHeight: 28.0,
  uniformLines: false,
  irregularity: 2.5,
  child: myContent,
)

// Every line looks the same
HandDrawnNotebook(
  lineHeight: 28.0,
  uniformLines: true,
  child: myContent,
)
```

### NotebookRow

A fixed-height container that occupies exactly `rowSpan` notebook rows. The child is vertically centered within the allocated space:

```dart
NotebookRow(
  lineHeight: 28.0,
  rowSpan: 2,  // occupies two rows
  padding: EdgeInsets.symmetric(horizontal: 16),
  child: Text('Double-height row'),
)
```

### NotebookSnappedBlock

Wraps dynamic-height content and ensures its total height is at least `minRows` notebook rows:

```dart
NotebookSnappedBlock(
  lineHeight: 28.0,
  minRows: 3,
  child: TextField(maxLines: null),
)
```

### Grid Helpers

Two utility functions for notebook grid calculations:

```dart
// Snap a pixel height up to the nearest row multiple
snapHeightToRows(33.0, 32.0);  // → 64.0  (2 rows)
snapHeightToRows(64.0, 32.0);  // → 64.0  (exact)

// Get the number of whole rows needed for a pixel height
rowsForHeight(33.0, 32.0);  // → 2
rowsForHeight(64.0, 32.0);  // → 2
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

Use it as a `foregroundPainter` to draw the stroke on top of content:

```dart
CustomPaint(
  foregroundPainter: HandDrawnLinePainter(
    color: Colors.red,
    buildPath: (size, h) => h.lineHorizontal(size),
  ),
  child: MyWidget(),
)
```

### Custom Path Shapes

Use `HandDrawnHelpers.smoothedOffsets()` to build arbitrary jittered paths beyond the built-in shapes:

```dart
HandDrawnLinePainter(
  color: Colors.deepPurple,
  strokeWidth: 2.5,
  irregularity: 2.0,
  buildPath: (size, h) {
    // A diagonal line from bottom-left to top-right with wobble
    final offsets = h.smoothedOffsets();
    final dx = size.width / h.segments;
    final path = Path()..moveTo(0, size.height);
    for (int i = 1; i <= h.segments; i++) {
      final t = i / h.segments;
      final y = size.height * (1 - t) + offsets[i];
      path.lineTo(dx * i, y);
    }
    return path;
  },
)
```

## Customization

### Core Parameters

These parameters are shared across all hand-drawn APIs:

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `irregularity` | `double` | varies | Jitter magnitude in pixels (`0` = straight, `6+` = very rough) |
| `segments` | `int` | varies | Points per edge (more = smoother wobble, fewer = chunkier) |
| `seed` | `int` | `42` | Random seed (same seed = same stroke every time) |
| `strokeWidth` | `double` | varies | Stroke thickness in logical pixels |
| `color` | `Color` | varies | Stroke color |

### HandDrawnContainer Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `backgroundColor` | `Color` | `Colors.white` | Solid fill behind content |
| `strokeColor` | `Color` | `Colors.black87` | Border stroke color |
| `padding` | `EdgeInsets` | `EdgeInsets.all(20)` | Inner padding |
| `borderOpacity` | `double` | `1.0` | Border opacity multiplier (0.0–1.0) |

### HandDrawnDivider Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `direction` | `Axis` | `Axis.horizontal` | Line orientation |
| `thickness` | `double` | `1.5` | Stroke width |
| `width` | `double?` | `double.infinity` | Horizontal divider length |
| `height` | `double?` | `null` | Vertical divider length |
| `indent` | `double` | `0.0` | Start padding |
| `endIndent` | `double` | `0.0` | End padding |

### HandDrawnStatusSquare Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `color` | `Color` | required | Border and fill color |
| `isFilled` | `bool` | `false` | Whether the square is filled |
| `indicator` | `StatusIndicator` | `.none` | Overlay indicator: `none`, `check`, or `dash` |
| `indicatorColor` | `Color` | `Colors.white` | Color of the indicator stroke |
| `size` | `double` | `14.0` | Side length in logical pixels |
| `scaleFactor` | `double` | `1.0` | Multiplier for accessibility scaling |
| `onTap` | `VoidCallback?` | `null` | Tap handler (adds enlarged hit area) |
| `tapPadding` | `double` | `6.0` | Padding around square for tap target |

### HandDrawnTextField Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `controller` | `TextEditingController?` | `null` | Controls the text being edited |
| `hintText` | `String?` | `null` | Placeholder text shown when empty |
| `onChanged` | `ValueChanged<String>?` | `null` | Fires on every keystroke |
| `onSubmitted` | `ValueChanged<String>?` | `null` | Fires when the user presses done/submit |
| `maxLines` | `int` | `1` | Maximum number of lines |
| `focusNode` | `FocusNode?` | `null` | For programmatic focus control |
| `seed` | `int` | `42` | Random seed for the hand-drawn underline wobble |
| `style` | `TextStyle?` | `null` | Overrides `textColor` and `fontSize` when set |
| `autofocus` | `bool` | `false` | Whether to request focus on first build |
| `textCapitalization` | `TextCapitalization` | `.sentences` | Keyboard auto-capitalization behavior |
| `backgroundColor` | `Color` | `Color(0xFFF5F5F5)` | Outer container fill |
| `textColor` | `Color` | `Color(0xFF1A1A1A)` | Default text color (ignored when `style` is set) |
| `hintColor` | `Color` | `Color(0xFF999999)` | Hint text color |
| `dividerColor` | `Color` | `Color(0xFFE0E0E0)` | Hand-drawn underline color |
| `fontSize` | `double` | `16.0` | Font size for text and hint |
| `borderRadius` | `double` | `8.0` | Corner radius of background |
| `padding` | `EdgeInsetsGeometry` | `EdgeInsets.symmetric(horizontal: 12, vertical: 2)` | Outer container padding |
| `dividerThickness` | `double` | `1.0` | Underline stroke width |

### HandDrawnNotebook Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lineHeight` | `double` | required | Pixel height of one grid row |
| `lineColor` | `Color` | `Color(0xFFE0E0E0)` | Ruled line color |
| `strokeWidth` | `double` | `1.0` | Ruled line thickness |
| `uniformLines` | `bool` | `true` | Whether all lines share the same wobble |

### NotebookRow Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lineHeight` | `double` | required | Pixel height of one notebook row |
| `rowSpan` | `int` | `1` | Number of rows to occupy |
| `padding` | `EdgeInsetsGeometry?` | `null` | Optional horizontal padding |

### NotebookSnappedBlock Properties

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `lineHeight` | `double` | required | Pixel height of one notebook row |
| `minRows` | `int` | `1` | Minimum row count |
| `padding` | `EdgeInsetsGeometry?` | `null` | Optional horizontal padding |

## How It Works

1. **Offset generation** — `smoothedOffsets()` creates random perpendicular offsets for each segment point. First and last points are pinned to zero so strokes start and end cleanly.

2. **Smoothing** — A 3-point moving average softens harsh spikes while preserving the organic feel, preventing the "angry zigzag" look that raw random offsets produce.

3. **Path assembly** — Built-in helpers (`lineHorizontal`, `lineVertical`, `rectBorder`) stitch smoothed offsets into Flutter `Path` objects. `rectBorder` uses four independent offset sets so irregularity varies around the perimeter.

4. **Caching** — `HandDrawnLinePainter` and `HandDrawnNotebook` cache generated paths and only recompute when the widget size or generation parameters change.

5. **Determinism** — All randomness flows through `dart:math.Random(seed)`, so identical parameters always produce identical strokes.

## Best Practices

**Tune irregularity to context** — borders look good at 2.0–4.0, while dividers and notebook lines work better at 0.5–1.5. The defaults reflect this (`3.5` for containers, `1.0` for dividers and notebook lines).

**Use unique seeds for adjacent elements** to prevent identical wobble patterns lining up:

```dart
ListView.builder(
  itemBuilder: (context, index) => HandDrawnContainer(
    seed: index * 17 + 3,
    child: MyListItem(index),
  ),
)
```

**Use `uniformLines: false` on notebooks** when you want each ruled line to have its own character. Use `uniformLines: true` (the default) for a cleaner, more regular look.

**Align text to the notebook grid** by setting `TextStyle.height` to `lineHeight / fontSize`. This ensures each rendered text line occupies exactly one notebook row.

**Keep segment count reasonable** — 20–30 segments is the sweet spot for most use cases. Going above 50 adds computation without visible improvement at typical widget sizes.

**Leverage caching** — the painters only recompute when parameters or size change, so avoid recreating painter instances unnecessarily in build methods. The convenience widgets handle this correctly by default.

## License

MIT License — see [LICENSE](LICENSE) for details.

## Contributing

Contributions are welcome! Please feel free to submit issues and pull requests.
