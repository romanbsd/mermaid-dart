part of '../layout.dart';

// Mermaid's railroad stylesheet uses `stroke-dasharray: 5,3`.
const _railSpecialDashLength = 5.0;
const _railSpecialGapLength = 3.0;

// Mermaid terminals always use a fixed corner radius; arcRadius only controls
// routing curves around choices, optional branches, and repetitions.
const _railTerminalRadius = 10.0;

// Mermaid's railroad renderer reserves these fixed dimensions around rules.
const _railEmptyWidth = 200.0;
const _railEmptyHeight = 100.0;
const _railRuleNamePadding = 20.0;
const _railDefinitionGap = 20.0;
const _railMinimumBaseline = 20.0;
const _railEndGap = 10.0;
const _railMinimumRowHeight = 40.0;

final class _RailBox {
  const _RailBox(this.width, this.height, this.up, this.down, this.elements);
  final double width;
  final double height;
  final double up;
  final double down;
  final List<SceneElement> elements;
}

final class _RailroadContext {
  factory _RailroadContext(_LayoutContext scene) {
    final config = scene.options.optionsFor(const RailroadRenderOptions());
    final theme = config.resolveTheme(scene.options.theme);
    SceneTextStyle textStyle({FontWeight weight = FontWeight.normal, Color? color}) => SceneTextStyle(
      fontFamily: theme.fontFamily,
      fontSize: theme.fontSize,
      weight: weight,
      color: color ?? theme.nonTerminalTextColor,
    );
    SceneStroke stroke({bool dashed = false, Color? color}) => SceneStroke(
      color: color ?? theme.lineColor,
      width: theme.strokeWidth,
      dashes: dashed ? const [_railSpecialDashLength, _railSpecialGapLength] : const [],
    );
    return _RailroadContext._(
      scene: scene,
      config: config,
      theme: theme,
      nonTerminalTextStyle: textStyle(),
      terminalTextStyle: textStyle(color: theme.terminalTextColor),
      ruleTextStyle: textStyle(weight: FontWeight.bold, color: theme.ruleNameColor),
      lineStroke: stroke(),
      terminalStroke: stroke(color: theme.terminalStroke),
      nonTerminalStroke: stroke(color: theme.nonTerminalStroke),
      specialStroke: stroke(dashed: true, color: theme.specialStroke),
    );
  }

  const _RailroadContext._({
    required this.scene,
    required this.config,
    required this.theme,
    required this.nonTerminalTextStyle,
    required this.terminalTextStyle,
    required this.ruleTextStyle,
    required this.lineStroke,
    required this.terminalStroke,
    required this.nonTerminalStroke,
    required this.specialStroke,
  });

  final _LayoutContext scene;
  final RailroadRenderOptions config;
  final RailroadTheme theme;
  final SceneTextStyle nonTerminalTextStyle;
  final SceneTextStyle terminalTextStyle;
  final SceneTextStyle ruleTextStyle;
  final SceneStroke lineStroke;
  final SceneStroke terminalStroke;
  final SceneStroke nonTerminalStroke;
  final SceneStroke specialStroke;

  ScenePath path(List<PathCommand> commands) => ScenePath(
    id: scene.id('railroad-line'),
    commands: commands,
    fill: const NoFill(),
    stroke: lineStroke,
    role: SemanticRole.edge,
    cssClasses: const ['railroad-line'],
  );
}

_RailBox _railNode(RailroadNodeAst node, _RailroadContext context) => switch (node) {
  RailroadTerminalAst(:final value) => _railLeaf(value, context, true),
  RailroadNonTerminalAst(:final name) => _railLeaf(name, context, false),
  RailroadSpecialAst(:final text) => _railLeaf('? $text ?', context, false, special: true),
  RailroadSequenceAst(:final elements) => _railSequence(elements, context),
  RailroadChoiceAst(:final alternatives) => _railChoice(alternatives, context),
  RailroadOptionalAst(:final element) => _railOptional(element, context),
  RailroadRepetitionAst(:final element, :final min, :final max) => _railRepetition(element, min, max, context),
};

_RailBox _railLeaf(String label, _RailroadContext context, bool terminal, {bool special = false}) {
  final config = context.config;
  final theme = context.theme;
  final scene = context.scene;
  final fillColor = terminal
      ? theme.terminalFill
      : special
      ? theme.specialFill
      : theme.nonTerminalFill;
  final nodeStroke = terminal
      ? context.terminalStroke
      : special
      ? context.specialStroke
      : context.nonTerminalStroke;
  final style = terminal ? context.terminalTextStyle : context.nonTerminalTextStyle;
  final measured = scene.measurer.measure(label, style);
  final width = measured.width + config.padding * 2;
  final height = measured.height + config.padding * 2;
  final groupClass = terminal ? 'railroad-terminal' : (special ? 'railroad-special' : 'railroad-nonterminal');
  return _RailBox(width, height, height / 2, height / 2, [
    SceneGroup(
      id: scene.id(groupClass),
      cssClasses: [groupClass],
      role: SemanticRole.node,
      label: label,
      children: [
        SceneRect(
          id: scene.id('railroad-node'),
          bounds: Bounds(left: 0, top: 0, width: width, height: height),
          radiusX: terminal ? _railTerminalRadius : 0,
          radiusY: terminal ? _railTerminalRadius : 0,
          fill: SolidFill(fillColor),
          stroke: nodeStroke,
          role: SemanticRole.node,
          label: label,
        ),
        _text(
          scene,
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

_RailBox _railSequence(List<RailroadNodeAst> nodes, _RailroadContext context) {
  if (nodes.isEmpty) return const _RailBox(0, 0, 0, 0, []);
  final config = context.config;
  final scene = context.scene;
  final boxes = nodes.map((node) => _railNode(node, context)).toList();
  final up = boxes.map((box) => box.up).reduce(math.max);
  final down = boxes.map((box) => box.down).reduce(math.max);
  final height = up + down;
  final elements = <SceneElement>[];
  var x = 0.0;
  for (var i = 0; i < boxes.length; i++) {
    final box = boxes[i];
    final y = up - box.up;
    elements.add(SceneGroup(id: scene.id('rail-item'), transforms: [Translate(x, y)], children: box.elements));
    x += box.width;
    if (i != boxes.length - 1) {
      elements.add(context.path([MoveTo(Point(x, up)), LineTo(Point(x + config.horizontalSeparation, up))]));
      x += config.horizontalSeparation;
    }
  }
  return _RailBox(x, height, up, down, [
    SceneGroup(id: scene.id('railroad-sequence'), children: elements, cssClasses: const ['railroad-sequence']),
  ]);
}

_RailBox _railChoice(List<RailroadNodeAst> nodes, _RailroadContext context) {
  final boxes = nodes.map((node) => _railNode(node, context)).toList();
  if (boxes.isEmpty) return const _RailBox(0, 0, 0, 0, []);
  final config = context.config;
  final scene = context.scene;
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
    elements.add(
      SceneGroup(id: scene.id('rail-choice-item'), transforms: [Translate(itemX, y)], children: box.elements),
    );
    final routes = railroadChoiceBranchCommands(
      width: width,
      itemX: itemX,
      itemWidth: box.width,
      itemCenterY: itemCenterY,
      centerY: centerY,
      radius: radius,
    );
    elements
      ..add(context.path(routes.left))
      ..add(context.path(routes.right));
    y += box.height + config.verticalSeparation;
  }
  return _RailBox(width, height, centerY, height - centerY, [
    SceneGroup(id: scene.id('railroad-choice'), children: elements, cssClasses: const ['railroad-choice']),
  ]);
}

_RailBox _railOptional(RailroadNodeAst node, _RailroadContext context) {
  final box = _railNode(node, context);
  final radius = context.config.arcRadius;
  final scene = context.scene;
  final width = box.width + radius * 4;
  final height = box.height + radius * 2;
  final itemY = radius * 2;
  final centerY = itemY + box.up;
  final elements = <SceneElement>[
    SceneGroup(id: scene.id('rail-optional-item'), transforms: [Translate(radius * 2, itemY)], children: box.elements),
    context.path([MoveTo(Point(0, centerY)), LineTo(Point(radius * 2, centerY))]),
    context.path([MoveTo(Point(radius * 2 + box.width, centerY)), LineTo(Point(width, centerY))]),
    context.path(railroadBypassCommands(width: width, baselineY: centerY, radius: radius)),
  ];
  return _RailBox(width, height, centerY, height - centerY, [
    SceneGroup(id: scene.id('railroad-optional'), children: elements, cssClasses: const ['railroad-optional']),
  ]);
}

_RailBox _railRepetition(RailroadNodeAst node, int min, num _, _RailroadContext context) {
  final box = _railNode(node, context);
  final radius = context.config.arcRadius;
  final scene = context.scene;
  final hasBypass = min == 0;
  final itemY = hasBypass ? radius * 2 : 0.0;
  final width = box.width + radius * 4;
  final height = box.height + radius * 2 + (hasBypass ? radius * 2 : 0);
  final centerY = itemY + box.up;
  final loopY = itemY + box.height + radius;
  final elements = <SceneElement>[
    SceneGroup(id: scene.id('rail-repeat-item'), transforms: [Translate(radius * 2, itemY)], children: box.elements),
    context.path([MoveTo(Point(0, centerY)), LineTo(Point(radius * 2, centerY))]),
    context.path([MoveTo(Point(radius * 2 + box.width, centerY)), LineTo(Point(width, centerY))]),
    context.path(
      railroadRepetitionLoopCommands(itemWidth: box.width, baselineY: centerY, loopY: loopY, radius: radius),
    ),
    if (hasBypass) context.path(railroadBypassCommands(width: width, baselineY: centerY, radius: radius)),
  ];
  return _RailBox(width, height, centerY, height - centerY, [
    SceneGroup(id: scene.id('railroad-repetition'), children: elements, cssClasses: const ['railroad-repetition']),
  ]);
}

_LayoutResult _layoutRailroad(RailroadAst ast, _LayoutContext context) {
  final rail = _RailroadContext(context);
  final config = rail.config;
  final theme = rail.theme;
  if (ast.rules.isEmpty) {
    return const _LayoutResult(_railEmptyWidth, _railEmptyHeight, []);
  }
  final style = rail.nonTerminalTextStyle;
  final ruleStyle = rail.ruleTextStyle;
  final elements = <SceneElement>[];
  var y = config.padding;
  var width = 0.0;
  for (final rule in ast.rules) {
    final ruleName = '${rule.name} =';
    final nameWidth = context.measurer.measure(ruleName, style).width + _railRuleNamePadding;
    final definitionX = nameWidth + _railDefinitionGap;
    final box = _railNode(rule.definition, rail);
    final baselineY = math.max(_railMinimumBaseline, box.up);
    final definitionY = baselineY - box.up;
    final endX = definitionX + box.width + _railEndGap;
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
      rail.path([MoveTo(Point(nameWidth + config.markerRadius, baselineY)), LineTo(Point(definitionX, baselineY))]),
      rail.path([
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
    final rowHeight = math.max(_railMinimumRowHeight, definitionY + box.height + config.padding * 2);
    width = math.max(width, endX + config.markerRadius);
    y += rowHeight + config.verticalSeparation;
  }
  return _LayoutResult(width + config.padding * 2, y + config.padding, elements);
}
