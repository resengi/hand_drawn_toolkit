import 'package:flutter/widgets.dart';

import '../hand_drawn_constants.dart';
import '../hand_drawn_container.dart';
import '../hand_drawn_toolkit_defaults.dart';
import 'chart_data.dart';

/// A standalone hand-drawn legend widget.
///
/// Use this when you want to position a legend independently of any
/// chart — for example, above a chart, between two charts, or inside
/// a sidebar. Configure the chart with [ChartLegendConfig.hidden] to
/// suppress the chart's own legend, then place a [HandDrawnLegend]
/// elsewhere in your widget tree.
///
/// For bar charts, pass [BarChartData.legend] directly:
///
/// ```dart
/// Column(
///   children: [
///     HandDrawnLegend(entries: barData.legend),
///     SizedBox(height: 240, child: HandDrawnBarChart(
///       data: barData,
///       legendConfig: ChartLegendConfig.hidden,
///     )),
///   ],
/// )
/// ```
///
/// For line charts, use [ChartLegendEntries.fromLineChartData] (the
/// same helper the chart calls internally when no explicit entries
/// are supplied) so the standalone legend matches what the chart
/// would have rendered:
///
/// ```dart
/// HandDrawnLegend(entries: ChartLegendEntries.fromLineChartData(lineData));
/// ```
class HandDrawnLegend extends StatelessWidget {
  const HandDrawnLegend({
    required this.entries,
    this.config = ChartLegendConfig.externalBottomBoxed,
    this.textStyle,
    this.borderColor = chartAxisColor,
    this.seed = HandDrawnDefaults.seed,
    this.irregularity = chartIrregularity,
    this.segments = wobblyRectSegments,
    this.maxWidth,
    super.key,
  });

  /// Legend entries to render, in display order.
  final List<LegendEntry> entries;

  /// Layout configuration. Defaults to
  /// [ChartLegendConfig.externalBottomBoxed] because a standalone
  /// legend is most often placed in its own boxed container; pass
  /// [ChartLegendConfig.inlineBottom] for an unboxed inline row, or
  /// any other config for custom layouts.
  final ChartLegendConfig config;

  /// Style for legend entry labels. When null, derives from a
  /// neutral default sized at [chartLegendFontSize].
  final TextStyle? textStyle;

  /// Color of the wobbly border drawn when [config.boxed] is true.
  /// Defaults to [chartAxisColor] so a standalone legend matches its
  /// chart's axis tone.
  final Color borderColor;

  /// Seed for the wobbly border's deterministic stroke jitter.
  final int seed;

  /// Stroke wobble amplitude. Higher values = more sketchy.
  final double irregularity;

  /// Edge segment count for the wobbly border. Higher = smoother.
  final int segments;

  /// Optional maximum width override. When null, the widget flows
  /// within whatever bounded constraint its parent provides. Set
  /// explicitly to override the parent's constraint.
  final double? maxWidth;

  TextStyle get _resolvedStyle =>
      textStyle ??
      const TextStyle(color: Color(0xFF1A1A1A), fontSize: chartLegendFontSize);

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty || !config.visible) return const SizedBox.shrink();

    final layout = _buildLayout();

    if (!config.boxed) {
      // Unboxed — return the layout directly. Bound the width so the
      // Wrap / Row inside has a width to flow within.
      return _maybeBound(layout);
    }

    // Boxed — wrap in HandDrawnContainer. Forward every parameter
    // explicitly so default-mismatches between the two widgets don't
    // silently change rendering.
    return _maybeBound(
      HandDrawnContainer(
        strokeColor: borderColor,
        irregularity: irregularity,
        segments: segments,
        seed: seed,
        padding: config.padding,
        child: layout,
      ),
    );
  }

  /// Wraps [child] in a width-bounding box when [maxWidth] is set or
  /// the parent constraint is bounded.
  Widget _maybeBound(Widget child) {
    if (maxWidth != null) {
      return SizedBox(width: maxWidth, child: child);
    }
    return child;
  }

  /// The flow of entry widgets, sized to [config.position] +
  /// [config.wrap].
  Widget _buildLayout() {
    final entryWidgets = [
      for (final e in entries)
        _LegendEntryWidget(entry: e, textStyle: _resolvedStyle),
    ];

    if (config.position == ChartLegendPosition.right) {
      // Vertical stack — one entry per row.
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < entryWidgets.length; i++) ...[
            if (i > 0) SizedBox(height: config.runSpacing),
            entryWidgets[i],
          ],
        ],
      );
    }

    // Bottom position. Wrap when wrap=true; otherwise a single row
    // that clips overflow visually.
    if (config.wrap) {
      return Wrap(
        spacing: config.spacing,
        runSpacing: config.runSpacing,
        children: entryWidgets,
      );
    }

    // Non-wrapping single row. The Row gets unbounded horizontal
    // width via SingleChildScrollView (so it never reports Flex
    // Overflow), NeverScrollableScrollPhysics blocks user scrolling,
    // and the outer ClipRect truncates the visual overflow at the
    // legend's bounds — the standard Flutter idiom for "render
    // unbounded, clip visually, no scroll".
    return ClipRect(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (int i = 0; i < entryWidgets.length; i++) ...[
              if (i > 0) SizedBox(width: config.spacing),
              entryWidgets[i],
            ],
          ],
        ),
      ),
    );
  }
}

/// A single legend entry: colored dot + label text.
class _LegendEntryWidget extends StatelessWidget {
  const _LegendEntryWidget({required this.entry, required this.textStyle});

  final LegendEntry entry;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: chartLegendDotOffset - chartLegendDotRadius),
        Container(
          width: chartLegendDotRadius * 2,
          height: chartLegendDotRadius * 2,
          decoration: BoxDecoration(shape: BoxShape.circle, color: entry.color),
        ),
        const SizedBox(
          width:
              chartLegendTextOffset -
              chartLegendDotOffset -
              chartLegendDotRadius,
        ),
        Text(entry.label, style: textStyle),
      ],
    );
  }
}
