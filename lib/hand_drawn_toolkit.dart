/// A lightweight Flutter package for rendering hand-drawn, sketchy lines,
/// borders, and containers.
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

export 'src/hand_drawn_container.dart';
export 'src/hand_drawn_divider.dart';
export 'src/hand_drawn_line_painter.dart';
export 'src/hand_drawn_notebook.dart';
export 'src/hand_drawn_status_square.dart';
export 'src/hand_drawn_text_field.dart';
export 'src/hand_drawn_toolkit_defaults.dart';
export 'src/hand_drawn_toolkit_helpers.dart';
export 'src/notebook_row.dart';
export 'src/status_indicator.dart';
