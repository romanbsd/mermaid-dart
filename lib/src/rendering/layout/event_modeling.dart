part of '../layout.dart';

_LayoutResult _layoutEventModeling(EventModelingAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const EventModelingRenderOptions());
  final boxTextStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: context.options.theme.fontSize,
    weight: FontWeight.bold,
    color: context.options.theme.primaryText,
  );
  final layout = layoutEventModel(ast, config, context.measurer, boxTextStyle);
  final elements = <SceneElement>[];

  for (final lane in layout.lanes) {
    elements.add(
      SceneRect(
        id: context.id('event-swimlane'),
        bounds: Bounds(left: 0, top: lane.y, width: layout.maxRight + config.swimlanePadding, height: lane.height),
        radiusX: 3,
        radiusY: 3,
        fill: const SolidFill(Color(250, 250, 250)),
        stroke: const SceneStroke(color: Color(240, 240, 240)),
        role: SemanticRole.group,
        cssClasses: const ['em-swimlane-background'],
        label: lane.label,
      ),
    );
    elements.add(
      _text(context, lane.label, 30, lane.y + 30, style: boxTextStyle, cssClasses: const ['em-swimlane-label']),
    );
  }

  for (final box in layout.boxes) {
    final bounds = Bounds(
      left: box.bounds.left,
      top: box.lane.y + config.swimlanePadding,
      width: box.bounds.width,
      height: box.bounds.height,
    );
    elements.add(
      SceneRect(
        id: context.id('event-frame'),
        bounds: bounds,
        radiusX: 3,
        radiusY: 3,
        fill: SolidFill(box.fill),
        stroke: SceneStroke(color: box.stroke),
        role: SemanticRole.node,
        cssClasses: const ['em-box-rect'],
        label: box.text,
      ),
    );
    elements.add(
      _text(
        context,
        box.text,
        bounds.center.x,
        bounds.center.y,
        anchor: TextAnchor.middle,
        style: boxTextStyle,
        cssClasses: const ['em-box-label'],
      ),
    );
  }

  for (final relation in layout.relations) {
    final sourceTop = relation.source.lane.y + config.swimlanePadding;
    final targetTop = relation.target.lane.y + config.swimlanePadding;
    final upwards = sourceTop > targetTop;
    final start = Point(
      relation.source.bounds.left + relation.source.bounds.width * 2 / 3,
      upwards ? sourceTop : sourceTop + relation.source.bounds.height,
    );
    final end = Point(
      relation.target.bounds.left + relation.target.bounds.width / 3,
      upwards ? targetTop + relation.target.bounds.height : targetTop,
    );
    elements.add(
      ScenePath(
        id: context.id('event-edge'),
        commands: [MoveTo(start), LineTo(end)],
        fill: const NoFill(),
        stroke: SceneStroke(color: context.options.theme.line),
        role: SemanticRole.edge,
        cssClasses: const ['em-relation'],
      ),
    );
    final dx = end.x - start.x;
    final dy = end.y - start.y;
    final length = math.sqrt(dx * dx + dy * dy);
    if (length > 0) {
      final unitX = dx / length;
      final unitY = dy / length;
      final base = Point(end.x - unitX * 10, end.y - unitY * 10);
      elements.add(
        ScenePolygon(
          id: context.id('event-arrowhead'),
          points: [
            end,
            Point(base.x - unitY * 3.5, base.y + unitX * 3.5),
            Point(base.x + unitY * 3.5, base.y - unitX * 3.5),
          ],
          fill: SolidFill(context.options.theme.line),
          role: SemanticRole.edge,
          cssClasses: const ['em-arrowhead'],
        ),
      );
    }
  }

  return _LayoutResult(layout.maxRight + config.swimlanePadding, layout.height, elements);
}
