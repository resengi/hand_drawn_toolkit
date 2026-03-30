import 'package:flutter/material.dart';

import 'hand_drawn_divider.dart';
import 'hand_drawn_toolkit_defaults.dart';

/// A text field with a hand-drawn divider underline.
///
/// Wraps a standard [TextField] in a rounded container and places a
/// [HandDrawnDivider] underneath for a sketchy aesthetic.
///
/// ```dart
/// HandDrawnTextField(
///   hintText: 'Enter a title…',
///   onChanged: (value) => print(value),
/// )
/// ```
///
/// ## Color & style customization
///
/// All visual properties are parameterized with sensible defaults. Pass
/// explicit colors to match your app's palette:
///
/// ```dart
/// HandDrawnTextField(
///   backgroundColor: theme.cardColor,
///   textColor: theme.textTheme.bodyMedium!.color!,
///   hintColor: theme.hintColor,
///   dividerColor: theme.dividerColor,
/// )
/// ```
///
/// When a custom [style] is provided it completely replaces the default
/// [TextStyle] built from [textColor] and [fontSize].
class HandDrawnTextField extends StatelessWidget {
  /// Creates a text field with a hand-drawn underline.
  const HandDrawnTextField({
    this.controller,
    this.hintText,
    this.onChanged,
    this.onSubmitted,
    this.maxLines = 1,
    this.focusNode,
    this.seed = HandDrawnDefaults.seed,
    this.style,
    this.autofocus = false,
    this.textCapitalization = TextCapitalization.sentences,
    this.backgroundColor = const Color(0xFFF5F5F5),
    this.textColor = const Color(0xFF1A1A1A),
    this.hintColor = const Color(0xFF999999),
    this.dividerColor = const Color(0xFFE0E0E0),
    this.fontSize = HandDrawnDefaults.textFieldFontSize,
    this.borderRadius = HandDrawnDefaults.textFieldBorderRadius,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    this.dividerThickness = HandDrawnDefaults.textFieldDividerThickness,
    super.key,
  });

  /// Controls the text being edited.
  final TextEditingController? controller;

  /// Placeholder text shown when the field is empty.
  final String? hintText;

  /// Called when the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the field (e.g. presses done).
  final ValueChanged<String>? onSubmitted;

  /// The maximum number of lines for the text field.
  final int maxLines;

  /// An optional focus node for controlling focus.
  final FocusNode? focusNode;

  /// The random seed passed to the internal [HandDrawnDivider].
  final int seed;

  /// An optional text style that completely replaces the default style
  /// built from [textColor] and [fontSize].
  final TextStyle? style;

  /// Whether the field should request focus when first built.
  final bool autofocus;

  /// The capitalization behavior of the text field.
  final TextCapitalization textCapitalization;

  /// Background color of the outer container.
  final Color backgroundColor;

  /// Default text color. Ignored when a custom [style] is provided.
  final Color textColor;

  /// Hint text color.
  final Color hintColor;

  /// Color of the hand-drawn divider underline.
  final Color dividerColor;

  /// Font size used for both the default text style and the hint style.
  /// Ignored for the main text when a custom [style] is provided.
  final double fontSize;

  /// Corner radius of the background container.
  final double borderRadius;

  /// Padding inside the background container.
  final EdgeInsetsGeometry padding;

  /// Thickness of the hand-drawn divider underline.
  final double dividerThickness;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            maxLines: maxLines,
            autofocus: autofocus,
            textCapitalization: textCapitalization,
            style: style ?? TextStyle(fontSize: fontSize, color: textColor),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(fontSize: fontSize, color: hintColor),
              border: InputBorder.none,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(vertical: 6),
            ),
          ),
          HandDrawnDivider(
            color: dividerColor,
            thickness: dividerThickness,
            seed: seed,
          ),
        ],
      ),
    );
  }
}
