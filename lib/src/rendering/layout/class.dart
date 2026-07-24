part of '../layout.dart';

// Mermaid.js classBox uses its configured padding as both outer padding and
// the gap between compartments.
const _classMarkerLength = 12.0;
const _classExtensionMarkerLength = 17.0;
const _classMarkerHalfWidth = 6.0;
const _classNotePadding = 6.0;
const _classMarkerPathOffset = 17.25;
const _classCardinalityFontSize = 11.0;
const _classStartCardinalityAlong = 17.5;
const _classStartCardinalityAcross = 15.0;
const _classEndCardinalityAlong = 25.890625;
const _classEndCardinalityAcross = 0.75;
const _classPrimaryText = Color(19, 19, 0);
const _classNoteText = Color(0, 0, 0);
const _classNoteFill = Color(255, 245, 173);
const _classNoteBorder = Color(170, 170, 51);

_LayoutResult _layoutClassDiagram(ClassDiagramAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const ClassRenderOptions());
  final nodeMetrics = {for (final node in ast.classes) node.id: _classNodeMetrics(node, context, config)};
  final noteIds = <ClassNoteAst, String>{for (final (index, note) in ast.notes.indexed) note: '__class_note_$index'};
  final sizes = <String, Size>{
    for (final entry in nodeMetrics.entries) entry.key: entry.value.size,
    for (final note in ast.notes) noteIds[note]!: _classNoteSize(note, context),
  };
  final edges = <_GraphEdgeLayout>[
    for (final relation in ast.relations) _GraphEdgeLayout(relation.from, relation.to, relation.label),
    for (final note in ast.notes)
      if (note.classId case final classId?) _GraphEdgeLayout(noteIds[note]!, classId, null),
  ];
  final graph = _layoutGraphBoxes(
    ids: [...ast.notes.map((note) => noteIds[note]!), ...ast.classes.map((node) => node.id)],
    sizes: sizes,
    edges: edges,
    direction: ast.direction,
    nodeSpacing: config.nodeSpacing,
    rankSpacing: config.rankSpacing,
    padding: config.diagramPadding,
    context: context,
  );
  _alignClassRanks(ast, noteIds, graph, config.diagramPadding);
  final elements = <SceneElement>[];
  for (final relation in ast.relations) {
    final from = graph.positions[relation.from];
    final to = graph.positions[relation.to];
    if (from == null || to == null) continue;
    elements.addAll(_classRelationElements(relation, from, to, context, config));
  }
  for (final namespace in ast.namespaces) {
    final memberBounds = namespace.classIds.map((id) => graph.positions[id]).whereType<Bounds>().toList();
    if (memberBounds.isEmpty) continue;
    var bounds = memberBounds.first;
    for (final member in memberBounds.skip(1)) {
      bounds = bounds.union(member);
    }
    final namespaceBounds = bounds.expand(config.nodePadding);
    elements.add(
      SceneRect(
        id: context.id('class-namespace'),
        bounds: namespaceBounds,
        fill: const SolidFill(Color(255, 255, 255, 0)),
        stroke: _graphStroke(context.options.theme.tertiaryBorder, config.edgeWidth),
        role: SemanticRole.group,
        cssClasses: const ['class-namespace'],
        label: namespace.label,
      ),
    );
    elements.add(
      _text(
        context,
        namespace.label,
        namespaceBounds.left + config.nodePadding,
        namespaceBounds.top + config.compartmentPadding,
        cssClasses: const ['class-namespace-label'],
      ),
    );
  }
  for (final node in ast.classes) {
    final bounds = graph.positions[node.id];
    if (bounds == null) continue;
    elements.addAll(_classNodeElements(node, bounds, nodeMetrics[node.id]!, ast.classDefinitions, context, config));
  }
  for (final note in ast.notes) {
    final bounds = graph.positions[noteIds[note]];
    if (bounds == null) continue;
    if (note.classId case final classId?) {
      final attached = graph.positions[classId];
      if (attached != null) {
        final route = _classEdgeRoute(
          bounds,
          attached,
          primaryMiddle: _classRankMiddle(graph.positions.values, attached),
        );
        elements.add(
          ScenePath(
            id: context.id('class-note-edge'),
            commands: _graphBasisPath([route.start, route.middle, route.end]),
            fill: const NoFill(),
            stroke: SceneStroke(color: context.options.theme.line, width: config.edgeWidth, dashes: const [2]),
            role: SemanticRole.edge,
            cssClasses: const ['class-note-edge'],
          ),
        );
      }
    }
    elements.addAll(_classNoteElements(note, bounds, context));
  }
  return _LayoutResult(
    graph.width,
    graph.height,
    elements,
    bounds: Bounds(left: 0, top: 0, width: graph.width, height: graph.height),
  );
}

_ClassNodeMetrics _classNodeMetrics(ClassAst node, _LayoutContext context, ClassRenderOptions config) {
  final header = [
    ...node.annotations.map((value) => _ClassTextMetric('«$value»', context)),
    _ClassTextMetric(node.label, context),
  ];
  final attributes = [
    for (final member in node.members)
      if (member.kind == ClassMemberKind.attribute) _ClassTextMetric(member.text, context),
  ];
  final methods = [
    for (final member in node.members)
      if (member.kind == ClassMemberKind.method) _ClassTextMetric(member.text, context),
  ];
  final centeredWidth = header.fold(0.0, (width, row) => math.max(width, row.size.width));
  final leftAlignedWidth = [...attributes, ...methods].fold(0.0, (width, row) => math.max(width, row.size.width));
  final contentWidth = math.max(centeredWidth / 2, leftAlignedWidth) + centeredWidth / 2;
  final headerHeight = header.fold(0.0, (height, row) => height + row.size.height);
  final attributesHeight = attributes.fold(0.0, (height, row) => height + row.size.height);
  final methodsHeight = methods.fold(0.0, (height, row) => height + row.size.height);
  final gap = config.nodePadding;
  final memberGroupHeight = attributes.isEmpty ? gap / 2 : attributesHeight;
  final memberTop = headerHeight + gap * 2;
  final methodTop = headerHeight + memberGroupHeight + gap * 4;
  final contentHeight = switch ((attributes.isEmpty, methods.isEmpty)) {
    (true, true) => headerHeight + gap,
    (false, true) => memberTop + attributesHeight + gap * 2,
    (_, false) => methodTop + methodsHeight,
  };
  return _ClassNodeMetrics(
    size: Size(contentWidth + config.nodePadding * 2, contentHeight + config.nodePadding * 2),
    header: header,
    attributes: attributes,
    methods: methods,
    headerHeight: headerHeight,
    attributesHeight: attributesHeight,
    memberTop: memberTop,
    methodTop: methodTop,
  );
}

List<SceneElement> _classNodeElements(
  ClassAst node,
  Bounds bounds,
  _ClassNodeMetrics metrics,
  Map<String, Map<String, String>> definitions,
  _LayoutContext context,
  ClassRenderOptions config,
) {
  final paint = _graphNodePaint(node.cssClasses, node.styles, definitions, context, _graphRoughStrokeWidth);
  final elements = <SceneElement>[
    SceneRect(
      id: context.id('class-node'),
      bounds: bounds,
      fill: SolidFill(paint.fill),
      stroke: paint.stroke,
      role: SemanticRole.node,
      cssClasses: ['class-node', ...node.cssClasses],
      label: node.label,
    ),
  ];
  var top = bounds.top + config.nodePadding;
  for (final (index, row) in metrics.header.indexed) {
    elements.add(
      _text(
        context,
        row.text,
        bounds.center.x,
        top + row.size.height / 2,
        anchor: TextAnchor.middle,
        style: _classTextStyle(
          context,
          weight: index == metrics.header.length - 1 ? FontWeight.bold : FontWeight.normal,
        ),
        cssClasses: index == metrics.header.length - 1 ? const ['class-title'] : const ['class-annotation'],
      ),
    );
    top += row.size.height;
  }
  if (metrics.attributes.isNotEmpty || metrics.methods.isNotEmpty) {
    final firstDivider = bounds.top + config.nodePadding + metrics.headerHeight + config.nodePadding;
    elements
      ..add(_classDivider(context, bounds, firstDivider, paint.stroke))
      ..add(
        _classDivider(
          context,
          bounds,
          firstDivider +
              (metrics.attributes.isEmpty ? config.nodePadding * 2 : metrics.attributesHeight + config.nodePadding * 2),
          paint.stroke,
        ),
      );
  }
  top = bounds.top + config.nodePadding + metrics.memberTop;
  for (final row in metrics.attributes) {
    elements.add(
      _text(
        context,
        row.text,
        bounds.left + config.nodePadding + row.size.width / 2,
        top + row.size.height / 2,
        anchor: TextAnchor.middle,
        style: _classTextStyle(context),
        cssClasses: const ['class-attribute'],
      ),
    );
    top += row.size.height;
  }
  top = bounds.top + config.nodePadding + metrics.methodTop;
  for (final row in metrics.methods) {
    elements.add(
      _text(
        context,
        row.text,
        bounds.left + config.nodePadding + row.size.width / 2,
        top + row.size.height / 2,
        anchor: TextAnchor.middle,
        style: _classTextStyle(context),
        cssClasses: const ['class-method'],
      ),
    );
    top += row.size.height;
  }
  return elements;
}

SceneLine _classDivider(_LayoutContext context, Bounds bounds, double y, SceneStroke stroke) => SceneLine(
  id: context.id('class-divider'),
  start: Point(bounds.left, y),
  end: Point(bounds.right, y),
  stroke: stroke,
  cssClasses: const ['class-compartment-divider'],
);

List<SceneElement> _classRelationElements(
  ClassRelationAst relation,
  Bounds fromBounds,
  Bounds toBounds,
  _LayoutContext context,
  ClassRenderOptions config,
) {
  final route = _classEdgeRoute(fromBounds, toBounds);
  final pathStart = relation.startMarker == ClassRelationMarker.none
      ? route.start
      : pointToward(route.start, route.middle, _classMarkerPathOffset);
  final color = context.options.theme.line;
  final elements = <SceneElement>[
    ScenePath(
      id: context.id('class-relation'),
      commands: _graphBasisPath([pathStart, route.middle, route.end]),
      fill: const NoFill(),
      stroke: _graphStroke(color, config.edgeWidth, dotted: relation.line == ClassRelationLine.dotted),
      role: SemanticRole.edge,
      cssClasses: const ['class-relation'],
      label: relation.label,
    ),
  ];
  elements.addAll(_classEndpointMarker(relation.startMarker, route.start, route.middle, context, color));
  elements.addAll(_classEndpointMarker(relation.endMarker, route.end, route.middle, context, color));
  if (relation.label case final label?) {
    final center = route.middle;
    elements.add(
      _graphLabelBackground(
        context,
        label,
        center,
        cssClass: 'class-relation-label-background',
        color: context.options.theme.primary,
      ),
    );
    elements.add(
      _text(
        context,
        label,
        center.x,
        center.y,
        anchor: TextAnchor.middle,
        style: _classTextStyle(context),
        cssClasses: const ['class-relation-label'],
      ),
    );
  }
  if (relation.fromCardinality case final cardinality?) {
    elements.add(
      _classCardinality(context, cardinality, route.start, route.middle, route.end, const [
        'class-cardinality',
        'class-cardinality-start',
      ], source: true),
    );
  }
  if (relation.toCardinality case final cardinality?) {
    elements.add(
      _classCardinality(context, cardinality, route.start, route.middle, route.end, const [
        'class-cardinality',
        'class-cardinality-end',
      ], source: false),
    );
  }
  return elements;
}

List<SceneElement> _classEndpointMarker(
  ClassRelationMarker marker,
  Point endpoint,
  Point opposite,
  _LayoutContext context,
  Color color,
) {
  if (marker == ClassRelationMarker.none) return const [];
  final frame = _classMarkerFrame(
    endpoint,
    opposite,
    length: marker == ClassRelationMarker.extension ? _classExtensionMarkerLength : _classMarkerLength,
  );
  final stroke = _graphStroke(color, 1);
  return switch (marker) {
    ClassRelationMarker.extension => [
      ScenePolygon(
        id: context.id('class-extension'),
        points: [endpoint, frame.left, frame.right],
        fill: const NoFill(),
        stroke: stroke,
        cssClasses: const ['class-extension-marker'],
      ),
    ],
    ClassRelationMarker.composition || ClassRelationMarker.aggregation => [
      ScenePolygon(
        id: context.id('class-diamond'),
        points: [endpoint, frame.left, frame.back, frame.right],
        fill: marker == ClassRelationMarker.composition ? SolidFill(color) : const NoFill(),
        stroke: stroke,
        cssClasses: [
          marker == ClassRelationMarker.composition ? 'class-composition-marker' : 'class-aggregation-marker',
        ],
      ),
    ],
    ClassRelationMarker.dependency => [
      _graphArrow(context, tip: endpoint, tail: opposite, color: color, cssClass: 'class-dependency-marker'),
    ],
    ClassRelationMarker.lollipop => [
      SceneCircle(
        id: context.id('class-lollipop'),
        center: frame.middle,
        radius: _classMarkerHalfWidth,
        fill: const NoFill(),
        stroke: stroke,
        cssClasses: const ['class-lollipop-marker'],
      ),
    ],
    ClassRelationMarker.none => const [],
  };
}

({Point left, Point right, Point back, Point middle}) _classMarkerFrame(
  Point endpoint,
  Point opposite, {
  required double length,
}) {
  final direction = Direction.between(endpoint, opposite);
  final middle = direction.from(endpoint, length);
  return (
    left: direction.from(middle, 0, _classMarkerHalfWidth),
    right: direction.from(middle, 0, -_classMarkerHalfWidth),
    back: direction.from(endpoint, length * 2),
    middle: middle,
  );
}

SceneText _classCardinality(
  _LayoutContext context,
  String value,
  Point start,
  Point middle,
  Point end,
  List<String> cssClasses, {
  required bool source,
}) {
  final direction = Direction.between(start, middle);
  final position = source
      ? direction.from(start, _classStartCardinalityAlong, _classStartCardinalityAcross)
      : direction.from(end, -_classEndCardinalityAlong, _classEndCardinalityAcross);
  return _text(
    context,
    value,
    position.x,
    position.y,
    anchor: TextAnchor.middle,
    style: SceneTextStyle(
      fontFamily: context.textStyle.fontFamily,
      fontSize: _classCardinalityFontSize,
      color: _classPrimaryText,
    ),
    cssClasses: cssClasses,
  );
}

Size _classNoteSize(ClassNoteAst note, _LayoutContext context) {
  final measured = context.measurer.measure(note.text, context.textStyle);
  return Size(measured.width + _classNotePadding * 2, measured.height + _classNotePadding * 2);
}

List<SceneElement> _classNoteElements(ClassNoteAst note, Bounds bounds, _LayoutContext context) {
  return [
    SceneRect(
      id: context.id('class-note'),
      bounds: bounds,
      fill: const SolidFill(_classNoteFill),
      stroke: _graphStroke(_classNoteBorder, 1),
      role: SemanticRole.annotation,
      cssClasses: const ['class-note'],
      label: note.text,
    ),
    _text(
      context,
      note.text,
      bounds.center.x,
      bounds.center.y,
      anchor: TextAnchor.middle,
      style: _classTextStyle(context, color: _classNoteText),
      cssClasses: const ['class-note-text'],
    ),
  ];
}

final class _ClassTextMetric {
  _ClassTextMetric(this.text, _LayoutContext context) : size = context.measurer.measure(text, context.textStyle);

  final String text;
  final Size size;
}

final class _ClassNodeMetrics {
  const _ClassNodeMetrics({
    required this.size,
    required this.header,
    required this.attributes,
    required this.methods,
    required this.headerHeight,
    required this.attributesHeight,
    required this.memberTop,
    required this.methodTop,
  });

  final Size size;
  final List<_ClassTextMetric> header;
  final List<_ClassTextMetric> attributes;
  final List<_ClassTextMetric> methods;
  final double headerHeight;
  final double attributesHeight;
  final double memberTop;
  final double methodTop;
}

SceneTextStyle _classTextStyle(
  _LayoutContext context, {
  FontWeight weight = FontWeight.normal,
  Color color = _classPrimaryText,
}) => SceneTextStyle(
  fontFamily: context.textStyle.fontFamily,
  fontSize: context.textStyle.fontSize,
  weight: weight,
  color: color,
  lineHeight: context.textStyle.lineHeight,
);

void _alignClassRanks(
  ClassDiagramAst ast,
  Map<ClassNoteAst, String> noteIds,
  _FlowchartGraphLayout graph,
  double padding,
) {
  if (!ast.direction.isHorizontal) return;
  for (final node in ast.classes) {
    final predecessors = <Bounds>[
      for (final relation in ast.relations)
        if (relation.to == node.id) ?graph.positions[relation.from],
      for (final note in ast.notes)
        if (note.classId == node.id) ?graph.positions[noteIds[note]],
    ];
    if (predecessors.isEmpty) continue;
    final bounds = graph.positions[node.id]!;
    final centerY = predecessors.fold(0.0, (sum, predecessor) => sum + predecessor.center.y) / predecessors.length;
    final top = (centerY - bounds.height / 2).clamp(padding, graph.height - padding - bounds.height);
    graph.positions[node.id] = Bounds(left: bounds.left, top: top, width: bounds.width, height: bounds.height);
  }
}

({Point start, Point middle, Point end}) _classEdgeRoute(Bounds from, Bounds to, {double? primaryMiddle}) {
  final horizontal = (to.center.x - from.center.x).abs() >= (to.center.y - from.center.y).abs();
  if (horizontal) {
    final forward = to.center.x >= from.center.x;
    final start = Point(forward ? from.right : from.left, from.center.y);
    final middle = Point(
      primaryMiddle ?? ((forward ? from.right : from.left) + (forward ? to.left : to.right)) / 2,
      start.y,
    );
    final end = _graphEdgePoints(Bounds(left: middle.x, top: middle.y, width: 0, height: 0), to).end;
    return (start: start, middle: middle, end: end);
  }
  final forward = to.center.y >= from.center.y;
  final start = Point(from.center.x, forward ? from.bottom : from.top);
  final middle = Point(start.x, ((forward ? from.bottom : from.top) + (forward ? to.top : to.bottom)) / 2);
  final end = _graphEdgePoints(Bounds(left: middle.x, top: middle.y, width: 0, height: 0), to).end;
  return (start: start, middle: middle, end: end);
}

double _classRankMiddle(Iterable<Bounds> positions, Bounds target) {
  final precedingRight = positions
      .where((bounds) => bounds.right < target.left)
      .map((bounds) => bounds.right)
      .fold(double.negativeInfinity, math.max);
  return precedingRight.isFinite ? (precedingRight + target.left) / 2 : target.left;
}
