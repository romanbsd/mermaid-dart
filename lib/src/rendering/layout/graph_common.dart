part of '../layout.dart';

// Rough.js emits the hand-drawn Class and ER outlines with this stroke width.
const _graphRoughStrokeWidth = 1.3;

final class _GraphEdgeLayout {
  const _GraphEdgeLayout(this.from, this.to, [this.label]);

  final String from;
  final String to;
  final String? label;
}

_FlowchartGraphLayout _layoutGraphBoxes({
  required List<String> ids,
  required Map<String, Size> sizes,
  required List<_GraphEdgeLayout> edges,
  required GraphDirection direction,
  required double nodeSpacing,
  required double rankSpacing,
  required double padding,
  required _LayoutContext context,
}) => _layoutFlowchartGraph(
  ids,
  sizes,
  [for (final edge in edges) _FlowchartRankEdge(edge.from, edge.to, 1, edge.label)],
  _flowchartDirection(direction),
  FlowchartRenderOptions(nodeSpacing: nodeSpacing, rankSpacing: rankSpacing, diagramPadding: padding),
  context,
  padding: padding,
);

FlowchartDirection _flowchartDirection(GraphDirection direction) => switch (direction) {
  GraphDirection.topDown => FlowchartDirection.topDown,
  GraphDirection.bottomTop => FlowchartDirection.bottomTop,
  GraphDirection.leftRight => FlowchartDirection.leftRight,
  GraphDirection.rightLeft => FlowchartDirection.rightLeft,
};

({Point start, Point end}) _graphEdgePoints(Bounds from, Bounds to) {
  final fromCenter = from.center;
  final toCenter = to.center;
  return (start: _rectangleIntersection(from, toCenter), end: _rectangleIntersection(to, fromCenter));
}

List<PathCommand> _graphEdgePath(Point start, Point end) {
  final horizontal = (end.x - start.x).abs() >= (end.y - start.y).abs();
  final middle = horizontal ? Point((start.x + end.x) / 2, start.y) : Point(start.x, (start.y + end.y) / 2);
  return _graphBasisPath([start, middle, end]);
}

/// Matches d3-shape's open basis curve through two or more routing points.
List<PathCommand> _graphBasisPath(List<Point> points) {
  assert(points.length >= 2);
  final [start, second, ...] = points;
  final commands = <PathCommand>[MoveTo(start), LineTo(_weightedPoint(start, 5, second, 1, 6))];
  for (var index = 1; index < points.length - 1; index++) {
    final previous = points[index - 1];
    final current = points[index];
    final next = points[index + 1];
    commands.add(
      CubicTo(
        _weightedPoint(previous, 2, current, 1, 3),
        _weightedPoint(previous, 1, current, 2, 3),
        _weightedPoint(previous, 1, current, 4, 6, end: next),
      ),
    );
  }
  final beforeEnd = points[points.length - 2];
  final end = points.last;
  return commands
    ..add(
      CubicTo(
        _weightedPoint(beforeEnd, 2, end, 1, 3),
        _weightedPoint(beforeEnd, 1, end, 2, 3),
        _weightedPoint(beforeEnd, 1, end, 5, 6),
      ),
    )
    ..add(LineTo(end));
}

Point _weightedPoint(Point first, double firstWeight, Point second, double secondWeight, double divisor, {Point? end}) {
  final third = end ?? const Point(0, 0);
  return Point(
    (first.x * firstWeight + second.x * secondWeight + third.x) / divisor,
    (first.y * firstWeight + second.y * secondWeight + third.y) / divisor,
  );
}

Point _rectangleIntersection(Bounds bounds, Point target) {
  final center = bounds.center;
  final dx = target.x - center.x;
  final dy = target.y - center.y;
  if (dx == 0 && dy == 0) return center;
  final xScale = dx == 0 ? double.infinity : bounds.width / 2 / dx.abs();
  final yScale = dy == 0 ? double.infinity : bounds.height / 2 / dy.abs();
  final scale = math.min(xScale, yScale);
  return Point(center.x + dx * scale, center.y + dy * scale);
}

ScenePolygon _graphArrow(
  _LayoutContext context, {
  required Point tip,
  required Point tail,
  required Color color,
  required String cssClass,
}) => _triangleArrow(
  context,
  tip: tip,
  tail: tail,
  length: 9,
  halfWidth: 4.5,
  color: color,
  idPrefix: cssClass,
  cssClasses: [cssClass],
);

ScenePolygon _graphBarbArrow(
  _LayoutContext context, {
  required Point tip,
  required Point tail,
  required Color color,
  required String cssClass,
}) {
  final dx = tip.x - tail.x;
  final dy = tip.y - tail.y;
  final distance = math.sqrt(dx * dx + dy * dy);
  final ux = distance == 0 ? 1.0 : dx / distance;
  final uy = distance == 0 ? 0.0 : dy / distance;
  final px = -uy;
  final py = ux;
  Point behind(double along, [double across = 0]) =>
      Point(tip.x - ux * along + px * across, tip.y - uy * along + py * across);
  return ScenePolygon(
    id: context.id(cssClass),
    points: [tip, behind(10, 6), behind(5), behind(10, -6)],
    fill: SolidFill(color),
    stroke: _graphStroke(color, 1),
    cssClasses: [cssClass],
  );
}

SceneStroke _graphStroke(Color color, double width, {bool dotted = false}) =>
    SceneStroke(color: color, width: width, dashes: dotted ? const [3, 3] : const []);

SceneRect _graphLabelBackground(
  _LayoutContext context,
  String text,
  Point center, {
  required String cssClass,
  Color? color,
}) {
  final size = context.measurer.measure(text, context.textStyle);
  return SceneRect(
    id: context.id('graph-label-background'),
    bounds: Bounds(
      left: center.x - size.width / 2,
      top: center.y - size.height / 2,
      width: size.width,
      height: size.height,
    ),
    fill: SolidFill(color ?? context.options.theme.labelBackground),
    cssClasses: [cssClass],
  );
}

double _maxGraphTextWidth(Iterable<String> rows, _LayoutContext context, {double minimum = 0}) =>
    rows.map((row) => context.measurer.measure(row, context.textStyle).width).fold(minimum, math.max);

({Color fill, SceneStroke stroke}) _graphNodePaint(
  List<String> cssClasses,
  Map<String, String> inline,
  Map<String, Map<String, String>> definitions,
  _LayoutContext context,
  double strokeWidth,
) {
  final styles = _diagramNodeStyles(cssClasses, inline, definitions);
  return (
    fill: _flowchartColor(styles['fill']) ?? context.options.theme.mainBackground,
    stroke: _graphStroke(_flowchartColor(styles['stroke']) ?? context.options.theme.primaryBorder, strokeWidth),
  );
}

Map<String, String> _diagramNodeStyles(
  List<String> cssClasses,
  Map<String, String> inline,
  Map<String, Map<String, String>> definitions,
) {
  final result = <String, String>{};
  for (final cssClass in cssClasses) {
    result.addAll(definitions[cssClass] ?? const {});
  }
  result.addAll(inline);
  return result;
}
