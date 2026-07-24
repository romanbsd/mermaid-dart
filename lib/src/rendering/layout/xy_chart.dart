part of '../layout.dart';

const _xyAxisStrokeWidth = 2.0;
const _xyGridStrokeWidth = 1.0;
const _xyLineStrokeWidth = 2.0;
const _xyTickCount = 5;
const _xyDataLabelOffset = 8.0;

_LayoutResult _layoutXyChart(XyChartAst ast, _LayoutContext context) {
  if (ast.plots.isEmpty) {
    throw StateError('No Plot to render, please provide a plot with some data');
  }
  final config = context.options.optionsFor(const XyChartRenderOptions());
  final geometry = _XyChartGeometry(ast, config);
  final elements = <SceneElement>[
    SceneRect(
      id: context.id('xychart-background'),
      bounds: Bounds(left: 0, top: 0, width: config.width, height: config.height),
      fill: SolidFill(context.options.theme.background),
      cssClasses: const ['background'],
    ),
    ..._xyValueAxis(context, geometry),
    ..._xyCategoryAxis(ast, context, geometry),
  ];
  final bars = ast.plots.where((plot) => plot.type == XyChartPlotType.bar).toList();
  for (final (plotIndex, plot) in ast.plots.indexed) {
    elements.addAll(_xyPlot(plot, plotIndex, bars, context, geometry));
  }
  elements.addAll(_xyTitles(ast, context, geometry));
  return _LayoutResult(config.width, config.height, elements);
}

List<SceneElement> _xyValueAxis(_LayoutContext context, _XyChartGeometry geometry) {
  final stroke = SceneStroke(color: context.options.theme.line, width: _xyAxisStrokeWidth);
  final gridStroke = SceneStroke(color: context.options.theme.tertiaryBorder, width: _xyGridStrokeWidth);
  return [
    for (var tick = 0; tick <= _xyTickCount; tick++) ...[
      SceneLine(
        id: context.id('xychart-grid'),
        start: geometry.valueGridLine(tick / _xyTickCount).$1,
        end: geometry.valueGridLine(tick / _xyTickCount).$2,
        stroke: gridStroke,
        cssClasses: const ['grid'],
      ),
      _text(
        context,
        _xyNumber(geometry.valueAt(tick / _xyTickCount)),
        geometry.valueLabelPosition(tick / _xyTickCount).x,
        geometry.valueLabelPosition(tick / _xyTickCount).y,
        anchor: geometry.horizontal ? TextAnchor.middle : TextAnchor.end,
        cssClasses: const ['tick'],
      ),
    ],
    SceneLine(
      id: context.id('xychart-x-axis'),
      start: geometry.origin,
      end: geometry.categoryAxisEnd,
      stroke: stroke,
      cssClasses: const ['axis', 'x-axis'],
    ),
    SceneLine(
      id: context.id('xychart-y-axis'),
      start: geometry.origin,
      end: geometry.valueAxisEnd,
      stroke: stroke,
      cssClasses: const ['axis', 'y-axis'],
    ),
  ];
}

List<SceneElement> _xyCategoryAxis(XyChartAst ast, _LayoutContext context, _XyChartGeometry geometry) => [
  for (final (index, label) in geometry.categoryLabels.indexed)
    _text(
      context,
      label,
      geometry.categoryLabelPosition(index).x,
      geometry.categoryLabelPosition(index).y,
      anchor: geometry.horizontal ? TextAnchor.end : TextAnchor.middle,
      cssClasses: const ['tick'],
    ),
];

List<SceneElement> _xyPlot(
  XyChartPlotAst plot,
  int plotIndex,
  List<XyChartPlotAst> bars,
  _LayoutContext context,
  _XyChartGeometry geometry,
) {
  final color = context.options.theme.categoricalColors[plotIndex % context.options.theme.categoricalColors.length];
  final visible = math.min(geometry.categoryCount, plot.points.length);
  return switch (plot.type) {
    XyChartPlotType.bar => _xyBars(plot, bars.indexOf(plot), bars.length, visible, color, context, geometry),
    XyChartPlotType.line => _xyLine(plot, visible, color, context, geometry),
  };
}

List<SceneElement> _xyBars(
  XyChartPlotAst plot,
  int barIndex,
  int barCount,
  int visible,
  Color color,
  _LayoutContext context,
  _XyChartGeometry geometry,
) {
  final barSize = geometry.availableBarSize / barCount;
  return [
    for (var index = 0; index < visible; index++) ...[
      SceneRect(
        id: context.id('xychart-bar'),
        bounds: geometry.barBounds(index, plot.points[index], barIndex, barSize),
        fill: SolidFill(color),
        role: SemanticRole.node,
        cssClasses: const ['xychart-bar'],
        label: plot.title,
      ),
      if (geometry.config.showDataLabel)
        _xyLabel(
          context,
          _xyNumber(plot.points[index]),
          geometry.dataLabelPosition(index, plot.points[index]),
          geometry.horizontal ? TextAnchor.start : TextAnchor.middle,
          const ['data-label'],
        ),
    ],
  ];
}

List<SceneElement> _xyLine(
  XyChartPlotAst plot,
  int visible,
  Color color,
  _LayoutContext context,
  _XyChartGeometry geometry,
) {
  final points = [for (var index = 0; index < visible; index++) geometry.datum(index, plot.points[index])];
  return [
    ScenePolyline(
      id: context.id('xychart-line'),
      points: points,
      fill: const NoFill(),
      stroke: SceneStroke(color: color, width: _xyLineStrokeWidth, join: StrokeJoin.round),
      role: SemanticRole.edge,
      cssClasses: const ['xychart-line'],
      label: plot.title,
    ),
    for (final (index, point) in points.indexed) ...[
      SceneCircle(
        id: context.id('xychart-point'),
        center: point,
        radius: 3,
        fill: SolidFill(color),
        cssClasses: const ['xychart-point'],
      ),
      if (index < plot.pointLabels.length && plot.pointLabels[index].isNotEmpty)
        _xyLabel(context, plot.pointLabels[index], point.translated(0, -_xyDataLabelOffset), TextAnchor.middle, const [
          'point-label',
        ]),
    ],
  ];
}

List<SceneElement> _xyTitles(XyChartAst ast, _LayoutContext context, _XyChartGeometry geometry) => [
  if (ast.title case final title?)
    _text(
      context,
      title,
      geometry.config.width / 2,
      geometry.config.chartPadding / 2,
      anchor: TextAnchor.middle,
      role: SemanticRole.title,
      style: _mermaidTextStyle(context, context.options.theme.fontSize * 1.25, color: context.options.theme.title),
      cssClasses: const ['chart-title'],
    ),
  if (ast.xAxis.title.isNotEmpty)
    _xyLabel(
      context,
      ast.xAxis.title,
      geometry.categoryTitlePosition,
      geometry.horizontal ? TextAnchor.start : TextAnchor.middle,
      const ['axis-title'],
    ),
  if (ast.yAxis.title.isNotEmpty)
    _xyLabel(
      context,
      ast.yAxis.title,
      geometry.valueTitlePosition,
      geometry.horizontal ? TextAnchor.end : TextAnchor.start,
      const ['axis-title'],
    ),
];

SceneText _xyLabel(_LayoutContext context, String value, Point position, TextAnchor anchor, List<String> cssClasses) =>
    _text(context, value, position.x, position.y, anchor: anchor, cssClasses: cssClasses);

final class _XyChartGeometry {
  _XyChartGeometry(this.ast, this.config)
    : horizontal = ast.orientation == XyChartOrientation.horizontal,
      left = config.chartPadding,
      top = config.chartPadding + (ast.title == null ? 0 : config.titlePadding),
      right = config.width - config.chartPadding,
      bottom = config.height - config.chartPadding,
      categoryCount = switch (ast.xAxis) {
        XyChartBandAxisAst axis => axis.categories.length,
        XyChartLinearAxisAst axis => math.max(1, axis.max.round() - axis.min.round() + 1),
      };

  final XyChartAst ast;
  final XyChartRenderOptions config;
  final bool horizontal;
  final double left;
  final double top;
  final double right;
  final double bottom;
  final int categoryCount;

  double get width => right - left;
  double get height => bottom - top;
  double get bandSize => (horizontal ? height : width) / math.max(1, categoryCount);
  double get availableBarSize => bandSize * (1 - config.barGapRatio);
  double get valueSpan => ast.yAxis.max == ast.yAxis.min ? 1 : ast.yAxis.max - ast.yAxis.min;
  Point get origin => Point(left, bottom);
  Point get categoryAxisEnd => horizontal ? Point(left, top) : Point(right, bottom);
  Point get valueAxisEnd => horizontal ? Point(right, bottom) : Point(left, top);

  List<String> get categoryLabels => switch (ast.xAxis) {
    XyChartBandAxisAst axis => axis.categories,
    XyChartLinearAxisAst axis => [for (var i = 0; i < categoryCount; i++) _xyNumber(axis.min + i)],
  };

  double valueAt(double fraction) => ast.yAxis.min + valueSpan * fraction;

  double valuePosition(double value) => horizontal
      ? left + (value - ast.yAxis.min) / valueSpan * width
      : bottom - (value - ast.yAxis.min) / valueSpan * height;

  double categoryPosition(int index) =>
      (horizontal ? top : left) +
      (categoryCount <= 1 ? .5 : (index + .5) / categoryCount) * (horizontal ? height : width);

  Point datum(int index, double value) => horizontal
      ? Point(valuePosition(value), categoryPosition(index))
      : Point(categoryPosition(index), valuePosition(value));

  (Point, Point) valueGridLine(double fraction) {
    final coordinate = horizontal ? left + fraction * width : bottom - fraction * height;
    return horizontal
        ? (Point(coordinate, top), Point(coordinate, bottom))
        : (Point(left, coordinate), Point(right, coordinate));
  }

  Point valueLabelPosition(double fraction) {
    final line = valueGridLine(fraction);
    return horizontal
        ? Point(line.$1.x, bottom + config.axisLabelPadding)
        : Point(left - config.axisLabelPadding, line.$1.y);
  }

  Point categoryLabelPosition(int index) => horizontal
      ? Point(left - config.axisLabelPadding, categoryPosition(index))
      : Point(categoryPosition(index), bottom + config.axisLabelPadding);

  Bounds barBounds(int index, double value, int barIndex, double barSize) {
    final point = datum(index, value);
    final zero = valuePosition(
      0.clamp(math.min(ast.yAxis.min, ast.yAxis.max), math.max(ast.yAxis.min, ast.yAxis.max)).toDouble(),
    );
    final offset =
        (horizontal ? top : left) + index * bandSize + bandSize * config.barGapRatio / 2 + barIndex * barSize;
    return horizontal
        ? Bounds(left: math.min(zero, point.x), top: offset, width: (point.x - zero).abs(), height: barSize)
        : Bounds(left: offset, top: math.min(zero, point.y), width: barSize, height: (point.y - zero).abs());
  }

  Point dataLabelPosition(int index, double value) {
    final point = datum(index, value);
    return horizontal ? point.translated(_xyDataLabelOffset, 0) : point.translated(0, -_xyDataLabelOffset);
  }

  Point get categoryTitlePosition => horizontal
      ? Point(left, top - config.axisLabelPadding)
      : Point((left + right) / 2, config.height - config.axisLabelPadding);

  Point get valueTitlePosition =>
      horizontal ? Point(right, config.height - config.axisLabelPadding) : Point(left, top - config.axisLabelPadding);
}

String _xyNumber(double value) => value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(2);
