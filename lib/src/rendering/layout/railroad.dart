part of '../layout.dart';

// Mermaid's railroad stylesheet uses `stroke-dasharray: 5,3`.
const _railSpecialDashLength = 5.0;
const _railSpecialGapLength = 3.0;

// Mermaid terminals always use a fixed corner radius; arcRadius only controls
// routing curves around choices, optional branches, and repetitions.
const _railTerminalRadius = 10.0;

final class _RailBox {
  const _RailBox(this.width, this.height, this.up, this.down, this.elements);
  final double width;
  final double height;
  final double up;
  final double down;
  final List<SceneElement> elements;
}

_RailBox _railNode(RailroadNodeAst node, _LayoutContext context) => switch (node) {
  RailroadTerminalAst(:final value) => _railLeaf(value, context, true),
  RailroadNonTerminalAst(:final name) => _railLeaf(name, context, false),
  RailroadSpecialAst(:final text) => _railLeaf('? $text ?', context, false, special: true),
  RailroadSequenceAst(:final elements) => _railSequence(elements, context),
  RailroadChoiceAst(:final alternatives) => _railChoice(alternatives, context),
  RailroadOptionalAst(:final element) => _railOptional(element, context),
  RailroadRepetitionAst(:final element, :final min, :final max) => _railRepetition(element, min, max, context),
};

SceneTextStyle _railTextStyle(_LayoutContext context, {FontWeight weight = FontWeight.normal, Color? color}) {
  final config = context.options.optionsFor(const RailroadRenderOptions());
  final theme = config.resolveTheme(context.options.theme);
  return SceneTextStyle(
    fontFamily: theme.fontFamily,
    fontSize: theme.fontSize,
    weight: weight,
    color: color ?? theme.nonTerminalTextColor,
  );
}

SceneStroke _railStroke(_LayoutContext context, {bool dashed = false, Color? color}) {
  final config = context.options.optionsFor(const RailroadRenderOptions());
  final theme = config.resolveTheme(context.options.theme);
  return SceneStroke(
    color: color ?? theme.lineColor,
    width: theme.strokeWidth,
    dashes: dashed ? const [_railSpecialDashLength, _railSpecialGapLength] : const [],
  );
}

ScenePath _railPath(_LayoutContext context, List<PathCommand> commands) => ScenePath(
  id: context.id('railroad-line'),
  commands: commands,
  fill: const NoFill(),
  stroke: _railStroke(context),
  role: SemanticRole.edge,
  cssClasses: const ['railroad-line'],
);

_RailBox _railLeaf(String label, _LayoutContext context, bool terminal, {bool special = false}) {
  final config = context.options.optionsFor(const RailroadRenderOptions());
  final theme = config.resolveTheme(context.options.theme);
  final fillColor = terminal
      ? theme.terminalFill
      : special
      ? theme.specialFill
      : theme.nonTerminalFill;
  final borderColor = terminal
      ? theme.terminalStroke
      : special
      ? theme.specialStroke
      : theme.nonTerminalStroke;
  final textColor = terminal ? theme.terminalTextColor : theme.nonTerminalTextColor;
  final style = _railTextStyle(context, color: textColor);
  final measured = context.measurer.measure(label, style);
  final width = measured.width + config.padding * 2;
  final height = measured.height + config.padding * 2;
  final groupClass = terminal ? 'railroad-terminal' : (special ? 'railroad-special' : 'railroad-nonterminal');
  return _RailBox(width, height, height / 2, height / 2, [
    SceneGroup(
      id: context.id(groupClass),
      cssClasses: [groupClass],
      role: SemanticRole.node,
      label: label,
      children: [
        SceneRect(
          id: context.id('railroad-node'),
          bounds: Bounds(left: 0, top: 0, width: width, height: height),
          radiusX: terminal ? _railTerminalRadius : 0,
          radiusY: terminal ? _railTerminalRadius : 0,
          fill: SolidFill(fillColor),
          stroke: _railStroke(context, dashed: special, color: borderColor),
          role: SemanticRole.node,
          label: label,
        ),
        _text(
          context,
          label,
          width / 2,
          height / 2,
          anchor: TextAnchor.middle,
          baseline: TextBaseline.middle,
          style: style,
        ),
      ],
    ),
  ]);
}

_RailBox _railSequence(List<RailroadNodeAst> nodes, _LayoutContext context) {
  if (nodes.isEmpty) return const _RailBox(0, 0, 0, 0, []);
  final config = context.options.optionsFor(const RailroadRenderOptions());
  final boxes = nodes.map((node) => _railNode(node, context)).toList();
  final up = boxes.map((box) => box.up).reduce(math.max);
  final down = boxes.map((box) => box.down).reduce(math.max);
  final height = up + down;
  final elements = <SceneElement>[];
  var x = 0.0;
  for (var i = 0; i < boxes.length; i++) {
    final box = boxes[i];
    final y = up - box.up;
    elements.add(SceneGroup(id: context.id('rail-item'), transforms: [Translate(x, y)], children: box.elements));
    x += box.width;
    if (i != boxes.length - 1) {
      elements.add(_railPath(context, [MoveTo(Point(x, up)), LineTo(Point(x + config.horizontalSeparation, up))]));
      x += config.horizontalSeparation;
    }
  }
  return _RailBox(x, height, up, down, [
    SceneGroup(id: context.id('railroad-sequence'), children: elements, cssClasses: const ['railroad-sequence']),
  ]);
}

_RailBox _railChoice(List<RailroadNodeAst> nodes, _LayoutContext context) {
  final boxes = nodes.map((node) => _railNode(node, context)).toList();
  if (boxes.isEmpty) return const _RailBox(0, 0, 0, 0, []);
  final config = context.options.optionsFor(const RailroadRenderOptions());
  final radius = config.arcRadius;
  final maxWidth = boxes.map((box) => box.width).fold(0.0, math.max);
  final height = boxes.fold(0.0, (sum, box) => sum + box.height) + config.verticalSeparation * (boxes.length - 1);
  final width = maxWidth + radius * 4;
  final centerY = height / 2;
  final elements = <SceneElement>[];
  var y = 0.0;
  for (final box in boxes) {
    final itemCenterY = y + box.up;
    final itemX = radius * 2 + (maxWidth - box.width) / 2;
    final below = itemCenterY > centerY;
    elements.add(
      SceneGroup(id: context.id('rail-choice-item'), transforms: [Translate(itemX, y)], children: box.elements),
    );
    final left = <PathCommand>[MoveTo(Point(0, centerY))];
    if (itemCenterY == centerY) {
      left.add(LineTo(Point(itemX, itemCenterY)));
    } else {
      left
        ..add(
          ArcTo(
            radiusX: radius,
            radiusY: radius,
            clockwise: below,
            end: Point(radius, centerY + (below ? radius : -radius)),
          ),
        )
        ..add(LineTo(Point(radius, itemCenterY - (below ? radius : -radius))))
        ..add(ArcTo(radiusX: radius, radiusY: radius, clockwise: !below, end: Point(radius * 2, itemCenterY)))
        ..add(LineTo(Point(itemX, itemCenterY)));
    }
    elements.add(_railPath(context, left));
    final rightStart = itemX + box.width;
    final right = <PathCommand>[MoveTo(Point(rightStart, itemCenterY))];
    if (itemCenterY == centerY) {
      right.add(LineTo(Point(width, centerY)));
    } else {
      right
        ..add(LineTo(Point(width - radius * 2, itemCenterY)))
        ..add(
          ArcTo(
            radiusX: radius,
            radiusY: radius,
            clockwise: !below,
            end: Point(width - radius, itemCenterY + (below ? -radius : radius)),
          ),
        )
        ..add(LineTo(Point(width - radius, centerY + (below ? radius : -radius))))
        ..add(ArcTo(radiusX: radius, radiusY: radius, clockwise: below, end: Point(width, centerY)));
    }
    elements.add(_railPath(context, right));
    y += box.height + config.verticalSeparation;
  }
  return _RailBox(width, height, centerY, height - centerY, [
    SceneGroup(id: context.id('railroad-choice'), children: elements, cssClasses: const ['railroad-choice']),
  ]);
}

_RailBox _railOptional(RailroadNodeAst node, _LayoutContext context) {
  final box = _railNode(node, context);
  final radius = context.options.optionsFor(const RailroadRenderOptions()).arcRadius;
  final width = box.width + radius * 4;
  final height = box.height + radius * 2;
  final itemY = radius * 2;
  final centerY = itemY + box.up;
  final elements = <SceneElement>[
    SceneGroup(
      id: context.id('rail-optional-item'),
      transforms: [Translate(radius * 2, itemY)],
      children: box.elements,
    ),
    _railPath(context, [MoveTo(Point(0, centerY)), LineTo(Point(radius * 2, centerY))]),
    _railPath(context, [MoveTo(Point(radius * 2 + box.width, centerY)), LineTo(Point(width, centerY))]),
    _railPath(context, [
      MoveTo(Point(0, centerY)),
      ArcTo(radiusX: radius, radiusY: radius, clockwise: false, end: Point(radius, centerY - radius)),
      LineTo(Point(radius, radius)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2, 0)),
      LineTo(Point(width - radius * 2, 0)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(width - radius, radius)),
      LineTo(Point(width - radius, centerY - radius)),
      ArcTo(radiusX: radius, radiusY: radius, clockwise: false, end: Point(width, centerY)),
    ]),
  ];
  return _RailBox(width, height, centerY, height - centerY, [
    SceneGroup(id: context.id('railroad-optional'), children: elements, cssClasses: const ['railroad-optional']),
  ]);
}

_RailBox _railRepetition(RailroadNodeAst node, int min, num max, _LayoutContext context) {
  final box = _railNode(node, context);
  final radius = context.options.optionsFor(const RailroadRenderOptions()).arcRadius;
  final hasBypass = min == 0;
  final itemY = hasBypass ? radius * 2 : 0.0;
  final width = box.width + radius * 4;
  final height = box.height + radius * 2 + (hasBypass ? radius * 2 : 0);
  final centerY = itemY + box.up;
  final loopY = itemY + box.height + radius;
  final elements = <SceneElement>[
    SceneGroup(id: context.id('rail-repeat-item'), transforms: [Translate(radius * 2, itemY)], children: box.elements),
    _railPath(context, [MoveTo(Point(0, centerY)), LineTo(Point(radius * 2, centerY))]),
    _railPath(context, [MoveTo(Point(radius * 2 + box.width, centerY)), LineTo(Point(width, centerY))]),
    _railPath(context, [
      MoveTo(Point(radius * 2 + box.width, centerY)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 3 + box.width, centerY + radius)),
      LineTo(Point(radius * 3 + box.width, loopY)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2 + box.width, loopY + radius)),
      LineTo(Point(radius * 2, loopY + radius)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius, loopY)),
      LineTo(Point(radius, centerY + radius)),
      ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2, centerY)),
    ]),
    if (hasBypass)
      _railPath(context, [
        MoveTo(Point(0, centerY)),
        ArcTo(radiusX: radius, radiusY: radius, clockwise: false, end: Point(radius, centerY - radius)),
        LineTo(Point(radius, radius)),
        ArcTo(radiusX: radius, radiusY: radius, end: Point(radius * 2, 0)),
        LineTo(Point(width - radius * 2, 0)),
        ArcTo(radiusX: radius, radiusY: radius, end: Point(width - radius, radius)),
        LineTo(Point(width - radius, centerY - radius)),
        ArcTo(radiusX: radius, radiusY: radius, clockwise: false, end: Point(width, centerY)),
      ]),
  ];
  return _RailBox(width, height, centerY, height - centerY, [
    SceneGroup(id: context.id('railroad-repetition'), children: elements, cssClasses: const ['railroad-repetition']),
  ]);
}

_LayoutResult _layoutRailroad(RailroadAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const RailroadRenderOptions());
  final theme = config.resolveTheme(context.options.theme);
  if (ast.rules.isEmpty) return const _LayoutResult(200, 100, []);
  final style = _railTextStyle(context);
  final ruleStyle = _railTextStyle(context, weight: FontWeight.bold, color: theme.ruleNameColor);
  final elements = <SceneElement>[];
  var y = config.padding;
  var width = 0.0;
  for (final rule in ast.rules) {
    final ruleName = '${rule.name} =';
    final nameWidth = context.measurer.measure(ruleName, style).width + 20;
    final definitionX = nameWidth + 20;
    final box = _railNode(rule.definition, context);
    final baselineY = math.max(20.0, box.up);
    final definitionY = baselineY - box.up;
    final endX = definitionX + box.width + 10;
    final ruleElements = <SceneElement>[
      SceneGroup(
        id: context.id('rail-definition'),
        transforms: [Translate(definitionX, definitionY)],
        children: box.elements,
      ),
      _text(
        context,
        ruleName,
        0,
        baselineY,
        baseline: TextBaseline.alphabetic,
        role: SemanticRole.title,
        style: ruleStyle,
        cssClasses: const ['railroad-rule-name'],
      ),
      if (config.showMarkers) ...[
        SceneCircle(
          id: context.id('railroad-start'),
          center: Point(nameWidth, baselineY),
          radius: config.markerRadius,
          fill: SolidFill(theme.markerFill),
          cssClasses: const ['railroad-start'],
        ),
        SceneCircle(
          id: context.id('railroad-end'),
          center: Point(endX, baselineY),
          radius: config.markerRadius,
          fill: SolidFill(theme.markerFill),
          cssClasses: const ['railroad-end'],
        ),
      ],
      _railPath(context, [
        MoveTo(Point(nameWidth + config.markerRadius, baselineY)),
        LineTo(Point(definitionX, baselineY)),
      ]),
      _railPath(context, [
        MoveTo(Point(definitionX + box.width, baselineY)),
        LineTo(Point(endX - config.markerRadius, baselineY)),
      ]),
    ];
    elements.add(
      SceneGroup(
        id: context.id('railroad-rule'),
        transforms: [Translate(0, y)],
        children: ruleElements,
        cssClasses: const ['railroad-rule'],
      ),
    );
    final rowHeight = math.max(40.0, definitionY + box.height + config.padding * 2);
    width = math.max(width, endX + config.markerRadius);
    y += rowHeight + config.verticalSeparation;
  }
  return _LayoutResult(width + config.padding * 2, y + config.padding, elements);
}
