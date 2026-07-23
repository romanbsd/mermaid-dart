part of '../layout.dart';

// Mermaid pie renderer typography, filtering, geometry, and stroke defaults.
const _pieMinimumVisiblePercentage = 1.0;
const _percentageScale = 100.0;
const _pieLegendRectSize = 18.0;
const _pieLegendSpacing = 4.0;
const _pieLegendRightOffsetInRects = 12.0;
const _pieMaximumDonutRatio = .9;
const _pieTitleY = 25.0;

/// Mermaid's `.pieCircle.highlighted` stylesheet enlarges the selected slice
/// by five percent. The scene records that visual state as explicit geometry.
const _pieHighlightScale = 1.05;

_LayoutResult _layoutPie(PieAst ast, _LayoutContext context) {
  final config = context.options.optionsFor(const PieRenderOptions());
  final theme = config.resolveTheme(context.options.theme);
  final sectionColors = config.resolveSectionColors(context.options.theme);
  final textStyle = SceneTextStyle(
    fontFamily: context.options.theme.resolveFontFamily(fallback: _mermaidFontFamily),
    fontSize: theme.sectionTextSize,
    color: theme.sectionTextColor,
  );
  final legendTextStyle = SceneTextStyle(
    fontFamily: textStyle.fontFamily,
    fontSize: theme.legendTextSize,
    color: theme.legendTextColor,
  );
  final inheritedTitleStyle = _mermaidTextStyle(context, theme.titleTextSize);
  final titleStyle = SceneTextStyle(
    fontFamily: inheritedTitleStyle.fontFamily,
    fontSize: inheritedTitleStyle.fontSize,
    color: theme.titleTextColor,
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
      // The SVG renderer centers the outer stroke on this radius. Mermaid
      // expands it by half the configured stroke width so its inner edge stays
      // aligned with the pie's radius for every custom width.
      radius: radius + theme.outerStrokeWidth / 2,
      fill: const NoFill(),
      stroke: SceneStroke(color: theme.outerStrokeColor, width: theme.outerStrokeWidth),
      cssClasses: const ['pieOuterCircle'],
    ),
  );
  var angle = topAngleRadians;
  final innerRadius = config.donutHole > 0 && config.donutHole <= _pieMaximumDonutRatio
      ? radius * config.donutHole
      : 0.0;
  for (final entry in rendered) {
    final section = entry.section;
    final sweep = section.value.toDouble() / arcTotal * fullTurnRadians;
    final end = angle + sweep;
    final classes = <String>['pieCircle'];
    final isHighlighted = config.highlightSlice == section.label;
    if (config.highlightSlice == 'hover') {
      classes.add('highlightedOnHover');
    } else if (isHighlighted) {
      classes.add('highlighted');
    }
    final sectionOpacity = isHighlighted ? 1.0 : theme.opacity;
    final path = ScenePath(
      id: context.id('pie-section'),
      commands: annularSectorPath(
        center: isHighlighted ? const Point(0, 0) : center,
        outerRadius: radius,
        innerRadius: innerRadius,
        startAngle: angle,
        endAngle: end,
      ),
      fill: SolidFill(_colorWithOpacity(_pieSectionColor(sectionColors, entry.index), sectionOpacity)),
      stroke: SceneStroke(color: _colorWithOpacity(theme.strokeColor, sectionOpacity), width: theme.strokeWidth),
      role: SemanticRole.node,
      cssClasses: classes,
      label: section.label,
    );
    elements.add(
      isHighlighted
          ? SceneGroup(
              id: context.id('pie-highlight'),
              transforms: [Translate(center.x, center.y), const Scale(_pieHighlightScale)],
              cssClasses: const ['pie-highlight-transform'],
              children: [path],
            )
          : path,
    );
    final middle = angle + sweep / 2;
    final labelRadius = radius * config.textPosition.clamp(0, 1);
    final labelPosition = polarPoint(center, labelRadius, middle);
    elements.add(
      _text(
        context,
        '${(section.value.toDouble() / total * _percentageScale).round()}%',
        labelPosition.x,
        labelPosition.y,
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
          fill: SolidFill(_pieSectionColor(sectionColors, i)),
          stroke: SceneStroke(color: _pieSectionColor(sectionColors, i)),
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

Color _pieSectionColor(List<Color> colors, int index) {
  return colors[index % colors.length];
}
