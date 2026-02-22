# Hand Drawn Toolkit — Example

A demo app showcasing the `hand_drawn_toolkit` package. It renders a simple
journal page where headings, body text, and notes are wrapped in sketchy,
hand-drawn borders and dividers.

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
- **Custom path building** using `smoothedOffsets()` to draw a diagonal line,
  demonstrating the lowest-level API
- **Unique seeds on adjacent items** so each component card has a distinct wobble
  pattern
- **Parameter tuning** across contexts: subtler irregularity for small cards,
  rougher strokes for the callout box

## How It Works

The example is a single stateless page built with a `Column` inside a
`SingleChildScrollView`. Each section uses a different layer of the
package API:

1. **High-level widgets** — `HandDrawnContainer` wraps the journal entry
   and component cards, `HandDrawnDivider` separates sections.
2. **Mid-level painter** — `HandDrawnLinePainter` with a built-in helper
   (`lineHorizontal`) draws the title underline.
3. **Low-level path building** — a `buildPath` callback calls
   `smoothedOffsets()` directly to construct a custom diagonal line.

This layered approach mirrors how you would use the package in a real app:
- Reach for the convenience widgets first
- Drop down to the painter or raw helpers only when you need a shape the
  widgets don't cover.