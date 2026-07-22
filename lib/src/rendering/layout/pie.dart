part of '../layout.dart';

_LayoutResult _layoutPie(PieAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const PieRenderOptions());
  final textStyle = _mermaidTextStyle(context, 17);
  final titleStyle = _mermaidTextStyle(context, 25);
  final radius = config.radius ?? config.size / 2 - config.margin;
  final total = ast.sections.fold<double>(0, (sum, section) => sum + math.max(0, section.value.toDouble()));
  final rendered = <({int index, PieSectionAst section})>[
    for (var i = 0; i < ast.sections.length; i++)
      if (total > 0 && math.max(0, ast.sections[i].value.toDouble()) / total * 100 >= 1)
        (index: i, section: ast.sections[i]),
  ];
  final arcTotal = rendered.fold<double>(0, (sum, entry) => sum + entry.section.value.toDouble());
  const legendRectSize = 18.0;
  const legendSpacing = 4.0;
  final legendLineHeight = legendRectSize + legendSpacing;
  final legendLabels = [
    for (final section in ast.sections) '${section.label}${ast.showData ? ' [${section.value}]' : ''}',
  ];
  final longestLegend = legendLabels
      .map((label) => context.measurer.measure(label, textStyle).width)
      .fold(0.0, math.max);
  final legendWidth = legendRectSize + legendSpacing + longestLegend;
  final totalLegendHeight = ast.sections.length * legendLineHeight;
  var width = config.size + config.margin;
  var height = config.size;
  var center = Point(config.size / 2, config.size / 2);
  var legendLeft = center.x + 12 * legendRectSize;
  var legendTop = center.y - totalLegendHeight / 2;
  switch (config.legendPosition) {
    case PieLegendPosition.top:
      height += totalLegendHeight;
      legendLeft = center.x - longestLegend / 2 - legendRectSize - legendSpacing;
      legendTop = config.margin;
      center = Point(center.x, center.y + totalLegendHeight + legendLineHeight);
    case PieLegendPosition.bottom:
      height += totalLegendHeight;
      legendLeft = center.x - longestLegend / 2 - legendRectSize - legendSpacing;
      legendTop = center.y + radius + legendLineHeight;
    case PieLegendPosition.left:
      width += legendWidth;
      legendLeft = legendRectSize;
      legendTop = center.y - totalLegendHeight / 2;
      center = Point(center.x + legendWidth + legendLineHeight, center.y);
    case PieLegendPosition.right:
      width += legendWidth;
    case PieLegendPosition.center:
      legendLeft = center.x - longestLegend / 2 - legendRectSize - legendSpacing;
      legendTop = center.y - totalLegendHeight / 2;
  }
  final elements = <SceneElement>[];
  elements.add(
    SceneCircle(
      id: context.id('pie-outer-circle'),
      center: center,
      radius: radius + 1,
      fill: const NoFill(),
      stroke: _stroke(context, width: 2),
      cssClasses: const ['pieOuterCircle'],
    ),
  );
  var angle = -math.pi / 2;
  final innerRadius = config.donutHole > 0 && config.donutHole <= .9 ? radius * config.donutHole : 0.0;
  for (final entry in rendered) {
    final section = entry.section;
    final sweep = section.value.toDouble() / arcTotal * math.pi * 2;
    final end = angle + sweep;
    final classes = <String>['pieCircle'];
    if (config.highlightSlice == 'hover') {
      classes.add('highlightedOnHover');
    } else if (config.highlightSlice == section.label) {
      classes.add('highlighted');
    }
    elements.add(
      ScenePath(
        id: context.id('pie-section'),
        commands: _pieArcCommands(center, radius, innerRadius, angle, end),
        fill: SolidFill(_palette[entry.index % _palette.length]),
        stroke: const SceneStroke(color: Color(255, 255, 255), width: 2),
        role: SemanticRole.node,
        cssClasses: classes,
        label: section.label,
      ),
    );
    final middle = angle + sweep / 2;
    final labelRadius = radius * config.textPosition.clamp(0, 1);
    elements.add(
      _text(
        context,
        '${(section.value.toDouble() / total * 100).round()}%',
        center.x + math.cos(middle) * labelRadius,
        center.y + math.sin(middle) * labelRadius,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.alphabetic,
        style: textStyle,
        cssClasses: const ['slice'],
      ),
    );
    angle = end;
  }
  if (config.showLegend) {
    for (var i = 0; i < ast.sections.length; i++) {
      elements.add(
        SceneRect(
          id: context.id('legend-swatch'),
          bounds: Bounds(
            left: legendLeft,
            top: legendTop + i * legendLineHeight,
            width: legendRectSize,
            height: legendRectSize,
          ),
          fill: SolidFill(_palette[i % _palette.length]),
          stroke: SceneStroke(color: _palette[i % _palette.length]),
          role: SemanticRole.legend,
          cssClasses: const ['legend'],
        ),
      );
      elements.add(
        _text(
          context,
          legendLabels[i],
          legendLeft + legendRectSize + legendSpacing,
          legendTop + i * legendLineHeight + legendRectSize - legendSpacing,
          role: SemanticRole.legend,
          baseline: TextBaseline.alphabetic,
          style: textStyle,
          cssClasses: const ['legendText'],
        ),
      );
    }
  }
  if (ast.title != null) {
    elements.add(
      _text(
        context,
        ast.title!,
        config.size / 2,
        25,
        anchor: TextAnchor.middle,
        baseline: TextBaseline.alphabetic,
        role: SemanticRole.title,
        style: titleStyle,
        cssClasses: const ['pieTitleText'],
      ),
    );
  }
  return _LayoutResult(width, height, elements);
}

List<PathCommand> _pieArcCommands(Point center, double outer, double inner, double start, double end) {
  Point polar(double radius, double angle) =>
      Point(center.x + radius * math.cos(angle), center.y + radius * math.sin(angle));
  final sweep = end - start;
  final full = sweep >= math.pi * 2 - 1e-9;
  final commands = <PathCommand>[MoveTo(polar(outer, start))];
  if (full) {
    commands
      ..add(ArcTo(radiusX: outer, radiusY: outer, end: polar(outer, start + math.pi)))
      ..add(ArcTo(radiusX: outer, radiusY: outer, end: polar(outer, end)));
  } else {
    commands.add(ArcTo(radiusX: outer, radiusY: outer, largeArc: sweep > math.pi, end: polar(outer, end)));
  }
  if (inner == 0) {
    commands.add(LineTo(center));
  } else {
    commands.add(LineTo(polar(inner, end)));
    if (full) {
      commands
        ..add(ArcTo(radiusX: inner, radiusY: inner, clockwise: false, end: polar(inner, start + math.pi)))
        ..add(ArcTo(radiusX: inner, radiusY: inner, clockwise: false, end: polar(inner, start)));
    } else {
      commands.add(
        ArcTo(radiusX: inner, radiusY: inner, largeArc: sweep > math.pi, clockwise: false, end: polar(inner, start)),
      );
    }
  }
  commands.add(const ClosePath());
  return commands;
}
