part of '../layout.dart';

typedef _QuadrantSpace = ({double left, double top, double width, double height});

_LayoutResult _layoutQuadrantChart(QuadrantChartAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const QuadrantChartRenderOptions());
  final theme = context.options.theme.quadrant;
  final hasPoints = ast.points.isNotEmpty;
  final showTitle = ast.title?.isNotEmpty ?? false;
  final showXAxis = ast.xAxis != null && ast.xAxis!.start.isNotEmpty;
  final showYAxis = ast.yAxis != null && ast.yAxis!.start.isNotEmpty;
  final xAxisPosition = hasPoints ? QuadrantXAxisPosition.bottom : config.xAxisPosition;

  final xAxisSpace = showXAxis ? config.xAxisLabelPadding * 2 + config.xAxisLabelFontSize : 0.0;
  final yAxisSpace = showYAxis ? config.yAxisLabelPadding * 2 + config.yAxisLabelFontSize : 0.0;
  final titleSpace = showTitle ? config.titleFontSize + config.titlePadding * 2 : 0.0;
  final xAxisTopSpace = xAxisPosition == QuadrantXAxisPosition.top ? xAxisSpace : 0.0;
  final xAxisBottomSpace = xAxisPosition == QuadrantXAxisPosition.bottom ? xAxisSpace : 0.0;
  final yAxisLeftSpace = config.yAxisPosition == QuadrantYAxisPosition.left ? yAxisSpace : 0.0;
  final yAxisRightSpace = config.yAxisPosition == QuadrantYAxisPosition.right ? yAxisSpace : 0.0;

  final left = config.quadrantPadding + yAxisLeftSpace;
  final top = config.quadrantPadding + xAxisTopSpace + titleSpace;
  final width = config.chartWidth - config.quadrantPadding * 2 - yAxisLeftSpace - yAxisRightSpace;
  final height = config.chartHeight - config.quadrantPadding * 2 - xAxisTopSpace - xAxisBottomSpace - titleSpace;
  final space = (left: left, top: top, width: width, height: height);
  final halfWidth = width / 2;
  final halfHeight = height / 2;
  final elements = <SceneElement>[];

  if (showTitle) {
    elements.add(
      _transformedText(
        context,
        ast.title!,
        config.chartWidth / 2,
        config.titlePadding,
        idPrefix: 'quadrant-text',
        color: theme.titleFill,
        fontSize: config.titleFontSize,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.hanging,
        role: SemanticRole.title,
        cssClasses: const ['quadrant-title'],
      ),
    );
  }

  final quadrants = [
    (
      quadrant: Quadrant.topRight,
      bounds: Bounds(left: left + halfWidth, top: top, width: halfWidth, height: halfHeight),
      fill: theme.quadrant1Fill,
      textFill: theme.quadrant1TextFill,
    ),
    (
      quadrant: Quadrant.topLeft,
      bounds: Bounds(left: left, top: top, width: halfWidth, height: halfHeight),
      fill: theme.quadrant2Fill,
      textFill: theme.quadrant2TextFill,
    ),
    (
      quadrant: Quadrant.bottomLeft,
      bounds: Bounds(left: left, top: top + halfHeight, width: halfWidth, height: halfHeight),
      fill: theme.quadrant3Fill,
      textFill: theme.quadrant3TextFill,
    ),
    (
      quadrant: Quadrant.bottomRight,
      bounds: Bounds(left: left + halfWidth, top: top + halfHeight, width: halfWidth, height: halfHeight),
      fill: theme.quadrant4Fill,
      textFill: theme.quadrant4TextFill,
    ),
  ];
  for (final (index, entry) in quadrants.indexed) {
    final (:quadrant, :bounds, :fill, :textFill) = entry;
    elements.add(
      SceneRect(
        id: context.id('quadrant'),
        bounds: bounds,
        fill: SolidFill(fill),
        role: SemanticRole.background,
        cssClasses: ['quadrant', 'quadrant-${index + 1}'],
      ),
    );
    final label = ast.quadrants[quadrant] ?? '';
    if (label.isNotEmpty) {
      elements.add(
        _transformedText(
          context,
          label,
          bounds.left + bounds.width / 2,
          hasPoints ? bounds.top + config.quadrantTextTopPadding : bounds.top + bounds.height / 2,
          idPrefix: 'quadrant-text',
          color: textFill,
          fontSize: config.quadrantLabelFontSize,
          anchor: TextAnchor.middle,
          baseline: hasPoints ? TextBaseline.hanging : TextBaseline.middle,
          cssClasses: const ['quadrant-label'],
        ),
      );
    }
  }

  _addQuadrantBorders(elements, context, config, theme, space);
  _addQuadrantAxisLabels(
    elements,
    context,
    ast,
    config,
    theme,
    space,
    titleSpace: titleSpace,
    xAxisPosition: xAxisPosition,
  );

  for (final point in ast.points.reversed) {
    final classStyle = point.className == null ? null : ast.classDefinitions[point.className];
    final style = (classStyle ?? const QuadrantPointStyleAst()).overlay(point.style);
    final center = Point(left + width * point.x, top + height * (1 - point.y));
    final fill = style.color == null ? theme.pointFill : _quadrantColor(style.color!);
    elements.add(
      SceneCircle(
        id: context.id('quadrant-point'),
        center: center,
        radius: style.radius ?? config.pointRadius,
        fill: SolidFill(fill),
        stroke: SceneStroke(
          color: style.strokeColor == null ? theme.pointFill : _quadrantColor(style.strokeColor!),
          width: style.strokeWidth ?? 0,
        ),
        role: SemanticRole.node,
        cssClasses: const ['quadrant-point'],
        label: point.label,
      ),
    );
    elements.add(
      _transformedText(
        context,
        point.label,
        center.x,
        center.y + config.pointTextPadding,
        idPrefix: 'quadrant-text',
        color: theme.pointTextFill,
        fontSize: config.pointLabelFontSize,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.hanging,
        cssClasses: const ['quadrant-point-label'],
      ),
    );
  }

  return _LayoutResult(
    config.chartWidth,
    config.chartHeight,
    elements,
    bounds: Bounds(left: 0, top: 0, width: config.chartWidth, height: config.chartHeight),
  );
}

void _addQuadrantBorders(
  List<SceneElement> elements,
  _LayoutContext context,
  QuadrantChartRenderOptions config,
  QuadrantTheme theme,
  _QuadrantSpace space,
) {
  final (:left, :top, :width, :height) = space;
  final halfExternalWidth = config.externalBorderStrokeWidth / 2;
  final external = SceneStroke(color: theme.externalBorderStroke, width: config.externalBorderStrokeWidth);
  final internal = SceneStroke(color: theme.internalBorderStroke, width: config.internalBorderStrokeWidth);
  final lines = <(Point, Point, SceneStroke)>[
    (Point(left - halfExternalWidth, top), Point(left + width + halfExternalWidth, top), external),
    (Point(left + width, top + halfExternalWidth), Point(left + width, top + height - halfExternalWidth), external),
    (Point(left - halfExternalWidth, top + height), Point(left + width + halfExternalWidth, top + height), external),
    (Point(left, top + halfExternalWidth), Point(left, top + height - halfExternalWidth), external),
    (
      Point(left + width / 2, top + halfExternalWidth),
      Point(left + width / 2, top + height - halfExternalWidth),
      internal,
    ),
    (
      Point(left + halfExternalWidth, top + height / 2),
      Point(left + width - halfExternalWidth, top + height / 2),
      internal,
    ),
  ];
  for (final (start, end, stroke) in lines) {
    elements.add(
      SceneLine(
        id: context.id('quadrant-border'),
        start: start,
        end: end,
        stroke: stroke,
        role: SemanticRole.edge,
        cssClasses: const ['quadrant-border'],
      ),
    );
  }
}

void _addQuadrantAxisLabels(
  List<SceneElement> elements,
  _LayoutContext context,
  QuadrantChartAst ast,
  QuadrantChartRenderOptions config,
  QuadrantTheme theme,
  _QuadrantSpace space, {
  required double titleSpace,
  required QuadrantXAxisPosition xAxisPosition,
}) {
  final (:left, :top, :width, :height) = space;
  final xAxis = ast.xAxis;
  if (xAxis != null) {
    final hasEnd = xAxis.end?.isNotEmpty ?? false;
    final y = xAxisPosition == QuadrantXAxisPosition.top
        ? config.xAxisLabelPadding + titleSpace
        : config.xAxisLabelPadding + top + height + config.quadrantPadding;
    elements.add(
      _transformedText(
        context,
        xAxis.start,
        left + (hasEnd ? width / 4 : 0),
        y,
        idPrefix: 'quadrant-text',
        color: theme.xAxisTextFill,
        fontSize: config.xAxisLabelFontSize,
        anchor: hasEnd ? TextAnchor.middle : TextAnchor.start,
        baseline: TextBaseline.hanging,
        cssClasses: const ['quadrant-axis-label', 'quadrant-x-axis-label'],
      ),
    );
    if (hasEnd) {
      elements.add(
        _transformedText(
          context,
          xAxis.end!,
          left + width * .75,
          y,
          idPrefix: 'quadrant-text',
          color: theme.xAxisTextFill,
          fontSize: config.xAxisLabelFontSize,
          anchor: TextAnchor.middle,
          baseline: TextBaseline.hanging,
          cssClasses: const ['quadrant-axis-label', 'quadrant-x-axis-label'],
        ),
      );
    }
  }

  final yAxis = ast.yAxis;
  if (yAxis != null) {
    final hasEnd = yAxis.end?.isNotEmpty ?? false;
    final x = config.yAxisPosition == QuadrantYAxisPosition.left
        ? config.yAxisLabelPadding
        : config.yAxisLabelPadding + left + width + config.quadrantPadding;
    void addLabel(String text, double y) {
      elements.add(
        _transformedText(
          context,
          text,
          x,
          y,
          color: theme.yAxisTextFill,
          fontSize: config.yAxisLabelFontSize,
          anchor: hasEnd ? TextAnchor.middle : TextAnchor.start,
          baseline: TextBaseline.hanging,
          rotation: -90,
          idPrefix: 'quadrant-y-axis',
          groupRole: SemanticRole.label,
          groupCssClasses: const ['quadrant-y-axis-label-group'],
          cssClasses: const ['quadrant-axis-label', 'quadrant-y-axis-label'],
        ),
      );
    }

    addLabel(yAxis.start, top + height - (hasEnd ? height / 4 : 0));
    if (hasEnd) addLabel(yAxis.end!, top + height / 4);
  }
}

Color _quadrantColor(String value) {
  final hex = value.replaceFirst('#', '');
  final expanded = hex.length == 3 ? '${hex[0]}${hex[0]}${hex[1]}${hex[1]}${hex[2]}${hex[2]}' : hex;
  return Color.fromHex(expanded);
}
