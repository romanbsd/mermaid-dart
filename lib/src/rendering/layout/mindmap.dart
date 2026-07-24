part of '../layout.dart';

// Mermaid's classic default root colors (`--mindmap-node-bkg` / root label).
const _mindmapRootFill = Color(0, 0, 236);
const _mindmapRootText = Color(255, 255, 255);
const _mindmapMinimumNodeHeight = 40.0;
const _mindmapIconSize = 20.0;

final class _MindmapLayoutNode {
  _MindmapLayoutNode({
    required this.layoutId,
    required this.node,
    required this.depth,
    required this.section,
    required this.width,
    required this.height,
  });

  final String layoutId;
  final MindmapNodeAst node;
  final int depth;
  final int section;
  final double width;
  final double height;
  double x = 0;
  double y = 0;
  final children = <_MindmapLayoutNode>[];
}

_LayoutResult _layoutMindmap(MindmapAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const MindmapRenderOptions());
  final theme = context.options.theme;
  final textStyle = SceneTextStyle(fontFamily: theme.fontFamily, fontSize: theme.fontSize, color: theme.primaryText);
  var nextSection = 0;
  var nextLayoutId = 0;

  _MindmapLayoutNode build(MindmapNodeAst node, int depth, int section) {
    final measured = context.measurer.measure(node.label, textStyle);
    final iconAllowance = node.icon == null ? 0.0 : _mindmapIconSize + config.padding;
    final horizontalPadding = switch (node.shape) {
      MindmapNodeShape.roundedRectangle => 15.0,
      MindmapNodeShape.rectangle => 20.0,
      MindmapNodeShape.hexagon => 21.0,
      MindmapNodeShape.cloud || MindmapNodeShape.bang => 5.0,
      _ => config.padding,
    };
    final verticalPadding = switch (node.shape) {
      MindmapNodeShape.roundedRectangle => 15.0,
      MindmapNodeShape.rectangle || MindmapNodeShape.hexagon => 10.0,
      MindmapNodeShape.cloud || MindmapNodeShape.bang => 5.0,
      _ => config.padding,
    };
    var width = measured.width + 2 * horizontalPadding + iconAllowance;
    var height = math.max(
      measured.height + 2 * verticalPadding,
      node.shape == MindmapNodeShape.circle ||
              node.shape == MindmapNodeShape.cloud ||
              node.shape == MindmapNodeShape.bang
          ? 0.0
          : _mindmapMinimumNodeHeight,
    );
    if (node.shape == MindmapNodeShape.circle) {
      width = height = math.max(width, height);
    }
    final layout = _MindmapLayoutNode(
      layoutId: '${nextLayoutId++}',
      node: node,
      depth: depth,
      section: section,
      width: width,
      height: height,
    );
    for (final child in node.children) {
      final childSection = depth == 0 ? nextSection++ : section;
      layout.children.add(build(child, depth + 1, childSection));
    }
    return layout;
  }

  final root = build(ast.root, 0, 0);
  final all = <_MindmapLayoutNode>[];
  void collect(_MindmapLayoutNode node) {
    all.add(node);
    node.children.forEach(collect);
  }

  collect(root);
  final graph = FcoseGraph(
    nodes: [for (final node in all) FcoseNode(id: node.layoutId, width: node.width, height: node.height)],
    edges: [
      for (final parent in all)
        for (final child in parent.children)
          FcoseEdge(id: '${parent.layoutId}-${child.layoutId}', source: parent.layoutId, target: child.layoutId),
    ],
  );
  final positions = FcoseLayout(options: const FcoseOptions(quality: LayoutQuality.proof, seed: 1)).run(graph);
  for (final node in all) {
    final center = positions.positionOf(node.layoutId);
    // Mermaid's cose-bilkent coordinate system grows the first branch
    // downward for this insertion order. fCoSE uses the opposite handedness,
    // so reflect its otherwise equivalent force-directed result.
    node.x = center.x - node.width / 2;
    node.y = -center.y - node.height / 2;
  }
  final minX = all.map((node) => node.x).reduce(math.min);
  final minY = all.map((node) => node.y).reduce(math.min);
  for (final node in all) {
    node.x -= minX;
    node.y -= minY;
  }
  final elements = <SceneElement>[];
  for (final parent in all) {
    for (final child in parent.children) {
      final parentCenter = Point(parent.x + parent.width / 2, parent.y + parent.height / 2);
      final childCenter = Point(child.x + child.width / 2, child.y + child.height / 2);
      final start = _mindmapBoundaryPoint(parent, childCenter);
      final end = _mindmapBoundaryPoint(child, parentCenter);
      final firstControl = Point(start.x + (end.x - start.x) / 3, start.y + (end.y - start.y) / 3);
      final secondControl = Point(start.x + 2 * (end.x - start.x) / 3, start.y + 2 * (end.y - start.y) / 3);
      final edgeDepth = 2 * child.depth - 1;
      final edgeWidth = math.max(2, 14 - 3 * edgeDepth).toDouble();
      final colorIndex = (child.section + 1) % theme.categoricalColors.length;
      elements.add(
        ScenePath(
          id: context.id('mindmap-edge'),
          commands: [MoveTo(start), CubicTo(firstControl, secondControl, end)],
          fill: const SolidFill(Color(255, 255, 255, 0)),
          stroke: SceneStroke(color: theme.categoricalColors[colorIndex], width: edgeWidth),
          cssClasses: ['mindmap-edge', 'section-${child.section}'],
        ),
      );
    }
  }

  for (final node in all) {
    final colorIndex = node.depth == 0 ? 0 : (node.section + 1) % theme.categoricalColors.length;
    final fillColor = node.depth == 0 ? _mindmapRootFill : theme.categoricalColors[colorIndex];
    final fill = SolidFill(fillColor);
    final bounds = Bounds(left: node.x, top: node.y, width: node.width, height: node.height);
    final classes = ['mindmap-node', 'mindmap-${node.node.shape.name}', ...node.node.cssClasses];
    elements.add(_mindmapShape(context, node.node.shape, bounds, fill, null, classes));
    var labelX = bounds.left + bounds.width / 2;
    if (node.node.icon case final icon?) {
      final iconX = bounds.left + config.padding;
      final iconY = bounds.top + (bounds.height - _mindmapIconSize) / 2;
      elements.add(
        _scaledIcon(
          context,
          icon,
          Point(iconX, iconY),
          _mindmapIconSize,
          idPrefix: 'mindmap-icon',
          fill: SolidFill(theme.primaryText),
          cssClasses: const ['mindmap-icon'],
        ),
      );
      labelX += (_mindmapIconSize + config.padding) / 2;
    }
    elements.add(
      _text(
        context,
        node.node.label,
        labelX,
        bounds.top + bounds.height / 2,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.middle,
        style: SceneTextStyle(
          fontFamily: theme.fontFamily,
          fontSize: theme.fontSize,
          color: node.depth == 0 ? _mindmapRootText : theme.categoricalLabelColors[colorIndex],
        ),
        cssClasses: ['mindmap-label', ...node.node.cssClasses],
      ),
    );
  }

  final width = all.map((node) => node.x + node.width).reduce(math.max);
  final height = all.map((node) => node.y + node.height).reduce(math.max);
  return _LayoutResult(width, height, elements, viewportPadding: config.padding);
}

Point _mindmapBoundaryPoint(_MindmapLayoutNode node, Point toward) {
  final center = Point(node.x + node.width / 2, node.y + node.height / 2);
  final dx = toward.x - center.x;
  final dy = toward.y - center.y;
  if (dx == 0 && dy == 0) return center;
  if (node.node.shape case MindmapNodeShape.circle || MindmapNodeShape.cloud || MindmapNodeShape.bang) {
    final denominator = math.sqrt(dx * dx / math.pow(node.width / 2, 2) + dy * dy / math.pow(node.height / 2, 2));
    return Point(center.x + dx / denominator, center.y + dy / denominator);
  }
  final scale = 1 / math.max(dx.abs() / (node.width / 2), dy.abs() / (node.height / 2));
  return Point(center.x + dx * scale, center.y + dy * scale);
}

SceneElement _mindmapShape(
  _LayoutContext context,
  MindmapNodeShape shape,
  Bounds bounds,
  SceneFill fill,
  SceneStroke? stroke,
  List<String> classes,
) => switch (shape) {
  MindmapNodeShape.circle => SceneCircle(
    id: context.id('mindmap-node'),
    center: Point(bounds.left + bounds.width / 2, bounds.top + bounds.height / 2),
    radius: bounds.width / 2,
    fill: fill,
    stroke: stroke,
    cssClasses: classes,
  ),
  MindmapNodeShape.hexagon => ScenePolygon(
    id: context.id('mindmap-node'),
    points: [
      Point(bounds.left + bounds.height / 4, bounds.top),
      Point(bounds.right - bounds.height / 4, bounds.top),
      Point(bounds.right, bounds.top + bounds.height / 2),
      Point(bounds.right - bounds.height / 4, bounds.bottom),
      Point(bounds.left + bounds.height / 4, bounds.bottom),
      Point(bounds.left, bounds.top + bounds.height / 2),
    ],
    fill: fill,
    stroke: stroke,
    cssClasses: classes,
  ),
  MindmapNodeShape.bang => ScenePath(
    id: context.id('mindmap-node'),
    commands: [
      for (var index = 0; index < 16; index++)
        if (index == 0) MoveTo(_mindmapStarPoint(bounds, index)) else LineTo(_mindmapStarPoint(bounds, index)),
      const ClosePath(),
    ],
    fill: fill,
    stroke: stroke,
    cssClasses: classes,
  ),
  MindmapNodeShape.cloud => ScenePath(
    id: context.id('mindmap-node'),
    commands: _mindmapCloudPath(bounds),
    fill: fill,
    stroke: stroke,
    cssClasses: classes,
  ),
  MindmapNodeShape.roundedRectangle => SceneRect(
    id: context.id('mindmap-node'),
    bounds: bounds,
    radiusX: 5,
    radiusY: 5,
    fill: fill,
    stroke: stroke,
    cssClasses: classes,
  ),
  MindmapNodeShape.rectangle => SceneRect(
    id: context.id('mindmap-node'),
    bounds: bounds,
    fill: fill,
    stroke: stroke,
    cssClasses: classes,
  ),
  MindmapNodeShape.noBorder => SceneRect(
    id: context.id('mindmap-node'),
    bounds: bounds,
    fill: const SolidFill(Color(255, 255, 255, 0)),
    cssClasses: classes,
  ),
};

Point _mindmapStarPoint(Bounds bounds, int index) {
  final scale = index.isEven ? 1.0 : 0.72;
  return Point(
    bounds.left + bounds.width / 2 + math.cos(index * math.pi / 8) * bounds.width / 2 * scale,
    bounds.top + bounds.height / 2 + math.sin(index * math.pi / 8) * bounds.height / 2 * scale,
  );
}

List<PathCommand> _mindmapCloudPath(Bounds bounds) {
  final left = bounds.left;
  final top = bounds.top;
  final width = bounds.width;
  final height = bounds.height;
  var point = Point(left, top);
  ArcTo arc(double radiusX, double radiusY, double dx, double dy, {double rotation = 1}) {
    point = Point(point.x + dx, point.y + dy);
    return ArcTo(radiusX: radiusX, radiusY: radiusY, rotation: rotation, end: point);
  }

  return [
    MoveTo(point),
    arc(width * 0.15, width * 0.15, width * 0.25, -width * 0.1, rotation: 0),
    arc(width * 0.35, width * 0.35, width * 0.4, -width * 0.1),
    arc(width * 0.25, width * 0.25, width * 0.35, width * 0.2),
    arc(width * 0.15, width * 0.15, width * 0.15, height * 0.35),
    arc(width * 0.2, width * 0.2, -width * 0.15, height * 0.65),
    arc(width * 0.25, width * 0.15, -width * 0.25, width * 0.15),
    arc(width * 0.35, width * 0.35, -width * 0.5, 0),
    arc(width * 0.15, width * 0.15, -width * 0.25, -width * 0.15),
    arc(width * 0.15, width * 0.15, -width * 0.1, -height * 0.35),
    arc(width * 0.2, width * 0.2, width * 0.1, -height * 0.65),
    LineTo(Point(left, point.y)),
    LineTo(Point(left, top)),
    const ClosePath(),
  ];
}
