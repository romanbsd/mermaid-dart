part of '../layout.dart';

// Mermaid Flowchart reserves a 50-unit title band above unchanged graph
// coordinates and positions its 18px title baseline at y=-25.
const _flowchartTitleBandHeight = 50.0;
const _flowchartTitleY = -25.0;
const _flowchartTitleFontSize = 18.0;
// Mermaid flowchart nodes use label-driven dimensions with a practical minimum
// matching the Dagre renderer's compact simple-node geometry.
const _flowchartMinimumNodeWidth = 80.0;
const _flowchartMinimumNodeHeight = 50.0;
const _flowchartRoundedRadius = 5.0;
const _flowchartStadiumRadius = 25.0;
const _flowchartArrowLength = 10.0;
const _flowchartArrowHalfWidth = 5.0;
// Mermaid's point marker reference shortens the painted edge by four scene
// units while leaving the marker tip on the node boundary.
const _flowchartPointMarkerOffset = 4.0;
// Mermaid's classic polygon renderer applies a half-pixel horizontal alignment
// to diamond points for crisp one-pixel strokes.
const _flowchartDiamondHorizontalOffset = .5;
// Dagre reserves 35 horizontal and 37.5 vertical scene units around compound
// flowchart nodes in Mermaid.js.
const _flowchartSubgraphHorizontalPadding = 35.0;
const _flowchartSubgraphVerticalPadding = 37.5;
const _flowchartSubgraphTitleOffset = 12.0;
// Compound ranks receive additional clearance for the cluster boundary.
const _flowchartSubgraphRankSpacingAdjustment = 25.0;
const _flowchartCylinderHeightOverlap = .625;
// Mermaid's stadium path adds 24.73 units around a 15-unit node padding.
const _flowchartStadiumPaddingRatio = 1.648656;

final class _FlowchartNodeLayout {
  const _FlowchartNodeLayout(this.node, this.bounds);

  final FlowchartNodeAst node;
  final Bounds bounds;
}

final class _FlowchartRankEdge {
  const _FlowchartRankEdge(this.from, this.to, this.length, [this.label]);

  final String from;
  final String to;
  final int length;
  final String? label;
}

final class _FlowchartGraphLayout {
  const _FlowchartGraphLayout(this.positions, this.width, this.height);

  final Map<String, Bounds> positions;
  final double width;
  final double height;
}

_LayoutResult _layoutFlowchart(FlowchartAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const FlowchartRenderOptions());
  final nodeSizes = {for (final node in ast.nodes) node.id: _flowchartNodeSize(node, context, config)};

  final nodeIds = {for (final node in ast.nodes) node.id};
  final subgraphByNode = <String, FlowchartSubgraphAst>{};
  for (final subgraph in ast.subgraphs.reversed) {
    for (final nodeId in subgraph.nodeIds) {
      subgraphByNode.putIfAbsent(nodeId, () => subgraph);
    }
  }

  String itemIdForNode(String nodeId) {
    final subgraph = subgraphByNode[nodeId];
    return subgraph == null ? nodeId : _flowchartSubgraphItemId(subgraph);
  }

  final localLayouts = <String, _FlowchartGraphLayout>{};
  final itemSizes = <String, Size>{};
  final itemIds = <String>[];
  final addedSubgraphs = <String>{};
  for (final node in ast.nodes) {
    final subgraph = subgraphByNode[node.id];
    if (subgraph == null) {
      itemIds.add(node.id);
      itemSizes[node.id] = nodeSizes[node.id]!;
      continue;
    }
    if (!addedSubgraphs.add(subgraph.id)) continue;

    final memberIds = subgraph.nodeIds.where(nodeIds.contains).toList();
    final memberSet = memberIds.toSet();
    final local = _layoutFlowchartGraph(
      memberIds,
      {for (final id in memberIds) id: nodeSizes[id]!},
      [
        for (final edge in ast.edges)
          if (memberSet.contains(edge.from) && memberSet.contains(edge.to))
            _FlowchartRankEdge(edge.from, edge.to, edge.length, edge.label),
      ],
      subgraph.direction ?? ast.direction,
      config,
      context,
      rankSpacingAdjustment: _flowchartSubgraphRankSpacingAdjustment,
    );
    final itemId = _flowchartSubgraphItemId(subgraph);
    localLayouts[subgraph.id] = local;
    itemIds.add(itemId);
    itemSizes[itemId] = Size(
      local.width + _flowchartSubgraphHorizontalPadding * 2,
      local.height + _flowchartSubgraphVerticalPadding * 2,
    );
  }

  final outerEdges = <_FlowchartRankEdge>[];
  for (final edge in ast.edges) {
    final from = itemIdForNode(edge.from);
    final to = itemIdForNode(edge.to);
    if (from != to) outerEdges.add(_FlowchartRankEdge(from, to, edge.length, edge.label));
  }
  final outer = _layoutFlowchartGraph(
    itemIds,
    itemSizes,
    outerEdges,
    ast.direction,
    config,
    context,
    padding: config.diagramPadding,
  );

  final positions = <String, _FlowchartNodeLayout>{};
  for (final node in ast.nodes) {
    final subgraph = subgraphByNode[node.id];
    if (subgraph == null) {
      positions[node.id] = _FlowchartNodeLayout(node, outer.positions[node.id]!);
      continue;
    }
    final subgraphBounds = outer.positions[_flowchartSubgraphItemId(subgraph)]!;
    positions[node.id] = _FlowchartNodeLayout(
      node,
      localLayouts[subgraph.id]!.positions[node.id]!.translated(
        subgraphBounds.left + _flowchartSubgraphHorizontalPadding,
        subgraphBounds.top + _flowchartSubgraphVerticalPadding,
      ),
    );
  }

  final elements = <SceneElement>[];
  for (final subgraph in ast.subgraphs) {
    final bounds = outer.positions[_flowchartSubgraphItemId(subgraph)];
    if (bounds == null) continue;
    elements
      ..add(
        SceneRect(
          id: context.id('flowchart-subgraph'),
          bounds: bounds,
          fill: SolidFill(context.options.theme.secondary),
          stroke: SceneStroke(color: context.options.theme.secondaryBorder),
          role: SemanticRole.group,
          cssClasses: const ['flowchart-subgraph'],
          label: subgraph.title,
        ),
      )
      ..add(
        _text(
          context,
          subgraph.title,
          bounds.center.x,
          bounds.top + _flowchartSubgraphTitleOffset,
          anchor: TextAnchor.middle,
          role: SemanticRole.title,
          cssClasses: const ['flowchart-subgraph-title'],
        ),
      );
  }

  for (final edge in ast.edges) {
    final from = positions[edge.from];
    final to = positions[edge.to];
    if (from == null || to == null) continue;
    final fromSubgraph = subgraphByNode[edge.from];
    final toSubgraph = subgraphByNode[edge.to];
    final internal = fromSubgraph != null && fromSubgraph == toSubgraph;
    final direction = internal ? fromSubgraph.direction ?? ast.direction : ast.direction;
    final fromBounds = _flowchartEndpointBounds(from.bounds, fromSubgraph, internal, outer.positions);
    final toBounds = _flowchartEndpointBounds(to.bounds, toSubgraph, internal, outer.positions);
    elements.addAll(_flowchartEdgeElements(edge, fromBounds, toBounds, direction, context, config));
  }
  for (final layout in positions.values) {
    elements.addAll(_flowchartNodeElements(layout, ast.classDefinitions, context, config));
  }
  if (ast.title == null) return _LayoutResult(outer.width, outer.height, elements);
  elements.add(
    _text(
      context,
      ast.title!,
      outer.width / 2,
      _flowchartTitleY,
      anchor: TextAnchor.middle,
      baseline: TextBaseline.alphabetic,
      role: SemanticRole.title,
      style: SceneTextStyle(
        fontFamily: context.textStyle.fontFamily,
        fontSize: _flowchartTitleFontSize,
        color: context.textStyle.color,
      ),
      cssClasses: const ['flowchart-title'],
    ),
  );
  return _LayoutResult(
    outer.width,
    outer.height + _flowchartTitleBandHeight,
    elements,
    bounds: Bounds(
      left: 0,
      top: -_flowchartTitleBandHeight,
      width: outer.width,
      height: outer.height + _flowchartTitleBandHeight,
    ),
  );
}

Size _flowchartNodeSize(FlowchartNodeAst node, _LayoutContext context, FlowchartRenderOptions config) {
  final measured = context.measurer.measure(node.label, context.textStyle);
  final baseWidth = math.max(_flowchartMinimumNodeWidth, measured.width + config.nodePadding * 2);
  final baseHeight = math.max(_flowchartMinimumNodeHeight, measured.height + config.nodePadding * 2);
  return switch (node.shape) {
    FlowchartNodeShape.rectangle => Size(
      math.max(_flowchartMinimumNodeWidth, measured.width + config.nodePadding * 4),
      baseHeight,
    ),
    FlowchartNodeShape.diamond => _flowchartSquareSize(
      math.max(_flowchartMinimumNodeHeight, measured.width + config.nodePadding * 3.6),
    ),
    FlowchartNodeShape.circle || FlowchartNodeShape.doubleCircle => _flowchartSquareSize(
      math.max(measured.width, measured.height) + config.nodePadding,
    ),
    FlowchartNodeShape.stadium => Size(
      measured.width + config.nodePadding * _flowchartStadiumPaddingRatio,
      measured.height + config.nodePadding,
    ),
    FlowchartNodeShape.cylinder => Size(
      math.max(_flowchartMinimumNodeWidth, measured.width + config.nodePadding),
      baseHeight + config.nodePadding - _flowchartCylinderHeightOverlap,
    ),
    _ => Size(baseWidth, baseHeight),
  };
}

String _flowchartSubgraphItemId(FlowchartSubgraphAst subgraph) => '@subgraph:${subgraph.id}';

Bounds _flowchartEndpointBounds(
  Bounds nodeBounds,
  FlowchartSubgraphAst? subgraph,
  bool internal,
  Map<String, Bounds> itemPositions,
) => !internal && subgraph != null ? itemPositions[_flowchartSubgraphItemId(subgraph)]! : nodeBounds;

Size _flowchartSquareSize(double extent) => Size(extent, extent);

_FlowchartGraphLayout _layoutFlowchartGraph(
  List<String> ids,
  Map<String, Size> sizes,
  List<_FlowchartRankEdge> edges,
  FlowchartDirection direction,
  FlowchartRenderOptions config,
  _LayoutContext context, {
  double padding = 0,
  double rankSpacingAdjustment = 0,
}) {
  final ranks = {for (final id in ids) id: 0};
  // Bellman-Ford-style relaxation gives deterministic longest-path ranks while
  // the pass limit prevents cycles from causing unbounded growth.
  for (var pass = 0; pass < math.max(0, ids.length - 1); pass++) {
    var changed = false;
    for (final edge in edges) {
      final from = ranks[edge.from];
      final to = ranks[edge.to];
      if (from == null || to == null) continue;
      final candidate = from + edge.length;
      if (candidate > to) {
        ranks[edge.to] = candidate;
        changed = true;
      }
    }
    if (!changed) break;
  }

  final byRank = <int, List<String>>{};
  for (final id in ids) {
    (byRank[ranks[id] ?? 0] ??= []).add(id);
  }
  final horizontal = direction.isHorizontal;
  final orderedRanks = byRank.keys.toList()..sort();
  final rankPrimarySizes = <int, double>{};
  final rankSecondarySizes = <int, double>{};
  final labeledEdgeGaps = <int, double>{};
  for (final edge in edges) {
    if (edge.label case final label? when label.isNotEmpty) {
      final rank = ranks[edge.from];
      if (rank == null) continue;
      final labelSize = context.measurer.measure(label, context.textStyle);
      final labelExtent = horizontal ? labelSize.width : labelSize.height;
      labeledEdgeGaps[rank] = math.max(labeledEdgeGaps[rank] ?? 0, labelExtent);
    }
  }
  for (final rank in orderedRanks) {
    final rankIds = byRank[rank]!;
    rankPrimarySizes[rank] = rankIds.map((id) => horizontal ? sizes[id]!.width : sizes[id]!.height).fold(0, math.max);
    rankSecondarySizes[rank] =
        rankIds.map((id) => horizontal ? sizes[id]!.height : sizes[id]!.width).fold(0.0, (sum, size) => sum + size) +
        math.max(0, rankIds.length - 1) * config.nodeSpacing;
  }

  final positions = <String, Bounds>{};
  var primary = padding;
  final maxSecondary = rankSecondarySizes.values.fold(0.0, math.max);
  for (final rank in orderedRanks) {
    final rankIds = byRank[rank]!;
    var secondary = padding + (maxSecondary - rankSecondarySizes[rank]!) / 2;
    final rankPrimary = rankPrimarySizes[rank]!;
    for (final id in rankIds) {
      final size = sizes[id]!;
      positions[id] = horizontal
          ? Bounds(
              left: primary + (rankPrimary - size.width) / 2,
              top: secondary,
              width: size.width,
              height: size.height,
            )
          : Bounds(
              left: secondary,
              top: primary + (rankPrimary - size.height) / 2,
              width: size.width,
              height: size.height,
            );
      secondary += (horizontal ? size.height : size.width) + config.nodeSpacing;
    }
    primary += rankPrimary + config.rankSpacing + rankSpacingAdjustment + (labeledEdgeGaps[rank] ?? 0);
  }

  final lastRank = orderedRanks.isEmpty ? null : orderedRanks.last;
  final trailingGap = lastRank == null
      ? 0
      : config.rankSpacing + rankSpacingAdjustment + (labeledEdgeGaps[lastRank] ?? 0);
  final contentPrimary = primary - trailingGap + padding;
  final width = horizontal ? contentPrimary : maxSecondary + padding * 2;
  final height = horizontal ? maxSecondary + padding * 2 : contentPrimary;
  if (direction.isReversed) {
    for (final MapEntry(key: id, value: bounds) in positions.entries.toList()) {
      positions[id] = horizontal
          ? Bounds(left: width - bounds.right, top: bounds.top, width: bounds.width, height: bounds.height)
          : Bounds(left: bounds.left, top: height - bounds.bottom, width: bounds.width, height: bounds.height);
    }
  }
  return _FlowchartGraphLayout(positions, width, height);
}

List<SceneElement> _flowchartNodeElements(
  _FlowchartNodeLayout layout,
  Map<String, Map<String, String>> classDefinitions,
  _LayoutContext context,
  FlowchartRenderOptions config,
) {
  final node = layout.node;
  final styles = <String, String>{
    for (final className in node.cssClasses) ...?classDefinitions[className],
    ...node.styles,
  };
  final fill = _flowchartColor(styles['fill']) ?? context.options.theme.mainBackground;
  final strokeColor = _flowchartColor(styles['stroke']) ?? context.options.theme.nodeBorder;
  final strokeWidth = double.tryParse(styles['stroke-width']?.replaceFirst('px', '') ?? '') ?? 1;
  final stroke = SceneStroke(color: strokeColor, width: strokeWidth);
  final classes = [
    'flowchart-node',
    if (node.shape == FlowchartNodeShape.stadium) 'flowchart-node-stadium',
    ...node.cssClasses,
  ];
  final shape = _flowchartNodeShape(context, node, layout.bounds, fill, stroke, classes);
  return [
    shape,
    _text(
      context,
      node.label,
      layout.bounds.center.x,
      layout.bounds.center.y + (node.shape == FlowchartNodeShape.cylinder ? config.nodePadding / 1.5 : 0),
      anchor: TextAnchor.middle,
      role: SemanticRole.label,
      style: SceneTextStyle(
        fontFamily: context.textStyle.fontFamily,
        fontSize: context.textStyle.fontSize,
        color: _flowchartColor(styles['color']) ?? context.textStyle.color,
      ),
      cssClasses: const ['flowchart-node-label'],
    ),
  ];
}

SceneElement _flowchartNodeShape(
  _LayoutContext context,
  FlowchartNodeAst node,
  Bounds bounds,
  Color fill,
  SceneStroke stroke,
  List<String> classes,
) {
  final commonFill = SolidFill(fill);
  return switch (node.shape) {
    FlowchartNodeShape.circle || FlowchartNodeShape.doubleCircle => SceneCircle(
      id: context.id('flowchart-node'),
      center: bounds.center,
      radius: bounds.width / 2,
      fill: commonFill,
      stroke: stroke,
      role: SemanticRole.node,
      cssClasses: classes,
      label: node.label,
    ),
    FlowchartNodeShape.diamond => ScenePolygon(
      id: context.id('flowchart-node'),
      points: [
        Point(bounds.center.x + _flowchartDiamondHorizontalOffset, bounds.top),
        Point(bounds.right + _flowchartDiamondHorizontalOffset, bounds.center.y),
        Point(bounds.center.x + _flowchartDiamondHorizontalOffset, bounds.bottom),
        Point(bounds.left + _flowchartDiamondHorizontalOffset, bounds.center.y),
      ],
      fill: commonFill,
      stroke: stroke,
      role: SemanticRole.node,
      cssClasses: classes,
      label: node.label,
    ),
    FlowchartNodeShape.cylinder => _flowchartCylinder(context, node, bounds, commonFill, stroke, classes),
    FlowchartNodeShape.hexagon => ScenePolygon(
      id: context.id('flowchart-node'),
      points: [
        Point(bounds.left + bounds.width * .2, bounds.top),
        Point(bounds.right - bounds.width * .2, bounds.top),
        Point(bounds.right, bounds.center.y),
        Point(bounds.right - bounds.width * .2, bounds.bottom),
        Point(bounds.left + bounds.width * .2, bounds.bottom),
        Point(bounds.left, bounds.center.y),
      ],
      fill: commonFill,
      stroke: stroke,
      role: SemanticRole.node,
      cssClasses: classes,
      label: node.label,
    ),
    FlowchartNodeShape.parallelogram ||
    FlowchartNodeShape.parallelogramAlt ||
    FlowchartNodeShape.trapezoid ||
    FlowchartNodeShape.trapezoidAlt ||
    FlowchartNodeShape.asymmetric => ScenePolygon(
      id: context.id('flowchart-node'),
      points: _flowchartQuadrilateral(node.shape, bounds),
      fill: commonFill,
      stroke: stroke,
      role: SemanticRole.node,
      cssClasses: classes,
      label: node.label,
    ),
    _ => SceneRect(
      id: context.id('flowchart-node'),
      bounds: bounds,
      radiusX: node.shape == FlowchartNodeShape.stadium
          ? _flowchartStadiumRadius
          : node.shape == FlowchartNodeShape.rounded
          ? _flowchartRoundedRadius
          : 0,
      radiusY: node.shape == FlowchartNodeShape.stadium
          ? _flowchartStadiumRadius
          : node.shape == FlowchartNodeShape.rounded
          ? _flowchartRoundedRadius
          : 0,
      fill: commonFill,
      stroke: stroke,
      role: SemanticRole.node,
      cssClasses: classes,
      label: node.label,
    ),
  };
}

ScenePath _flowchartCylinder(
  _LayoutContext context,
  FlowchartNodeAst node,
  Bounds bounds,
  SolidFill fill,
  SceneStroke stroke,
  List<String> classes,
) {
  final radiusX = bounds.width / 2;
  // Mermaid.js cylinder.ts: ry = rx / (2.5 + width / 50).
  final capHeight = radiusX / (2.5 + bounds.width / 50);
  final capY = bounds.top + capHeight;
  final bottomCapY = bounds.bottom - capHeight;
  return ScenePath(
    id: context.id('flowchart-node'),
    commands: [
      MoveTo(Point(bounds.left, capY)),
      ArcTo(radiusX: radiusX, radiusY: capHeight, clockwise: false, end: Point(bounds.right, capY)),
      ArcTo(radiusX: radiusX, radiusY: capHeight, clockwise: false, end: Point(bounds.left, capY)),
      LineTo(Point(bounds.left, bottomCapY)),
      ArcTo(radiusX: radiusX, radiusY: capHeight, clockwise: false, end: Point(bounds.right, bottomCapY)),
      LineTo(Point(bounds.right, capY)),
    ],
    fill: fill,
    stroke: stroke,
    role: SemanticRole.node,
    cssClasses: classes,
    label: node.label,
  );
}

List<Point> _flowchartQuadrilateral(FlowchartNodeShape shape, Bounds bounds) {
  final skew = math.min(20.0, bounds.width / 4);
  return switch (shape) {
    FlowchartNodeShape.parallelogram => [
      Point(bounds.left + skew, bounds.top),
      Point(bounds.right, bounds.top),
      Point(bounds.right - skew, bounds.bottom),
      Point(bounds.left, bounds.bottom),
    ],
    FlowchartNodeShape.parallelogramAlt => [
      Point(bounds.left, bounds.top),
      Point(bounds.right - skew, bounds.top),
      Point(bounds.right, bounds.bottom),
      Point(bounds.left + skew, bounds.bottom),
    ],
    FlowchartNodeShape.trapezoid => [
      Point(bounds.left + skew, bounds.top),
      Point(bounds.right - skew, bounds.top),
      Point(bounds.right, bounds.bottom),
      Point(bounds.left, bounds.bottom),
    ],
    FlowchartNodeShape.trapezoidAlt => [
      Point(bounds.left, bounds.top),
      Point(bounds.right, bounds.top),
      Point(bounds.right - skew, bounds.bottom),
      Point(bounds.left + skew, bounds.bottom),
    ],
    _ => [
      Point(bounds.left, bounds.top),
      Point(bounds.right - skew, bounds.top),
      Point(bounds.right, bounds.center.y),
      Point(bounds.right - skew, bounds.bottom),
      Point(bounds.left, bounds.bottom),
    ],
  };
}

List<SceneElement> _flowchartEdgeElements(
  FlowchartEdgeAst edge,
  Bounds from,
  Bounds to,
  FlowchartDirection direction,
  _LayoutContext context,
  FlowchartRenderOptions config,
) {
  final horizontal = direction.isHorizontal;
  final forward = direction.isForward;
  final start = horizontal
      ? Point(forward ? from.right : from.left, from.center.y)
      : Point(from.center.x, forward ? from.bottom : from.top);
  final end = horizontal
      ? Point(forward ? to.left : to.right, to.center.y)
      : Point(to.center.x, forward ? to.top : to.bottom);
  final middle = horizontal ? Point((start.x + end.x) / 2, start.y) : Point(start.x, (start.y + end.y) / 2);
  final beforeEnd = horizontal ? Point(middle.x, end.y) : Point(end.x, middle.y);
  final pathEnd = edge.endMarker == FlowchartEdgeMarker.arrow
      ? horizontal
            ? Point(end.x + (forward ? -_flowchartPointMarkerOffset : _flowchartPointMarkerOffset), end.y)
            : Point(end.x, end.y + (forward ? -_flowchartPointMarkerOffset : _flowchartPointMarkerOffset))
      : end;
  final commands = middle.x == beforeEnd.x && middle.y == beforeEnd.y
      ? _graphBasisPath([start, middle, pathEnd])
      : <PathCommand>[MoveTo(start), LineTo(middle), LineTo(beforeEnd), LineTo(pathEnd)];
  final stroke = SceneStroke(
    color: context.options.theme.line,
    width: edge.stroke == FlowchartEdgeStroke.thick ? config.edgeWidth * 3.5 : config.edgeWidth,
    dashes: edge.stroke == FlowchartEdgeStroke.dotted ? const [2] : const [0],
    join: StrokeJoin.miter,
  );
  final elements = <SceneElement>[
    ScenePath(
      id: edge.id ?? context.id('flowchart-edge'),
      commands: commands,
      fill: const NoFill(),
      stroke: stroke,
      role: SemanticRole.edge,
      cssClasses: ['flowchart-edge', 'flowchart-edge-${edge.stroke.name}'],
      label: edge.label,
    ),
  ];
  if (edge.startMarker != FlowchartEdgeMarker.none) {
    elements.add(_flowchartMarker(context, edge.startMarker, start, end, stroke: stroke));
  }
  if (edge.endMarker != FlowchartEdgeMarker.none) {
    elements.add(_flowchartMarker(context, edge.endMarker, end, start, stroke: stroke));
  }
  if (edge.label case final label? when label.isNotEmpty) {
    elements.add(
      _text(
        context,
        label,
        (start.x + end.x) / 2,
        (start.y + end.y) / 2,
        anchor: TextAnchor.middle,
        role: SemanticRole.label,
        cssClasses: const ['flowchart-edge-label'],
      ),
    );
  }
  return elements;
}

SceneElement _flowchartMarker(
  _LayoutContext context,
  FlowchartEdgeMarker marker,
  Point tip,
  Point opposite, {
  required SceneStroke stroke,
}) {
  final horizontal = (tip.x - opposite.x).abs() >= (tip.y - opposite.y).abs();
  final sign = horizontal ? (tip.x >= opposite.x ? 1.0 : -1.0) : (tip.y >= opposite.y ? 1.0 : -1.0);
  return switch (marker) {
    FlowchartEdgeMarker.arrow => ScenePolygon(
      id: context.id('flowchart-arrow'),
      points: horizontal
          ? [
              tip,
              Point(tip.x - sign * _flowchartArrowLength, tip.y - _flowchartArrowHalfWidth),
              Point(tip.x - sign * _flowchartArrowLength, tip.y + _flowchartArrowHalfWidth),
            ]
          : [
              tip,
              Point(tip.x - _flowchartArrowHalfWidth, tip.y - sign * _flowchartArrowLength),
              Point(tip.x + _flowchartArrowHalfWidth, tip.y - sign * _flowchartArrowLength),
            ],
      fill: SolidFill(stroke.color),
      role: SemanticRole.edge,
      cssClasses: const ['flowchart-arrowhead'],
    ),
    FlowchartEdgeMarker.circle => SceneCircle(
      id: context.id('flowchart-circle-marker'),
      center: tip,
      radius: _flowchartArrowHalfWidth,
      fill: SolidFill(context.options.theme.background),
      stroke: stroke,
      role: SemanticRole.edge,
      cssClasses: const ['flowchart-circle-marker'],
    ),
    FlowchartEdgeMarker.cross => ScenePath(
      id: context.id('flowchart-cross-marker'),
      commands: [
        MoveTo(Point(tip.x - _flowchartArrowHalfWidth, tip.y - _flowchartArrowHalfWidth)),
        LineTo(Point(tip.x + _flowchartArrowHalfWidth, tip.y + _flowchartArrowHalfWidth)),
        MoveTo(Point(tip.x + _flowchartArrowHalfWidth, tip.y - _flowchartArrowHalfWidth)),
        LineTo(Point(tip.x - _flowchartArrowHalfWidth, tip.y + _flowchartArrowHalfWidth)),
      ],
      stroke: stroke,
      role: SemanticRole.edge,
      cssClasses: const ['flowchart-cross-marker'],
    ),
    FlowchartEdgeMarker.none => throw StateError('No marker geometry exists for none'),
  };
}

Color? _flowchartColor(String? value) {
  if (value == null) return null;
  try {
    return Color.fromHex(value);
  } on FormatException {
    return null;
  }
}
