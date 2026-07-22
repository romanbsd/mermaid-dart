part of '../layout.dart';

// Mermaid pie renderer typography, filtering, geometry, and stroke defaults.
const _pieLabelFontSize = 17.0;
const _pieTitleFontSize = 25.0;
const _pieMinimumVisiblePercentage = 1.0;
const _percentageScale = 100.0;
const _pieLegendRectSize = 18.0;
const _pieLegendSpacing = 4.0;
const _pieLegendRightOffsetInRects = 12.0;
const _pieOuterRadiusOffset = 1.0;
const _pieStrokeWidth = 2.0;
const _pieMaximumDonutRatio = .9;
const _pieTitleY = 25.0;
const _fullCircleTolerance = 1e-9;

_LayoutResult _layoutPie(PieAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const PieRenderOptions());
  final textStyle = _mermaidTextStyle(context, _pieLabelFontSize);
  final legendTextStyle = SceneTextStyle(
    fontFamily: textStyle.fontFamily,
    fontSize: textStyle.fontSize,
    color: config.legendText,
  );
  final inheritedTitleStyle = _mermaidTextStyle(context, _pieTitleFontSize);
  final titleStyle = SceneTextStyle(
    fontFamily: inheritedTitleStyle.fontFamily,
    fontSize: inheritedTitleStyle.fontSize,
    color: config.titleText,
  );
  final radius = config.radius ?? config.size / 2 - config.margin;
  final total = ast.sections.fold<double>(0, (sum, section) => sum + math.max(0, section.value.toDouble()));
  final rendered = <({int index, PieSectionAst section})>[
    for (var i = 0; i < ast.sections.length; i++)
      if (total > 0 &&
          math.max(0, ast.sections[i].value.toDouble()) / total * _percentageScale >= _pieMinimumVisiblePercentage)
        (index: i, section: ast.sections[i]),
  ];
  final arcTotal = rendered.fold<double>(0, (sum, entry) => sum + entry.section.value.toDouble());
  final legendLineHeight = _pieLegendRectSize + _pieLegendSpacing;
  final legendLabels = [
    for (final section in ast.sections) '${section.label}${ast.showData ? ' [${section.value}]' : ''}',
  ];
  final longestLegend = legendLabels
      .map((label) => context.measurer.measure(label, textStyle).width)
      .fold(0.0, math.max);
  final legendWidth = _pieLegendRectSize + _pieLegendSpacing + longestLegend;
  final totalLegendHeight = ast.sections.length * legendLineHeight;
  var width = config.size + config.margin;
  var height = config.size;
  var center = Point(config.size / 2, config.size / 2);
  var legendLeft = center.x + _pieLegendRightOffsetInRects * _pieLegendRectSize;
  var legendTop = center.y - totalLegendHeight / 2;
  switch (config.legendPosition) {
    case PieLegendPosition.top:
      height += totalLegendHeight;
      legendLeft = center.x - longestLegend / 2 - _pieLegendRectSize - _pieLegendSpacing;
      legendTop = config.margin;
      center = Point(center.x, center.y + totalLegendHeight + legendLineHeight);
    case PieLegendPosition.bottom:
      height += totalLegendHeight;
      legendLeft = center.x - longestLegend / 2 - _pieLegendRectSize - _pieLegendSpacing;
      legendTop = center.y + radius + legendLineHeight;
    case PieLegendPosition.left:
      width += legendWidth;
      legendLeft = _pieLegendRectSize;
      legendTop = center.y - totalLegendHeight / 2;
      center = Point(center.x + legendWidth + legendLineHeight, center.y);
    case PieLegendPosition.right:
      width += legendWidth;
    case PieLegendPosition.center:
      legendLeft = center.x - longestLegend / 2 - _pieLegendRectSize - _pieLegendSpacing;
      legendTop = center.y - totalLegendHeight / 2;
  }
  final elements = <SceneElement>[];
  elements.add(
    SceneCircle(
      id: context.id('pie-outer-circle'),
      center: center,
      radius: radius + _pieOuterRadiusOffset,
      fill: const NoFill(),
      stroke: SceneStroke(color: config.outerStroke, width: _pieStrokeWidth),
      cssClasses: const ['pieOuterCircle'],
    ),
  );
  var angle = -math.pi / 2;
  final innerRadius = config.donutHole > 0 && config.donutHole <= _pieMaximumDonutRatio
      ? radius * config.donutHole
      : 0.0;
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
        fill: SolidFill(_colorWithOpacity(_pieSectionColor(config, entry.index), config.sectionOpacity)),
        stroke: SceneStroke(
          color: _colorWithOpacity(config.sectionStroke, config.sectionOpacity),
          width: _pieStrokeWidth,
        ),
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
        '${(section.value.toDouble() / total * _percentageScale).round()}%',
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
            width: _pieLegendRectSize,
            height: _pieLegendRectSize,
          ),
          fill: SolidFill(_pieSectionColor(config, i)),
          stroke: SceneStroke(color: _pieSectionColor(config, i)),
          role: SemanticRole.legend,
          cssClasses: const ['legend'],
        ),
      );
      elements.add(
        _text(
          context,
          legendLabels[i],
          legendLeft + _pieLegendRectSize + _pieLegendSpacing,
          legendTop + i * legendLineHeight + _pieLegendRectSize - _pieLegendSpacing,
          role: SemanticRole.legend,
          baseline: TextBaseline.alphabetic,
          style: legendTextStyle,
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
        _pieTitleY,
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

Color _pieSectionColor(PieRenderOptions config, int index) {
  final colors = config.sectionColors.isEmpty ? const PieRenderOptions().sectionColors : config.sectionColors;
  return colors[index % colors.length];
}

List<PathCommand> _pieArcCommands(Point center, double outer, double inner, double start, double end) {
  Point polar(double radius, double angle) =>
      Point(center.x + radius * math.cos(angle), center.y + radius * math.sin(angle));
  final sweep = end - start;
  final full = sweep >= math.pi * 2 - _fullCircleTolerance;
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
