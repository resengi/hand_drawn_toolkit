/// A lightweight Flutter package for rendering hand-drawn, sketchy UI
/// elements: containers, dividers, tables, charts, and more.
///
/// ## Chart model
///
/// The package supports three chart types with intentional restrictions:
///
/// - **Bar charts** are categorical on X and numeric on Y. Stacked bar
///   segments must have non-negative values and accumulate from a data
///   baseline of `0.0`. The `minY`/`maxY` parameters control the visible
///   Y-range, not the stacking origin.
/// - **Line charts** are numeric on both axes. Points should be sorted
///   by X for coherent rendering.
/// - **Scatter plots** are numeric on both axes.
///
/// ## Quick start
///
/// ```dart
/// import 'package:hand_drawn_toolkit/hand_drawn_toolkit.dart';
///
/// // Sketchy container
/// HandDrawnContainer(
///   child: Text('Hello!'),
/// )
///
/// // Sketchy divider
/// HandDrawnDivider()
///
/// // Custom painter usage
/// CustomPaint(
///   painter: HandDrawnLinePainter(
///     color: Colors.black,
///     buildPath: (size, h) => h.rectBorder(size),
///   ),
/// )
/// ```
///
/// See the [README](https://github.com/resengi/hand_drawn_toolkit) for full
/// documentation and examples.
library;

export 'src/charts/chart_data.dart';
export 'src/charts/hand_drawn_bar_chart.dart';
export 'src/charts/hand_drawn_chart_painter.dart';
export 'src/charts/hand_drawn_line_chart.dart';
export 'src/charts/hand_drawn_scatter_plot.dart';
export 'src/hand_drawn_container.dart';
export 'src/hand_drawn_divider.dart';
export 'src/hand_drawn_line_painter.dart';
export 'src/hand_drawn_notebook.dart';
export 'src/hand_drawn_status_square.dart';
export 'src/hand_drawn_table.dart';
export 'src/hand_drawn_text_field.dart';
export 'src/hand_drawn_toolkit_defaults.dart';
export 'src/hand_drawn_toolkit_helpers.dart';
export 'src/notebook_row.dart';
export 'src/status_indicator.dart';
