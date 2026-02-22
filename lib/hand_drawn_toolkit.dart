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
/// See the [README](https://github.com/your-org/hand_drawn_toolkit) for full
/// documentation and examples.
library;

export 'src/hand_drawn_container.dart';
export 'src/hand_drawn_divider.dart';
export 'src/hand_drawn_line_painter.dart';
export 'src/hand_drawn_toolkit_defaults.dart';
export 'src/hand_drawn_toolkit_helpers.dart';
