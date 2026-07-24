part of '../layout.dart';

// Mermaid.js state renderer geometry defaults, expressed in scene units.
const _stateSpecialExtent = 14.0;
const _stateChoiceExtent = 28.0;
const _stateBarWidth = 70.0;
const _stateBarHeight = 8.0;
// Mermaid's state cluster reserves 26 units for its title and 37.5 units
// around the nested graph. Nested state ranks are separated by 75 units.
const _stateCompositeHeaderHeight = 26.0;
const _stateCompositeInset = 37.5;
const _stateCompositeHorizontalPadding = 35.0;
const _stateCompositeRankSpacing = 75.0;
const _stateNodeHorizontalPadding = 8.0;
const _stateNodeHeight = 40.0;
const _stateNotePadding = 15.0;
const _stateNoteLayoutHorizontalInset = 35.0;
const _stateNoteLayoutVerticalInset = 25.0;
// Dagre's classic State renderer offsets terminal columns by these fractions
// after crossing minimization. They keep split branches aligned with their
// end-state and note successors.
const _stateTerminalColumnInset = 0.4375;
const _stateNoteColumnShift = 4.375 + _stateEndEdgeInset;
const _stateCompositeBranchPortInset = 14.4640625;
// Mermaid's rough end-state circle intersects an incoming edge just inside
// the ideal seven-unit radius.
const _stateEndEdgeInset = 0.0066466331482;
const _statePrimaryText = Color(19, 19, 0);
const _stateNoteText = Color(0, 0, 0);
const _stateNoteFill = Color(255, 245, 173);
const _stateNoteBorder = Color(170, 170, 51);

_LayoutResult _layoutStateDiagram(StateDiagramAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const StateRenderOptions());
  final elements = _layoutStateScope(ast.states, ast.transitions, ast.direction, ast.classDefinitions, context, config);
  return _LayoutResult(
    elements.width,
    elements.height,
    elements.elements,
    bounds: Bounds(left: 0, top: 0, width: elements.width, height: elements.height),
  );
}

({List<SceneElement> elements, double width, double height}) _layoutStateScope(
  List<StateAst> states,
  List<StateTransitionAst> transitions,
  GraphDirection direction,
  Map<String, Map<String, String>> definitions,
  _LayoutContext context,
  StateRenderOptions config,
) {
  final notes = [
    for (final state in states)
      if (state.note case final note?) (state: state, note: note, id: '${state.id}----note'),
  ];
  final sizes = <String, Size>{
    for (final state in states) state.id: _stateNodeSize(state, context, config),
    for (final note in notes) note.id: _stateNoteLayoutSize(note.note, context),
  };
  final rawGraph = _layoutGraphBoxes(
    ids: [...states.map((state) => state.id), ...notes.map((note) => note.id)],
    sizes: sizes,
    edges: [
      for (final transition in transitions) _GraphEdgeLayout(transition.from, transition.to, transition.label),
      for (final note in notes) _GraphEdgeLayout(note.state.id, note.id, null),
    ],
    direction: direction,
    nodeSpacing: config.nodeSpacing,
    rankSpacing: config.rankSpacing,
    padding: config.diagramPadding,
    context: context,
  );
  final graph = _alignStateColumns(
    rawGraph,
    states,
    transitions,
    notes,
    direction: direction,
    padding: config.diagramPadding,
  );
  final elements = <SceneElement>[];
  for (final transition in transitions) {
    final from = graph.positions[transition.from];
    final to = graph.positions[transition.to];
    if (from == null || to == null) continue;
    elements.addAll(_stateTransitionElements(transition, from, to, context, config));
  }
  for (final state in states) {
    final bounds = graph.positions[state.id];
    if (bounds == null) continue;
    elements.addAll(_stateNodeElements(state, bounds, definitions, context, config));
  }
  for (final note in notes) {
    final stateBounds = graph.positions[note.state.id];
    final noteBounds = graph.positions[note.id];
    if (stateBounds == null || noteBounds == null) continue;
    elements.addAll(_stateNoteElements(note.note, stateBounds, noteBounds, context, config));
  }
  return (elements: elements, width: graph.width, height: graph.height);
}

_FlowchartGraphLayout _alignStateColumns(
  _FlowchartGraphLayout graph,
  List<StateAst> states,
  List<StateTransitionAst> transitions,
  List<({String id, StateNoteAst note, StateAst state})> notes, {
  required GraphDirection direction,
  required double padding,
}) {
  if (notes.isEmpty || direction.isHorizontal) return graph;
  final positions = Map<String, Bounds>.of(graph.positions);
  void centerAt(String id, double centerX) {
    final bounds = positions[id];
    if (bounds == null) return;
    positions[id] = Bounds(
      left: centerX - bounds.width / 2,
      top: bounds.top,
      width: bounds.width,
      height: bounds.height,
    );
  }

  for (final note in notes) {
    final bounds = positions[note.id];
    if (bounds == null) continue;
    final centerX = bounds.center.x + _stateNoteColumnShift;
    centerAt(note.id, centerX);
    centerAt(note.state.id, centerX);
  }
  for (final end in states.where((state) => state.type == StateType.end)) {
    final predecessorId = transitions.where((transition) => transition.to == end.id).firstOrNull?.from;
    final predecessor = predecessorId == null ? null : positions[predecessorId];
    if (predecessor == null) continue;
    final centerX = padding + predecessor.width / 2 + _stateTerminalColumnInset;
    centerAt(end.id, centerX);
    centerAt(predecessorId!, centerX);
  }

  final fixed = {
    ...notes.map((note) => note.state.id),
    ...states.where((state) => state.type == StateType.end).map((state) => state.id),
  };
  for (final state in states.reversed) {
    if (fixed.contains(state.id)) continue;
    final targets = transitions
        .where((transition) => transition.from == state.id)
        .map((transition) => positions[transition.to]?.center.x)
        .whereType<double>()
        .toList();
    if (targets.isEmpty) continue;
    centerAt(state.id, targets.fold(0.0, (sum, value) => sum + value) / targets.length);
  }
  return _FlowchartGraphLayout(positions, graph.width + _stateNoteColumnShift, graph.height);
}

Size _stateNodeSize(StateAst state, _LayoutContext context, StateRenderOptions config) => switch (state.type) {
  StateType.start || StateType.end => const Size(_stateSpecialExtent, _stateSpecialExtent),
  StateType.choice => const Size(_stateChoiceExtent, _stateChoiceExtent),
  StateType.fork || StateType.join => const Size(_stateBarWidth, _stateBarHeight),
  StateType.divider => const Size(_stateBarWidth, 3),
  StateType.normal => _stateNormalSize(state, context, config),
};

Size _stateNormalSize(StateAst state, _LayoutContext context, StateRenderOptions config) {
  final rows = [state.label, ...state.descriptions];
  final textWidth = _maxGraphTextWidth(rows, context);
  if (state.children.isEmpty) {
    return Size(textWidth + _stateNodeHorizontalPadding * 2, _stateNodeHeight * rows.length);
  }
  final children = _stateChildGraph(state, context, config);
  return Size(
    math.max(textWidth + _stateNodeHorizontalPadding * 2, children.width + _stateCompositeHorizontalPadding * 2),
    children.height + _stateCompositeInset * 2,
  );
}

List<SceneElement> _stateNodeElements(
  StateAst state,
  Bounds bounds,
  Map<String, Map<String, String>> definitions,
  _LayoutContext context,
  StateRenderOptions config,
) {
  final paint = _graphNodePaint(state.cssClasses, state.styles, definitions, context, config.edgeWidth);
  final elements = <SceneElement>[];
  switch (state.type) {
    case StateType.start:
      elements.add(
        SceneCircle(
          id: context.id('state-start'),
          center: bounds.center,
          radius: bounds.width / 2,
          fill: SolidFill(context.options.theme.line),
          stroke: _graphStroke(context.options.theme.line, 1),
          cssClasses: const ['state-start'],
          role: SemanticRole.node,
        ),
      );
    case StateType.end:
      elements
        ..add(
          SceneCircle(
            id: context.id('state-end'),
            center: bounds.center,
            radius: bounds.width / 2,
            fill: SolidFill(context.options.theme.primary),
            stroke: _graphStroke(context.options.theme.line, 2),
            cssClasses: const ['state-end'],
            role: SemanticRole.node,
          ),
        )
        ..add(
          SceneCircle(
            id: context.id('state-end-inner'),
            center: bounds.center,
            radius: 2.5,
            fill: SolidFill(context.options.theme.primaryBorder),
            stroke: _graphStroke(context.options.theme.primaryBorder, 2),
            cssClasses: const ['state-end-inner'],
          ),
        );
    case StateType.choice:
      elements
        ..add(
          ScenePolygon(
            id: context.id('state-choice'),
            points: [
              Point(bounds.center.x, bounds.top),
              Point(bounds.right, bounds.center.y),
              Point(bounds.center.x, bounds.bottom),
              Point(bounds.left, bounds.center.y),
            ],
            fill: SolidFill(paint.fill),
            stroke: paint.stroke,
            cssClasses: const ['state-choice'],
            role: SemanticRole.node,
            label: state.label,
          ),
        )
        ..add(
          _text(
            context,
            state.label,
            bounds.center.x,
            bounds.bottom + context.textStyle.fontSize,
            anchor: TextAnchor.middle,
            cssClasses: const ['state-choice-label'],
          ),
        );
    case StateType.fork || StateType.join:
      elements.add(
        SceneRect(
          id: context.id('state-bar'),
          bounds: bounds,
          fill: SolidFill(context.options.theme.line),
          cssClasses: [state.type == StateType.fork ? 'state-fork' : 'state-join'],
          role: SemanticRole.node,
          label: state.label,
        ),
      );
    case StateType.divider:
      elements.add(
        SceneRect(
          id: context.id('state-divider'),
          bounds: bounds,
          fill: SolidFill(context.options.theme.line),
          cssClasses: const ['state-divider'],
          role: SemanticRole.group,
        ),
      );
    case StateType.normal:
      elements.add(
        SceneRect(
          id: context.id('state-node'),
          bounds: bounds,
          radiusX: 5,
          radiusY: 5,
          fill: SolidFill(paint.fill),
          stroke: paint.stroke,
          cssClasses: ['state-node', if (state.children.isNotEmpty) 'state-composite', ...state.cssClasses],
          role: SemanticRole.node,
          label: state.label,
        ),
      );
      final rowHeight = context.textStyle.fontSize + config.nodePadding;
      elements.add(
        _text(
          context,
          state.label,
          bounds.center.x,
          bounds.top + (state.children.isEmpty ? _stateNodeHeight / 2 : _stateCompositeHeaderHeight / 2),
          anchor: TextAnchor.middle,
          style: _stateTextStyle(context, _statePrimaryText),
          cssClasses: const ['state-title'],
        ),
      );
      for (var index = 0; index < state.descriptions.length; index++) {
        elements.add(
          _text(
            context,
            state.descriptions[index],
            bounds.left + config.nodePadding,
            bounds.top + rowHeight * (index + 1.5) + config.nodePadding / 2,
            style: _stateTextStyle(context, _statePrimaryText),
            cssClasses: const ['state-description'],
          ),
        );
      }
      if (state.children.isNotEmpty) {
        elements.add(
          SceneRect(
            id: context.id('state-composite-inner'),
            bounds: Bounds(
              left: bounds.left,
              top: bounds.top + _stateCompositeHeaderHeight,
              width: bounds.width,
              height: bounds.height - _stateCompositeHeaderHeight - 4,
            ),
            fill: const SolidFill(Color(255, 255, 255)),
            stroke: paint.stroke,
            cssClasses: const ['state-composite-inner'],
          ),
        );
        elements.addAll(_stateCompositeChildren(state, bounds, definitions, context, config));
      }
  }
  return elements;
}

List<SceneElement> _stateCompositeChildren(
  StateAst state,
  Bounds parentBounds,
  Map<String, Map<String, String>> definitions,
  _LayoutContext context,
  StateRenderOptions config,
) {
  final graph = _stateChildGraph(state, context, config);
  final offsetX = parentBounds.left + (parentBounds.width - graph.width) / 2;
  final offsetY = parentBounds.top + _stateCompositeInset;
  final children = <SceneElement>[];
  for (final transition in state.transitions) {
    final from = graph.positions[transition.from];
    final to = graph.positions[transition.to];
    if (from == null || to == null) continue;
    children.addAll(_stateTransitionElements(transition, from, to, context, config));
  }
  for (final child in state.children) {
    final bounds = graph.positions[child.id];
    if (bounds == null) continue;
    children.addAll(_stateNodeElements(child, bounds, definitions, context, config));
  }
  return [
    SceneGroup(
      id: context.id('state-composite-content'),
      transforms: [Translate(offsetX, offsetY)],
      children: children,
      role: SemanticRole.group,
      cssClasses: const ['state-composite-content'],
    ),
  ];
}

List<SceneElement> _stateTransitionElements(
  StateTransitionAst transition,
  Bounds from,
  Bounds to,
  _LayoutContext context,
  StateRenderOptions config,
) {
  final rawPoints = _graphEdgePoints(from, to);
  final targetsSpecialState = to.width == _stateSpecialExtent && to.height == _stateSpecialExtent;
  final rawEnd = targetsSpecialState
      ? _statePointToward(rawPoints.end, rawPoints.start, _stateEndEdgeInset)
      : rawPoints.end;
  final verticalCompositeBranch =
      from.height > _stateNodeHeight && (to.center.y - from.center.y).abs() >= (to.center.x - from.center.x).abs();
  final end = verticalCompositeBranch ? Point(to.center.x, to.center.y >= from.center.y ? to.top : to.bottom) : rawEnd;
  final start = verticalCompositeBranch
      ? Point(
          end.x + (from.center.x - end.x).sign * _stateCompositeBranchPortInset,
          to.center.y >= from.center.y ? from.bottom : from.top,
        )
      : rawPoints.start;
  final middle = verticalCompositeBranch
      ? Point(end.x, (start.y + end.y) / 2)
      : (end.x - start.x).abs() >= (end.y - start.y).abs()
      ? Point((start.x + end.x) / 2, start.y)
      : Point(start.x, (start.y + end.y) / 2);
  final points = (start: start, end: end);
  final color = context.options.theme.line;
  var route = [start, middle, end];
  if (targetsSpecialState &&
      (end.y - start.y).abs() > _stateCompositeRankSpacing &&
      (end.x - start.x).abs() < _stateEndEdgeInset) {
    final step = _stateCompositeRankSpacing / 3 * (end.y - start.y).sign;
    route = [start, Point(start.x, start.y + step), Point(start.x, start.y + step * 2), end];
  }
  final elements = <SceneElement>[
    ScenePath(
      id: context.id('state-transition'),
      commands: _graphBasisPath(route),
      fill: const NoFill(),
      stroke: _graphStroke(color, config.edgeWidth),
      cssClasses: const ['state-transition'],
      role: SemanticRole.edge,
      label: transition.label,
    ),
    _graphBarbArrow(context, tip: points.end, tail: points.start, color: color, cssClass: 'state-transition-arrow'),
  ];
  if (transition.label case final label?) {
    final center = middle;
    elements.add(_graphLabelBackground(context, label, center, cssClass: 'state-transition-label-background'));
    elements.add(
      _text(
        context,
        label,
        center.x,
        center.y,
        anchor: TextAnchor.middle,
        style: _stateTextStyle(context, context.options.theme.text),
        cssClasses: const ['state-transition-label'],
      ),
    );
  }
  return elements;
}

Point _statePointToward(Point point, Point target, double distance) {
  final dx = target.x - point.x;
  final dy = target.y - point.y;
  final length = math.sqrt(dx * dx + dy * dy);
  if (length == 0) return point;
  return Point(point.x + dx / length * distance, point.y + dy / length * distance);
}

Size _stateNoteSize(StateNoteAst note, _LayoutContext context) {
  final measured = context.measurer.measure(note.text, context.textStyle);
  return Size(measured.width + _stateNotePadding * 2, measured.height + _stateNotePadding * 2);
}

Size _stateNoteLayoutSize(StateNoteAst note, _LayoutContext context) {
  final size = _stateNoteSize(note, context);
  return Size(size.width + _stateNoteLayoutHorizontalInset * 2, size.height + _stateNoteLayoutVerticalInset * 2);
}

List<SceneElement> _stateNoteElements(
  StateNoteAst note,
  Bounds stateBounds,
  Bounds layoutBounds,
  _LayoutContext context,
  StateRenderOptions config,
) {
  final bounds = Bounds(
    left: layoutBounds.left + _stateNoteLayoutHorizontalInset,
    top: layoutBounds.top + _stateNoteLayoutVerticalInset,
    width: layoutBounds.width - _stateNoteLayoutHorizontalInset * 2,
    height: layoutBounds.height - _stateNoteLayoutVerticalInset * 2,
  );
  final points = _graphEdgePoints(stateBounds, bounds);
  return [
    SceneRect(
      id: context.id('state-note-layout'),
      bounds: layoutBounds,
      fill: const NoFill(),
      cssClasses: const ['state-note-layout'],
    ),
    ScenePath(
      id: context.id('state-note-edge'),
      commands: _graphEdgePath(points.start, points.end),
      fill: const NoFill(),
      stroke: SceneStroke(color: context.options.theme.line, width: config.edgeWidth, dashes: const [5, 5]),
      cssClasses: const ['state-transition', 'state-note-edge'],
      role: SemanticRole.edge,
    ),
    SceneRect(
      id: context.id('state-note'),
      bounds: bounds,
      fill: const SolidFill(_stateNoteFill),
      stroke: _graphStroke(_stateNoteBorder, 1),
      cssClasses: const ['state-note'],
      role: SemanticRole.annotation,
      label: note.text,
    ),
    _text(
      context,
      note.text,
      bounds.center.x,
      bounds.center.y,
      anchor: TextAnchor.middle,
      style: _stateTextStyle(context, _stateNoteText),
      cssClasses: const ['state-note-text'],
    ),
  ];
}

_FlowchartGraphLayout _stateChildGraph(StateAst state, _LayoutContext context, StateRenderOptions config) =>
    _layoutGraphBoxes(
      ids: state.children.map((child) => child.id).toList(growable: false),
      sizes: {for (final child in state.children) child.id: _stateNodeSize(child, context, config)},
      edges: [
        for (final transition in state.transitions) _GraphEdgeLayout(transition.from, transition.to, transition.label),
      ],
      direction: state.direction ?? GraphDirection.topDown,
      nodeSpacing: config.nodeSpacing,
      rankSpacing: _stateCompositeRankSpacing,
      padding: 0,
      context: context,
    );

SceneTextStyle _stateTextStyle(_LayoutContext context, Color color) => SceneTextStyle(
  fontFamily: context.textStyle.fontFamily,
  fontSize: context.textStyle.fontSize,
  color: color,
  lineHeight: context.textStyle.lineHeight,
);
