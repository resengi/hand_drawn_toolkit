import 'package:flutter/material.dart';

import '../hand_drawn_constants.dart';

/// Builds the standard loading → empty → chart body wrapper used by
/// all chart widgets. Eliminates duplication of null/empty state handling.
///
/// The [builder] callback is only invoked when data is valid (neither
/// null nor empty), which defers widget construction and avoids
/// null-assertion crashes when data is null.
///
/// Pass [emptyStyle] to customize the "No data" message appearance.
Widget buildChartBody({
  required bool isLoading,
  required bool isEmpty,
  required double height,
  required Widget Function() builder,
  TextStyle? emptyStyle,
}) {
  if (isLoading) {
    return SizedBox(
      height: height,
      child: const Center(
        child: SizedBox(
          width: loadingIndicatorSize,
          height: loadingIndicatorSize,
          child: CircularProgressIndicator(strokeWidth: loadingStrokeWidth),
        ),
      ),
    );
  }
  if (isEmpty) {
    return SizedBox(
      height: height,
      child: Center(
        child: Text(
          'No data for this range',
          style:
              emptyStyle ??
              const TextStyle(
                color: emptyMessageColor,
                fontSize: emptyMessageFontSize,
              ),
        ),
      ),
    );
  }
  return SizedBox(height: height, child: builder());
}
