part of '../layout.dart';

// Mermaid.js rough-table cells use 12.5 horizontal and 9.375 vertical units
// of padding around the browser-measured 24-unit label boxes.
const _erVerticalCellPadding = 9.375;
const _erMarkerHalfWidth = 9.0;
const _erMarkerCircleRadius = 6.0;
const _erMarkerBarNear = 9.0;
const _erMarkerBarFar = 15.0;
const _erMarkerCircleDepth = 21.0;
const _erMarkerCrowDepth = 18.0;
const _erMarkerCrowBarDepth = 24.0;
const _erMarkerCrowCircleDepth = 30.0;
const _erOddRowFill = Color(255, 255, 255);
const _erEvenRowFill = Color(241, 241, 255);

_LayoutResult _layoutErDiagram(ErDiagramAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const ErRenderOptions());
  final sizes = {for (final entity in ast.entities) entity.id: _erEntitySize(entity, context, config)};
  final graph = _layoutGraphBoxes(
    ids: ast.entities.map((entity) => entity.id).toList(growable: false),
    sizes: sizes,
    edges: [
      for (final relationship in ast.relationships)
        _GraphEdgeLayout(relationship.from, relationship.to, relationship.label),
    ],
    direction: ast.direction,
    nodeSpacing: config.nodeSpacing,
    rankSpacing: config.rankSpacing,
    padding: config.diagramPadding,
    context: context,
  );
  final elements = <SceneElement>[];
  for (final relationship in ast.relationships) {
    final from = graph.positions[relationship.from];
    final to = graph.positions[relationship.to];
    if (from == null || to == null) continue;
    elements.addAll(_erRelationshipElements(relationship, from, to, context, config));
  }
  for (final entity in ast.entities) {
    final bounds = graph.positions[entity.id];
    if (bounds == null) continue;
    elements.addAll(_erEntityElements(entity, bounds, ast.classDefinitions, context, config));
  }
  return _LayoutResult(
    graph.width,
    graph.height,
    elements,
    bounds: Bounds(left: 0, top: 0, width: graph.width, height: graph.height),
  );
}

Size _erEntitySize(ErEntityAst entity, _LayoutContext context, ErRenderOptions config) {
  final typeWidth = _maxGraphTextWidth(entity.attributes.map((attribute) => attribute.type), context);
  final nameWidth = _maxGraphTextWidth(entity.attributes.map((attribute) => attribute.name), context);
  final keyWidth = _maxGraphTextWidth(entity.attributes.map((attribute) => _erKeys(attribute.keys)), context);
  final commentWidth = _maxGraphTextWidth(entity.attributes.map((attribute) => attribute.comment ?? ''), context);
  final titleWidth = context.measurer.measure(entity.label, context.textStyle).width;
  final columns = [typeWidth, nameWidth, keyWidth, if (commentWidth > 0) commentWidth];
  final width = math.max(
    titleWidth + config.cellPadding * 2,
    columns.fold(0.0, (sum, width) => sum + width + config.cellPadding * 2),
  );
  final rowHeight = _erRowHeight(entity, context);
  return Size(width, rowHeight * (entity.attributes.length + 1));
}

List<SceneElement> _erEntityElements(
  ErEntityAst entity,
  Bounds bounds,
  Map<String, Map<String, String>> definitions,
  _LayoutContext context,
  ErRenderOptions config,
) {
  final paint = _graphNodePaint(entity.cssClasses, entity.styles, definitions, context, _graphRoughStrokeWidth);
  final rowHeight = _erRowHeight(entity, context);
  final typeWidth = _maxGraphTextWidth(entity.attributes.map((attribute) => attribute.type), context);
  final typeDividerX = bounds.left + config.cellPadding * 2 + typeWidth;
  final nameWidth = _maxGraphTextWidth(entity.attributes.map((attribute) => attribute.name), context);
  final keyDividerX = typeDividerX + config.cellPadding * 2 + nameWidth;
  final elements = <SceneElement>[
    SceneRect(
      id: context.id('er-entity'),
      bounds: bounds,
      radiusX: 3,
      radiusY: 3,
      fill: SolidFill(paint.fill),
      stroke: paint.stroke,
      role: SemanticRole.node,
      cssClasses: ['er-entity', ...entity.cssClasses],
      label: entity.label,
    ),
    for (var index = 0; index < entity.attributes.length; index++)
      SceneRect(
        id: context.id('er-attribute-row'),
        bounds: Bounds(
          left: bounds.left,
          top: bounds.top + rowHeight * (index + 1),
          width: bounds.width,
          height: rowHeight,
        ),
        fill: SolidFill(index.isEven ? _erOddRowFill : _erEvenRowFill),
        stroke: paint.stroke,
        cssClasses: ['er-attribute-row', index.isEven ? 'er-row-odd' : 'er-row-even'],
      ),
    _text(
      context,
      entity.label,
      bounds.center.x,
      bounds.top + rowHeight / 2,
      anchor: TextAnchor.middle,
      cssClasses: const ['er-entity-title'],
    ),
    SceneLine(
      id: context.id('er-attribute-divider'),
      start: Point(bounds.left, bounds.top + rowHeight),
      end: Point(bounds.right, bounds.top + rowHeight),
      stroke: paint.stroke,
      cssClasses: const ['er-attribute-divider'],
    ),
  ];
  if (entity.attributes.isNotEmpty) {
    elements
      ..add(
        SceneLine(
          id: context.id('er-type-divider'),
          start: Point(typeDividerX, bounds.top + rowHeight),
          end: Point(typeDividerX, bounds.bottom),
          stroke: paint.stroke,
          cssClasses: const ['er-column-divider', 'er-type-divider'],
        ),
      )
      ..add(
        SceneLine(
          id: context.id('er-key-divider'),
          start: Point(keyDividerX, bounds.top + rowHeight),
          end: Point(keyDividerX, bounds.bottom),
          stroke: paint.stroke,
          cssClasses: const ['er-column-divider', 'er-key-divider'],
        ),
      );
  }
  for (var index = 0; index < entity.attributes.length; index++) {
    final attribute = entity.attributes[index];
    final y = bounds.top + rowHeight * (index + 1.5);
    final typeSize = context.measurer.measure(attribute.type, context.textStyle);
    final nameSize = context.measurer.measure(attribute.name, context.textStyle);
    elements
      ..add(
        _text(
          context,
          attribute.type,
          bounds.left + config.cellPadding + typeSize.width / 2,
          y,
          anchor: TextAnchor.middle,
          cssClasses: const ['er-attribute-type'],
        ),
      )
      ..add(
        _text(
          context,
          attribute.name,
          typeDividerX + config.cellPadding + nameSize.width / 2,
          y,
          anchor: TextAnchor.middle,
          cssClasses: const ['er-attribute-name'],
        ),
      );
    final keys = _erKeys(attribute.keys);
    if (keys.isNotEmpty) {
      final keySize = context.measurer.measure(keys, context.textStyle);
      elements.add(
        _text(
          context,
          keys,
          keyDividerX + config.cellPadding + keySize.width / 2,
          y,
          anchor: TextAnchor.middle,
          cssClasses: const ['er-attribute-key'],
        ),
      );
    }
    if (attribute.comment case final comment?) {
      elements.add(
        _text(context, comment, bounds.right + config.cellPadding, y, cssClasses: const ['er-attribute-comment']),
      );
    }
  }
  return elements;
}

String _erKeys(Set<ErAttributeKey> keys) => [
  if (keys.contains(ErAttributeKey.primary)) 'PK',
  if (keys.contains(ErAttributeKey.foreign)) 'FK',
  if (keys.contains(ErAttributeKey.unique)) 'UK',
].join(',');

List<SceneElement> _erRelationshipElements(
  ErRelationshipAst relationship,
  Bounds from,
  Bounds to,
  _LayoutContext context,
  ErRenderOptions config,
) {
  final points = _graphEdgePoints(from, to);
  final color = context.options.theme.line;
  final center = Point((points.start.x + points.end.x) / 2, (points.start.y + points.end.y) / 2);
  final elements = <SceneElement>[
    ScenePath(
      id: context.id('er-relationship'),
      commands: _graphEdgePath(points.start, points.end),
      fill: const NoFill(),
      stroke: _graphStroke(color, config.edgeWidth, dotted: !relationship.identifying),
      cssClasses: const ['er-relationship'],
      role: SemanticRole.edge,
      label: relationship.label,
    ),
    ..._erCardinalityElements(relationship.fromCardinality, points.start, points.end, context, color),
    ..._erCardinalityElements(relationship.toCardinality, points.end, points.start, context, color),
    _graphLabelBackground(context, relationship.label, center, cssClass: 'er-relationship-label-background'),
    _text(
      context,
      relationship.label,
      center.x,
      center.y,
      anchor: TextAnchor.middle,
      style: SceneTextStyle(fontFamily: context.textStyle.fontFamily, fontSize: 14, color: const Color(0, 0, 0)),
      cssClasses: const ['er-relationship-label'],
    ),
  ];
  return elements;
}

List<SceneElement> _erCardinalityElements(
  ErCardinality cardinality,
  Point endpoint,
  Point opposite,
  _LayoutContext context,
  Color color,
) {
  final direction = Direction.between(endpoint, opposite);
  Point at(double along, [double across = 0]) => direction.from(endpoint, along, across);
  SceneLine bar(double depth) {
    final center = at(depth);
    return SceneLine(
      id: context.id('er-cardinality-bar'),
      start: direction.from(center, 0, _erMarkerHalfWidth),
      end: direction.from(center, 0, -_erMarkerHalfWidth),
      stroke: _graphStroke(color, 1),
      cssClasses: const ['er-cardinality', 'er-cardinality-bar'],
    );
  }

  SceneCircle circle(double depth) => SceneCircle(
    id: context.id('er-cardinality-circle'),
    center: at(depth),
    radius: _erMarkerCircleRadius,
    fill: const SolidFill(Color(255, 255, 255)),
    stroke: _graphStroke(color, 1),
    cssClasses: const ['er-cardinality', 'er-cardinality-circle'],
  );

  ScenePath crowFoot() => ScenePath(
    id: context.id('er-cardinality-crow'),
    commands: [
      MoveTo(at(_erMarkerCrowDepth)),
      QuadraticTo(at(0, -_erMarkerCrowDepth), at(-_erMarkerCrowDepth)),
      QuadraticTo(at(0, _erMarkerCrowDepth), at(_erMarkerCrowDepth)),
    ],
    fill: const NoFill(),
    stroke: _graphStroke(color, 1),
    cssClasses: const ['er-cardinality', 'er-cardinality-crow-foot'],
  );

  return switch (cardinality) {
    ErCardinality.exactlyOne => [bar(_erMarkerBarNear), bar(_erMarkerBarFar)],
    ErCardinality.zeroOrOne => [circle(_erMarkerCircleDepth), bar(_erMarkerBarNear)],
    ErCardinality.zeroOrMore => [circle(_erMarkerCrowCircleDepth), crowFoot()],
    ErCardinality.oneOrMore => [bar(_erMarkerCrowBarDepth), crowFoot()],
    ErCardinality.parent => [
      _graphArrow(context, tip: endpoint, tail: opposite, color: color, cssClass: 'er-cardinality'),
    ],
  };
}

double _erRowHeight(ErEntityAst entity, _LayoutContext context) =>
    context.measurer.measure(entity.label, context.textStyle).height + _erVerticalCellPadding * 2;
