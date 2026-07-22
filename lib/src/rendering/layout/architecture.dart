part of '../layout.dart';

_LayoutResult _layoutArchitecture(ArchitectureAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const ArchitectureRenderOptions());
  final layout = layoutArchitectureModel(ast, config);
  final elements = <SceneElement>[
    for (final group in layout.groups) ..._architectureGroupElements(context, config, group),
    for (final edge in layout.edges) ..._architectureEdgeElements(context, config, edge),
    for (final node in layout.nodes) _architectureNodeElement(context, config, node),
  ];
  return _LayoutResult(layout.bounds.width, layout.bounds.height, [
    SceneGroup(id: context.id('architecture'), children: elements, cssClasses: const ['architecture']),
  ]);
}

SceneTextStyle _architectureTextStyle(_LayoutContext context, ArchitectureRenderOptions config) => SceneTextStyle(
  fontFamily: context.options.theme.fontFamily,
  fontSize: config.fontSize,
  color: context.options.theme.primaryText,
);

List<SceneElement> _architectureGroupElements(
  _LayoutContext context,
  ArchitectureRenderOptions config,
  ArchitectureGroupLayout group,
) {
  final iconSize = group.icon == null ? 0.0 : config.padding * .75;
  return [
    SceneRect(
      id: context.id('architecture-group'),
      bounds: group.bounds,
      fill: SolidFill(context.options.theme.tertiary),
      stroke: _stroke(context),
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
        group.bounds.top + config.fontSize / 2 + 4,
        baseline: TextBaseline.hanging,
        style: _architectureTextStyle(context, config),
        cssClasses: const ['architecture-group-label', 'architecture-service-label'],
      ),
  ];
}

List<SceneElement> _architectureEdgeElements(
  _LayoutContext context,
  ArchitectureRenderOptions config,
  ArchitectureEdgeLayout edge,
) {
  final data = edge.data;
  final elements = <SceneElement>[
    ScenePath(
      id: context.id('architecture-edge'),
      commands: [MoveTo(edge.start), LineTo(edge.bend), LineTo(edge.end)],
      fill: const NoFill(),
      stroke: _stroke(context, width: 2),
      role: SemanticRole.edge,
      label: data.title,
      cssClasses: const ['architecture-edge', 'edge'],
    ),
    if (data.leftArrow) _architectureArrow(context, edge.start, data.leftDirection, config),
    if (data.rightArrow) _architectureArrow(context, edge.end, data.rightDirection, config),
  ];
  if (data.title case final title?) {
    final label = _text(
      context,
      title,
      edge.bend.x,
      edge.bend.y,
      anchor: TextAnchor.middle,
      style: _architectureTextStyle(context, config),
      cssClasses: const ['architecture-edge-label', 'architecture-service-label'],
    );
    elements.add(
      data.leftDirection.isVertical && data.rightDirection.isVertical
          ? SceneGroup(
              id: context.id('architecture-edge-label-group'),
              children: [label],
              transforms: [Rotate(-90, center: edge.bend)],
              role: SemanticRole.label,
            )
          : label,
    );
  }
  return elements;
}

SceneElement _architectureNodeElement(
  _LayoutContext context,
  ArchitectureRenderOptions config,
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
      SceneRect(
        id: context.id('architecture-node-background'),
        bounds: localBounds,
        radiusX: 5,
        radiusY: 5,
        fill: SolidFill(context.options.theme.primary),
        stroke: _stroke(context),
        role: SemanticRole.background,
        cssClasses: const ['architecture-node-background', 'node-bkg'],
      ),
    if (node.iconText case final iconText?)
      _text(
        context,
        iconText,
        0,
        0,
        anchor: TextAnchor.middle,
        style: _architectureTextStyle(context, config),
        cssClasses: const ['architecture-icon-text', 'node-icon-text'],
      ),
    if (node.label case final label?)
      _text(
        context,
        label,
        0,
        config.iconSize / 2 + config.fontSize / 2 + 2,
        anchor: TextAnchor.middle,
        style: _architectureTextStyle(context, config),
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

ScenePolygon _architectureArrow(
  _LayoutContext context,
  Point tip,
  ArchitectureDirection direction,
  ArchitectureRenderOptions config,
) {
  final delta = direction.axisSign.toDouble();
  final tail = direction.isVertical ? tip.translated(0, delta) : tip.translated(delta, 0);
  final size = config.iconSize / 6;
  return _triangleArrow(
    context,
    tip: tip,
    tail: tail,
    length: size,
    halfWidth: size / 2,
    color: context.options.theme.line,
    idPrefix: 'architecture',
    cssClasses: const ['architecture-arrow', 'arrow'],
  );
}
