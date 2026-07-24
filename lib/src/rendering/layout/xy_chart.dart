part of '../layout.dart';

const _xyLineStrokeWidth = 2.0;
const _xyBarPaddingPercent = .05;
const _xyBarWidthToTickWidthRatio = .7;
const _xyLineLabelOffset = 10.0;
const _xyLineLabelFontSize = 12.0;

_LayoutResult _layoutXyChart(XyChartAst ast, _LayoutContext context) {
  if (ast.plots.isEmpty) {
    throw StateError('No Plot to render, please provide a plot with some data');
  }
  final config = context.options.optionsFor(const XyChartRenderOptions());
  final theme = context.options.theme.xyChart;
  final geometry = _MermaidXyGeometry(ast, config, context);
  final elements = <SceneElement>[
    SceneRect(
      id: context.id('xychart-background'),
      bounds: Bounds(left: 0, top: 0, width: config.width, height: config.height),
      fill: SolidFill(theme.backgroundColor),
      cssClasses: const ['background'],
    ),
    if (config.showTitle && ast.title != null)
      _transformedText(
        context,
        ast.title!,
        config.width / 2,
        geometry.titleHeight / 2,
        idPrefix: 'xychart-text',
        color: theme.titleColor,
        fontSize: config.titleFontSize,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.middle,
        role: SemanticRole.title,
        cssClasses: const ['chart-title'],
      ),
  ];

  for (final (plotIndex, plot) in ast.plots.indexed) {
    final color = theme.plotColors[plotIndex % theme.plotColors.length];
    final visible = math.min(geometry.categoryCount, plot.points.length);
    switch (plot.type) {
      case XyChartPlotType.bar:
        for (var index = 0; index < visible; index++) {
          final bounds = geometry.barBounds(index, plot.points[index]);
          elements.add(
            SceneRect(
              id: context.id('xychart-bar'),
              bounds: bounds,
              fill: SolidFill(color),
              stroke: SceneStroke(color: color, width: 0),
              role: SemanticRole.node,
              cssClasses: ['bar-plot-$plotIndex'],
              label: plot.title,
            ),
          );
        }
      case XyChartPlotType.line:
        final points = [for (var index = 0; index < visible; index++) geometry.datum(index, plot.points[index])];
        if (points.isNotEmpty) {
          elements.add(
            ScenePath(
              id: context.id('xychart-line'),
              commands: [MoveTo(points.first), for (final point in points.skip(1)) LineTo(point)],
              fill: const NoFill(),
              stroke: SceneStroke(color: color, width: _xyLineStrokeWidth),
              role: SemanticRole.edge,
              cssClasses: ['line-plot-$plotIndex'],
              label: plot.title,
            ),
          );
        }
        for (final (index, point) in points.indexed) {
          if (index >= plot.pointLabels.length || plot.pointLabels[index].isEmpty) continue;
          elements.add(
            _transformedText(
              context,
              plot.pointLabels[index],
              point.x + (geometry.horizontal ? _xyLineLabelOffset : 0),
              point.y - (geometry.horizontal ? 0 : _xyLineLabelOffset),
              idPrefix: 'xychart-text',
              color: color,
              fontSize: _xyLineLabelFontSize,
              anchor: geometry.horizontal ? TextAnchor.start : TextAnchor.middle,
              baseline: TextBaseline.middle,
              cssClasses: const ['point-label'],
            ),
          );
        }
    }
  }

  if (geometry.horizontal) {
    elements.addAll(_xyUpstreamLeftCategoryAxis(ast, context, geometry, theme));
    elements.addAll(_xyUpstreamTopValueAxis(ast, context, geometry, theme));
  } else {
    elements.addAll(_xyUpstreamBottomAxis(ast, context, geometry, theme));
    elements.addAll(_xyUpstreamLeftValueAxis(ast, context, geometry, theme));
  }
  return _LayoutResult(config.width, config.height, elements);
}

List<SceneElement> _xyUpstreamBottomAxis(
  XyChartAst ast,
  _LayoutContext context,
  _MermaidXyGeometry geometry,
  XyChartTheme theme,
) {
  final config = geometry.config.xAxis;
  final axisY = geometry.bottom + config.axisLineWidth / 2;
  final tickY = geometry.bottom + config.axisLineWidth;
  final labelY = tickY + config.tickLength + config.labelPadding;
  return [
    if (config.showAxisLine)
      _xyPath(
        context,
        Point(geometry.left, axisY),
        Point(geometry.right, axisY),
        theme.xAxisLineColor,
        config.axisLineWidth,
        const ['bottom-axis', 'axis-line'],
      ),
    if (config.showLabel)
      for (final (index, label) in geometry.categoryLabels.indexed)
        _transformedText(
          context,
          label,
          geometry.categoryPosition(index),
          labelY,
          idPrefix: 'xychart-text',
          color: theme.xAxisLabelColor,
          fontSize: config.labelFontSize,
          anchor: TextAnchor.middle,
          baseline: TextBaseline.textBeforeEdge,
          cssClasses: const ['bottom-axis', 'label'],
        ),
    if (config.showTick)
      for (var index = 0; index < geometry.categoryCount; index++)
        _xyPath(
          context,
          Point(geometry.categoryPosition(index), tickY),
          Point(geometry.categoryPosition(index), tickY + config.tickLength),
          theme.xAxisTickColor,
          config.tickWidth,
          const ['bottom-axis', 'ticks'],
        ),
    if (config.showTitle && ast.xAxis.title.isNotEmpty)
      _transformedText(
        context,
        ast.xAxis.title,
        _xyRoundToThousandth((geometry.left + geometry.right) / 2),
        geometry.config.height - config.titlePadding - geometry.xAxisTitleTextHeight,
        idPrefix: 'xychart-text',
        color: theme.xAxisTitleColor,
        fontSize: config.titleFontSize,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.textBeforeEdge,
        cssClasses: const ['bottom-axis', 'title'],
      ),
  ];
}

List<SceneElement> _xyUpstreamLeftValueAxis(
  XyChartAst ast,
  _LayoutContext context,
  _MermaidXyGeometry geometry,
  XyChartTheme theme,
) => _xyUpstreamLeftAxis(
  context,
  geometry,
  config: geometry.config.yAxis,
  title: ast.yAxis.title,
  labels: [for (final tick in geometry.yTicks) (text: _xyNumber(tick), position: geometry.valuePosition(tick))],
  tickPositions: [for (final tick in geometry.yTicks) geometry.valuePosition(tick)],
  colors: (
    line: theme.yAxisLineColor,
    label: theme.yAxisLabelColor,
    tick: theme.yAxisTickColor,
    title: theme.yAxisTitleColor,
  ),
);

List<SceneElement> _xyUpstreamLeftCategoryAxis(
  XyChartAst ast,
  _LayoutContext context,
  _MermaidXyGeometry geometry,
  XyChartTheme theme,
) => _xyUpstreamLeftAxis(
  context,
  geometry,
  config: geometry.config.xAxis,
  title: ast.xAxis.title,
  labels: [
    for (final (index, label) in geometry.categoryLabels.indexed)
      (text: label, position: geometry.categoryPosition(index)),
  ],
  tickPositions: [for (var index = 0; index < geometry.categoryCount; index++) geometry.categoryPosition(index)],
  colors: (
    line: theme.xAxisLineColor,
    label: theme.xAxisLabelColor,
    tick: theme.xAxisTickColor,
    title: theme.xAxisTitleColor,
  ),
);

/// The left axis, shared by the value axis of a vertical chart and the category
/// axis of a horizontal one: upstream draws both the same way, differing only in
/// which axis supplies the labels, the palette, and the title.
List<SceneElement> _xyUpstreamLeftAxis(
  _LayoutContext context,
  _MermaidXyGeometry geometry, {
  required XyChartAxisRenderOptions config,
  required String title,
  required List<({String text, double position})> labels,
  required List<double> tickPositions,
  required ({Color line, Color label, Color tick, Color title}) colors,
}) {
  final axisX = geometry.left - config.axisLineWidth / 2;
  final tickX = geometry.left - config.axisLineWidth;
  final labelX = tickX - config.tickLength - config.labelPadding;
  return [
    if (config.showAxisLine)
      _xyPath(
        context,
        Point(axisX, geometry.top),
        Point(axisX, geometry.bottom),
        colors.line,
        config.axisLineWidth,
        const ['left-axis', 'axis-line'],
      ),
    if (config.showLabel)
      for (final label in labels)
        _transformedText(
          context,
          label.text,
          labelX,
          label.position,
          idPrefix: 'xychart-text',
          color: colors.label,
          fontSize: config.labelFontSize,
          anchor: TextAnchor.end,
          baseline: TextBaseline.middle,
          cssClasses: const ['left-axis', 'label'],
        ),
    if (config.showTick)
      for (final position in tickPositions)
        _xyPath(
          context,
          Point(tickX, position),
          Point(tickX - config.tickLength, position),
          colors.tick,
          config.tickWidth,
          const ['left-axis', 'ticks'],
        ),
    if (config.showTitle && title.isNotEmpty)
      _transformedText(
        context,
        title,
        config.titlePadding,
        (geometry.top + geometry.bottom) / 2,
        idPrefix: 'xychart-text',
        color: colors.title,
        fontSize: config.titleFontSize,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.textBeforeEdge,
        rotation: 270,
        cssClasses: const ['left-axis', 'title'],
      ),
  ];
}

List<SceneElement> _xyUpstreamTopValueAxis(
  XyChartAst ast,
  _LayoutContext context,
  _MermaidXyGeometry geometry,
  XyChartTheme theme,
) {
  final config = geometry.config.yAxis;
  final axisY = geometry.top - config.axisLineWidth / 2;
  final tickY = geometry.top - config.axisLineWidth;
  final labelY = geometry.titleHeight + geometry.yAxisTitleTextHeight + config.titlePadding * 2 + config.labelPadding;
  return [
    if (config.showAxisLine)
      _xyPath(
        context,
        Point(geometry.left, axisY),
        Point(geometry.right, axisY),
        theme.yAxisLineColor,
        config.axisLineWidth,
        const ['top-axis', 'axis-line'],
      ),
    if (config.showLabel)
      for (final tick in geometry.yTicks)
        _transformedText(
          context,
          _xyNumber(tick),
          geometry.valuePosition(tick),
          labelY,
          idPrefix: 'xychart-text',
          color: theme.yAxisLabelColor,
          fontSize: config.labelFontSize,
          anchor: TextAnchor.middle,
          baseline: TextBaseline.textBeforeEdge,
          cssClasses: const ['top-axis', 'label'],
        ),
    if (config.showTick)
      for (final tick in geometry.yTicks)
        _xyPath(
          context,
          Point(geometry.valuePosition(tick), tickY),
          Point(geometry.valuePosition(tick), tickY - config.tickLength),
          theme.yAxisTickColor,
          config.tickWidth,
          const ['top-axis', 'ticks'],
        ),
    if (config.showTitle && ast.yAxis.title.isNotEmpty)
      _transformedText(
        context,
        ast.yAxis.title,
        (geometry.left + geometry.right) / 2,
        geometry.titleHeight + config.titlePadding,
        idPrefix: 'xychart-text',
        color: theme.yAxisTitleColor,
        fontSize: config.titleFontSize,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.textBeforeEdge,
        cssClasses: const ['top-axis', 'title'],
      ),
  ];
}

ScenePath _xyPath(_LayoutContext context, Point start, Point end, Color color, double width, List<String> cssClasses) =>
    ScenePath(
      id: context.id('xychart-path'),
      commands: [MoveTo(start), LineTo(end)],
      fill: const NoFill(),
      stroke: SceneStroke(color: color, width: width),
      cssClasses: cssClasses,
    );

final class _MermaidXyGeometry {
  _MermaidXyGeometry(this.ast, this.config, _LayoutContext context)
    : horizontal = ast.orientation == XyChartOrientation.horizontal {
    categoryLabels = switch (ast.xAxis) {
      XyChartBandAxisAst axis => axis.categories,
      XyChartLinearAxisAst axis => _xyD3Ticks(axis.min, axis.max).map(_xyNumber).toList(growable: false),
    };
    categoryCount = math.max(1, categoryLabels.length);
    final ticks = _xyD3Ticks(ast.yAxis.min, ast.yAxis.max);
    yTicks = horizontal ? ticks : ticks.reversed.toList(growable: false);

    final titleSize = ast.title == null
        ? const Size(0, 0)
        : context.measurer.measure(
            ast.title!,
            _xyTextStyle(context, config.titleFontSize, context.options.theme.xyChart.titleColor),
          );
    titleHeight = !config.showTitle || ast.title == null ? 0 : titleSize.height + config.titlePadding * 2;

    final xLabelSizes = [
      for (final label in categoryLabels)
        context.measurer.measure(
          label,
          _xyTextStyle(context, config.xAxis.labelFontSize, context.options.theme.xyChart.xAxisLabelColor),
        ),
    ];
    final xLabelHeight = xLabelSizes.fold(0.0, (height, size) => math.max(height, size.height));
    final xLabelWidth = xLabelSizes.fold(0.0, (width, size) => math.max(width, size.width));
    xAxisTitleTextHeight = ast.xAxis.title.isEmpty
        ? 0
        : context.measurer
              .measure(
                ast.xAxis.title,
                _xyTextStyle(context, config.xAxis.titleFontSize, context.options.theme.xyChart.xAxisTitleColor),
              )
              .height;
    xAxisHeight =
        (config.xAxis.showAxisLine ? config.xAxis.axisLineWidth : 0.0) +
        (config.xAxis.showLabel ? xLabelHeight + config.xAxis.labelPadding * 2 : 0.0) +
        (config.xAxis.showTick ? config.xAxis.tickLength : 0.0) +
        (!config.xAxis.showTitle || ast.xAxis.title.isEmpty
            ? 0.0
            : xAxisTitleTextHeight + config.xAxis.titlePadding * 2);

    final yLabelSizes = [
      for (final tick in yTicks)
        context.measurer.measure(
          _xyNumber(tick),
          _xyTextStyle(context, config.yAxis.labelFontSize, context.options.theme.xyChart.yAxisLabelColor),
        ),
    ];
    final yLabelWidth = yLabelSizes.fold(0.0, (width, size) => math.max(width, size.width));
    final yLabelHeight = yLabelSizes.fold(0.0, (height, size) => math.max(height, size.height));
    yAxisTitleTextHeight = ast.yAxis.title.isEmpty
        ? 0
        : context.measurer
              .measure(
                ast.yAxis.title,
                _xyTextStyle(context, config.yAxis.titleFontSize, context.options.theme.xyChart.yAxisTitleColor),
              )
              .height;
    final yAxisWidth =
        (config.yAxis.showAxisLine ? config.yAxis.axisLineWidth : 0.0) +
        (config.yAxis.showLabel ? yLabelWidth + config.yAxis.labelPadding * 2 : 0.0) +
        (config.yAxis.showTick ? config.yAxis.tickLength : 0.0) +
        (!config.yAxis.showTitle || ast.yAxis.title.isEmpty
            ? 0.0
            : yAxisTitleTextHeight + config.yAxis.titlePadding * 2);

    final reservedWidth = (config.width * config.plotReservedSpacePercent / 100).floorToDouble();
    final reservedHeight = (config.height * config.plotReservedSpacePercent / 100).floorToDouble();
    if (horizontal) {
      final xAxisWidth =
          (config.xAxis.showAxisLine ? config.xAxis.axisLineWidth : 0.0) +
          (config.xAxis.showLabel ? xLabelWidth + config.xAxis.labelPadding * 2 : 0.0) +
          (config.xAxis.showTick ? config.xAxis.tickLength : 0.0) +
          (!config.xAxis.showTitle || ast.xAxis.title.isEmpty
              ? 0.0
              : xAxisTitleTextHeight + config.xAxis.titlePadding * 2);
      final yAxisHeight =
          (config.yAxis.showAxisLine ? config.yAxis.axisLineWidth : 0.0) +
          (config.yAxis.showLabel ? yLabelHeight + config.yAxis.labelPadding * 2 : 0.0) +
          (config.yAxis.showTick ? config.yAxis.tickLength : 0.0) +
          (!config.yAxis.showTitle || ast.yAxis.title.isEmpty
              ? 0.0
              : yAxisTitleTextHeight + config.yAxis.titlePadding * 2);
      left = xAxisWidth;
      top = titleHeight + yAxisHeight;
      width = reservedWidth + (config.width - reservedWidth - xAxisWidth);
      height = reservedHeight + (config.height - reservedHeight - titleHeight - yAxisHeight);
    } else {
      left = yAxisWidth;
      top = titleHeight;
      width = reservedWidth + (config.width - reservedWidth - yAxisWidth);
      height = reservedHeight + (config.height - reservedHeight - titleHeight - xAxisHeight);
    }
    right = left + width;
    bottom = top + height;

    final categoryLabelHalfSize = (horizontal ? xLabelHeight : xLabelWidth) / 2;
    final categoryLength = horizontal ? height : width;
    final initialCategoryPadding = math.min(categoryLabelHalfSize, categoryLength * .2);
    final initialTickDistance = (categoryLength - initialCategoryPadding * 2) / categoryCount;
    categoryOuterPadding = _xyBarWidthToTickWidthRatio * initialTickDistance > initialCategoryPadding * 2
        ? (_xyBarWidthToTickWidthRatio * initialTickDistance / 2).floorToDouble()
        : initialCategoryPadding;
    valueOuterPadding = horizontal ? math.min(yLabelWidth / 2, width * .2) : math.min(yLabelHeight / 2, height * .2);
  }

  final XyChartAst ast;
  final XyChartRenderOptions config;
  final bool horizontal;
  late final List<String> categoryLabels;
  late final List<double> yTicks;
  late final int categoryCount;
  late final double titleHeight;
  late final double xAxisTitleTextHeight;
  late final double yAxisTitleTextHeight;
  late final double xAxisHeight;
  late final double yAxisWidth;
  late final double left;
  late final double top;
  late final double width;
  late final double height;
  late final double right;
  late final double bottom;
  late final double categoryOuterPadding;
  late final double valueOuterPadding;

  double categoryPosition(int index) {
    final start = (horizontal ? top : left) + categoryOuterPadding;
    final end = (horizontal ? bottom : right) - categoryOuterPadding;
    return categoryCount == 1 ? (start + end) / 2 : start + (end - start) * index / (categoryCount - 1);
  }

  double valuePosition(double value) {
    final start = (horizontal ? left : top) + valueOuterPadding;
    final end = (horizontal ? right : bottom) - valueOuterPadding;
    final span = ast.yAxis.max - ast.yAxis.min;
    if (span == 0) return (start + end) / 2;
    return start + (horizontal ? value - ast.yAxis.min : ast.yAxis.max - value) / span * (end - start);
  }

  Point datum(int index, double value) => horizontal
      ? Point(valuePosition(value), categoryPosition(index))
      : Point(categoryPosition(index), valuePosition(value));

  Bounds barBounds(int index, double value) {
    final categoryLength = horizontal ? height : width;
    final tickDistance = (categoryLength - categoryOuterPadding * 2) / categoryCount;
    final barWidth = math.min(categoryOuterPadding * 2, tickDistance) * (1 - _xyBarPaddingPercent);
    final valueCoordinate = valuePosition(value);
    return horizontal
        ? Bounds(
            left: left,
            top: categoryPosition(index) - barWidth / 2,
            width: valueCoordinate - left,
            height: barWidth,
          )
        : Bounds(
            left: categoryPosition(index) - barWidth / 2,
            top: valueCoordinate,
            width: barWidth,
            height: bottom - valueCoordinate,
          );
  }
}

SceneTextStyle _xyTextStyle(_LayoutContext context, double fontSize, Color color) =>
    SceneTextStyle(fontFamily: context.options.theme.fontFamily, fontSize: fontSize, color: color);

List<double> _xyD3Ticks(double start, double stop, [int count = 10]) {
  if (start == stop || count <= 0) return [start];
  final reverse = stop < start;
  final low = reverse ? stop : start;
  final high = reverse ? start : stop;
  final rawStep = (high - low) / count;
  final power = (math.log(rawStep) / math.ln10).floor();
  final magnitude = math.pow(10, power).toDouble();
  final error = rawStep / magnitude;
  final factor = error >= math.sqrt(50)
      ? 10
      : error >= math.sqrt(10)
      ? 5
      : error >= math.sqrt(2)
      ? 2
      : 1;
  final step = factor * magnitude;
  final first = (low / step).ceil();
  final last = (high / step).floor();
  final ticks = [for (var index = first; index <= last; index++) index * step];
  return reverse ? ticks.reversed.toList(growable: false) : ticks;
}

double _xyRoundToThousandth(double value) => (value * 1000).round() / 1000;

String _xyNumber(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
