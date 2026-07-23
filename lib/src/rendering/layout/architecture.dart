part of '../layout.dart';

// Mermaid draws architecture edges at three pixels and places arrow tips two
// pixels inside their endpoint so the marker meets the service boundary cleanly.
const _architectureArrowEndpointInset = 2.0;
const _architectureGroupStrokeDash = 8.0;

// Mermaid's createText wrapper advances its tspan by one font-size line. Group
// labels add the two-pixel base transform and, when an icon is present, the
// icon/label alignment correction from svgDraw.ts.
const _architectureGroupLabelBaseOffset = 2.0;
const _architectureGroupIconLabelCorrection = 3.0;
const _architectureDiagonalEdgeLabelRotation = 45.0;
const _architecturePlainServiceCornerRadius = 5.0;

_LayoutResult _layoutArchitecture(ArchitectureAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const ArchitectureRenderOptions());
  final theme = config.resolveTheme(context.options.theme);
  final layout = layoutArchitectureModel(
    ast,
    config,
    textMeasurer: context.measurer,
    fontFamily: context.options.theme.fontFamily,
  );
  final elements = <SceneElement>[
    for (final group in layout.groups) ..._architectureGroupElements(context, config, theme, group),
    for (final edge in layout.edges) ..._architectureEdgeElements(context, config, theme, edge),
    for (final node in layout.nodes) _architectureNodeElement(context, config, theme, node),
  ];
  return _LayoutResult(
    layout.bounds.width,
    layout.bounds.height,
    [
      SceneGroup(id: context.id('architecture'), children: elements, cssClasses: const ['architecture']),
    ],
    bounds: layout.bounds,
    viewportPadding: math.max(0, config.padding - context.options.padding),
  );
}

SceneTextStyle _architectureTextStyle(_LayoutContext context) => SceneTextStyle(
  fontFamily: context.options.theme.fontFamily,
  fontSize: context.options.theme.fontSize,
  color: context.options.theme.primaryText,
);

List<SceneElement> _architectureGroupElements(
  _LayoutContext context,
  ArchitectureRenderOptions config,
  ArchitectureTheme theme,
  ArchitectureGroupLayout group,
) {
  final iconSize = group.icon == null ? 0.0 : config.padding * .75;
  return [
    SceneRect(
      id: context.id('architecture-group'),
      bounds: group.bounds,
      fill: const NoFill(),
      stroke: SceneStroke(
        color: theme.groupBorderColor,
        width: theme.groupBorderWidth,
        dashes: const [_architectureGroupStrokeDash],
      ),
      role: SemanticRole.group,
      label: group.label,
      cssClasses: const ['architecture-group', 'node-bkg'],
    ),
    if (group.icon case final icon?)
      _scaledIcon(
        context,
        icon,
        Point(group.bounds.left + 1, group.bounds.top + 1),
        iconSize,
        idPrefix: 'architecture',
        fill: SolidFill(context.options.theme.primaryText),
        cssClasses: const ['architecture-group-icon'],
      ),
    if (group.label case final label?)
      _text(
        context,
        label,
        group.bounds.left + 4 + iconSize,
        group.bounds.top +
            _architectureGroupLabelBaseOffset +
            (group.icon == null ? 0 : config.fontSize / 2 - _architectureGroupIconLabelCorrection),
        baseline: TextBaseline.hanging,
        style: _architectureTextStyle(context),
        cssClasses: const ['architecture-group-label', 'architecture-service-label'],
      ),
  ];
}

List<SceneElement> _architectureEdgeElements(
  _LayoutContext context,
  ArchitectureRenderOptions config,
  ArchitectureTheme theme,
  ArchitectureEdgeLayout edge,
) {
  final data = edge.data;
  final elements = <SceneElement>[
    ScenePath(
      id: context.id('architecture-edge'),
      commands: [MoveTo(edge.start), LineTo(edge.bend), LineTo(edge.end)],
      fill: const NoFill(),
      stroke: SceneStroke(color: theme.edgeColor, width: theme.edgeWidth),
      role: SemanticRole.edge,
      label: data.title,
      cssClasses: const ['architecture-edge', 'edge'],
    ),
    if (data.leftArrow) _architectureArrow(context, edge.start, data.leftDirection, config, theme),
    if (data.rightArrow) _architectureArrow(context, edge.end, data.rightDirection, config, theme),
  ];
  if (data.title case final title?) {
    elements.add(_architectureEdgeLabel(context, edge, title));
  }
  return elements;
}

SceneElement _architectureEdgeLabel(_LayoutContext context, ArchitectureEdgeLayout edge, String title) {
  final style = _architectureTextStyle(context);
  final renderedFontSize = context.options.theme.fontSize;
  const classes = ['architecture-edge-label', 'architecture-service-label'];
  if (edge.data.leftDirection.isVertical == edge.data.rightDirection.isVertical) {
    if (!edge.data.leftDirection.isVertical) {
      return _text(
        context,
        title,
        edge.bend.x,
        edge.bend.y + renderedFontSize,
        anchor: TextAnchor.middle,
        style: style,
        cssClasses: classes,
      );
    }
    final label = _text(
      context,
      title,
      0,
      renderedFontSize,
      anchor: TextAnchor.middle,
      style: style,
      cssClasses: classes,
    );
    return SceneGroup(
      id: context.id('architecture-edge-label-group'),
      children: [label],
      transforms: [Translate(edge.bend.x, edge.bend.y), const Rotate(-90)],
      role: SemanticRole.label,
    );
  }

  final size = context.measurer.measure(title, style);
  final horizontalDirection = edge.data.leftDirection.isVertical ? edge.data.rightDirection : edge.data.leftDirection;
  final verticalDirection = edge.data.leftDirection.isVertical ? edge.data.leftDirection : edge.data.rightDirection;
  final horizontalOffset = -horizontalDirection.axisSign * size.width / 2;
  final verticalOffset = -verticalDirection.axisSign * size.width / 2;
  final rotation = -_architectureDiagonalEdgeLabelRotation * horizontalOffset.sign * verticalOffset.sign;
  final label = _text(
    context,
    title,
    0,
    renderedFontSize,
    anchor: TextAnchor.middle,
    baseline: TextBaseline.alphabetic,
    style: style,
    cssClasses: classes,
  );
  return SceneGroup(
    id: context.id('architecture-edge-label-group'),
    children: [label],
    transforms: [
      Translate(edge.bend.x, edge.bend.y - size.height / 2),
      Translate(horizontalOffset, verticalOffset),
      Rotate(rotation, center: Point(0, size.height / 2)),
    ],
    role: SemanticRole.label,
  );
}

SceneElement _architectureNodeElement(
  _LayoutContext context,
  ArchitectureRenderOptions config,
  ArchitectureTheme theme,
  ArchitectureNodeLayout node,
) {
  if (node.kind == ArchitectureNodeKind.junction) {
    return SceneRect(
      id: context.id('architecture-junction'),
      bounds: node.bounds,
      fill: const NoFill(),
      role: SemanticRole.node,
      label: node.id,
      cssClasses: const ['architecture-junction'],
    );
  }
  final localBounds = Bounds.fromCenter(const Point(0, 0), Size(config.iconSize, config.iconSize));
  final children = <SceneElement>[
    if (node.icon case final icon?)
      _scaledIcon(
        context,
        icon,
        Point(localBounds.left, localBounds.top),
        config.iconSize,
        idPrefix: 'architecture',
        fill: SolidFill(context.options.theme.primaryText),
        cssClasses: const ['architecture-service-icon'],
      )
    else
      _architecturePlainServiceOutline(context, theme, localBounds),
    if (node.iconText case final iconText?)
      _text(
        context,
        iconText,
        0,
        0,
        anchor: TextAnchor.middle,
        style: _architectureTextStyle(context),
        cssClasses: const ['architecture-icon-text', 'node-icon-text'],
      ),
    if (node.label case final label?)
      _text(
        context,
        label,
        0,
        config.iconSize / 2 + context.options.theme.fontSize,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.middle,
        style: _architectureTextStyle(context),
        cssClasses: const ['architecture-service-label'],
      ),
  ];
  return SceneGroup(
    id: context.id('architecture-service'),
    children: children,
    transforms: [Translate(node.center.x, node.center.y)],
    role: SemanticRole.node,
    label: node.label,
    cssClasses: const ['architecture-service', 'node-service'],
  );
}

ScenePath _architecturePlainServiceOutline(_LayoutContext context, ArchitectureTheme theme, Bounds bounds) => ScenePath(
  id: context.id('architecture-node-background'),
  commands: [
    MoveTo(Point(bounds.left, bounds.bottom)),
    LineTo(Point(bounds.left, bounds.top + _architecturePlainServiceCornerRadius)),
    QuadraticTo(Point(bounds.left, bounds.top), Point(bounds.left + _architecturePlainServiceCornerRadius, bounds.top)),
    LineTo(Point(bounds.right - _architecturePlainServiceCornerRadius, bounds.top)),
    QuadraticTo(
      Point(bounds.right, bounds.top),
      Point(bounds.right, bounds.top + _architecturePlainServiceCornerRadius),
    ),
    LineTo(Point(bounds.right, bounds.bottom)),
    const ClosePath(),
  ],
  fill: const NoFill(),
  stroke: SceneStroke(
    color: theme.groupBorderColor,
    width: theme.groupBorderWidth,
    dashes: const [_architectureGroupStrokeDash],
  ),
  role: SemanticRole.background,
  cssClasses: const ['architecture-node-background', 'node-bkg'],
);

ScenePolygon _architectureArrow(
  _LayoutContext context,
  Point tip,
  ArchitectureDirection direction,
  ArchitectureRenderOptions config,
  ArchitectureTheme theme,
) {
  final delta = direction.axisSign.toDouble();
  final adjustedTip = direction.isVertical
      ? tip.translated(0, -delta * _architectureArrowEndpointInset)
      : tip.translated(-delta * _architectureArrowEndpointInset, 0);
  final tail = direction.isVertical ? adjustedTip.translated(0, delta) : adjustedTip.translated(delta, 0);
  final size = config.iconSize / 6;
  return _triangleArrow(
    context,
    tip: adjustedTip,
    tail: tail,
    length: size,
    halfWidth: size / 2,
    color: theme.edgeArrowColor,
    idPrefix: 'architecture',
    cssClasses: const ['architecture-arrow', 'arrow'],
  );
}
