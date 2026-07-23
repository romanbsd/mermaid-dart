part of '../layout.dart';

// Fixed geometry from Mermaid's event-modeling renderer. Typed options own
// frame and lane sizing; these values describe its SVG decoration rules.
const _eventModelingCornerRadius = 3.0;
const _eventModelingLaneLabelInset = 30.0;
const _eventModelingRelationAnchorDivisor = 3.0;
const _eventModelingRelationSourceAnchor = 2.0;
const _eventModelingRelationTargetAnchor = 1.0;
const _eventModelingArrowLength = 10.0;
const _eventModelingArrowHalfWidth = 3.5;

_LayoutResult _layoutEventModeling(EventModelingAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const EventModelingRenderOptions());
  final theme = context.options.theme.eventModeling;
  final boxTextStyle = SceneTextStyle(
    fontFamily: context.options.theme.fontFamily,
    fontSize: context.options.theme.fontSize,
    weight: FontWeight.bold,
    color: context.options.theme.primaryText,
  );
  final layout = layoutEventModel(ast, config, context.measurer, boxTextStyle, theme: theme);
  final elements = <SceneElement>[];

  for (final lane in layout.lanes) {
    elements.add(
      SceneRect(
        id: context.id('event-swimlane'),
        bounds: Bounds(left: 0, top: lane.y, width: layout.maxRight + config.swimlanePadding, height: lane.height),
        radiusX: _eventModelingCornerRadius,
        radiusY: _eventModelingCornerRadius,
        fill: SolidFill(theme.swimlaneBackgroundOdd),
        stroke: SceneStroke(color: theme.swimlaneBackgroundStroke),
        role: SemanticRole.group,
        cssClasses: const ['em-swimlane-background'],
        label: lane.label,
      ),
    );
    elements.add(
      _text(
        context,
        lane.label,
        _eventModelingLaneLabelInset,
        lane.y + _eventModelingLaneLabelInset,
        baseline: TextBaseline.alphabetic,
        style: boxTextStyle,
        cssClasses: const ['em-swimlane-label'],
      ),
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
        radiusX: _eventModelingCornerRadius,
        radiusY: _eventModelingCornerRadius,
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
      relation.source.bounds.left +
          relation.source.bounds.width * _eventModelingRelationSourceAnchor / _eventModelingRelationAnchorDivisor,
      upwards ? sourceTop : sourceTop + relation.source.bounds.height,
    );
    final end = Point(
      relation.target.bounds.left +
          relation.target.bounds.width * _eventModelingRelationTargetAnchor / _eventModelingRelationAnchorDivisor,
      upwards ? targetTop + relation.target.bounds.height : targetTop,
    );
    elements.add(
      ScenePath(
        id: context.id('event-edge'),
        commands: [MoveTo(start), LineTo(end)],
        fill: const NoFill(),
        stroke: SceneStroke(color: theme.relationStroke),
        role: SemanticRole.edge,
        cssClasses: const ['em-relation'],
      ),
    );
    if (start != end) {
      elements.add(
        _triangleArrow(
          context,
          tip: end,
          tail: start,
          length: _eventModelingArrowLength,
          halfWidth: _eventModelingArrowHalfWidth,
          color: theme.arrowhead,
          idPrefix: 'event',
          idSuffix: 'arrowhead',
          cssClasses: const ['em-arrowhead'],
        ),
      );
    }
  }

  final bounds = Bounds(left: 0, top: 0, width: layout.maxRight + config.swimlanePadding, height: layout.height);
  return _LayoutResult(bounds.width, bounds.height, elements, bounds: bounds, viewportPadding: config.padding);
}
